import 'dart:async';

import 'package:drift/drift.dart' as drift;

import '../../../core/storage/app_database.dart' as db;
import '../../../core/time/week_set.dart';
import '../domain/timetable_models.dart';

class TimetableRepository {
  TimetableRepository(this.database);

  final db.AppDatabase database;

  Future<void> upsertSemester(Semester semester) async {
    await database
        .into(database.semesters)
        .insertOnConflictUpdate(_semesterCompanion(semester));
  }

  Future<void> deleteSemester(String semesterId) async {
    await database.transaction(() async {
      await (database.delete(
        database.periodDefinitions,
      )..where((table) => table.semesterId.equals(semesterId))).go();
      await _deleteCoursesForSemester(semesterId);
      await (database.delete(
        database.semesters,
      )..where((table) => table.id.equals(semesterId))).go();
    });
  }

  Future<List<Semester>> getSemesters() async {
    final query = database.select(database.semesters)
      ..orderBy([
        (table) => drift.OrderingTerm.desc(table.startDate),
        (table) => drift.OrderingTerm.asc(table.name),
      ]);
    return (await query.get()).map(_semesterFromRow).toList();
  }

  Stream<List<Semester>> watchSemesters() {
    final query = database.select(database.semesters)
      ..orderBy([
        (table) => drift.OrderingTerm.desc(table.startDate),
        (table) => drift.OrderingTerm.asc(table.name),
      ]);
    return query.watch().map(
      (rows) => rows.map(_semesterFromRow).toList(growable: false),
    );
  }

  Stream<Semester?> watchCurrentSemester() {
    return watchSemesters().map((semesters) {
      for (final semester in semesters) {
        if (semester.isCurrent) {
          return semester;
        }
      }
      return semesters.isEmpty ? null : semesters.first;
    });
  }

  Future<void> setCurrentSemester(String semesterId) async {
    await database.transaction(() async {
      await database
          .update(database.semesters)
          .write(const db.SemestersCompanion(isCurrent: drift.Value(false)));
      await (database.update(database.semesters)
            ..where((table) => table.id.equals(semesterId)))
          .write(const db.SemestersCompanion(isCurrent: drift.Value(true)));
    });
  }

  Future<void> upsertCourse(CourseWithSessions course) async {
    _validateCourseGraph(course);
    await database.transaction(() async {
      await database
          .into(database.courses)
          .insertOnConflictUpdate(_courseCompanion(course.course));
      await (database.delete(
        database.courseSessions,
      )..where((table) => table.courseId.equals(course.course.id))).go();
      await _insertSessions(course.sessions);
    });
  }

  Future<void> deleteCourse(String courseId) async {
    await database.transaction(() async {
      await (database.delete(
        database.courseSessions,
      )..where((table) => table.courseId.equals(courseId))).go();
      await (database.delete(
        database.courses,
      )..where((table) => table.id.equals(courseId))).go();
    });
  }

  Future<void> upsertPeriodDefinition(PeriodDefinition definition) async {
    await database
        .into(database.periodDefinitions)
        .insertOnConflictUpdate(_periodCompanion(definition));
  }

  Future<void> deletePeriodDefinition(String definitionId) async {
    await (database.delete(
      database.periodDefinitions,
    )..where((table) => table.id.equals(definitionId))).go();
  }

  Future<SemesterTimetable?> getSemesterTimetable(String semesterId) async {
    final semesterRow = await (database.select(
      database.semesters,
    )..where((table) => table.id.equals(semesterId))).getSingleOrNull();
    if (semesterRow == null) {
      return null;
    }
    return _loadSemesterTimetable(_semesterFromRow(semesterRow));
  }

  Stream<SemesterTimetable?> watchSemesterTimetable(String semesterId) {
    final semesterQuery = database.select(database.semesters)
      ..where((table) => table.id.equals(semesterId));
    final courseQuery = database.select(database.courses)
      ..where((table) => table.semesterId.equals(semesterId));
    final sessionsQuery = database.select(database.courseSessions).join([
      drift.innerJoin(
        database.courses,
        database.courses.id.equalsExp(database.courseSessions.courseId),
        useColumns: false,
      ),
    ])..where(database.courses.semesterId.equals(semesterId));
    final periodsQuery = database.select(database.periodDefinitions)
      ..where((table) => table.semesterId.equals(semesterId));

    return _combineLatest4(
      semesterQuery.watchSingleOrNull(),
      courseQuery.watch(),
      sessionsQuery.watch(),
      periodsQuery.watch(),
      (semesterRow, courseRows, sessionRows, periodRows) {
        if (semesterRow == null) {
          return null;
        }
        return _assembleTimetable(
          _semesterFromRow(semesterRow),
          courseRows,
          sessionRows
              .map((row) => row.readTable(database.courseSessions))
              .toList(growable: false),
          periodRows,
        );
      },
    );
  }

  Stream<SemesterTimetable?> watchCurrentTimetable() {
    late StreamController<SemesterTimetable?> controller;
    StreamSubscription<Semester?>? semesterSubscription;
    StreamSubscription<SemesterTimetable?>? timetableSubscription;

    controller = StreamController<SemesterTimetable?>.broadcast(
      onListen: () {
        semesterSubscription = watchCurrentSemester().listen((semester) async {
          await timetableSubscription?.cancel();
          if (semester == null) {
            controller.add(null);
            return;
          }
          timetableSubscription = watchSemesterTimetable(semester.id)
              .listen(controller.add, onError: controller.addError);
        }, onError: controller.addError);
      },
      onCancel: () async {
        await semesterSubscription?.cancel();
        await timetableSubscription?.cancel();
      },
    );
    return controller.stream;
  }

  Future<void> replaceSemesterTimetable(SemesterTimetable timetable) async {
    await applyImport(timetable, replaceCourses: true, replacePeriods: true);
  }

  Future<void> mergeSemesterTimetable(SemesterTimetable timetable) async {
    await applyImport(timetable, replaceCourses: false, replacePeriods: false);
  }

  /// Atomically applies semester metadata, courses, and period definitions.
  /// Course replacement and period replacement are deliberately independent.
  Future<void> applyImport(
    SemesterTimetable timetable, {
    required bool replaceCourses,
    required bool replacePeriods,
  }) async {
    _validateTimetable(timetable);
    await database.transaction(() async {
      await database
          .into(database.semesters)
          .insertOnConflictUpdate(_semesterCompanion(timetable.semester));
      if (replacePeriods) {
        await (database.delete(
              database.periodDefinitions,
            )..where((table) => table.semesterId.equals(timetable.semester.id)))
            .go();
      }
      if (replaceCourses) {
        await _deleteCoursesForSemester(timetable.semester.id);
      }
      for (final definition in timetable.periodDefinitions) {
        await database
            .into(database.periodDefinitions)
            .insertOnConflictUpdate(_periodCompanion(definition));
      }
      for (final course in timetable.courses) {
        await database
            .into(database.courses)
            .insertOnConflictUpdate(_courseCompanion(course.course));
        for (final session in course.sessions) {
          await database
              .into(database.courseSessions)
              .insertOnConflictUpdate(_sessionCompanion(session));
        }
      }
    });
  }

  Future<void> _insertSessions(Iterable<CourseSession> sessions) async {
    for (final session in sessions) {
      await database
          .into(database.courseSessions)
          .insert(_sessionCompanion(session));
    }
  }

  Future<void> _deleteCoursesForSemester(String semesterId) async {
    final courseIds =
        await (database.selectOnly(database.courses)
              ..addColumns([database.courses.id])
              ..where(database.courses.semesterId.equals(semesterId)))
            .map((row) => row.read(database.courses.id)!)
            .get();
    if (courseIds.isNotEmpty) {
      await (database.delete(
        database.courseSessions,
      )..where((table) => table.courseId.isIn(courseIds))).go();
    }
    await (database.delete(
      database.courses,
    )..where((table) => table.semesterId.equals(semesterId))).go();
  }

  Future<SemesterTimetable> _loadSemesterTimetable(Semester semester) async {
    final courseRows = await (database.select(
      database.courses,
    )..where((table) => table.semesterId.equals(semester.id))).get();
    final courseIds = courseRows.map((row) => row.id).toList(growable: false);
    final sessionRows = courseIds.isEmpty
        ? <db.CourseSession>[]
        : await (database.select(
            database.courseSessions,
          )..where((table) => table.courseId.isIn(courseIds))).get();
    final periodRows = await (database.select(
      database.periodDefinitions,
    )..where((table) => table.semesterId.equals(semester.id))).get();
    return _assembleTimetable(semester, courseRows, sessionRows, periodRows);
  }

  SemesterTimetable _assembleTimetable(
    Semester semester,
    List<db.Course> courseRows,
    List<db.CourseSession> sessionRows,
    List<db.PeriodDefinition> periodRows,
  ) {
    final sessionsByCourse = <String, List<CourseSession>>{};
    for (final row in sessionRows) {
      (sessionsByCourse[row.courseId] ??= []).add(_sessionFromRow(row));
    }
    for (final sessions in sessionsByCourse.values) {
      sessions.sort(_compareSessions);
    }

    final courses =
        courseRows
            .map(
              (row) => CourseWithSessions(
                course: _courseFromRow(row),
                sessions: sessionsByCourse[row.id] ?? const [],
              ),
            )
            .toList(growable: false)
          ..sort(
            (first, second) => first.course.name.compareTo(second.course.name),
          );
    final periods = periodRows.map(_periodFromRow).toList(growable: false)
      ..sort((first, second) => first.period.compareTo(second.period));

    return SemesterTimetable(
      semester: semester,
      courses: courses,
      periodDefinitions: periods,
    );
  }

  void _validateTimetable(SemesterTimetable timetable) {
    final periodIds = <String>{};
    final periodNumbers = <int>{};
    for (final definition in timetable.periodDefinitions) {
      if (definition.semesterId != timetable.semester.id) {
        throw ArgumentError('Period definition belongs to another semester.');
      }
      if (!periodIds.add(definition.id)) {
        throw ArgumentError(
          'Duplicate period definition id: ${definition.id}.',
        );
      }
      if (!periodNumbers.add(definition.period)) {
        throw ArgumentError('Duplicate period number: ${definition.period}.');
      }
    }
    final courseIds = <String>{};
    final sessionIds = <String>{};
    for (final course in timetable.courses) {
      if (course.course.semesterId != timetable.semester.id) {
        throw ArgumentError('Course belongs to another semester.');
      }
      if (!courseIds.add(course.course.id)) {
        throw ArgumentError('Duplicate course id: ${course.course.id}.');
      }
      _validateCourseGraph(course, sessionIds: sessionIds);
    }
  }

  void _validateCourseGraph(
    CourseWithSessions course, {
    Set<String>? sessionIds,
  }) {
    final ids = sessionIds ?? <String>{};
    for (final session in course.sessions) {
      if (session.courseId != course.course.id) {
        throw ArgumentError('Course session belongs to another course.');
      }
      if (!ids.add(session.id)) {
        throw ArgumentError('Duplicate course session id: ${session.id}.');
      }
    }
  }
}

db.SemestersCompanion _semesterCompanion(Semester semester) {
  return db.SemestersCompanion.insert(
    id: semester.id,
    academicYear: semester.academicYear,
    term: semester.term,
    name: semester.name,
    startDate: semester.startDate,
    teachingWeeks: semester.teachingWeeks,
    timeZone: drift.Value(semester.timeZone),
    isCurrent: drift.Value(semester.isCurrent),
  );
}

db.CoursesCompanion _courseCompanion(Course course) {
  return db.CoursesCompanion.insert(
    id: course.id,
    semesterId: course.semesterId,
    name: course.name,
    code: drift.Value(course.code),
    teacher: drift.Value(course.teacher),
    teachingClass: drift.Value(course.teachingClass),
    colorValue: course.colorValue,
    notes: drift.Value(course.notes),
    source: course.source.name,
    sourceId: drift.Value(course.sourceId),
    isLocallyModified: drift.Value(course.isLocallyModified),
  );
}

db.CourseSessionsCompanion _sessionCompanion(CourseSession session) {
  return db.CourseSessionsCompanion.insert(
    id: session.id,
    courseId: session.courseId,
    weekday: session.weekday,
    startPeriod: session.startPeriod,
    endPeriod: session.endPeriod,
    location: drift.Value(session.location),
    weeks: formatWeekExpression(session.weeks),
  );
}

db.PeriodDefinitionsCompanion _periodCompanion(PeriodDefinition definition) {
  return db.PeriodDefinitionsCompanion.insert(
    id: definition.id,
    semesterId: definition.semesterId,
    period: definition.period,
    startTime: definition.startTime,
    endTime: definition.endTime,
    periodGroup: definition.group.name,
  );
}

Semester _semesterFromRow(db.Semester row) {
  return Semester(
    id: row.id,
    academicYear: row.academicYear,
    term: row.term,
    name: row.name,
    startDate: row.startDate,
    teachingWeeks: row.teachingWeeks,
    timeZone: row.timeZone,
    isCurrent: row.isCurrent,
  );
}

Course _courseFromRow(db.Course row) {
  return Course(
    id: row.id,
    semesterId: row.semesterId,
    name: row.name,
    code: row.code,
    teacher: row.teacher,
    teachingClass: row.teachingClass,
    colorValue: row.colorValue,
    notes: row.notes,
    source: CourseSource.values.byName(row.source),
    sourceId: row.sourceId,
    isLocallyModified: row.isLocallyModified,
  );
}

CourseSession _sessionFromRow(db.CourseSession row) {
  return CourseSession(
    id: row.id,
    courseId: row.courseId,
    weekday: row.weekday,
    startPeriod: row.startPeriod,
    endPeriod: row.endPeriod,
    location: row.location,
    weeks: parseWeekExpression(row.weeks),
  );
}

PeriodDefinition _periodFromRow(db.PeriodDefinition row) {
  return PeriodDefinition(
    id: row.id,
    semesterId: row.semesterId,
    period: row.period,
    startTime: row.startTime,
    endTime: row.endTime,
    group: PeriodGroup.values.byName(row.periodGroup),
  );
}

int _compareSessions(CourseSession first, CourseSession second) {
  final weekday = first.weekday.compareTo(second.weekday);
  if (weekday != 0) {
    return weekday;
  }
  final startPeriod = first.startPeriod.compareTo(second.startPeriod);
  if (startPeriod != 0) {
    return startPeriod;
  }
  return first.id.compareTo(second.id);
}

Stream<Result> _combineLatest4<A, B, C, D, Result>(
  Stream<A> first,
  Stream<B> second,
  Stream<C> third,
  Stream<D> fourth,
  Result Function(A, B, C, D) combine,
) {
  late StreamController<Result> controller;
  final subscriptions = <StreamSubscription<Object?>>[];
  A? firstValue;
  B? secondValue;
  C? thirdValue;
  D? fourthValue;
  var hasFirst = false;
  var hasSecond = false;
  var hasThird = false;
  var hasFourth = false;

  void emitIfReady() {
    if (hasFirst && hasSecond && hasThird && hasFourth) {
      controller.add(
        combine(
          firstValue as A,
          secondValue as B,
          thirdValue as C,
          fourthValue as D,
        ),
      );
    }
  }

  controller = StreamController<Result>.broadcast(
    onListen: () {
      subscriptions.addAll([
        first.listen((value) {
          firstValue = value;
          hasFirst = true;
          emitIfReady();
        }, onError: controller.addError),
        second.listen((value) {
          secondValue = value;
          hasSecond = true;
          emitIfReady();
        }, onError: controller.addError),
        third.listen((value) {
          thirdValue = value;
          hasThird = true;
          emitIfReady();
        }, onError: controller.addError),
        fourth.listen((value) {
          fourthValue = value;
          hasFourth = true;
          emitIfReady();
        }, onError: controller.addError),
      ]);
    },
    onCancel: () async {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
    },
  );
  return controller.stream;
}

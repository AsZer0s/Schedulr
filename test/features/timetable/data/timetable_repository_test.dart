import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schedulr/core/storage/app_database.dart' show AppDatabase;
import 'package:schedulr/features/timetable/data/timetable_repository.dart';
import 'package:schedulr/features/timetable/domain/timetable_models.dart';

void main() {
  late AppDatabase database;
  late TimetableRepository repository;

  var uuidCounter = 0;

  setUp(() {
    uuidCounter = 0;
    database = AppDatabase(NativeDatabase.memory());
    repository = TimetableRepository(
      database,
      uuidGenerator: () => 'generated-${uuidCounter++}',
    );
  });

  tearDown(() => database.close());

  test(
    'create initial timetable is atomic and only allowed when empty',
    () async {
      final created = await repository.createInitialTimetable(
        timetableName: '  我的新课表  ',
        academicYear: '2030-2031',
        term: 2,
        startDate: DateTime(2031, 2, 19, 18),
        teachingWeeks: 19,
      );

      expect(created.id, 'generated-0');
      expect(created.timetableName, '我的新课表');
      expect(created.academicYear, '2030-2031');
      expect(created.term, '2');
      expect(created.name, '2030-2031 第二学期');
      expect(created.startDate, DateTime(2031, 2, 19));
      expect(created.teachingWeeks, 19);
      expect(created.isCurrent, isTrue);
      final timetable = await repository.getSemesterTimetable(created.id);
      expect(timetable!.courses, isEmpty);
      expect(timetable.periodDefinitions, isEmpty);

      await expectLater(
        repository.createInitialTimetable(
          timetableName: '另一个',
          academicYear: '2031-2032',
          term: 1,
          startDate: DateTime(2031, 9, 1),
          teachingWeeks: 20,
        ),
        throwsStateError,
      );
      expect(await repository.getSemesters(), [created]);
    },
  );

  test('invalid initial data creates no partial semester', () async {
    await expectLater(
      repository.createInitialTimetable(
        timetableName: '   ',
        academicYear: '2030-2032',
        term: 4,
        startDate: DateTime(2030, 9, 1),
        teachingWeeks: 41,
      ),
      throwsA(anything),
    );
    expect(await repository.getSemesters(), isEmpty);
  });

  test('clear all removes sessions, courses, periods and semesters', () async {
    await repository.replaceSemesterTimetable(
      _timetable(courseId: 'course-a', courseName: '高等数学'),
    );

    await repository.clearAllTimetableData();

    expect(await database.select(database.courseSessions).get(), isEmpty);
    expect(await database.select(database.courses).get(), isEmpty);
    expect(await database.select(database.periodDefinitions).get(), isEmpty);
    expect(await database.select(database.semesters).get(), isEmpty);
    expect(await repository.getSemesters(), isEmpty);
  });

  test('persists semester timetable CRUD and emits watch updates', () async {
    final timetable = _timetable(courseId: 'course-a', courseName: '高等数学');
    final watchFuture = repository
        .watchSemesterTimetable(timetable.semester.id)
        .firstWhere((value) => value?.courses.isNotEmpty ?? false);

    await repository.replaceSemesterTimetable(timetable);

    expect(
      await repository.getSemesterTimetable(timetable.semester.id),
      timetable,
    );
    expect(await watchFuture, timetable);

    final updatedCourse = timetable.courses.single.copyWith(
      course: timetable.courses.single.course.copyWith(name: '线性代数'),
    );
    await repository.upsertCourse(updatedCourse);
    expect(
      (await repository.getSemesterTimetable(timetable.semester.id))!
          .courses
          .single
          .course
          .name,
      '线性代数',
    );

    await repository.deleteCourse(updatedCourse.course.id);
    expect(
      (await repository.getSemesterTimetable(timetable.semester.id))!.courses,
      isEmpty,
    );

    await repository.deleteSemester(timetable.semester.id);
    expect(
      await repository.getSemesterTimetable(timetable.semester.id),
      isNull,
    );
  });

  test('replace removes prior courses and periods atomically', () async {
    final initial = _timetable(courseId: 'course-a', courseName: '高等数学');
    await repository.replaceSemesterTimetable(initial);

    final replacement = SemesterTimetable(
      semester: initial.semester,
      courses: [
        _course(
          initial.semester.id,
          id: 'course-b',
          name: '大学英语',
          weekday: DateTime.tuesday,
        ),
      ],
      periodDefinitions: [
        PeriodDefinition(
          id: 'period-2',
          semesterId: initial.semester.id,
          period: 2,
          startTime: '09:00',
          endTime: '09:45',
          group: PeriodGroup.morning,
        ),
      ],
    );
    await repository.replaceSemesterTimetable(replacement);

    expect(
      await repository.getSemesterTimetable(initial.semester.id),
      replacement,
    );
  });

  test('merge keeps existing records and upserts matching ids', () async {
    final initial = _timetable(courseId: 'course-a', courseName: '高等数学');
    await repository.replaceSemesterTimetable(initial);

    final merged = SemesterTimetable(
      semester: initial.semester.copyWith(name: '秋季学期（更新）'),
      courses: [
        initial.courses.single.copyWith(
          course: initial.courses.single.course.copyWith(name: '高等数学 A'),
        ),
        _course(
          initial.semester.id,
          id: 'course-b',
          name: '大学物理',
          weekday: DateTime.friday,
        ),
      ],
      periodDefinitions: [
        PeriodDefinition(
          id: 'period-2',
          semesterId: initial.semester.id,
          period: 2,
          startTime: '09:00',
          endTime: '09:45',
          group: PeriodGroup.morning,
        ),
      ],
    );
    await repository.mergeSemesterTimetable(merged);

    final result = await repository.getSemesterTimetable(initial.semester.id);
    expect(result!.semester.name, '秋季学期（更新）');
    expect(result.courses.map((entry) => entry.course.name), [
      '大学物理',
      '高等数学 A',
    ]);
    expect(result.periodDefinitions.map((period) => period.period), [1, 2]);
  });

  test('failed replace rolls back existing timetable', () async {
    final initial = _timetable(courseId: 'course-a', courseName: '高等数学');
    await repository.replaceSemesterTimetable(initial);

    final invalid = SemesterTimetable(
      semester: initial.semester,
      courses: [
        CourseWithSessions(
          course: Course(
            id: 'duplicate-course',
            semesterId: initial.semester.id,
            name: '重复课程',
          ),
          sessions: [
            CourseSession(
              id: 'session-a',
              courseId: 'duplicate-course',
              weekday: DateTime.monday,
              startPeriod: 1,
              endPeriod: 2,
              weeks: const {1},
            ),
            CourseSession(
              id: 'session-a',
              courseId: 'duplicate-course',
              weekday: DateTime.tuesday,
              startPeriod: 3,
              endPeriod: 4,
              weeks: const {2},
            ),
          ],
        ),
      ],
      periodDefinitions: initial.periodDefinitions,
    );

    await expectLater(
      repository.replaceSemesterTimetable(invalid),
      throwsA(anything),
    );
    expect(await repository.getSemesterTimetable(initial.semester.id), initial);
  });

  test('keeps timetable data isolated and allows matching times', () async {
    final first = _timetable(
      semesterId: 'semester-a',
      timetableName: '课表 A',
      courseId: 'course-a',
      courseName: '高等数学',
    );
    final second = _timetable(
      semesterId: 'semester-b',
      timetableName: '课表 B',
      courseId: 'course-b',
      courseName: '大学英语',
      isCurrent: false,
    );

    await repository.replaceSemesterTimetable(first);
    await repository.replaceSemesterTimetable(second);

    expect((await repository.getSemesterTimetable('semester-a'))!.courses, [
      first.courses.single,
    ]);
    expect((await repository.getSemesterTimetable('semester-b'))!.courses, [
      second.courses.single,
    ]);
    expect(first.courses.single.sessions.single.weekday, DateTime.monday);
    expect(second.courses.single.sessions.single.weekday, DateTime.monday);
    expect(first.courses.single.sessions.single.startPeriod, 1);
    expect(second.courses.single.sessions.single.startPeriod, 1);
  });

  test('create blank copies calendar and periods but not courses', () async {
    final template = _timetable(courseId: 'course-a', courseName: '高等数学');
    await repository.replaceSemesterTimetable(template);

    final created = await repository.createBlankTimetable(
      name: '  新课表  ',
      template: template.semester,
    );
    final result = await repository.getSemesterTimetable(created.id);

    expect(created.timetableName, '新课表');
    expect(created.academicYear, template.semester.academicYear);
    expect(created.term, template.semester.term);
    expect(created.name, template.semester.name);
    expect(created.startDate, template.semester.startDate);
    expect(created.teachingWeeks, template.semester.teachingWeeks);
    expect(created.timeZone, template.semester.timeZone);
    expect(created.isCurrent, isTrue);
    expect(result!.courses, isEmpty);
    expect(
      result.periodDefinitions.single.copyWith(
        id: template.periodDefinitions.single.id,
        semesterId: template.semester.id,
      ),
      template.periodDefinitions.single,
    );
    expect(
      (await repository.getSemester(template.semester.id))!.isCurrent,
      false,
    );
  });

  test('rename trims name and rejects blank names', () async {
    final timetable = _timetable(courseId: 'course-a', courseName: '高等数学');
    await repository.replaceSemesterTimetable(timetable);

    await repository.renameTimetable(timetable.semester.id, '  主课表  ');
    expect(
      (await repository.getSemester(timetable.semester.id))!.timetableName,
      '主课表',
    );
    await expectLater(
      repository.renameTimetable(timetable.semester.id, '   '),
      throwsArgumentError,
    );
  });

  test(
    'switch persists exactly one current and rejects missing target',
    () async {
      final first = _timetable(
        semesterId: 'semester-a',
        timetableName: '课表 A',
        courseId: 'course-a',
        courseName: '高等数学',
      );
      final second = _timetable(
        semesterId: 'semester-b',
        timetableName: '课表 B',
        courseId: 'course-b',
        courseName: '大学英语',
        isCurrent: false,
      );
      await repository.replaceSemesterTimetable(first);
      await repository.replaceSemesterTimetable(second);

      await repository.switchCurrent(second.semester.id);
      final semesters = await repository.getSemesters();
      expect(
        semesters.where((semester) => semester.isCurrent).single.id,
        'semester-b',
      );
      expect((await repository.watchCurrentSemester().first)!.id, 'semester-b');

      await expectLater(
        repository.setCurrentSemester('missing'),
        throwsStateError,
      );
      expect(
        (await repository.getSemesters())
            .where((semester) => semester.isCurrent)
            .single
            .id,
        'semester-b',
      );
    },
  );

  test('delete current selects stable first remaining timetable', () async {
    final current = _timetable(
      semesterId: 'current',
      timetableName: '当前',
      courseId: 'course-current',
      courseName: '当前课程',
      startDate: DateTime(2026, 9, 1),
    );
    final older = _timetable(
      semesterId: 'older',
      timetableName: '较早',
      courseId: 'course-older',
      courseName: '较早课程',
      startDate: DateTime(2025, 9, 1),
      isCurrent: false,
    );
    final newer = _timetable(
      semesterId: 'newer',
      timetableName: '较新',
      courseId: 'course-newer',
      courseName: '较新课程',
      startDate: DateTime(2027, 9, 1),
      isCurrent: false,
    );
    await repository.replaceSemesterTimetable(current);
    await repository.replaceSemesterTimetable(older);
    await repository.replaceSemesterTimetable(newer);

    final fallback = await repository.deleteTimetableAndSelectFallback(
      'current',
    );

    expect(fallback.id, 'newer');
    expect((await repository.getSemester('newer'))!.isCurrent, isTrue);
    expect(await repository.getSemester('current'), isNull);
  });

  test('delete last recreates blank timetable from deleted template', () async {
    final timetable = _timetable(courseId: 'course-a', courseName: '高等数学');
    await repository.replaceSemesterTimetable(timetable);

    final replacement = await repository.deleteTimetableAndSelectFallback(
      timetable.semester.id,
    );
    final loaded = await repository.getSemesterTimetable(replacement.id);

    expect(replacement.id, 'generated-0');
    expect(replacement.timetableName, '我的课表');
    expect(replacement.isCurrent, isTrue);
    expect(loaded!.courses, isEmpty);
    expect(loaded.periodDefinitions, hasLength(1));
    expect(loaded.periodDefinitions.single.semesterId, replacement.id);
    expect(loaded.semester.startDate, timetable.semester.startDate);
  });

  test('replace target A does not affect target B', () async {
    final first = _timetable(
      semesterId: 'semester-a',
      timetableName: '课表 A',
      courseId: 'course-a',
      courseName: '高等数学',
    );
    final second = _timetable(
      semesterId: 'semester-b',
      timetableName: '课表 B',
      courseId: 'course-b',
      courseName: '大学英语',
      isCurrent: false,
    );
    await repository.replaceSemesterTimetable(first);
    await repository.replaceSemesterTimetable(second);

    await repository.replaceSemesterTimetable(
      first.copyWith(
        courses: [_course(first.semester.id, id: 'course-a2', name: '线性代数')],
      ),
    );

    expect(
      (await repository.getSemesterTimetable('semester-a'))!
          .courses
          .single
          .course
          .name,
      '线性代数',
    );
    expect(await repository.getSemesterTimetable('semester-b'), second);
  });

  test(
    'duplicate ids roll back replacement without affecting other timetable',
    () async {
      final first = _timetable(
        semesterId: 'semester-a',
        timetableName: '课表 A',
        courseId: 'course-a',
        courseName: '高等数学',
      );
      final second = _timetable(
        semesterId: 'semester-b',
        timetableName: '课表 B',
        courseId: 'course-b',
        courseName: '大学英语',
        isCurrent: false,
      );
      await repository.replaceSemesterTimetable(first);
      await repository.replaceSemesterTimetable(second);

      final conflicting = second.copyWith(
        courses: [
          _course(
            second.semester.id,
            id: first.courses.single.course.id,
            name: '冲突课程',
          ),
        ],
      );
      await expectLater(
        repository.replaceSemesterTimetable(conflicting),
        throwsStateError,
      );

      expect(await repository.getSemesterTimetable('semester-a'), first);
      expect(await repository.getSemesterTimetable('semester-b'), second);
    },
  );
}

SemesterTimetable _timetable({
  String semesterId = '2026-fall',
  String timetableName = '秋季学期',
  required String courseId,
  required String courseName,
  DateTime? startDate,
  bool isCurrent = true,
}) {
  final semester = Semester(
    id: semesterId,
    academicYear: '2026-2027',
    term: '1',
    name: '秋季学期',
    timetableName: timetableName,
    startDate: startDate ?? DateTime(2026, 9, 1),
    teachingWeeks: 18,
    isCurrent: isCurrent,
  );
  return SemesterTimetable(
    semester: semester,
    courses: [_course(semester.id, id: courseId, name: courseName)],
    periodDefinitions: [
      PeriodDefinition(
        id: 'period-$semesterId-1',
        semesterId: semester.id,
        period: 1,
        startTime: '08:00',
        endTime: '08:45',
        group: PeriodGroup.morning,
      ),
    ],
  );
}

CourseWithSessions _course(
  String semesterId, {
  required String id,
  required String name,
  int weekday = DateTime.monday,
}) {
  return CourseWithSessions(
    course: Course(
      id: id,
      semesterId: semesterId,
      name: name,
      code: 'CODE-$id',
      teacher: '教师',
      teachingClass: '教学班 1',
      notes: '备注',
      source: CourseSource.zfsoft,
      sourceId: 'source-$id',
    ),
    sessions: [
      CourseSession(
        id: 'session-$id',
        courseId: id,
        weekday: weekday,
        startPeriod: 1,
        endPeriod: 2,
        location: '教学楼 A101',
        weeks: const {1, 2, 4, 7},
      ),
    ],
  );
}

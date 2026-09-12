import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schedulr/core/storage/app_database.dart' show AppDatabase;
import 'package:schedulr/features/timetable/data/timetable_repository.dart';
import 'package:schedulr/features/timetable/domain/timetable_models.dart';

void main() {
  late AppDatabase database;
  late TimetableRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = TimetableRepository(database);
  });

  tearDown(() => database.close());

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
}

SemesterTimetable _timetable({
  required String courseId,
  required String courseName,
}) {
  final semester = Semester(
    id: '2026-fall',
    academicYear: '2026-2027',
    term: '1',
    name: '秋季学期',
    startDate: DateTime(2026, 9, 1),
    teachingWeeks: 18,
    isCurrent: true,
  );
  return SemesterTimetable(
    semester: semester,
    courses: [_course(semester.id, id: courseId, name: courseName)],
    periodDefinitions: [
      PeriodDefinition(
        id: 'period-1',
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

import 'package:flutter_test/flutter_test.dart';
import 'package:schedulr/features/timetable/domain/timetable_models.dart';

void main() {
  test('course session uses immutable value-based week equality', () {
    final first = CourseSession(
      id: 'session',
      courseId: 'course',
      weekday: DateTime.monday,
      startPeriod: 1,
      endPeriod: 2,
      weeks: {1, 3, 5},
    );
    final second = first.copyWith(weeks: {5, 3, 1});

    expect(first, second);
    expect(() => first.weeks.add(7), throwsUnsupportedError);
  });

  test('semester timetable name is required, trimmed, and value-based', () {
    final semester = Semester(
      id: 'semester',
      academicYear: '2026-2027',
      term: '1',
      name: '第一学期',
      timetableName: '  主课表  ',
      startDate: DateTime(2026, 9, 7, 12),
      teachingWeeks: 20,
    );

    expect(semester.timetableName, '主课表');
    expect(
      semester.copyWith(),
      Semester(
        id: 'semester',
        academicYear: '2026-2027',
        term: '1',
        name: '第一学期',
        timetableName: '主课表',
        startDate: DateTime(2026, 9, 7),
        teachingWeeks: 20,
      ),
    );
    expect(semester.toString(), contains('timetableName: 主课表'));
    expect(
      () => Semester(
        id: 'semester',
        academicYear: '2026-2027',
        term: '1',
        name: '第一学期',
        timetableName: '   ',
        startDate: DateTime(2026, 9, 7),
        teachingWeeks: 20,
      ),
      throwsArgumentError,
    );
  });

  test('copyWith can clear nullable course fields', () {
    final course = Course(
      id: 'course',
      semesterId: 'semester',
      name: '课程',
      teacher: '教师',
      notes: '备注',
    );

    expect(course.copyWith(teacher: () => null).teacher, isNull);
    expect(course.copyWith(notes: () => null).notes, isNull);
  });
}

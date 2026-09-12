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

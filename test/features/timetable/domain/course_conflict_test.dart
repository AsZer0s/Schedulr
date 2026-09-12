import 'package:flutter_test/flutter_test.dart';
import 'package:schedulr/core/time/course_conflict.dart';
import 'package:schedulr/features/timetable/domain/course_session.dart';

CourseSession session({
  required String id,
  int weekday = DateTime.monday,
  int startPeriod = 1,
  int endPeriod = 2,
  Set<int> weeks = const {1, 2, 3},
}) {
  return CourseSession(
    id: id,
    courseId: 'course-$id',
    weekday: weekday,
    startPeriod: startPeriod,
    endPeriod: endPeriod,
    weeks: weeks,
  );
}

void main() {
  test('detects same-day overlapping weeks and periods', () {
    final first = session(id: 'first', startPeriod: 1, endPeriod: 2);
    final second = session(
      id: 'second',
      startPeriod: 2,
      endPeriod: 4,
      weeks: const {3, 4},
    );

    expect(courseSessionsConflict(first, second), isTrue);
    expect(conflictingWeeks(first, second), {3});
  });

  test('does not report conflicts across day, week, or period boundaries', () {
    final target = session(id: 'target');

    expect(
      courseSessionsConflict(
        target,
        session(id: 'day', weekday: DateTime.tuesday),
      ),
      isFalse,
    );
    expect(
      courseSessionsConflict(target, session(id: 'week', weeks: const {4, 5})),
      isFalse,
    );
    expect(
      courseSessionsConflict(
        target,
        session(id: 'period', startPeriod: 3, endPeriod: 4),
      ),
      isFalse,
    );
  });
}

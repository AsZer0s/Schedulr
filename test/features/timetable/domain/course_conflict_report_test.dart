import 'package:flutter_test/flutter_test.dart';
import 'package:schedulr/features/timetable/domain/timetable_models.dart';

void main() {
  test(
    'reports existing and internal conflicts with precise intersections',
    () {
      final candidate = _course(
        id: 'candidate',
        sessions: [
          _session(
            id: 'candidate-a',
            courseId: 'candidate',
            weekday: DateTime.tuesday,
            start: 2,
            end: 4,
            weeks: {1, 3, 5},
          ),
          _session(
            id: 'candidate-b',
            courseId: 'candidate',
            weekday: DateTime.tuesday,
            start: 4,
            end: 5,
            weeks: {3, 5},
          ),
        ],
      );
      final existing = _course(
        id: 'existing',
        name: '高等数学',
        sessions: [
          _session(
            id: 'existing-a',
            courseId: 'existing',
            weekday: DateTime.tuesday,
            start: 3,
            end: 6,
            weeks: {2, 3, 5},
          ),
        ],
      );

      final conflicts = findCourseConflicts(
        candidate: candidate,
        existingCourses: [existing],
      );

      expect(conflicts, hasLength(3));
      final internal = conflicts.singleWhere(
        (conflict) => conflict.kind == CourseConflictKind.internal,
      );
      expect(internal.weeks, {3, 5});
      expect(internal.startPeriod, 4);
      expect(internal.endPeriod, 4);
      final external = conflicts.where(
        (conflict) => conflict.kind == CourseConflictKind.existingCourse,
      );
      expect(
        external.every((conflict) => conflict.conflictingCourse == existing),
        isTrue,
      );
      expect(external.map((conflict) => conflict.weeks), everyElement({3, 5}));
    },
  );

  test('editing excludes all stored sessions with the same course id', () {
    final candidate = _course(
      id: 'same',
      sessions: [
        _session(id: 'new', courseId: 'same', weeks: {1}),
      ],
    );
    final storedSelf = _course(
      id: 'same',
      sessions: [
        _session(id: 'old', courseId: 'same', weeks: {1}),
      ],
    );

    expect(
      findCourseConflicts(candidate: candidate, existingCourses: [storedSelf]),
      isEmpty,
    );
  });

  test('conflict key changes when overlap details change', () {
    final first = _course(
      id: 'candidate',
      sessions: [
        _session(id: 'a', courseId: 'candidate', weeks: {1, 2}),
      ],
    );
    final other = _course(
      id: 'other',
      sessions: [
        _session(id: 'b', courseId: 'other', weeks: {2}),
      ],
    );
    final original = findCourseConflicts(
      candidate: first,
      existingCourses: [other],
    ).single;
    final changed = findCourseConflicts(
      candidate: first,
      existingCourses: [
        other.copyWith(
          sessions: [
            _session(id: 'b', courseId: 'other', weeks: {1}),
          ],
        ),
      ],
    ).single;

    expect(original.key, isNot(changed.key));
  });
}

CourseWithSessions _course({
  required String id,
  String name = '候选课程',
  required List<CourseSession> sessions,
}) {
  return CourseWithSessions(
    course: Course(id: id, semesterId: 'semester', name: name),
    sessions: sessions,
  );
}

CourseSession _session({
  required String id,
  required String courseId,
  int weekday = DateTime.monday,
  int start = 1,
  int end = 2,
  required Set<int> weeks,
}) {
  return CourseSession(
    id: id,
    courseId: courseId,
    weekday: weekday,
    startPeriod: start,
    endPeriod: end,
    weeks: weeks,
  );
}

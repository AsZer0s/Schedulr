import '../../features/timetable/domain/course_session.dart';
import 'week_set.dart';

bool courseSessionsConflict(CourseSession first, CourseSession second) {
  return first.weekday == second.weekday &&
      weeksOverlap(first.weeks, second.weeks) &&
      first.startPeriod <= second.endPeriod &&
      second.startPeriod <= first.endPeriod;
}

Set<int> conflictingWeeks(CourseSession first, CourseSession second) {
  if (first.weekday != second.weekday ||
      first.startPeriod > second.endPeriod ||
      second.startPeriod > first.endPeriod) {
    return <int>{};
  }
  return first.weeks.intersection(second.weeks);
}

List<CourseSession> conflictsForSession(
  CourseSession target,
  Iterable<CourseSession> sessions,
) {
  return [
    for (final session in sessions)
      if (session.id != target.id && courseSessionsConflict(target, session))
        session,
  ];
}

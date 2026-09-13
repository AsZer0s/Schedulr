import '../../../core/time/course_conflict.dart';
import 'course_session.dart';
import 'course_with_sessions.dart';

class CourseConflictReport {
  CourseConflictReport({
    required this.kind,
    required this.candidateSession,
    required this.candidateSessionIndex,
    required this.conflictingSession,
    required this.conflictingSessionIndex,
    required this.weekday,
    required this.startPeriod,
    required this.endPeriod,
    required Set<int> weeks,
    this.conflictingCourse,
  }) : weeks = Set.unmodifiable(weeks);

  final CourseConflictKind kind;
  final CourseSession candidateSession;
  final int candidateSessionIndex;
  final CourseSession conflictingSession;
  final int conflictingSessionIndex;
  final CourseWithSessions? conflictingCourse;
  final int weekday;
  final int startPeriod;
  final int endPeriod;
  final Set<int> weeks;

  String get key {
    final otherCourseId = conflictingCourse?.course.id ?? 'internal';
    final sortedWeeks = weeks.toList()..sort();
    return '${kind.name}|${candidateSession.id}|$otherCourseId|'
        '${conflictingSession.id}|$weekday|$startPeriod-$endPeriod|'
        '${sortedWeeks.join(',')}';
  }
}

enum CourseConflictKind { existingCourse, internal }

sealed class CourseSaveResult {
  const CourseSaveResult();
}

final class CourseSaved extends CourseSaveResult {
  const CourseSaved();
}

final class CourseConflictConfirmationRequired extends CourseSaveResult {
  CourseConflictConfirmationRequired({
    required List<CourseConflictReport> conflicts,
  }) : conflicts = List.unmodifiable(conflicts),
       conflictKeys = Set.unmodifiable(
         conflicts.map((conflict) => conflict.key),
       );

  final List<CourseConflictReport> conflicts;
  final Set<String> conflictKeys;
}

List<CourseConflictReport> findCourseConflicts({
  required CourseWithSessions candidate,
  required Iterable<CourseWithSessions> existingCourses,
}) {
  final reports = <CourseConflictReport>[];
  final sessions = candidate.sessions;

  for (var firstIndex = 0; firstIndex < sessions.length; firstIndex++) {
    for (
      var secondIndex = firstIndex + 1;
      secondIndex < sessions.length;
      secondIndex++
    ) {
      final first = sessions[firstIndex];
      final second = sessions[secondIndex];
      if (!courseSessionsConflict(first, second)) continue;
      reports.add(
        _report(
          kind: CourseConflictKind.internal,
          candidate: first,
          candidateIndex: firstIndex,
          conflicting: second,
          conflictingIndex: secondIndex,
        ),
      );
    }
  }

  for (
    var candidateIndex = 0;
    candidateIndex < sessions.length;
    candidateIndex++
  ) {
    final session = sessions[candidateIndex];
    for (final existing in existingCourses) {
      if (existing.course.id == candidate.course.id) continue;
      for (
        var existingIndex = 0;
        existingIndex < existing.sessions.length;
        existingIndex++
      ) {
        final other = existing.sessions[existingIndex];
        if (!courseSessionsConflict(session, other)) continue;
        reports.add(
          _report(
            kind: CourseConflictKind.existingCourse,
            candidate: session,
            candidateIndex: candidateIndex,
            conflicting: other,
            conflictingIndex: existingIndex,
            conflictingCourse: existing,
          ),
        );
      }
    }
  }

  reports.sort((first, second) {
    var comparison = first.candidateSessionIndex.compareTo(
      second.candidateSessionIndex,
    );
    if (comparison != 0) return comparison;
    comparison = first.weekday.compareTo(second.weekday);
    if (comparison != 0) return comparison;
    comparison = first.startPeriod.compareTo(second.startPeriod);
    if (comparison != 0) return comparison;
    comparison = (first.conflictingCourse?.course.name ?? '').compareTo(
      second.conflictingCourse?.course.name ?? '',
    );
    if (comparison != 0) return comparison;
    return first.key.compareTo(second.key);
  });
  return reports;
}

CourseConflictReport _report({
  required CourseConflictKind kind,
  required CourseSession candidate,
  required int candidateIndex,
  required CourseSession conflicting,
  required int conflictingIndex,
  CourseWithSessions? conflictingCourse,
}) {
  return CourseConflictReport(
    kind: kind,
    candidateSession: candidate,
    candidateSessionIndex: candidateIndex,
    conflictingSession: conflicting,
    conflictingSessionIndex: conflictingIndex,
    conflictingCourse: conflictingCourse,
    weekday: candidate.weekday,
    startPeriod: candidate.startPeriod > conflicting.startPeriod
        ? candidate.startPeriod
        : conflicting.startPeriod,
    endPeriod: candidate.endPeriod < conflicting.endPeriod
        ? candidate.endPeriod
        : conflicting.endPeriod,
    weeks: conflictingWeeks(candidate, conflicting),
  );
}

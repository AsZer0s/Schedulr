import 'package:uuid/uuid.dart';

import '../../timetable/domain/course.dart';
import '../../timetable/domain/course_session.dart';
import '../../timetable/domain/course_source.dart';
import '../../timetable/domain/course_with_sessions.dart';
import '../../timetable/domain/semester_timetable.dart';
import 'imported_timetable_entry.dart';

/// Generates IDs for newly-created courses and sessions.
///
/// The callback is invoked once per new entity. Existing IDs are reused during
/// an update whenever the imported row can be matched to an existing session.
typedef BitcRefreshIdGenerator = String Function();

/// A pure, in-memory refresh reconciler for BITC/Zhengfang courses.
///
/// This class only calculates a plan. It does not read or write storage, and
/// it deliberately does not modify semester calendar or timing metadata.
final class BitcRefreshReconciler {
  BitcRefreshReconciler({BitcRefreshIdGenerator? idGenerator})
    : _idGenerator = idGenerator ?? const Uuid().v4;

  final BitcRefreshIdGenerator _idGenerator;

  /// Reconciles [imported] against the courses in [existing].
  ///
  /// Imported rows are grouped by [ImportedTimetableEntry.externalId]. Existing
  /// courses are matched only when their source is [CourseSource.zfsoft] and
  /// their source ID is non-null. Non-Zhengfang courses and locally modified
  /// Zhengfang courses are never overwritten or removed.
  BitcRefreshPlan reconcile({
    required SemesterTimetable existing,
    required Iterable<ImportedTimetableEntry> imported,
  }) {
    final groups = _groupByExternalId(imported);
    final existingCourses = existing.courses;
    final matchIndexBySourceId = <String, int>{};

    for (var index = 0; index < existingCourses.length; index++) {
      final course = existingCourses[index].course;
      if (course.source == CourseSource.zfsoft &&
          course.sourceId != null &&
          !matchIndexBySourceId.containsKey(course.sourceId)) {
        matchIndexBySourceId[course.sourceId!] = index;
      }
    }

    if (groups.isEmpty &&
        existingCourses.any(
          (entry) =>
              entry.course.source == CourseSource.zfsoft &&
              !entry.course.isLocallyModified,
        )) {
      throw const BitcRefreshException(
        'BITC refresh returned no courses; existing unmodified courses were '
        'not removed.',
      );
    }

    final added = <CourseWithSessions>[];
    final updated = <CourseWithSessions>[];
    final unchanged = <CourseWithSessions>[];
    final removed = <CourseWithSessions>[];
    final locallyModifiedPreserved = <CourseWithSessions>[];
    final manualCoursesPreserved = <CourseWithSessions>[];
    final unmanagedSourceCoursesPreserved = <CourseWithSessions>[];
    final desiredByExistingIndex = <int, CourseWithSessions>{};
    final matchedIndexes = <int>{};

    for (final group in groups.entries) {
      final existingIndex = matchIndexBySourceId[group.key];
      if (existingIndex == null) {
        final created = _createCourse(
          semesterId: existing.semester.id,
          externalId: group.key,
          entries: group.value,
        );
        added.add(created);
        continue;
      }

      final current = existingCourses[existingIndex];
      final currentCourse = current.course;
      matchedIndexes.add(existingIndex);

      if (currentCourse.isLocallyModified) {
        desiredByExistingIndex[existingIndex] = current;
        locallyModifiedPreserved.add(current);
        continue;
      }

      final refreshed = _refreshCourse(existing: current, entries: group.value);
      if (refreshed == current) {
        desiredByExistingIndex[existingIndex] = current;
        unchanged.add(current);
      } else {
        desiredByExistingIndex[existingIndex] = refreshed;
        updated.add(refreshed);
      }
    }

    for (var index = 0; index < existingCourses.length; index++) {
      final current = existingCourses[index];
      final course = current.course;
      if (matchedIndexes.contains(index)) continue;

      if (course.source == CourseSource.zfsoft && course.sourceId != null) {
        if (course.isLocallyModified) {
          desiredByExistingIndex[index] = current;
          locallyModifiedPreserved.add(current);
        } else {
          removed.add(current);
        }
      } else if (course.source == CourseSource.zfsoft) {
        // A source course without an external ID cannot be safely reconciled.
        desiredByExistingIndex[index] = current;
        unmanagedSourceCoursesPreserved.add(current);
      } else {
        desiredByExistingIndex[index] = current;
        manualCoursesPreserved.add(current);
      }
    }

    final desiredCourses = <CourseWithSessions>[];
    final desiredSourceManagedCourses = <CourseWithSessions>[];
    for (var index = 0; index < existingCourses.length; index++) {
      final desired = desiredByExistingIndex[index];
      if (desired == null) continue;
      desiredCourses.add(desired);
      if (desired.course.source == CourseSource.zfsoft) {
        desiredSourceManagedCourses.add(desired);
      }
    }
    desiredCourses.addAll(added);
    desiredSourceManagedCourses.addAll(added);

    return BitcRefreshPlan(
      desiredCourses: desiredCourses,
      desiredSourceManagedCourses: desiredSourceManagedCourses,
      added: added,
      updated: updated,
      removed: removed,
      unchanged: unchanged,
      locallyModifiedPreserved: locallyModifiedPreserved,
      manualCoursesPreserved: manualCoursesPreserved,
      unmanagedSourceCoursesPreserved: unmanagedSourceCoursesPreserved,
    );
  }

  Map<String, List<ImportedTimetableEntry>> _groupByExternalId(
    Iterable<ImportedTimetableEntry> imported,
  ) {
    final groups = <String, List<ImportedTimetableEntry>>{};
    for (final entry in imported) {
      groups.putIfAbsent(entry.externalId, () => []).add(entry);
    }
    return groups;
  }

  CourseWithSessions _createCourse({
    required String semesterId,
    required String externalId,
    required List<ImportedTimetableEntry> entries,
  }) {
    final courseId = _idGenerator();
    final first = entries.first;
    final course = Course(
      id: courseId,
      semesterId: semesterId,
      name: first.title,
      teacher: first.teacher,
      notes: first.notes,
      source: CourseSource.zfsoft,
      sourceId: externalId,
    );
    return CourseWithSessions(
      course: course,
      sessions: [
        for (final entry in entries)
          _newSession(courseId: courseId, entry: entry),
      ],
    );
  }

  CourseWithSessions _refreshCourse({
    required CourseWithSessions existing,
    required List<ImportedTimetableEntry> entries,
  }) {
    final first = entries.first;
    final course = existing.course.copyWith(
      name: first.title,
      teacher: () => first.teacher,
      notes: () => first.notes,
      source: CourseSource.zfsoft,
      sourceId: () => first.externalId,
      isLocallyModified: false,
    );
    return CourseWithSessions(
      course: course,
      sessions: _refreshSessions(
        courseId: course.id,
        existing: existing.sessions,
        entries: entries,
      ),
    );
  }

  List<CourseSession> _refreshSessions({
    required String courseId,
    required List<CourseSession> existing,
    required List<ImportedTimetableEntry> entries,
  }) {
    final unused = List<CourseSession>.from(existing);
    final matches = List<CourseSession?>.filled(entries.length, null);
    _claimSessionMatches(
      unused: unused,
      entries: entries,
      matches: matches,
      quality: _SessionMatchQuality.exact,
    );
    _claimSessionMatches(
      unused: unused,
      entries: entries,
      matches: matches,
      quality: _SessionMatchQuality.sameSlotAndLocation,
    );
    _claimSessionMatches(
      unused: unused,
      entries: entries,
      matches: matches,
      quality: _SessionMatchQuality.sameSlot,
    );

    return [
      for (var index = 0; index < entries.length; index++)
        if (matches[index] case final previous?)
          previous.copyWith(
            courseId: courseId,
            weekday: entries[index].dayOfWeek,
            startPeriod: entries[index].startPeriod,
            endPeriod: entries[index].endPeriod,
            location: () => entries[index].location,
            weeks: entries[index].weeks,
          )
        else
          _newSession(courseId: courseId, entry: entries[index]),
    ];
  }

  void _claimSessionMatches({
    required List<CourseSession> unused,
    required List<ImportedTimetableEntry> entries,
    required List<CourseSession?> matches,
    required _SessionMatchQuality quality,
  }) {
    for (var entryIndex = 0; entryIndex < entries.length; entryIndex++) {
      if (matches[entryIndex] != null) continue;
      final candidateIndex = _findSessionMatch(
        unused,
        entries[entryIndex],
        quality,
      );
      if (candidateIndex == null) continue;
      matches[entryIndex] = unused.removeAt(candidateIndex);
    }
  }

  int? _findSessionMatch(
    List<CourseSession> candidates,
    ImportedTimetableEntry entry,
    _SessionMatchQuality quality,
  ) {
    for (var index = 0; index < candidates.length; index++) {
      if (_sessionMatches(candidates[index], entry, quality)) return index;
    }
    return null;
  }

  bool _sessionMatches(
    CourseSession session,
    ImportedTimetableEntry entry,
    _SessionMatchQuality quality,
  ) {
    final sameSlot =
        session.weekday == entry.dayOfWeek &&
        session.startPeriod == entry.startPeriod &&
        session.endPeriod == entry.endPeriod;
    if (!sameSlot) return false;
    if (quality == _SessionMatchQuality.sameSlot) return true;
    if (session.location != entry.location) return false;
    if (quality == _SessionMatchQuality.sameSlotAndLocation) return true;
    return session.weeks.length == entry.weeks.length &&
        session.weeks.containsAll(entry.weeks);
  }

  CourseSession _newSession({
    required String courseId,
    required ImportedTimetableEntry entry,
  }) {
    return CourseSession(
      id: _idGenerator(),
      courseId: courseId,
      weekday: entry.dayOfWeek,
      startPeriod: entry.startPeriod,
      endPeriod: entry.endPeriod,
      location: entry.location,
      weeks: entry.weeks,
    );
  }
}

/// The immutable result of a [BitcRefreshReconciler] operation.
final class BitcRefreshPlan {
  BitcRefreshPlan({
    required Iterable<CourseWithSessions> desiredCourses,
    required Iterable<CourseWithSessions> desiredSourceManagedCourses,
    required Iterable<CourseWithSessions> added,
    required Iterable<CourseWithSessions> updated,
    required Iterable<CourseWithSessions> removed,
    required Iterable<CourseWithSessions> unchanged,
    required Iterable<CourseWithSessions> locallyModifiedPreserved,
    required Iterable<CourseWithSessions> manualCoursesPreserved,
    Iterable<CourseWithSessions> unmanagedSourceCoursesPreserved = const [],
  }) : desiredCourses = List.unmodifiable(desiredCourses),
       desiredSourceManagedCourses = List.unmodifiable(
         desiredSourceManagedCourses,
       ),
       added = List.unmodifiable(added),
       updated = List.unmodifiable(updated),
       removed = List.unmodifiable(removed),
       unchanged = List.unmodifiable(unchanged),
       locallyModifiedPreserved = List.unmodifiable(locallyModifiedPreserved),
       manualCoursesPreserved = List.unmodifiable(manualCoursesPreserved),
       unmanagedSourceCoursesPreserved = List.unmodifiable(
         unmanagedSourceCoursesPreserved,
       );

  final List<CourseWithSessions> desiredCourses;
  final List<CourseWithSessions> desiredSourceManagedCourses;
  final List<CourseWithSessions> added;
  final List<CourseWithSessions> updated;
  final List<CourseWithSessions> removed;
  final List<CourseWithSessions> unchanged;
  final List<CourseWithSessions> locallyModifiedPreserved;
  final List<CourseWithSessions> manualCoursesPreserved;

  /// Source courses with [CourseSource.zfsoft] but no external ID.
  ///
  /// These are retained because there is no safe key with which to reconcile
  /// them. They are not included in [manualCoursesPreserved].
  final List<CourseWithSessions> unmanagedSourceCoursesPreserved;

  int get addedCount => added.length;
  int get updatedCount => updated.length;
  int get removedCount => removed.length;
  int get unchangedCount => unchanged.length;
  int get locallyModifiedPreservedCount => locallyModifiedPreserved.length;
  int get manualCoursesPreservedCount => manualCoursesPreserved.length;
  int get unmanagedSourceCoursesPreservedCount =>
      unmanagedSourceCoursesPreserved.length;

  /// Alias emphasizing that this is the persistence-ready complete course set.
  List<CourseWithSessions> get desiredCourseWithSessions => desiredCourses;
}

enum _SessionMatchQuality { exact, sameSlotAndLocation, sameSlot }

/// The remote response was unsafe to apply as a refresh.
final class BitcRefreshException implements Exception {
  const BitcRefreshException(this.message);

  final String message;

  @override
  String toString() => 'BitcRefreshException: $message';
}

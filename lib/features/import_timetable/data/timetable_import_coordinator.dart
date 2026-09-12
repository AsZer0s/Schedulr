import 'package:collection/collection.dart';
import 'package:uuid/uuid.dart';

import '../../timetable/data/timetable_repository.dart';
import '../../timetable/domain/timetable_models.dart';
import '../domain/import_timetable.dart';

class TimetableImportCoordinator {
  const TimetableImportCoordinator(this.repository);

  final TimetableRepository repository;

  Future<ImportCommitResult> commit({
    required SemesterTimetable currentTimetable,
    required ImportCommitRequest request,
    ImportTermRequest? importedTerm,
  }) async {
    final semester = importedTerm == null
        ? currentTimetable.semester
        : currentTimetable.semester.copyWith(
            academicYear: importedTerm.academicYear,
            term: '${importedTerm.term}',
            name:
                '${importedTerm.academicYear} 第${_termName(importedTerm.term)}学期',
          );
    final courses = _toCourses(
      semesterId: semester.id,
      entries: request.entriesToAdd,
    );
    final importedTimetable = SemesterTimetable(
      semester: semester,
      courses: courses,
      periodDefinitions: request.strategy == ImportStrategy.replace
          ? currentTimetable.periodDefinitions
          : const [],
    );

    switch (request.strategy) {
      case ImportStrategy.merge:
        await repository.mergeSemesterTimetable(importedTimetable);
      case ImportStrategy.replace:
        await repository.replaceSemesterTimetable(importedTimetable);
    }

    return ImportCommitResult(
      createdCount: courses.length,
      skippedCount:
          request.preview.possibleDuplicateCount +
          request.preview.conflictCount,
      replacedCount: request.strategy == ImportStrategy.replace
          ? currentTimetable.courses.length
          : 0,
    );
  }

  String _termName(int term) {
    return switch (term) {
      1 => '一',
      2 => '二',
      3 => '三',
      _ => '$term',
    };
  }

  List<CourseWithSessions> _toCourses({
    required String semesterId,
    required Iterable<ImportedTimetableEntry> entries,
  }) {
    final groups = groupBy(entries, (entry) => entry.externalId);
    var colorIndex = 0;
    return groups.entries
        .map((group) {
          final first = group.value.first;
          final courseId = const Uuid().v4();
          final course = Course(
            id: courseId,
            semesterId: semesterId,
            name: first.title,
            teacher: first.teacher,
            colorValue: _courseColors[colorIndex++ % _courseColors.length],
            notes: first.notes,
            source: CourseSource.zfsoft,
            sourceId: first.externalId,
          );
          return CourseWithSessions(
            course: course,
            sessions: [
              for (final entry in group.value)
                CourseSession(
                  id: const Uuid().v4(),
                  courseId: courseId,
                  weekday: entry.dayOfWeek,
                  startPeriod: entry.startPeriod,
                  endPeriod: entry.endPeriod,
                  location: entry.location,
                  weeks: entry.weeks,
                ),
            ],
          );
        })
        .toList(growable: false);
  }
}

const _courseColors = <int>[
  0xFF4F46E5,
  0xFF0F766E,
  0xFFB45309,
  0xFFBE123C,
  0xFF7E22CE,
  0xFF0369A1,
];

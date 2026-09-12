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
    @Deprecated('Put term in ImportCommitRequest instead.')
    ImportTermRequest? importedTerm,
    @Deprecated('Put calendar in ImportCommitRequest instead.')
    ImportedSemesterCalendar? calendar,
  }) async {
    final term = request.term ?? importedTerm;
    final importedCalendar = request.calendar ?? calendar;
    final currentSemester = currentTimetable.semester;
    final semester = currentSemester.copyWith(
      academicYear: term?.academicYear,
      term: term == null ? null : '${term.term}',
      name: term == null
          ? null
          : '${term.academicYear} 第${_termName(term.term)}学期',
      startDate: importedCalendar?.startDate,
      teachingWeeks: importedCalendar?.teachingWeeks,
    );
    final courses = _toCourses(
      semesterId: semester.id,
      entries: request.entriesToAdd,
    );

    var replacePeriods = false;
    var periodDefinitions = <PeriodDefinition>[];
    final issues = <ImportIssue>[];
    final schedule = request.timingProfile?.schedule;
    if (schedule != null) {
      final sessionsToCover = request.strategy == ImportStrategy.replace
          ? courses.expand((course) => course.sessions)
          : <CourseSession>[
              ...currentTimetable.courses.expand((course) => course.sessions),
              ...courses.expand((course) => course.sessions),
            ];
      if (_coversAll(schedule, sessionsToCover)) {
        replacePeriods = true;
        periodDefinitions = _toPeriodDefinitions(semester.id, schedule);
      } else if (request.strategy == ImportStrategy.replace) {
        throw ArgumentError(
          'Imported period schedule does not cover every replacement session.',
        );
      } else {
        issues.add(
          const ImportIssue(
            code: ImportIssueCode.invalidSourceData,
            severity: ImportIssueSeverity.warning,
            message: '新作息未覆盖合并后保留的全部课程节次，课程已导入，但本地作息保持不变。',
          ),
        );
      }
    }

    final importedTimetable = SemesterTimetable(
      semester: semester,
      courses: courses,
      periodDefinitions: periodDefinitions,
    );
    await repository.applyImport(
      importedTimetable,
      replaceCourses: request.strategy == ImportStrategy.replace,
      replacePeriods: replacePeriods,
    );

    return ImportCommitResult(
      createdCount: courses.length,
      skippedCount:
          request.preview.possibleDuplicateCount +
          request.preview.conflictCount,
      replacedCount: request.strategy == ImportStrategy.replace
          ? currentTimetable.courses.length
          : 0,
      issues: issues,
    );
  }

  bool _coversAll(
    ImportedPeriodSchedule schedule,
    Iterable<CourseSession> sessions,
  ) => sessions.every(
    (session) => schedule.covers(session.startPeriod, session.endPeriod),
  );

  List<PeriodDefinition> _toPeriodDefinitions(
    String semesterId,
    ImportedPeriodSchedule schedule,
  ) {
    return [
      for (final period in schedule.periods)
        PeriodDefinition(
          id: '$semesterId-period-${period.number}',
          semesterId: semesterId,
          period: period.number,
          startTime: period.startTime,
          endTime: period.endTime,
          group: switch (period.group) {
            ImportedPeriodGroup.morning => PeriodGroup.morning,
            ImportedPeriodGroup.afternoon => PeriodGroup.afternoon,
            ImportedPeriodGroup.evening => PeriodGroup.evening,
          },
        ),
    ];
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

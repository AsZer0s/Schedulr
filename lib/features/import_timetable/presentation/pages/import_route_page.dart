import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/widgets/adaptive_scaffold.dart';

import '../../../timetable/data/providers.dart';
import '../../../timetable/domain/timetable_models.dart';
import '../../data/timetable_import_coordinator.dart';
import '../../domain/import_timetable.dart';
import '../timetable_import_page.dart';

class ImportRoutePage extends ConsumerWidget {
  const ImportRoutePage({this.targetSemesterId, this.initialSource, super.key});

  final String? targetSemesterId;
  final String? initialSource;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final targetId = targetSemesterId?.trim();
    final timetable = targetId == null || targetId.isEmpty
        ? ref.watch(currentTimetableProvider)
        : ref.watch(semesterTimetableByIdProvider(targetId));
    return timetable.when(
      loading: () => const AdaptiveStatusPage(message: '', loading: true),
      error: (error, _) => const AdaptiveStatusPage(message: '读取目标课表失败'),
      data: (value) {
        if (value == null) {
          return const AdaptiveStatusPage(message: '目标课表不存在或已被删除');
        }
        return TimetableImportPage(
          targetTimetableName: value.semester.timetableName,
          existingEntries: _existingEntries(value),
          initialAcademicYear: value.semester.academicYear,
          initialTerm: int.tryParse(value.semester.term) ?? 1,
          initialSource: initialSource == 'demo'
              ? ImportSourceChoice.demo
              : ImportSourceChoice.bitc,
          onCommit: (request) async {
            await TimetableImportCoordinator(
              ref.read(timetableRepositoryProvider),
            ).commit(currentTimetable: value, request: request);
          },
        );
      },
    );
  }

  List<ExistingTimetableEntry> _existingEntries(SemesterTimetable timetable) {
    return [
      for (final course in timetable.courses)
        for (final session in course.sessions)
          ExistingTimetableEntry(
            id: session.id,
            title: course.course.name,
            teacher: course.course.teacher,
            location: session.location,
            sourceExternalId: course.course.sourceId,
            dayOfWeek: session.weekday,
            startPeriod: session.startPeriod,
            endPeriod: session.endPeriod,
            weeks: session.weeks,
          ),
    ];
  }
}

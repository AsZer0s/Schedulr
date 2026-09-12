import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../timetable/data/providers.dart';
import '../../../timetable/domain/timetable_models.dart';
import '../../data/timetable_import_coordinator.dart';
import '../../domain/import_timetable.dart';
import '../timetable_import_page.dart';

class ImportRoutePage extends ConsumerWidget {
  const ImportRoutePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timetable = ref.watch(currentTimetableProvider);
    return timetable.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) =>
          const Scaffold(body: Center(child: Text('读取本地课表失败'))),
      data: (value) {
        if (value == null) {
          return const Scaffold(body: Center(child: Text('尚未初始化学期')));
        }
        return TimetableImportPage(
          existingEntries: _existingEntries(value),
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

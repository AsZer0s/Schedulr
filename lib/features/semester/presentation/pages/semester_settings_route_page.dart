import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/widgets/adaptive_scaffold.dart';

import '../../../timetable/data/providers.dart';
import '../semester_settings_page.dart';

class SemesterSettingsRoutePage extends ConsumerWidget {
  const SemesterSettingsRoutePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final semester = ref.watch(currentSemesterProvider);
    return semester.when(
      loading: () => const AdaptiveStatusPage(message: '', loading: true),
      error: (error, _) => const AdaptiveStatusPage(message: '学期读取失败'),
      data: (value) {
        if (value == null) {
          return const AdaptiveStatusPage(message: '尚未初始化学期');
        }
        return SemesterSettingsPage(
          semester: value,
          onSave: ref.read(timetableRepositoryProvider).upsertSemester,
        );
      },
    );
  }
}

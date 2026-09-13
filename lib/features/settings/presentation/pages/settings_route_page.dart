import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/platform/adaptive_ui.dart';
import '../../../../core/storage/secure_session_store.dart';
import '../../../timetable/data/providers.dart';
import '../settings_page.dart';

class SettingsRoutePage extends ConsumerWidget {
  const SettingsRoutePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingsPage(
      onEditSemester: () => context.push('/settings/semester'),
      onClearSession: () async {
        await const SecureSessionStore().clear();
        await WebViewCookieManager().clearCookies();
      },
      onClearAllData: () async {
        final confirmed = await showAdaptiveConfirmationDialog(
          context,
          title: '删除全部本地数据？',
          message: '所有课程、学期和作息设置将被删除。完成后需要重新进行首次设置。',
          confirmLabel: '全部删除',
          destructive: true,
        );
        if (!confirmed) return;
        final repository = ref.read(timetableRepositoryProvider);
        await repository.clearAllTimetableData();
        if (!context.mounted) return;
        context.go('/onboarding');
      },
    );
  }
}

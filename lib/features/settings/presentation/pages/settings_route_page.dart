import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/platform/adaptive_ui.dart';
import '../../../desktop_widget/widget_providers.dart';
import '../../../desktop_widget/widget_publisher.dart';
import '../../../import_timetable/data/providers.dart' as import_providers;
import '../../../timetable/data/providers.dart';
import '../settings_page.dart';

class SettingsRoutePage extends ConsumerWidget {
  const SettingsRoutePage({this.clearWebViewCookies, super.key});

  final Future<void> Function()? clearWebViewCookies;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(import_providers.bitcAccountsProvider);
    final sessionStore = ref.watch(import_providers.secureSessionStoreProvider);
    final clearCookies =
        clearWebViewCookies ?? WebViewCookieManager().clearCookies;
    return SettingsPage(
      savedAccountCount: accounts.value?.length ?? 0,
      onEditSemester: () => context.push('/settings/semester'),
      onClearSession: () async {
        await sessionStore.clearCurrentWebSessionAccount();
        await clearCookies();
      },
      onDeleteSavedAccounts: () async {
        await ref.read(import_providers.bitcAccountStoreProvider).deleteAll();
        await sessionStore.clearCurrentWebSessionAccount();
        ref.invalidate(import_providers.bitcAccountsProvider);
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
        await WidgetSnapshotPublisher(ref.read(widgetStorageBridgeProvider))
            .clear();
        await ref.read(import_providers.bitcAccountStoreProvider).deleteAll();
        await sessionStore.clearCurrentWebSessionAccount();
        await clearCookies();
        await repository.clearAllTimetableData();
        if (!context.mounted) return;
        context.go('/onboarding');
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/widgets/adaptive_scaffold.dart';

import '../../../timetable/data/providers.dart';
import '../../../timetable/domain/timetable_models.dart';
import '../../data/providers.dart' as import_providers;
import '../../data/timetable_import_coordinator.dart';
import '../../domain/bitc_account.dart';
import '../../domain/import_timetable.dart';
import '../timetable_import_page.dart';

class ImportRoutePage extends ConsumerWidget {
  const ImportRoutePage({
    this.targetSemesterId,
    this.initialSource,
    this.refreshMode = false,
    this.onCommit,
    this.clearWebViewCookies,
    super.key,
  });

  final String? targetSemesterId;
  final String? initialSource;
  final bool refreshMode;
  final Future<void> Function(ImportCommitRequest request)? onCommit;
  final Future<void> Function()? clearWebViewCookies;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final targetId = targetSemesterId?.trim();
    final timetable = targetId == null || targetId.isEmpty
        ? ref.watch(currentTimetableProvider)
        : ref.watch(semesterTimetableByIdProvider(targetId));
    final account = targetId == null || targetId.isEmpty
        ? const AsyncValue<BitcAccount?>.data(null)
        : ref.watch(import_providers.bitcAccountProvider(targetId));
    return timetable.when(
      loading: () => const AdaptiveStatusPage(message: '', loading: true),
      error: (error, _) => const AdaptiveStatusPage(message: '读取目标课表失败'),
      data: (value) {
        if (value == null) {
          return const AdaptiveStatusPage(message: '目标课表不存在或已被删除');
        }
        return account.when(
          loading: () => const AdaptiveStatusPage(message: '', loading: true),
          error: (error, stackTrace) =>
              const AdaptiveStatusPage(message: '读取已保存教务账号失败'),
          data: (savedAccount) => TimetableImportPage(
            timetableId: value.semester.id,
            existingTimetable: value,
            initialAccount: savedAccount,
            refreshMode: refreshMode,
            clearWebViewCookies: clearWebViewCookies,
            targetTimetableName: value.semester.timetableName,
            existingEntries: _existingEntries(value),
            initialAcademicYear: value.semester.academicYear,
            initialTerm: int.tryParse(value.semester.term) ?? 1,
            initialSource: initialSource == 'demo'
                ? ImportSourceChoice.demo
                : ImportSourceChoice.bitc,
            secureSessionStore: ref.read(
              import_providers.secureSessionStoreProvider,
            ),
            onCommit:
                onCommit ??
                (request) async {
                  await TimetableImportCoordinator(
                    ref.read(timetableRepositoryProvider),
                  ).commit(currentTimetable: value, request: request);
                },
            onRefresh: (imported, timingProfile, plan) async {
              await TimetableImportCoordinator(
                ref.read(timetableRepositoryProvider),
              ).refresh(
                currentTimetable: value,
                imported: imported,
                timingProfile: timingProfile,
                preparedPlan: plan,
              );
            },
            onDeleteAccount: () async {
              await ref
                  .read(import_providers.bitcAccountStoreProvider)
                  .delete(value.semester.id);
              ref.invalidate(
                import_providers.bitcAccountProvider(value.semester.id),
              );
              ref.invalidate(import_providers.bitcAccountsProvider);
            },
            onSaveAccount: (accountId, refreshedAt) async {
              await ref
                  .read(import_providers.bitcAccountStoreProvider)
                  .write(
                    BitcAccount(
                      accountId: accountId,
                      timetableId: value.semester.id,
                      lastSuccessfulRefreshAt: refreshedAt,
                    ),
                  );
              ref.invalidate(
                import_providers.bitcAccountProvider(value.semester.id),
              );
              ref.invalidate(import_providers.bitcAccountsProvider);
            },
            onCompleted: () => context.go('/'),
          ),
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

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:schedulr/core/storage/app_database.dart' show AppDatabase;
import 'package:schedulr/features/desktop_widget/widget_providers.dart';
import 'package:schedulr/features/desktop_widget/widget_publisher.dart';
import 'package:schedulr/features/settings/presentation/pages/settings_route_page.dart';
import 'package:schedulr/features/timetable/data/providers.dart';
import 'package:schedulr/features/timetable/data/timetable_repository.dart';
import 'package:schedulr/features/timetable/domain/timetable_models.dart';

void main() {
  testWidgets('delete all clears repository and routes to onboarding', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = TimetableRepository(database);
    await repository.replaceSemesterTimetable(
      SemesterTimetable(
        semester: Semester(
          id: 'semester',
          academicYear: '2030-2031',
          term: '1',
          name: '测试学期',
          timetableName: '测试课表',
          startDate: DateTime(2030, 9, 2),
          teachingWeeks: 20,
          isCurrent: true,
        ),
        courses: const [],
        periodDefinitions: const [],
      ),
    );
    final bridge = _RecordingWidgetBridge();
    final router = GoRouter(
      initialLocation: '/settings',
      routes: [
        GoRoute(
          path: '/settings',
          builder: (_, _) => const SettingsRoutePage(),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (_, _) => const Scaffold(body: Text('首次设置页')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          timetableDatabaseProvider.overrideWithValue(database),
          timetableRepositoryProvider.overrideWithValue(repository),
          widgetStorageBridgeProvider.overrideWithValue(bridge),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除全部本地数据'));
    await tester.pumpAndSettle();

    expect(find.text('所有课程、学期和作息设置将被删除。完成后需要重新进行首次设置。'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, '全部删除'));
    await tester.pumpAndSettle();

    expect(await repository.getSemesters(), isEmpty);
    expect(bridge.calls, [
      'group:${HomeWidgetStorageBridge.appGroupId}',
      'clear',
    ]);
    expect(router.state.uri.path, '/onboarding');
    expect(find.text('首次设置页'), findsOneWidget);
  });
}

class _RecordingWidgetBridge implements WidgetStorageBridge {
  final calls = <String>[];

  @override
  Future<void> clearSnapshot() async => calls.add('clear');

  @override
  Future<void> saveSnapshot(String value) async => calls.add('save');

  @override
  Future<void> setAppGroupId(String groupId) async {
    calls.add('group:$groupId');
  }

  @override
  Future<void> updateWidget() async => calls.add('update');
}

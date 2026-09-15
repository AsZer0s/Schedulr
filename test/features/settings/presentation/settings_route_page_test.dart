import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:schedulr/core/storage/app_database.dart' show AppDatabase;
import 'package:schedulr/core/storage/secure_session_store.dart';
import 'package:schedulr/features/desktop_widget/widget_providers.dart';
import 'package:schedulr/features/desktop_widget/widget_publisher.dart';
import 'package:schedulr/features/import_timetable/data/providers.dart'
    as import_providers;
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
    final secureAdapter = _MemorySecureAdapter();
    var cookiesCleared = false;
    final router = GoRouter(
      initialLocation: '/settings',
      routes: [
        GoRoute(
          path: '/settings',
          builder: (_, _) => SettingsRoutePage(
            clearWebViewCookies: () async => cookiesCleared = true,
          ),
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
          import_providers.secureKeyValueAdapterProvider.overrideWithValue(
            secureAdapter,
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('正方教务导入'), findsNothing);
    expect(find.text('北京信息职业技术学院'), findsNothing);
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
    expect(cookiesCleared, isTrue);
    expect(secureAdapter.values, isEmpty);
    expect(find.text('首次设置页'), findsOneWidget);
  });
}

class _MemorySecureAdapter implements SecureKeyValueAdapter {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<Map<String, String>> readAll() async => Map.of(values);

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }
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

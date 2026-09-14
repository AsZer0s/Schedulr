import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:schedulr/core/storage/secure_session_store.dart';
import 'package:schedulr/features/import_timetable/data/providers.dart'
    as import_providers;
import 'package:schedulr/features/import_timetable/domain/import_timetable.dart';
import 'package:schedulr/features/import_timetable/presentation/pages/import_route_page.dart';
import 'package:schedulr/features/timetable/data/providers.dart';
import 'package:schedulr/features/timetable/domain/timetable_models.dart';

void main() {
  late _MemorySecureAdapter secureAdapter;

  setUp(() {
    secureAdapter = _MemorySecureAdapter();
  });

  testWidgets('target 参数固定读取指定课表而不是全局 current', (tester) async {
    final current = _timetable(id: 'current', timetableName: '我的课表');
    final target = _timetable(
      id: 'target',
      timetableName: '小明',
      academicYear: '2031-2032',
      term: '2',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          import_providers.secureKeyValueAdapterProvider.overrideWithValue(
            secureAdapter,
          ),
          currentTimetableProvider.overrideWith((ref) => Stream.value(current)),
          semesterTimetableByIdProvider.overrideWith(
            (ref, id) => Stream.value(id == target.semester.id ? target : null),
          ),
        ],
        child: const TestApp(
          child: ImportRoutePage(
            targetSemesterId: 'target',
            initialSource: 'bitc',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('导入到'), findsOneWidget);
    expect(find.text('小明'), findsOneWidget);
    expect(find.byKey(const ValueKey('bitc-account-field')), findsOneWidget);
    final saveAccount = tester.widget<SwitchListTile>(
      find.byKey(const ValueKey('save-bitc-account')),
    );
    expect(saveAccount.value, isTrue);
    expect(find.text('演示密码'), findsNothing);
    final yearField = tester.widget<TextField>(
      find.byWidgetPredicate(
        (widget) => widget is TextField && widget.decoration?.labelText == '学年',
      ),
    );
    expect(yearField.controller!.text, target.semester.academicYear);
    final termButton = tester.widget<SegmentedButton<int>>(
      find.byType(SegmentedButton<int>).first,
    );
    expect(termButton.selected, {int.parse(target.semester.term)});
  });

  testWidgets('不存在的 target 显示明确错误', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          import_providers.secureKeyValueAdapterProvider.overrideWithValue(
            secureAdapter,
          ),
          semesterTimetableByIdProvider.overrideWith(
            (ref, id) => Stream.value(null),
          ),
        ],
        child: const TestApp(
          child: ImportRoutePage(targetSemesterId: 'missing'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('目标课表不存在或已被删除'), findsOneWidget);
  });

  testWidgets('refresh requires an account before reusing or opening WebView', (
    tester,
  ) async {
    var cookiesCleared = 0;
    final timetable = _timetable(id: 'target', timetableName: '同学课表');
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          import_providers.secureKeyValueAdapterProvider.overrideWithValue(
            secureAdapter,
          ),
          semesterTimetableByIdProvider.overrideWith(
            (ref, id) => Stream.value(timetable),
          ),
        ],
        child: TestApp(
          child: ImportRoutePage(
            targetSemesterId: timetable.semester.id,
            initialSource: 'bitc',
            refreshMode: true,
            clearWebViewCookies: () async => cookiesCleared++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('bitc-account-field')),
      '',
    );
    await tester.tap(find.byKey(const ValueKey('import-primary-action')).first);
    await tester.pump();

    expect(find.text('请输入此课表对应的 BITC 教务账号后再刷新。'), findsOneWidget);
    expect(cookiesCleared, 0);
  });

  testWidgets('initial /import commits locally then routes to home', (
    tester,
  ) async {
    var commitCount = 0;
    final router = _importRouter(
      onCommit: (request) async {
        commitCount += 1;
        expect(request.entriesToAdd, isNotEmpty);
      },
    );
    addTearDown(router.dispose);
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          import_providers.secureKeyValueAdapterProvider.overrideWithValue(
            secureAdapter,
          ),
          currentTimetableProvider.overrideWith(
            (ref) =>
                Stream.value(_timetable(id: 'current', timetableName: '我的课表')),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('正方教务导入'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('import-primary-action')).first);
    await tester.pumpAndSettle();
    expect(find.text('导入预览'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('import-preview-commit')));
    await tester.pumpAndSettle();

    expect(commitCount, 1);
    expect(router.state.uri.path, '/');
    expect(find.text('首页'), findsOneWidget);
    expect(find.textContaining('已导入'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

GoRouter _importRouter({
  required Future<void> Function(ImportCommitRequest request) onCommit,
}) {
  return GoRouter(
    initialLocation: '/import?source=demo',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: Text('首页')),
      ),
      GoRoute(
        path: '/import',
        builder: (_, state) => ImportRoutePage(
          targetSemesterId: state.uri.queryParameters['target'],
          initialSource: state.uri.queryParameters['source'],
          onCommit: onCommit,
        ),
      ),
    ],
  );
}

class TestApp extends StatelessWidget {
  const TestApp({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => MaterialApp(home: child);
}

final class _MemorySecureAdapter implements SecureKeyValueAdapter {
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

SemesterTimetable _timetable({
  required String id,
  required String timetableName,
  String academicYear = '2026-2027',
  String term = '1',
}) {
  return SemesterTimetable(
    semester: Semester(
      id: id,
      academicYear: academicYear,
      term: term,
      name: '2026-2027 第一学期',
      timetableName: timetableName,
      startDate: DateTime(2026, 9, 7),
      teachingWeeks: 20,
      isCurrent: id == 'current',
    ),
    courses: const [],
    periodDefinitions: const [],
  );
}

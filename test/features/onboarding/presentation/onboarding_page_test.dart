import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:schedulr/core/time/current_date.dart';
import 'package:schedulr/features/onboarding/presentation/onboarding_page.dart';

void main() {
  testWidgets('iOS 使用 Cupertino 导航、分段控件和日期滚轮', (tester) async {
    final router = _router(
      OnboardingPage(
        onSubmit: ({
          required timetableName,
          required academicYear,
          required term,
          required startDate,
          required teachingWeeks,
        }) async => 'created',
      ),
    );
    addTearDown(router.dispose);
    await _pump(tester, router, platform: TargetPlatform.iOS);

    expect(find.byType(CupertinoNavigationBar), findsOneWidget);
    expect(find.byType(CupertinoButton), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('onboarding-next')));
    await tester.pump();
    expect(find.byType(CupertinoSlidingSegmentedControl<int>), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('onboarding-start-date')));
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoDatePicker), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('adaptive-date-done')));
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoDatePicker), findsNothing);
  });

  testWidgets('validates fields without submitting partial data', (
    tester,
  ) async {
    var submits = 0;
    final router = _router(
      OnboardingPage(
        onSubmit:
            ({
              required timetableName,
              required academicYear,
              required term,
              required startDate,
              required teachingWeeks,
            }) async {
              submits++;
              return 'created';
            },
      ),
    );
    addTearDown(router.dispose);
    await _pump(tester, router);

    await tester.enterText(
      find.byKey(const ValueKey('onboarding-name')),
      '   ',
    );
    await tester.tap(find.byKey(const ValueKey('onboarding-next')));
    await tester.pump();
    expect(find.text('请输入课表名称。'), findsOneWidget);
    expect(submits, 0);

    await tester.enterText(find.byKey(const ValueKey('onboarding-name')), '课表');
    await tester.tap(find.byKey(const ValueKey('onboarding-next')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('onboarding-academic-year')),
      '2030-2032',
    );
    await tester.enterText(
      find.byKey(const ValueKey('onboarding-weeks')),
      '41',
    );
    await tester.tap(find.byKey(const ValueKey('onboarding-next')));
    await tester.pump();
    expect(find.text('学年需使用连续的 YYYY-YYYY 格式。'), findsOneWidget);
    expect(submits, 0);
  });

  for (final completion in <String, String>{
    'onboarding-blank': '/',
    'onboarding-import': '/import',
  }.entries) {
    testWidgets(
      '${completion.key} creates once and navigates to expected branch',
      (tester) async {
        var submits = 0;
        Map<String, Object?>? values;
        final router = _router(
          OnboardingPage(
            onSubmit:
                ({
                  required timetableName,
                  required academicYear,
                  required term,
                  required startDate,
                  required teachingWeeks,
                }) async {
                  submits++;
                  values = {
                    'name': timetableName,
                    'academicYear': academicYear,
                    'term': term,
                    'startDate': startDate,
                    'weeks': teachingWeeks,
                  };
                  return 'created-id';
                },
          ),
        );
        addTearDown(router.dispose);
        await _pump(tester, router);

        await tester.enterText(
          find.byKey(const ValueKey('onboarding-name')),
          '  新课表  ',
        );
        await tester.tap(find.byKey(const ValueKey('onboarding-next')));
        await tester.pump();
        await tester.enterText(
          find.byKey(const ValueKey('onboarding-academic-year')),
          '2030-2031',
        );
        await tester.enterText(
          find.byKey(const ValueKey('onboarding-weeks')),
          '18',
        );
        await tester.tap(find.byKey(const ValueKey('onboarding-next')));
        await tester.pump();
        await tester.tap(find.byKey(ValueKey(completion.key)));
        await tester.pumpAndSettle();

        expect(submits, 1);
        expect(values?['name'], '新课表');
        expect(values?['academicYear'], '2030-2031');
        expect(values?['weeks'], 18);
        expect(router.state.uri.path, completion.value);
        if (completion.value == '/import') {
          expect(router.state.uri.queryParameters['target'], 'created-id');
          expect(router.state.uri.queryParameters['source'], 'bitc');
        }
      },
    );
  }

  testWidgets('failed submission stays on confirmation and shows error', (
    tester,
  ) async {
    final router = _router(
      OnboardingPage(
        onSubmit: ({
          required timetableName,
          required academicYear,
          required term,
          required startDate,
          required teachingWeeks,
        }) async => throw StateError('save failed'),
      ),
    );
    addTearDown(router.dispose);
    await _pump(tester, router);
    await tester.tap(find.byKey(const ValueKey('onboarding-next')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('onboarding-next')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('onboarding-blank')));
    await tester.pump();

    expect(router.state.uri.path, '/onboarding');
    expect(find.textContaining('首次设置保存失败'), findsOneWidget);
    expect(find.byKey(const ValueKey('onboarding-blank')), findsOneWidget);
  });
}

Future<void> _pump(
  WidgetTester tester,
  GoRouter router, {
  TargetPlatform platform = TargetPlatform.android,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [clockProvider.overrideWithValue(() => DateTime(2030, 9, 13))],
      child: MaterialApp.router(
        theme: ThemeData(platform: platform),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

GoRouter _router(Widget onboarding) {
  return GoRouter(
    initialLocation: '/onboarding',
    routes: [
      GoRoute(path: '/onboarding', builder: (_, _) => onboarding),
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: Text('首页')),
      ),
      GoRoute(
        path: '/import',
        builder: (_, _) => const Scaffold(body: Text('导入页')),
      ),
    ],
  );
}

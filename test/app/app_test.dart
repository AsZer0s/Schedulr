import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:schedulr/app/app.dart';
import 'package:schedulr/features/timetable/data/providers.dart';

class _NoopTimer implements CancelableMidnightTimer {
  @override
  void cancel() {}
}

void main() {
  testWidgets(
    'uses requested initial location and creates an isolated router',
    (tester) async {
      GoRouter? created;
      await tester.pumpWidget(
        ProviderScope(
          child: SchedulrApp(
            enableDesktopWidgetSync: false,
            initialLocation: '/onboarding',
            routerFactory: (initialLocation) {
              created = GoRouter(
                initialLocation: initialLocation,
                routes: [
                  GoRoute(
                    path: '/',
                    builder: (_, _) => const Scaffold(body: Text('首页')),
                  ),
                  GoRoute(
                    path: '/onboarding',
                    builder: (_, _) => const Scaffold(body: Text('首次设置')),
                  ),
                ],
              );
              return created!;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(created!.state.uri.path, '/onboarding');
      expect(find.text('首次设置'), findsOneWidget);
    },
  );

  testWidgets('resume refreshes current date from the clock', (tester) async {
    var now = DateTime(2030, 4, 5, 10);
    final container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(() => now),
        midnightTimerFactoryProvider.overrideWithValue(
          (delay, callback) => _NoopTimer(),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: SchedulrApp(
          enableDesktopWidgetSync: false,
          routerFactory: (initialLocation) => GoRouter(
            initialLocation: initialLocation,
            routes: [
              GoRoute(
                path: '/',
                builder: (_, _) => const Scaffold(body: Text('首页')),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(container.read(currentDateNotifierProvider), DateTime(2030, 4, 5));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    now = DateTime(2030, 4, 8, 9);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(container.read(currentDateNotifierProvider), DateTime(2030, 4, 8));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets(
    'widget clicks follow current router state instead of startup route',
    (tester) async {
      final clicks = StreamController<Uri?>();
      addTearDown(clicks.close);
      late GoRouter router;
      router = GoRouter(
        initialLocation: '/onboarding',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('首页')),
          ),
          GoRoute(
            path: '/onboarding',
            builder: (_, _) => Scaffold(
              body: TextButton(
                onPressed: () => router.go('/'),
                child: const Text('完成首次设置'),
              ),
            ),
          ),
          GoRoute(
            path: '/settings',
            builder: (_, _) => const Scaffold(body: Text('设置页')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentTimetableProvider.overrideWith((ref) => Stream.value(null)),
            midnightTimerFactoryProvider.overrideWithValue(
              (delay, callback) => _NoopTimer(),
            ),
          ],
          child: SchedulrApp(
            initialLocation: '/onboarding',
            routerFactory: (_) => router,
            desktopWidgetClicks: clicks.stream,
            publishDesktopWidgetSnapshot: (_) async {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));

      clicks.add(Uri.parse('schedulr://home?homeWidget'));
      await tester.pump();
      expect(router.state.uri.path, '/onboarding');

      await tester.tap(find.text('完成首次设置'));
      await tester.pumpAndSettle();
      router.go('/settings');
      await tester.pumpAndSettle();

      clicks.add(Uri.parse('schedulr://home?homeWidget'));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/');

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets('publishes a widget snapshot when current timetable changes', (
    tester,
  ) async {
    var publishCount = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentTimetableProvider.overrideWith((ref) => Stream.value(null)),
          clockProvider.overrideWithValue(() => DateTime(2030, 4, 5, 8)),
          midnightTimerFactoryProvider.overrideWithValue(
            (delay, callback) => _NoopTimer(),
          ),
        ],
        child: SchedulrApp(
          publishDesktopWidgetSnapshot: (now) async => publishCount++,
          routerFactory: (initialLocation) => GoRouter(
            initialLocation: initialLocation,
            routes: [
              GoRoute(
                path: '/',
                builder: (_, _) => const Scaffold(body: Text('首页')),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));

    expect(publishCount, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

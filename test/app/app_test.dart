import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:schedulr/app/app.dart';
import 'package:schedulr/core/time/current_date.dart';

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
}

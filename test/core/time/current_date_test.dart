import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schedulr/core/time/current_date.dart';

void main() {
  test(
    'initializes from local clock and schedules one next-midnight timer',
    () {
      final now = DateTime(2030, 4, 5, 10, 30);
      final scheduler = _FakeScheduler();
      final container = ProviderContainer(
        overrides: [
          clockProvider.overrideWithValue(() => now),
          midnightTimerFactoryProvider.overrideWithValue(scheduler.call),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(currentDateNotifierProvider), DateTime(2030, 4, 5));
      expect(scheduler.activeCount, 1);
      expect(
        scheduler.lastDelay,
        const Duration(hours: 13, minutes: 30, milliseconds: 10),
      );
    },
  );

  test('midnight callback refreshes date and self-reschedules once', () {
    var now = DateTime(2030, 4, 5, 23, 59, 59);
    final scheduler = _FakeScheduler();
    final container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(() => now),
        midnightTimerFactoryProvider.overrideWithValue(scheduler.call),
      ],
    );
    addTearDown(container.dispose);
    container.read(currentDateNotifierProvider);

    now = DateTime(2030, 4, 6, 0, 0, 1);
    scheduler.fireActive();

    expect(container.read(currentDateNotifierProvider), DateTime(2030, 4, 6));
    expect(scheduler.activeCount, 1);
  });

  test('delayed callback catches up multiple days from the current clock', () {
    var now = DateTime(2030, 4, 5, 22);
    final scheduler = _FakeScheduler();
    final container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(() => now),
        midnightTimerFactoryProvider.overrideWithValue(scheduler.call),
      ],
    );
    addTearDown(container.dispose);
    container.read(currentDateNotifierProvider);

    now = DateTime(2030, 4, 9, 8);
    scheduler.fireActive();

    expect(container.read(currentDateNotifierProvider), DateTime(2030, 4, 9));
    expect(scheduler.activeCount, 1);
  });

  test('refreshNow handles forward and backward clock changes', () {
    var now = DateTime(2030, 4, 5, 12);
    final scheduler = _FakeScheduler();
    final container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(() => now),
        midnightTimerFactoryProvider.overrideWithValue(scheduler.call),
      ],
    );
    addTearDown(container.dispose);
    final notifier = container.read(currentDateNotifierProvider.notifier);

    now = DateTime(2030, 4, 8, 12);
    notifier.refreshNow();
    expect(container.read(currentDateNotifierProvider), DateTime(2030, 4, 8));
    expect(scheduler.activeCount, 1);

    now = DateTime(2030, 4, 3, 12);
    notifier.refreshNow();
    expect(container.read(currentDateNotifierProvider), DateTime(2030, 4, 3));
    expect(scheduler.activeCount, 1);
  });

  test('dispose cancels the active timer', () {
    final scheduler = _FakeScheduler();
    final container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(() => DateTime(2030, 4, 5)),
        midnightTimerFactoryProvider.overrideWithValue(scheduler.call),
      ],
    );
    container.read(currentDateNotifierProvider);

    container.dispose();

    expect(scheduler.activeCount, 0);
    expect(scheduler.timers.single.cancelled, isTrue);
  });
}

class _FakeScheduler {
  final timers = <_FakeTimer>[];
  Duration? lastDelay;

  CancelableMidnightTimer call(Duration delay, void Function() callback) {
    lastDelay = delay;
    final timer = _FakeTimer(callback);
    timers.add(timer);
    return timer;
  }

  int get activeCount => timers.where((timer) => !timer.cancelled).length;

  void fireActive() {
    final active = timers.singleWhere((timer) => !timer.cancelled);
    active.cancelled = true;
    active.callback();
  }
}

class _FakeTimer implements CancelableMidnightTimer {
  _FakeTimer(this.callback);

  final void Function() callback;
  bool cancelled = false;

  @override
  void cancel() => cancelled = true;
}

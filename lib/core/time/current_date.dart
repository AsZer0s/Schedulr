import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'teaching_calendar.dart';

typedef AppClock = DateTime Function();
typedef MidnightTimerFactory = CancelableMidnightTimer Function(
  Duration delay,
  void Function() callback,
);

abstract interface class CancelableMidnightTimer {
  void cancel();
}

class _DartMidnightTimer implements CancelableMidnightTimer {
  _DartMidnightTimer(Duration delay, void Function() callback)
    : _timer = Timer(delay, callback);

  final Timer _timer;

  @override
  void cancel() => _timer.cancel();
}

final clockProvider = Provider<AppClock>((ref) => DateTime.now);

final midnightTimerFactoryProvider = Provider<MidnightTimerFactory>(
  (ref) =>
      (delay, callback) => _DartMidnightTimer(delay, callback),
);

final currentDateNotifierProvider =
    NotifierProvider<CurrentDateNotifier, DateTime>(CurrentDateNotifier.new);

// Compatibility alias for existing overrides and consumers.
final currentDateProvider = Provider<DateTime>((ref) {
  return ref.watch(currentDateNotifierProvider);
});

class CurrentDateNotifier extends Notifier<DateTime> {
  static const _midnightEpsilon = Duration(milliseconds: 10);

  CancelableMidnightTimer? _timer;

  @override
  DateTime build() {
    ref.onDispose(_cancelTimer);
    final now = ref.read(clockProvider)();
    _scheduleFrom(now);
    return dateOnly(now);
  }

  void refreshNow() {
    final now = ref.read(clockProvider)();
    state = dateOnly(now);
    _scheduleFrom(now);
  }

  void _scheduleFrom(DateTime now) {
    _cancelTimer();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    var delay = nextMidnight.difference(now) + _midnightEpsilon;
    if (delay <= Duration.zero) {
      delay = _midnightEpsilon;
    }
    _timer = ref.read(midnightTimerFactoryProvider)(delay, refreshNow);
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_widget/home_widget.dart';

import '../features/desktop_widget/widget_providers.dart';
import '../features/desktop_widget/widget_publisher.dart';
import '../features/timetable/data/providers.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class SchedulrApp extends ConsumerStatefulWidget {
  const SchedulrApp({
    this.initialLocation = '/',
    this.routerFactory,
    this.enableDesktopWidgetSync = true,
    this.publishDesktopWidgetSnapshot,
    this.onDesktopWidgetDiagnostics,
    this.desktopWidgetClicks,
    super.key,
  });

  final String initialLocation;
  final GoRouter Function(String initialLocation)? routerFactory;
  final bool enableDesktopWidgetSync;
  final Future<void> Function(DateTime now)? publishDesktopWidgetSnapshot;
  final void Function(WidgetPublishDiagnostics diagnostics)?
  onDesktopWidgetDiagnostics;
  final Stream<Uri?>? desktopWidgetClicks;

  @override
  ConsumerState<SchedulrApp> createState() => _SchedulrAppState();
}

class _SchedulrAppState extends ConsumerState<SchedulrApp> {
  late final GoRouter _router;
  late final AppLifecycleListener _lifecycleListener;
  Timer? _widgetPublishDebounce;
  StreamSubscription<Uri?>? _widgetClickSubscription;

  @override
  void initState() {
    super.initState();
    _router =
        (widget.routerFactory ??
        (initialLocation) => createAppRouter(initialLocation: initialLocation))(
          widget.initialLocation,
        );
    _lifecycleListener = AppLifecycleListener(
      onResume: () {
        ref.read(currentDateNotifierProvider.notifier).refreshNow();
        _scheduleWidgetPublish();
      },
    );
    if (widget.enableDesktopWidgetSync) {
      ref.listenManual(
        currentTimetableProvider,
        (_, _) => _scheduleWidgetPublish(),
      );
      ref.listenManual(currentDateProvider, (_, _) => _scheduleWidgetPublish());
      _widgetClickSubscription =
          (widget.desktopWidgetClicks ?? HomeWidget.widgetClicked).listen(
            _handleWidgetClick,
          );
      unawaited(_handleInitialWidgetLaunch());
      _scheduleWidgetPublish();
    }
  }

  Future<void> _handleInitialWidgetLaunch() async {
    try {
      _handleWidgetClick(await HomeWidget.initiallyLaunchedFromHomeWidget());
    } on Object {
      // The platform bridge is unavailable in pure widget tests and some hosts.
    }
  }

  void _handleWidgetClick(Uri? uri) {
    if (uri == null || _router.state.uri.path == '/onboarding') return;
    if (uri.scheme == 'schedulr' && uri.host == 'home') {
      _router.go('/');
    }
  }

  void _scheduleWidgetPublish() {
    if (!widget.enableDesktopWidgetSync) return;
    _widgetPublishDebounce?.cancel();
    _widgetPublishDebounce = Timer(const Duration(milliseconds: 200), () async {
      await _publishDesktopWidgetWithRetry();
    });
  }

  Future<void> _publishDesktopWidgetWithRetry() async {
    const maxAttempts = 2;
    Object? lastError;
    StackTrace? lastStackTrace;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final now = ref.read(clockProvider)();
        final callback = widget.publishDesktopWidgetSnapshot;
        if (callback != null) {
          await callback(now);
          widget.onDesktopWidgetDiagnostics?.call(
            WidgetPublishDiagnostics(
              stage: WidgetPublishStage.completed,
              attempt: attempt,
              occurredAt: DateTime.now().toUtc(),
            ),
          );
        } else {
          await WidgetSnapshotCoordinator(
            repository: ref.read(timetableRepositoryProvider),
            bridge: ref.read(widgetStorageBridgeProvider),
            onDiagnostics: widget.onDesktopWidgetDiagnostics,
          ).publishCurrent(now, attempt: attempt);
        }
        return;
      } on Object catch (error, stackTrace) {
        lastError = error;
        lastStackTrace = stackTrace;
        if (widget.publishDesktopWidgetSnapshot != null) {
          widget.onDesktopWidgetDiagnostics?.call(
            WidgetPublishDiagnostics(
              stage: WidgetPublishStage.failed,
              attempt: attempt,
              occurredAt: DateTime.now().toUtc(),
              errorCode: 'callback-failure',
              retryable: true,
            ),
          );
        }
        if (attempt < maxAttempts) {
          await Future<void>.delayed(const Duration(milliseconds: 250));
        }
      }
    }
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: lastError!,
        stack: lastStackTrace,
        library: 'Schedulr desktop widget',
        context: ErrorDescription('while publishing a desktop widget snapshot'),
      ),
    );
  }

  @override
  void dispose() {
    _widgetPublishDebounce?.cancel();
    unawaited(_widgetClickSubscription?.cancel());
    _lifecycleListener.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '课程表',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: _router,
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [Locale('zh', 'CN'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
    );
  }
}

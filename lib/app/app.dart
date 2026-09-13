import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/time/current_date.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class SchedulrApp extends ConsumerStatefulWidget {
  const SchedulrApp({
    this.initialLocation = '/',
    this.routerFactory,
    super.key,
  });

  final String initialLocation;
  final GoRouter Function(String initialLocation)? routerFactory;

  @override
  ConsumerState<SchedulrApp> createState() => _SchedulrAppState();
}

class _SchedulrAppState extends ConsumerState<SchedulrApp> {
  late final GoRouter _router;
  late final AppLifecycleListener _lifecycleListener;

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
      },
    );
  }

  @override
  void dispose() {
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

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/import_timetable/presentation/pages/import_route_page.dart';
import '../features/semester/presentation/pages/semester_settings_route_page.dart';
import '../features/settings/presentation/pages/settings_route_page.dart';
import '../features/timetable/presentation/pages/course_detail_route_page.dart';
import '../features/timetable/presentation/pages/course_editor_route_page.dart';
import '../features/timetable/presentation/pages/timetable_home_page.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) =>
          _adaptivePage(state: state, child: const TimetableHomePage()),
    ),
    GoRoute(
      path: '/course/new',
      pageBuilder: (context, state) =>
          _adaptivePage(state: state, child: const CourseEditorRoutePage()),
    ),
    GoRoute(
      path: '/course/:courseId',
      pageBuilder: (context, state) => _adaptivePage(
        state: state,
        child: CourseDetailRoutePage(
          courseId: state.pathParameters['courseId']!,
        ),
      ),
      routes: [
        GoRoute(
          path: 'edit',
          pageBuilder: (context, state) => _adaptivePage(
            state: state,
            child: CourseEditorRoutePage(
              courseId: state.pathParameters['courseId']!,
            ),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/import',
      pageBuilder: (context, state) =>
          _adaptivePage(state: state, child: const ImportRoutePage()),
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) =>
          _adaptivePage(state: state, child: const SettingsRoutePage()),
      routes: [
        GoRoute(
          path: 'semester',
          pageBuilder: (context, state) => _adaptivePage(
            state: state,
            child: const SemesterSettingsRoutePage(),
          ),
        ),
      ],
    ),
  ],
);

Page<void> _adaptivePage({
  required GoRouterState state,
  required Widget child,
}) {
  if (Platform.isIOS) {
    return CupertinoPage<void>(key: state.pageKey, child: child);
  }
  return MaterialPage<void>(key: state.pageKey, child: child);
}

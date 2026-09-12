import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:schedulr/features/timetable/data/providers.dart';
import 'package:schedulr/features/timetable/domain/timetable_models.dart';
import 'package:schedulr/features/timetable/presentation/pages/timetable_home_page.dart';
import 'package:schedulr/features/timetable/presentation/weekly_timetable_view.dart';

void main() {
  group('TimetableHomePage', () {
    testWidgets('默认跟随 provider 中的今天并显示对应教学周', (tester) async {
      final harness = await _pumpHome(
        tester,
        today: DateTime(2026, 9, 16),
        initialTimetable: _timetable(),
      );
      addTearDown(harness.dispose);

      expect(find.text('第 2 周 · 今天'), findsOneWidget);
      expect(find.textContaining('9/14 - 9/20'), findsOneWidget);
    });

    testWidgets('首页固定显示周一至周日且没有周末切换按钮', (tester) async {
      final course = Course(
        id: 'weekend-course',
        semesterId: 'semester',
        name: '周六课程',
      );
      final harness = await _pumpHome(
        tester,
        today: DateTime(2026, 9, 16),
        initialTimetable: _timetable(
          courses: [
            CourseWithSessions(
              course: course,
              sessions: [
                CourseSession(
                  id: 'weekend-session',
                  courseId: course.id,
                  weekday: DateTime.saturday,
                  startPeriod: 1,
                  endPeriod: 2,
                  weeks: const {2},
                ),
              ],
            ),
          ],
        ),
      );
      addTearDown(harness.dispose);

      expect(find.byTooltip('显示周末'), findsNothing);
      expect(find.byTooltip('隐藏周末'), findsNothing);
      expect(find.text('周六课程'), findsOneWidget);
      for (
        var weekday = DateTime.monday;
        weekday <= DateTime.sunday;
        weekday++
      ) {
        expect(
          find.byKey(WeeklyTimetableView.weekdayHeaderKey(weekday)),
          findsOneWidget,
        );
      }
    });

    testWidgets('左右切周创建显式选择，点击中间恢复跟随今天', (tester) async {
      final harness = await _pumpHome(
        tester,
        today: DateTime(2026, 9, 16),
        initialTimetable: _timetable(),
      );
      addTearDown(harness.dispose);

      await tester.tap(find.byTooltip('下一周'));
      await tester.pump();

      expect(find.text('第 3 周'), findsOneWidget);
      expect(find.textContaining('回到本周'), findsOneWidget);
      expect(find.textContaining('今天'), findsNothing);

      await tester.tap(find.byTooltip('上一周'));
      await tester.pump();

      expect(find.text('第 2 周'), findsOneWidget);
      expect(find.textContaining('回到本周'), findsOneWidget);
      expect(find.textContaining('今天'), findsNothing);

      await tester.tap(find.text('第 2 周'));
      await tester.pump();

      expect(find.text('第 2 周 · 今天'), findsOneWidget);
    });

    testWidgets('仅课程变化保留显式周数', (tester) async {
      final initial = _timetable();
      final harness = await _pumpHome(
        tester,
        today: DateTime(2026, 9, 16),
        initialTimetable: initial,
      );
      addTearDown(harness.dispose);

      await tester.tap(find.byTooltip('下一周'));
      await tester.pump();
      expect(find.text('第 3 周'), findsOneWidget);

      harness.add(
        initial.copyWith(
          courses: [
            CourseWithSessions(
              course: Course(
                id: 'course',
                semesterId: initial.semester.id,
                name: '新增课程',
                colorValue: 0xFF00695C,
              ),
              sessions: const [],
            ),
          ],
        ),
      );
      await tester.pump();

      expect(find.text('第 3 周'), findsOneWidget);
      expect(find.textContaining('回到本周'), findsOneWidget);
    });

    for (final calendarChange in <String, Semester Function(Semester)>{
      'semester id': (semester) => semester.copyWith(id: 'new-semester'),
      'startDate': (semester) =>
          semester.copyWith(startDate: DateTime(2026, 9, 14)),
      'teachingWeeks': (semester) => semester.copyWith(teachingWeeks: 3),
    }.entries) {
      testWidgets('${calendarChange.key} 变化后重置为跟随今天', (tester) async {
        final initial = _timetable(
          semester: _semester(
            startDate: DateTime(2026, 8, 31),
            teachingWeeks: 20,
          ),
        );
        final harness = await _pumpHome(
          tester,
          today: DateTime(2026, 9, 16),
          initialTimetable: initial,
        );
        addTearDown(harness.dispose);

        await tester.tap(find.byTooltip('下一周'));
        await tester.pump();
        expect(find.text('第 4 周'), findsOneWidget);

        final changedSemester = calendarChange.value(initial.semester);
        harness.add(initial.copyWith(semester: changedSemester));
        await tester.pump();
        await tester.pump();

        final expectedWeek = changedSemester.startDate == DateTime(2026, 9, 14)
            ? 1
            : 3;
        expect(find.text('第 $expectedWeek 周 · 今天'), findsOneWidget);
      });
    }

    testWidgets('教学周数缩短时不会以越界显式周数构建', (tester) async {
      final initial = _timetable(
        semester: _semester(
          startDate: DateTime(2026, 8, 31),
          teachingWeeks: 20,
        ),
      );
      final harness = await _pumpHome(
        tester,
        today: DateTime(2026, 9, 16),
        initialTimetable: initial,
      );
      addTearDown(harness.dispose);

      await tester.tap(find.byTooltip('下一周'));
      await tester.pump();
      expect(find.text('第 4 周'), findsOneWidget);

      harness.add(
        initial.copyWith(semester: initial.semester.copyWith(teachingWeeks: 3)),
      );
      await tester.pump();
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('第 3 周 · 今天'), findsOneWidget);
    });

    testWidgets('今天不在学期时先提示，用户选择后才查看第1周', (tester) async {
      final harness = await _pumpHome(
        tester,
        today: DateTime(2026, 8, 1),
        initialTimetable: _timetable(),
      );
      addTearDown(harness.dispose);

      expect(find.text('当前日期不在本学期'), findsOneWidget);
      expect(find.text('查看第1周'), findsOneWidget);
      expect(find.text('设置学期校历'), findsOneWidget);
      expect(find.textContaining('第 1 周'), findsNothing);

      await tester.tap(find.text('查看第1周'));
      await tester.pump();

      expect(find.text('第 1 周'), findsOneWidget);
      expect(find.textContaining('回到本周'), findsOneWidget);
      expect(find.text('当前日期不在本学期'), findsNothing);
    });

    testWidgets('越界提示可进入学期设置', (tester) async {
      final controller = StreamController<SemesterTimetable?>();
      addTearDown(controller.close);
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const TimetableHomePage(),
          ),
          GoRoute(
            path: '/settings/semester',
            builder: (context, state) => const Scaffold(body: Text('学期设置页面')),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentDateProvider.overrideWithValue(DateTime(2026, 8, 1)),
            currentTimetableProvider.overrideWith((ref) => controller.stream),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      controller.add(_timetable());
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('设置学期校历'));
      await tester.pumpAndSettle();

      expect(find.text('学期设置页面'), findsOneWidget);
      expect(router.state.uri.path, '/settings/semester');
    });
  });
}

Future<_HomeHarness> _pumpHome(
  WidgetTester tester, {
  required DateTime today,
  required SemesterTimetable initialTimetable,
}) async {
  final controller = StreamController<SemesterTimetable?>();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentDateProvider.overrideWithValue(today),
        currentTimetableProvider.overrideWith((ref) => controller.stream),
      ],
      child: const MaterialApp(home: TimetableHomePage()),
    ),
  );
  controller.add(initialTimetable);
  await tester.pump();
  await tester.pump();
  return _HomeHarness(controller);
}

class _HomeHarness {
  const _HomeHarness(this._controller);

  final StreamController<SemesterTimetable?> _controller;

  void add(SemesterTimetable timetable) => _controller.add(timetable);

  Future<void> dispose() => _controller.close();
}

SemesterTimetable _timetable({
  Semester? semester,
  List<CourseWithSessions> courses = const [],
}) {
  return SemesterTimetable(
    semester: semester ?? _semester(),
    courses: courses,
    periodDefinitions: const [],
  );
}

Semester _semester({
  String id = 'semester',
  DateTime? startDate,
  int teachingWeeks = 20,
}) {
  return Semester(
    id: id,
    academicYear: '2026-2027',
    term: '1',
    name: '测试学期',
    startDate: startDate ?? DateTime(2026, 9, 7),
    teachingWeeks: teachingWeeks,
    isCurrent: true,
  );
}

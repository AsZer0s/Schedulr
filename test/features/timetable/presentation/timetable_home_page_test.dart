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
    testWidgets('标题显示当前课表名称并提供切换语义', (tester) async {
      final semantics = tester.ensureSemantics();
      final harness = await _pumpHome(
        tester,
        today: DateTime(2026, 9, 16),
        initialTimetable: _timetable(semester: _semester(name: '我的课程表')),
      );
      addTearDown(harness.dispose);

      expect(find.text('课程表'), findsOneWidget);
      expect(find.text('我的课程表'), findsWidgets);
      expect(find.bySemanticsLabel('切换课程表，当前为我的课程表'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('打开列表显示全部课表、副标题和当前标记', (tester) async {
      final current = _semester(name: '主课表');
      final other = _semester(
        id: 'other',
        name: '选修课表',
        semesterName: '2026 秋季学期',
        isCurrent: false,
      );
      final harness = await _pumpHome(
        tester,
        today: DateTime(2026, 9, 16),
        initialTimetable: _timetable(semester: current),
        semesters: [current, other],
      );
      addTearDown(harness.dispose);

      await tester.tap(find.byKey(const ValueKey('timetable-title-button')));
      await tester.pumpAndSettle();

      expect(find.text('选择课程表'), findsOneWidget);
      expect(find.text('主课表'), findsWidgets);
      expect(find.text('选修课表'), findsOneWidget);
      expect(find.text('2026 秋季学期'), findsOneWidget);
      expect(find.byKey(const ValueKey('current-semester')), findsOneWidget);
    });

    testWidgets('切换课表更新课程、标题并恢复跟随今天', (tester) async {
      final current = _semester(name: '主课表');
      final other = _semester(id: 'other', name: '第二课表', isCurrent: false);
      late _HomeHarness harness;
      harness = await _pumpHome(
        tester,
        today: DateTime(2026, 9, 16),
        initialTimetable: _timetable(
          semester: current,
          courses: [_courseWithSession('旧课程', current.id, teachingWeek: 2)],
        ),
        semesters: [current, other],
        onSelect: (id) async {
          expect(id, other.id);
          harness.add(
            _timetable(
              semester: other.copyWith(isCurrent: true),
              courses: [_courseWithSession('新课程', other.id, teachingWeek: 2)],
            ),
          );
        },
      );
      addTearDown(harness.dispose);

      await tester.tap(find.byTooltip('下一周'));
      await tester.pump();
      expect(find.text('第 3 周'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('timetable-title-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('timetable-other')));
      await tester.pumpAndSettle();

      expect(find.text('第二课表'), findsWidgets);
      expect(find.text('新课程'), findsOneWidget);
      expect(find.text('旧课程'), findsNothing);
      expect(find.text('第 2 周 · 今天'), findsOneWidget);
    });

    testWidgets('添加空白课表先校验别名并复制当前模板后切换', (tester) async {
      final current = _semester(name: '主课表');
      SemesterTimetable? copiedTemplate;
      String? createdName;
      String? selectedId;
      final harness = await _pumpHome(
        tester,
        today: DateTime(2026, 9, 16),
        initialTimetable: _timetable(semester: current),
        semesters: [current],
        onCreate: (name, template) async {
          createdName = name;
          copiedTemplate = template;
          return 'new-id';
        },
        onSelect: (id) async => selectedId = id,
      );
      addTearDown(harness.dispose);

      await tester.tap(find.byKey(const ValueKey('timetable-title-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('添加课表'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('新建空白'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('继续'));
      await tester.pump();
      expect(find.text('请输入课表名称'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('timetable-name-field')),
        '  新课表  ',
      );
      await tester.tap(find.text('继续'));
      await tester.pumpAndSettle();

      expect(createdName, '新课表');
      expect(copiedTemplate?.semester.id, current.id);
      expect(selectedId, 'new-id');
      expect(find.text('选择课程表'), findsNothing);
    });

    testWidgets('同学导入创建后清 cookie 并携带 target/source 导航', (tester) async {
      var cookiesCleared = false;
      final current = _semester(name: '主课表');
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => TimetableHomePage(
              createBlankTimetable: (name, template) async => 'import-target',
              selectTimetable: (id) async {},
              clearImportCookies: () async => cookiesCleared = true,
            ),
          ),
          GoRoute(
            path: '/import',
            builder: (context, state) =>
                Scaffold(body: Text('导入地址 ${state.uri.query}')),
          ),
        ],
      );
      addTearDown(router.dispose);
      final timetableController = StreamController<SemesterTimetable?>();
      final semestersController = StreamController<List<Semester>>();
      addTearDown(timetableController.close);
      addTearDown(semestersController.close);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentDateProvider.overrideWithValue(DateTime(2026, 9, 16)),
            currentTimetableProvider.overrideWith(
              (ref) => timetableController.stream,
            ),
            timetablesProvider.overrideWith(
              (ref) => semestersController.stream,
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      timetableController.add(_timetable(semester: current));
      semestersController.add([current]);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('timetable-title-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('添加课表'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('同学登录导入'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('timetable-name-field')),
        '教务导入',
      );
      await tester.tap(find.text('继续'));
      await tester.pumpAndSettle();

      expect(cookiesCleared, isTrue);
      expect(router.state.uri.path, '/import');
      expect(router.state.uri.queryParameters['target'], 'import-target');
      expect(router.state.uri.queryParameters['source'], 'bitc');
    });

    testWidgets('普通导入菜单携带当前课表 target', (tester) async {
      final current = _semester(name: '主课表');
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const TimetableHomePage(),
          ),
          GoRoute(
            path: '/import',
            builder: (context, state) => const Scaffold(body: Text('导入页面')),
          ),
        ],
      );
      addTearDown(router.dispose);
      final timetableController = StreamController<SemesterTimetable?>();
      final semestersController = StreamController<List<Semester>>();
      addTearDown(timetableController.close);
      addTearDown(semestersController.close);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentDateProvider.overrideWithValue(DateTime(2026, 9, 16)),
            currentTimetableProvider.overrideWith(
              (ref) => timetableController.stream,
            ),
            timetablesProvider.overrideWith(
              (ref) => semestersController.stream,
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      timetableController.add(_timetable(semester: current));
      semestersController.add([current]);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('导入课表'));
      await tester.pumpAndSettle();

      expect(router.state.uri.queryParameters['target'], current.id);
    });

    testWidgets('重命名课表提交非空本地别名', (tester) async {
      final current = _semester(name: '主课表');
      String? renamedId;
      String? renamedName;
      final harness = await _pumpHome(
        tester,
        today: DateTime(2026, 9, 16),
        initialTimetable: _timetable(semester: current),
        semesters: [current],
        onRename: (id, name) async {
          renamedId = id;
          renamedName = name;
        },
      );
      addTearDown(harness.dispose);

      await tester.tap(find.byKey(const ValueKey('timetable-title-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('主课表的更多操作'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('重命名'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('timetable-name-field')),
        '新名字',
      );
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(renamedId, current.id);
      expect(renamedName, '新名字');
    });

    testWidgets('删除需要确认且说明仅删除本地数据', (tester) async {
      final current = _semester(name: '主课表');
      String? deletedId;
      final harness = await _pumpHome(
        tester,
        today: DateTime(2026, 9, 16),
        initialTimetable: _timetable(semester: current),
        semesters: [current],
        onDelete: (id) async => deletedId = id,
      );
      addTearDown(harness.dispose);

      await tester.tap(find.byKey(const ValueKey('timetable-title-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('主课表的更多操作'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('删除'));
      await tester.pumpAndSettle();

      expect(find.text('删除“主课表”？'), findsOneWidget);
      expect(find.textContaining('只会删除保存在此设备上的课表数据'), findsOneWidget);
      expect(deletedId, isNull);

      await tester.tap(find.widgetWithText(TextButton, '删除'));
      await tester.pumpAndSettle();
      expect(deletedId, current.id);
    });

    testWidgets('长课表名使用 ellipsis 且不产生 overflow', (tester) async {
      final harness = await _pumpHome(
        tester,
        today: DateTime(2026, 9, 16),
        initialTimetable: _timetable(
          semester: _semester(name: '这是一个非常非常非常非常非常非常非常长的课程表名称'),
        ),
      );
      addTearDown(harness.dispose);

      final title = tester.widget<Text>(
        find.byKey(const ValueKey('current-timetable-name')),
      );
      expect(title.maxLines, 1);
      expect(title.overflow, TextOverflow.ellipsis);
      expect(tester.takeException(), isNull);
    });

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
  List<Semester>? semesters,
  CreateBlankTimetableCallback? onCreate,
  RenameTimetableCallback? onRename,
  SelectTimetableCallback? onSelect,
  DeleteTimetableCallback? onDelete,
  ClearTimetableImportCookiesCallback? onClearCookies,
}) async {
  final controller = StreamController<SemesterTimetable?>();
  final semestersController = StreamController<List<Semester>>();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentDateProvider.overrideWithValue(today),
        currentTimetableProvider.overrideWith((ref) => controller.stream),
        timetablesProvider.overrideWith((ref) => semestersController.stream),
      ],
      child: MaterialApp(
        home: TimetableHomePage(
          createBlankTimetable: onCreate,
          renameTimetable: onRename,
          selectTimetable: onSelect,
          deleteTimetable: onDelete,
          clearImportCookies: onClearCookies,
        ),
      ),
    ),
  );
  controller.add(initialTimetable);
  semestersController.add(semesters ?? [initialTimetable.semester]);
  await tester.pump();
  await tester.pump();
  return _HomeHarness(controller, semestersController);
}

class _HomeHarness {
  const _HomeHarness(this._controller, this._semestersController);

  final StreamController<SemesterTimetable?> _controller;
  final StreamController<List<Semester>> _semestersController;

  void add(SemesterTimetable timetable) => _controller.add(timetable);

  Future<void> dispose() async {
    await _controller.close();
    await _semestersController.close();
  }
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
  String name = '测试课表',
  String semesterName = '测试学期',
  DateTime? startDate,
  int teachingWeeks = 20,
  bool isCurrent = true,
}) {
  return Semester(
    id: id,
    academicYear: '2026-2027',
    term: '1',
    name: semesterName,
    timetableName: name,
    startDate: startDate ?? DateTime(2026, 9, 7),
    teachingWeeks: teachingWeeks,
    isCurrent: isCurrent,
  );
}

CourseWithSessions _courseWithSession(
  String name,
  String semesterId, {
  required int teachingWeek,
}) {
  final course = Course(id: 'course-$name', semesterId: semesterId, name: name);
  return CourseWithSessions(
    course: course,
    sessions: [
      CourseSession(
        id: 'session-$name',
        courseId: course.id,
        weekday: DateTime.wednesday,
        startPeriod: 1,
        endPeriod: 2,
        weeks: {teachingWeek},
      ),
    ],
  );
}

import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schedulr/features/timetable/domain/timetable_models.dart';
import 'package:schedulr/features/timetable/presentation/weekly_timetable_view.dart';

void main() {
  group('WeeklyTimetableView', () {
    testWidgets('只显示选定教学周的课程', (tester) async {
      final timetable = _timetable([
        _course(
          id: 'week-1',
          name: '第一周课程',
          sessions: [
            _session(id: 'week-1-session', courseId: 'week-1', weeks: {1}),
          ],
        ),
        _course(
          id: 'week-2',
          name: '第二周课程',
          sessions: [
            _session(id: 'week-2-session', courseId: 'week-2', weeks: {2}),
          ],
        ),
      ]);

      await _pumpView(tester, timetable: timetable, teachingWeek: 2);

      expect(find.text('第二周课程'), findsOneWidget);
      expect(find.text('第一周课程'), findsNothing);
    });

    testWidgets('正确处理不连续周次并让空周完全隐藏表格', (tester) async {
      final timetable = _timetable([
        _course(
          id: 'odd-weeks',
          name: '不连续周课程',
          sessions: [
            _session(
              id: 'odd-weeks-session',
              courseId: 'odd-weeks',
              weeks: {1, 3, 5},
            ),
          ],
        ),
      ]);

      await _pumpView(tester, timetable: timetable, teachingWeek: 2);
      expect(find.text('不连续周课程'), findsNothing);
      expect(find.byType(TimetableEmptyState), findsOneWidget);
      _expectNoTableStructure();

      await _pumpView(tester, timetable: timetable, teachingWeek: 3);
      expect(find.text('不连续周课程'), findsOneWidget);
      expect(
        find.byKey(WeeklyTimetableView.weekdayHeaderKey(DateTime.monday)),
        findsOneWidget,
      );
    });

    testWidgets('空周提前返回空态且不构建表头、轴、网格和滚动', (tester) async {
      await _pumpView(tester, timetable: _timetable(const []), teachingWeek: 1);

      expect(find.byType(TimetableEmptyState), findsOneWidget);
      expect(find.text('本周暂无课程'), findsOneWidget);
      _expectNoTableStructure();
      expect(find.byKey(WeeklyTimetableView.periodCellKey(1)), findsNothing);
      expect(find.byKey(WeeklyTimetableView.todayColumnKey), findsNothing);
    });

    testWidgets('隐藏周末时仅周末有课显示工作日专用提示', (tester) async {
      final timetable = _timetable([
        _course(
          id: 'weekend',
          name: '周末课程',
          sessions: [
            _session(
              id: 'weekend-session',
              courseId: 'weekend',
              weeks: {1},
              weekday: DateTime.saturday,
            ),
          ],
        ),
      ]);

      await _pumpView(
        tester,
        timetable: timetable,
        teachingWeek: 1,
        showWeekend: false,
      );
      expect(find.byType(TimetableEmptyState), findsOneWidget);
      expect(find.text('工作日暂无课程'), findsOneWidget);
      expect(find.textContaining('开启“显示周末”后可查看'), findsOneWidget);
      expect(find.text('本周暂无课程'), findsNothing);
      _expectNoTableStructure();

      await _pumpView(
        tester,
        timetable: timetable,
        teachingWeek: 1,
        showWeekend: true,
      );
      expect(find.text('周末课程'), findsOneWidget);
      expect(
        find.byKey(WeeklyTimetableView.weekdayHeaderKey(DateTime.saturday)),
        findsOneWidget,
      );
    });

    testWidgets('visible session 节次无法映射时显示作息配置错误', (tester) async {
      final timetable = _timetable([
        _course(
          id: 'missing-period',
          name: '无法映射课程',
          sessions: [
            _session(
              id: 'missing-period-session',
              courseId: 'missing-period',
              weeks: {1},
              startPeriod: 8,
              endPeriod: 9,
            ),
          ],
        ),
      ], periodDefinitions: _periods(8));

      await _pumpView(tester, timetable: timetable, teachingWeek: 1);

      expect(find.byType(TimetableConfigurationErrorState), findsOneWidget);
      expect(find.text('作息配置不完整'), findsOneWidget);
      expect(find.byType(TimetableEmptyState), findsNothing);
      expect(find.text('无法映射课程'), findsNothing);
      _expectNoTableStructure();
    });

    for (final periodCount in <int>[8, 10, 12]) {
      testWidgets('真实 $periodCount 节作息只显示定义行数与时间', (tester) async {
        final periods = _periods(periodCount);
        final timetable = _timetable([
          _course(
            id: 'real-$periodCount',
            name: '$periodCount 节课程',
            sessions: [
              _session(
                id: 'real-$periodCount-session',
                courseId: 'real-$periodCount',
                weeks: {1},
              ),
            ],
          ),
        ], periodDefinitions: periods);

        await _pumpView(tester, timetable: timetable, teachingWeek: 1);

        for (var period = 1; period <= periodCount; period++) {
          expect(
            find.byKey(WeeklyTimetableView.periodCellKey(period)),
            findsOneWidget,
          );
        }
        expect(
          find.byKey(WeeklyTimetableView.periodCellKey(periodCount + 1)),
          findsNothing,
        );
        final last = periods.last;
        expect(
          find.byKey(WeeklyTimetableView.periodNumberKey(last.period)),
          findsOneWidget,
        );
        expect(
          find.byKey(WeeklyTimetableView.startTimeKey(last.period)),
          findsOneWidget,
        );
        expect(
          find.byKey(WeeklyTimetableView.endTimeKey(last.period)),
          findsOneWidget,
        );
        expect(find.text('第${last.period}节'), findsOneWidget);
        expect(find.text(last.startTime), findsOneWidget);
        expect(find.text(last.endTime), findsOneWidget);
      });
    }

    testWidgets('节次轴固定三个独立 Text 且按顺序完全位于 cell 内', (tester) async {
      final periods = _periods(8);
      final timetable = _timetable([
        _course(
          id: 'axis-lines',
          name: '轴测试课程',
          sessions: [
            _session(
              id: 'axis-lines-session',
              courseId: 'axis-lines',
              weeks: {1},
            ),
          ],
        ),
      ], periodDefinitions: periods);

      await _pumpView(tester, timetable: timetable, teachingWeek: 1);

      for (final period in periods) {
        final cell = tester.getRect(
          find.byKey(WeeklyTimetableView.periodCellKey(period.period)),
        );
        final number = tester.getRect(
          find.byKey(WeeklyTimetableView.periodNumberKey(period.period)),
        );
        final start = tester.getRect(
          find.byKey(WeeklyTimetableView.startTimeKey(period.period)),
        );
        final end = tester.getRect(
          find.byKey(WeeklyTimetableView.endTimeKey(period.period)),
        );
        expect(number.top, greaterThanOrEqualTo(cell.top));
        expect(number.bottom, lessThanOrEqualTo(start.top));
        expect(start.bottom, lessThanOrEqualTo(end.top));
        expect(end.bottom, lessThanOrEqualTo(cell.bottom));
        expect(number.left, greaterThanOrEqualTo(cell.left));
        expect(end.right, lessThanOrEqualTo(cell.right));

        final semantics = tester.getSemantics(
          find.byKey(WeeklyTimetableView.periodCellKey(period.period)),
        );
        expect(
          semantics.label,
          '第${period.period}节，上课时间${period.startTime}，'
          '下课时间${period.endTime}',
        );
      }
    });

    testWidgets('空 PeriodDefinition 保留 12 节 fallback', (tester) async {
      final timetable = _timetable([
        _course(
          id: 'fallback',
          name: '旧数据课程',
          sessions: [
            _session(
              id: 'fallback-session',
              courseId: 'fallback',
              weeks: {1},
              startPeriod: 12,
              endPeriod: 12,
            ),
          ],
        ),
      ]);

      await _pumpView(tester, timetable: timetable, teachingWeek: 1);

      expect(find.byKey(WeeklyTimetableView.periodCellKey(1)), findsOneWidget);
      expect(find.byKey(WeeklyTimetableView.periodCellKey(12)), findsOneWidget);
      expect(find.byKey(WeeklyTimetableView.periodCellKey(13)), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(WeeklyTimetableView.periodCellKey(12)),
          matching: find.text('--:--'),
        ),
        findsNWidgets(2),
      );
      final semantics = tester.getSemantics(
        find.byKey(WeeklyTimetableView.periodCellKey(12)),
      );
      expect(semantics.label, contains('第12节'));
      expect(semantics.label, contains('上课时间未提供'));
      expect(semantics.label, contains('下课时间未提供'));
    });

    testWidgets('三段标题按定义派生节数且各占独立 18px band', (tester) async {
      final timetable = _timetable([
        _course(
          id: 'groups',
          name: '分组课程',
          sessions: [
            _session(id: 'groups-session', courseId: 'groups', weeks: {1}),
          ],
        ),
      ], periodDefinitions: _periods(12));

      await _pumpView(tester, timetable: timetable, teachingWeek: 1);

      expect(find.text('上午 · 4节'), findsOneWidget);
      expect(find.text('下午 · 4节'), findsOneWidget);
      expect(find.text('晚上 · 4节'), findsOneWidget);
      for (final group in PeriodGroup.values) {
        expect(
          find.byKey(WeeklyTimetableView.groupLabelKey(group)),
          findsOneWidget,
        );
        expect(
          find.byKey(WeeklyTimetableView.groupSeparatorKey(group)),
          findsOneWidget,
        );
        expect(
          find.byKey(WeeklyTimetableView.groupGridHeaderKey(group)),
          findsOneWidget,
        );
        final axisHeaderRect = tester.getRect(
          find.byKey(WeeklyTimetableView.groupSeparatorKey(group)),
        );
        final gridHeaderRect = tester.getRect(
          find.byKey(WeeklyTimetableView.groupGridHeaderKey(group)),
        );
        expect(gridHeaderRect.top, closeTo(axisHeaderRect.top, 0.01));
        expect(gridHeaderRect.bottom, closeTo(axisHeaderRect.bottom, 0.01));
        final semantics = tester.getSemantics(
          find.byKey(WeeklyTimetableView.groupLabelKey(group)),
        );
        expect(semantics.label, '${_groupLabel(group)}，共4节');
        expect(semantics.flagsCollection.isHeader, isTrue);
      }

      final morningHeader = tester.getRect(
        find.byKey(WeeklyTimetableView.groupSeparatorKey(PeriodGroup.morning)),
      );
      final afternoonHeader = tester.getRect(
        find.byKey(
          WeeklyTimetableView.groupSeparatorKey(PeriodGroup.afternoon),
        ),
      );
      final eveningHeader = tester.getRect(
        find.byKey(WeeklyTimetableView.groupSeparatorKey(PeriodGroup.evening)),
      );
      final period1 = tester.getRect(
        find.byKey(WeeklyTimetableView.periodCellKey(1)),
      );
      final period4 = tester.getRect(
        find.byKey(WeeklyTimetableView.periodCellKey(4)),
      );
      final period5 = tester.getRect(
        find.byKey(WeeklyTimetableView.periodCellKey(5)),
      );
      final period8 = tester.getRect(
        find.byKey(WeeklyTimetableView.periodCellKey(8)),
      );
      final period9 = tester.getRect(
        find.byKey(WeeklyTimetableView.periodCellKey(9)),
      );
      expect(morningHeader.height, closeTo(18, 0.01));
      expect(afternoonHeader.height, closeTo(18, 0.01));
      expect(eveningHeader.height, closeTo(18, 0.01));
      expect(period1.top, closeTo(morningHeader.bottom, 0.01));
      expect(period5.top, closeTo(afternoonHeader.bottom, 0.01));
      expect(period9.top, closeTo(eveningHeader.bottom, 0.01));
      expect(afternoonHeader.top, closeTo(period4.bottom, 0.01));
      expect(eveningHeader.top, closeTo(period8.bottom, 0.01));
    });

    for (final periodCount in <int>[8, 10]) {
      testWidgets('常规高度 $periodCount 节完整适配且禁用纵向滚动', (tester) async {
        final timetable = _timetable([
          _course(
            id: 'fit-$periodCount',
            name: '完整适配课程',
            sessions: [
              _session(
                id: 'fit-$periodCount-session',
                courseId: 'fit-$periodCount',
                weeks: {1},
                startPeriod: periodCount,
                endPeriod: periodCount,
              ),
            ],
          ),
        ], periodDefinitions: _periods(periodCount));

        await _pumpView(tester, timetable: timetable, teachingWeek: 1);

        final position = _verticalPosition(tester);
        expect(position.maxScrollExtent, closeTo(0, 0.01));
        final scrollView = tester.widget<SingleChildScrollView>(
          find.byKey(WeeklyTimetableView.gridVerticalScrollKey),
        );
        expect(scrollView.physics, isA<NeverScrollableScrollPhysics>());
        final lastPeriod = tester.getRect(
          find.byKey(WeeklyTimetableView.periodCellKey(periodCount)),
        );
        final gridBody = tester.getRect(
          find.byKey(WeeklyTimetableView.gridBodyKey),
        );
        expect(lastPeriod.bottom, closeTo(gridBody.bottom, 0.01));
      });
    }

    testWidgets('矮屏 12 节启用纵向滚动并显示最后一节', (tester) async {
      final timetable = _timetable([
        _course(
          id: 'short-12',
          name: '矮屏课程',
          sessions: [
            _session(
              id: 'short-12-session',
              courseId: 'short-12',
              weeks: {1},
              startPeriod: 12,
              endPeriod: 12,
            ),
          ],
        ),
      ], periodDefinitions: _periods(12));

      await _pumpView(
        tester,
        timetable: timetable,
        teachingWeek: 1,
        surfaceHeight: 400,
        viewHeight: 340,
      );

      final position = _verticalPosition(tester);
      expect(position.maxScrollExtent, greaterThan(0));
      final scrollView = tester.widget<SingleChildScrollView>(
        find.byKey(WeeklyTimetableView.gridVerticalScrollKey),
      );
      expect(scrollView.physics, isA<ClampingScrollPhysics>());

      await tester.drag(
        find.byKey(WeeklyTimetableView.gridVerticalScrollKey),
        const Offset(0, -1000),
      );
      await tester.pumpAndSettle();
      expect(position.pixels, closeTo(position.maxScrollExtent, 0.01));
      expect(find.text('矮屏课程'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    for (final textScale in <double>[1, 2, 3]) {
      testWidgets('${textScale}x 字体三行轴不裁剪且需要时滚动', (tester) async {
        final timetable = _timetable([
          _course(
            id: 'scale-$textScale',
            name: '缩放课程',
            sessions: [
              _session(
                id: 'scale-$textScale-session',
                courseId: 'scale-$textScale',
                weeks: {1},
              ),
            ],
          ),
        ], periodDefinitions: _periods(10));

        await _pumpView(
          tester,
          timetable: timetable,
          teachingWeek: 1,
          width: 320,
          textScaler: TextScaler.linear(textScale),
        );

        final cell = tester.getRect(
          find.byKey(WeeklyTimetableView.periodCellKey(1)),
        );
        final number = tester.getRect(
          find.byKey(WeeklyTimetableView.periodNumberKey(1)),
        );
        final start = tester.getRect(
          find.byKey(WeeklyTimetableView.startTimeKey(1)),
        );
        final end = tester.getRect(
          find.byKey(WeeklyTimetableView.endTimeKey(1)),
        );
        expect(number.top, greaterThanOrEqualTo(cell.top));
        expect(number.bottom, lessThanOrEqualTo(start.top));
        expect(start.bottom, lessThanOrEqualTo(end.top));
        expect(end.bottom, lessThanOrEqualTo(cell.bottom));
        expect(
          cell.height,
          greaterThanOrEqualTo(
            textScale == 1
                ? 50
                : textScale == 2
                ? 76
                : 102,
          ),
        );
        if (textScale > 1) {
          expect(_verticalPosition(tester).maxScrollExtent, greaterThan(0));
        }
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('大字体提高最小行高且无 overflow', (tester) async {
      final timetable = _timetable([
        _course(
          id: 'large-text',
          name: '名称很长但必须优先显示的课程',
          sessions: [
            _session(
              id: 'large-text-session',
              courseId: 'large-text',
              weeks: {1},
              weekday: DateTime.friday,
            ),
          ],
        ),
      ], periodDefinitions: _periods(10));

      await _pumpView(
        tester,
        timetable: timetable,
        teachingWeek: 1,
        width: 320,
        textScaler: const TextScaler.linear(2),
      );

      final firstPeriod = tester.getSize(
        find.byKey(WeeklyTimetableView.periodCellKey(1)),
      );
      expect(firstPeriod.height, greaterThanOrEqualTo(64));
      expect(_verticalPosition(tester).maxScrollExtent, greaterThan(0));
      expect(find.text('名称很长但必须优先显示的课程'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    for (final width in <double>[320, 360, 390, 450]) {
      testWidgets('$width 宽七天完整显示且无水平滚动范围', (tester) async {
        final timetable = _timetable([
          _course(
            id: 'sunday',
            name: '周日课程',
            sessions: [
              _session(
                id: 'sunday-session',
                courseId: 'sunday',
                weeks: {1},
                weekday: DateTime.sunday,
              ),
            ],
          ),
        ]);

        await _pumpView(
          tester,
          timetable: timetable,
          teachingWeek: 1,
          width: width,
        );

        final viewRect = tester.getRect(find.byType(WeeklyTimetableView));
        final axisCell = tester.getRect(
          find.byKey(WeeklyTimetableView.periodCellKey(1)),
        );
        expect(axisCell.width, greaterThanOrEqualTo(60));
        for (
          var weekday = DateTime.monday;
          weekday <= DateTime.sunday;
          weekday++
        ) {
          final headerRect = tester.getRect(
            find.byKey(WeeklyTimetableView.weekdayHeaderKey(weekday)),
          );
          expect(headerRect.left, greaterThanOrEqualTo(viewRect.left));
          expect(headerRect.right, lessThanOrEqualTo(viewRect.right + 0.01));
        }
        final sundayCard = tester.getRect(
          find.byKey(const ValueKey<String>('course-session-sunday-session')),
        );
        expect(sundayCard.left, greaterThanOrEqualTo(viewRect.left));
        expect(sundayCard.right, lessThanOrEqualTo(viewRect.right + 0.01));
        expect(_horizontalPosition(tester).maxScrollExtent, closeTo(0, 0.01));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('课程卡显示课程名、教师和精简地点并保留完整语义', (tester) async {
      final course = CourseWithSessions(
        course: Course(
          id: 'details',
          semesterId: 'semester',
          name: '数据分析',
          teacher: '亢老师',
          colorValue: 0xFF00695C,
        ),
        sessions: [
          CourseSession(
            id: 'details-session',
            courseId: 'details',
            weekday: DateTime.monday,
            startPeriod: 1,
            endPeriod: 2,
            location: '虚构校区 · 东区13-301系统应用实训室1',
            weeks: const {1},
          ),
        ],
      );

      await _pumpView(
        tester,
        timetable: _timetable([course]),
        teachingWeek: 1,
        width: 390,
      );

      expect(find.text('数据分析'), findsOneWidget);
      expect(find.text('亢老师'), findsOneWidget);
      expect(find.text('13-301'), findsOneWidget);
      expect(find.textContaining('系统应用实训室'), findsNothing);
      final semantics = tester.getSemantics(
        find.byKey(const ValueKey<String>('course-session-details-session')),
      );
      expect(semantics.label, contains('亢老师'));
      expect(semantics.label, contains('虚构校区 · 东区13-301系统应用实训室1'));
    });

    testWidgets('教师或地点为空时不渲染占位行但语义说明缺失', (tester) async {
      final course = CourseWithSessions(
        course: Course(
          id: 'missing-meta',
          semesterId: 'semester',
          name: '无元数据课程',
          colorValue: 0xFF00695C,
        ),
        sessions: [
          CourseSession(
            id: 'missing-meta-session',
            courseId: 'missing-meta',
            weekday: DateTime.monday,
            startPeriod: 1,
            endPeriod: 2,
            weeks: const {1},
          ),
        ],
      );

      await _pumpView(
        tester,
        timetable: _timetable([course]),
        teachingWeek: 1,
        width: 390,
      );

      expect(
        find.byKey(
          WeeklyTimetableView.courseTeacherKey('missing-meta-session'),
        ),
        findsNothing,
      );
      expect(
        find.byKey(
          WeeklyTimetableView.courseLocationKey('missing-meta-session'),
        ),
        findsNothing,
      );
      final semantics = tester.getSemantics(
        find.byKey(
          const ValueKey<String>('course-session-missing-meta-session'),
        ),
      );
      expect(semantics.label, contains('教师未注明'));
      expect(semantics.label, contains('地点未注明'));
    });

    for (final span in <int>[1, 2, 4]) {
      testWidgets('$span 节课程均显示紧凑三项且不溢出', (tester) async {
        final course = CourseWithSessions(
          course: Course(
            id: 'span-$span',
            semesterId: 'semester',
            name: '移动开发',
            teacher: '陈老师',
            colorValue: 0xFF00695C,
          ),
          sessions: [
            CourseSession(
              id: 'span-$span-session',
              courseId: 'span-$span',
              weekday: DateTime.tuesday,
              startPeriod: 1,
              endPeriod: span,
              location: '东区14-311公共教室',
              weeks: const {1},
            ),
          ],
        );

        await _pumpView(
          tester,
          timetable: _timetable([course]),
          teachingWeek: 1,
          width: 320,
          textScaler: const TextScaler.linear(2),
        );

        expect(find.text('移动开发'), findsOneWidget);
        expect(find.text('陈老师'), findsOneWidget);
        expect(find.text('14-311'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('三门冲突在极窄子列降级但全部可点击且语义完整', (tester) async {
      final courses = [
        for (var index = 0; index < 3; index++)
          CourseWithSessions(
            course: Course(
              id: 'triple-$index',
              semesterId: 'semester',
              name: '冲突${index + 1}',
              teacher: '教师${index + 1}',
              colorValue: 0xFF00695C,
            ),
            sessions: [
              CourseSession(
                id: 'triple-$index-session',
                courseId: 'triple-$index',
                weekday: DateTime.wednesday,
                startPeriod: 1,
                endPeriod: 2,
                location: '东区13-30${index + 1}公共教室',
                weeks: const {1},
              ),
            ],
          ),
      ];
      final tapped = <String>[];

      await _pumpView(
        tester,
        timetable: _timetable(courses),
        teachingWeek: 1,
        width: 320,
        onCourseTap: (_, session) => tapped.add(session.id),
      );

      for (var index = 0; index < 3; index++) {
        final card = find.byKey(
          ValueKey<String>('course-session-triple-$index-session'),
        );
        expect(card, findsOneWidget);
        expect(
          find.byKey(
            WeeklyTimetableView.courseTeacherKey('triple-$index-session'),
          ),
          findsNothing,
        );
        final semantics = tester.getSemantics(card);
        expect(semantics.label, contains('教师${index + 1}'));
        expect(semantics.label, contains('东区13-30${index + 1}公共教室'));
        await tester.tapAt(tester.getCenter(card));
        await tester.pump();
      }

      expect(tapped, hasLength(3));
      expect(tester.takeException(), isNull);
    });

    testWidgets('当前教学周表头和 today 列按统一 metrics 覆盖', (tester) async {
      final timetable = _timetable([
        _course(
          id: 'today',
          name: '今天课程',
          sessions: [
            _session(
              id: 'today-session',
              courseId: 'today',
              weeks: {1},
              weekday: DateTime.wednesday,
            ),
          ],
        ),
      ], periodDefinitions: _periods(10));

      await _pumpView(
        tester,
        timetable: timetable,
        teachingWeek: 1,
        today: DateTime(2026, 9, 9),
      );

      final todayColumn = find.byKey(WeeklyTimetableView.todayColumnKey);
      expect(todayColumn, findsOneWidget);
      final semantics = tester.getSemantics(
        find.byKey(WeeklyTimetableView.weekdayHeaderKey(DateTime.wednesday)),
      );
      expect(semantics.label, contains('今天'));
      expect(semantics.label, contains('9月9日'));
      expect(semantics.flagsCollection.isSelected, Tristate.isTrue);
      final todayRect = tester.getRect(todayColumn);
      final gridRect = tester.getRect(
        find.byKey(WeeklyTimetableView.gridBodyKey),
      );
      expect(todayRect.top, closeTo(gridRect.top, 0.01));
      expect(todayRect.height, closeTo(gridRect.height, 0.01));
    });

    testWidgets('非当前周不显示今天高亮', (tester) async {
      final timetable = _timetable([
        _course(
          id: 'other-week',
          name: '第二周课程',
          sessions: [
            _session(
              id: 'other-week-session',
              courseId: 'other-week',
              weeks: {2},
            ),
          ],
        ),
      ]);

      await _pumpView(
        tester,
        timetable: timetable,
        teachingWeek: 2,
        today: DateTime(2026, 9, 9),
      );

      expect(find.byKey(WeeklyTimetableView.todayColumnKey), findsNothing);
      for (
        var weekday = DateTime.monday;
        weekday <= DateTime.sunday;
        weekday++
      ) {
        final semantics = tester.getSemantics(
          find.byKey(WeeklyTimetableView.weekdayHeaderKey(weekday)),
        );
        expect(semantics.label, isNot(contains('今天')));
      }
    });

    testWidgets('最后一节课程使用 metrics 定位并可点击', (tester) async {
      final course = _course(
        id: 'last-period',
        name: '最后一节课程',
        sessions: [
          _session(
            id: 'last-period-session',
            courseId: 'last-period',
            weeks: {1},
            startPeriod: 12,
            endPeriod: 12,
          ),
        ],
      );
      CourseSession? tappedSession;

      await _pumpView(
        tester,
        timetable: _timetable([course], periodDefinitions: _periods(12)),
        teachingWeek: 1,
        surfaceHeight: 400,
        viewHeight: 340,
        onCourseTap: (_, session) => tappedSession = session,
      );
      await tester.drag(
        find.byKey(WeeklyTimetableView.gridVerticalScrollKey),
        const Offset(0, -1000),
      );
      await tester.pumpAndSettle();

      final card = find.byKey(
        const ValueKey<String>('course-session-last-period-session'),
      );
      final periodCell = find.byKey(WeeklyTimetableView.periodCellKey(12));
      final gridBody = find.byKey(WeeklyTimetableView.gridBodyKey);
      expect(
        tester.getRect(card).top,
        greaterThan(tester.getRect(periodCell).top),
      );
      expect(
        tester.getRect(card).bottom,
        closeTo(tester.getRect(gridBody).bottom - 2, 0.01),
      );

      await tester.tapAt(tester.getCenter(card));
      await tester.pump();
      expect(tappedSession, same(course.sessions.single));
      expect(tester.takeException(), isNull);
    });

    testWidgets('12 节滚到底后切换 8 节会 post-frame clamp 同步滚动', (tester) async {
      final twelvePeriods = _periods(12);
      final eightPeriods = _periods(8);
      late StateSetter setHostState;
      var timetable = _timetable([
        _course(
          id: 'clamp',
          name: '滚动课程',
          sessions: [
            _session(id: 'clamp-session', courseId: 'clamp', weeks: {1}),
          ],
        ),
      ], periodDefinitions: twelvePeriods);

      await tester.binding.setSurfaceSize(const Size(400, 420));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                setHostState = setState;
                return WeeklyTimetableView(
                  timetable: timetable,
                  teachingWeek: 1,
                  height: 340,
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.drag(
        find.byKey(WeeklyTimetableView.gridVerticalScrollKey),
        const Offset(0, -1000),
      );
      await tester.pumpAndSettle();
      expect(_verticalPosition(tester).pixels, greaterThan(0));

      setHostState(() {
        timetable = _timetable([
          _course(
            id: 'clamp',
            name: '滚动课程',
            sessions: [
              _session(id: 'clamp-session', courseId: 'clamp', weeks: {1}),
            ],
          ),
        ], periodDefinitions: eightPeriods);
      });
      await tester.pump();
      await tester.pump();

      final gridPosition = _verticalPosition(tester);
      final axisPosition = _axisVerticalPosition(tester);
      expect(
        gridPosition.pixels,
        lessThanOrEqualTo(gridPosition.maxScrollExtent),
      );
      expect(
        axisPosition.pixels,
        lessThanOrEqualTo(axisPosition.maxScrollExtent),
      );
      expect(gridPosition.pixels, closeTo(axisPosition.pixels, 0.01));
      expect(find.byKey(WeeklyTimetableView.periodCellKey(9)), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('320 宽冲突课程不溢出且两张卡均可点击', (tester) async {
      final firstCourse = _course(
        id: 'conflict-a',
        name: '冲突课程甲',
        sessions: [
          _session(
            id: 'conflict-a-session',
            courseId: 'conflict-a',
            weeks: {1},
            startPeriod: 1,
            endPeriod: 2,
          ),
        ],
      );
      final secondCourse = _course(
        id: 'conflict-b',
        name: '冲突课程乙',
        sessions: [
          _session(
            id: 'conflict-b-session',
            courseId: 'conflict-b',
            weeks: {1},
            startPeriod: 2,
            endPeriod: 3,
          ),
        ],
      );
      final tapped = <String>[];

      await _pumpView(
        tester,
        timetable: _timetable([firstCourse, secondCourse]),
        teachingWeek: 1,
        width: 320,
        onCourseTap: (course, session) => tapped.add(session.id),
      );

      final first = find.byKey(
        const ValueKey<String>('course-session-conflict-a-session'),
      );
      final second = find.byKey(
        const ValueKey<String>('course-session-conflict-b-session'),
      );
      expect(first, findsOneWidget);
      expect(second, findsOneWidget);
      expect(tester.getTopLeft(first).dx, isNot(tester.getTopLeft(second).dx));
      expect(tester.getSize(first).width, greaterThan(0));
      expect(tester.getSize(second).width, greaterThan(0));

      await tester.tapAt(tester.getCenter(first));
      await tester.pump();
      await tester.tapAt(tester.getCenter(second));
      await tester.pump();

      expect(
        tapped,
        containsAll(<String>['conflict-a-session', 'conflict-b-session']),
      );
      expect(tester.takeException(), isNull);
    });
  });
}

String _groupLabel(PeriodGroup group) {
  return switch (group) {
    PeriodGroup.morning => '上午',
    PeriodGroup.afternoon => '下午',
    PeriodGroup.evening => '晚上',
  };
}

void _expectNoTableStructure() {
  expect(
    find.byKey(WeeklyTimetableView.headerHorizontalScrollKey),
    findsNothing,
  );
  expect(find.byKey(WeeklyTimetableView.gridHorizontalScrollKey), findsNothing);
  expect(find.byKey(WeeklyTimetableView.axisVerticalScrollKey), findsNothing);
  expect(find.byKey(WeeklyTimetableView.gridVerticalScrollKey), findsNothing);
  expect(find.byKey(WeeklyTimetableView.gridBodyKey), findsNothing);
  expect(
    find.byKey(WeeklyTimetableView.weekdayHeaderKey(DateTime.monday)),
    findsNothing,
  );
}

ScrollPosition _horizontalPosition(WidgetTester tester) {
  final scrollView = tester.widget<SingleChildScrollView>(
    find.byKey(WeeklyTimetableView.gridHorizontalScrollKey),
  );
  return scrollView.controller!.position;
}

ScrollPosition _verticalPosition(WidgetTester tester) {
  final scrollView = tester.widget<SingleChildScrollView>(
    find.byKey(WeeklyTimetableView.gridVerticalScrollKey),
  );
  return scrollView.controller!.position;
}

ScrollPosition _axisVerticalPosition(WidgetTester tester) {
  final scrollView = tester.widget<SingleChildScrollView>(
    find.byKey(WeeklyTimetableView.axisVerticalScrollKey),
  );
  return scrollView.controller!.position;
}

Future<void> _pumpView(
  WidgetTester tester, {
  required SemesterTimetable timetable,
  required int teachingWeek,
  bool showWeekend = true,
  CourseSessionTapCallback? onCourseTap,
  DateTime? today,
  double width = 800,
  double surfaceHeight = 700,
  double viewHeight = 650,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  await tester.binding.setSurfaceSize(Size(width, surfaceHeight));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(textScaler: textScaler),
        child: Scaffold(
          body: WeeklyTimetableView(
            timetable: timetable,
            teachingWeek: teachingWeek,
            showWeekend: showWeekend,
            onCourseTap: onCourseTap,
            today: today,
            height: viewHeight,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

SemesterTimetable _timetable(
  List<CourseWithSessions> courses, {
  List<PeriodDefinition> periodDefinitions = const [],
}) {
  return SemesterTimetable(
    semester: Semester(
      id: 'semester',
      academicYear: '2026-2027',
      term: '1',
      name: '测试学期',
      timetableName: '测试课表',
      startDate: DateTime(2026, 9, 7),
      teachingWeeks: 20,
    ),
    courses: courses,
    periodDefinitions: periodDefinitions,
  );
}

List<PeriodDefinition> _periods(int count) {
  const starts = <String>[
    '08:00',
    '08:55',
    '10:00',
    '10:55',
    '14:00',
    '14:55',
    '16:00',
    '16:55',
    '19:00',
    '19:55',
    '20:50',
    '21:45',
  ];
  const ends = <String>[
    '08:45',
    '09:40',
    '10:45',
    '11:40',
    '14:45',
    '15:40',
    '16:45',
    '17:40',
    '19:45',
    '20:40',
    '21:35',
    '22:30',
  ];
  return [
    for (var index = 0; index < count; index++)
      PeriodDefinition(
        id: 'period-${index + 1}',
        semesterId: 'semester',
        period: index + 1,
        startTime: starts[index],
        endTime: ends[index],
        group: index < 4
            ? PeriodGroup.morning
            : index < 8
            ? PeriodGroup.afternoon
            : PeriodGroup.evening,
      ),
  ];
}

CourseWithSessions _course({
  required String id,
  required String name,
  required List<CourseSession> sessions,
}) {
  return CourseWithSessions(
    course: Course(
      id: id,
      semesterId: 'semester',
      name: name,
      colorValue: 0xFF00695C,
    ),
    sessions: sessions,
  );
}

CourseSession _session({
  required String id,
  required String courseId,
  required Set<int> weeks,
  int weekday = DateTime.monday,
  int startPeriod = 1,
  int endPeriod = 2,
}) {
  return CourseSession(
    id: id,
    courseId: courseId,
    weekday: weekday,
    startPeriod: startPeriod,
    endPeriod: endPeriod,
    location: '教学楼 101',
    weeks: weeks,
  );
}

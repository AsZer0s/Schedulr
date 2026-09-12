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

    testWidgets('正确处理不连续周次', (tester) async {
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

      await _pumpView(tester, timetable: timetable, teachingWeek: 3);
      expect(find.text('不连续周课程'), findsOneWidget);
    });

    testWidgets('周末标题和课程由 showWeekend 控制', (tester) async {
      final timetable = _timetable([
        _course(
          id: 'weekday',
          name: '工作日课程',
          sessions: [
            _session(id: 'weekday-session', courseId: 'weekday', weeks: {1}),
          ],
        ),
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

      await _pumpView(tester, timetable: timetable, teachingWeek: 1);
      expect(
        find.byKey(WeeklyTimetableView.weekdayHeaderKey(5)),
        findsOneWidget,
      );
      expect(find.byKey(WeeklyTimetableView.weekdayHeaderKey(6)), findsNothing);
      expect(find.text('周末课程'), findsNothing);

      await _pumpView(
        tester,
        timetable: timetable,
        teachingWeek: 1,
        showWeekend: true,
      );
      expect(
        find.byKey(WeeklyTimetableView.weekdayHeaderKey(6)),
        findsOneWidget,
      );
      expect(
        find.byKey(WeeklyTimetableView.weekdayHeaderKey(7)),
        findsOneWidget,
      );
      expect(find.text('周末课程'), findsOneWidget);
    });

    for (final width in <double>[320, 360, 390, 450]) {
      testWidgets('$width 宽工作日完整显示且无水平滚动范围', (tester) async {
        final timetable = _timetable([
          _course(
            id: 'friday',
            name: '周五课程',
            sessions: [
              _session(
                id: 'friday-session',
                courseId: 'friday',
                weeks: {1},
                weekday: DateTime.friday,
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
        for (
          var weekday = DateTime.monday;
          weekday <= DateTime.friday;
          weekday++
        ) {
          final headerRect = tester.getRect(
            find.byKey(WeeklyTimetableView.weekdayHeaderKey(weekday)),
          );
          expect(headerRect.left, greaterThanOrEqualTo(viewRect.left));
          expect(headerRect.right, lessThanOrEqualTo(viewRect.right + 0.01));
        }
        final fridayCard = tester.getRect(
          find.byKey(const ValueKey<String>('course-session-friday-session')),
        );
        expect(fridayCard.left, greaterThanOrEqualTo(viewRect.left));
        expect(fridayCard.right, lessThanOrEqualTo(viewRect.right + 0.01));
        expect(_horizontalPosition(tester).maxScrollExtent, closeTo(0, 0.01));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('7 天窄屏使用最小列宽并可横滑', (tester) async {
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
        showWeekend: true,
        width: 320,
      );

      final position = _horizontalPosition(tester);
      expect(position.maxScrollExtent, greaterThan(0));
      final before = position.pixels;
      await tester.drag(
        find.byKey(WeeklyTimetableView.gridHorizontalScrollKey),
        const Offset(-220, 0),
      );
      await tester.pumpAndSettle();
      expect(position.pixels, greaterThan(before));
      expect(find.text('周日课程'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('当前教学周表头和整列高亮且语义标记今天', (tester) async {
      await _pumpView(
        tester,
        timetable: _timetable(const []),
        teachingWeek: 1,
        today: DateTime(2026, 9, 9),
      );

      expect(find.byKey(WeeklyTimetableView.todayColumnKey), findsOneWidget);
      final semantics = tester.getSemantics(
        find.byKey(WeeklyTimetableView.weekdayHeaderKey(DateTime.wednesday)),
      );
      expect(semantics.label, contains('今天'));
      expect(semantics.label, contains('9月9日'));
      expect(semantics.flagsCollection.isSelected, Tristate.isTrue);
    });

    testWidgets('非当前周不显示今天高亮', (tester) async {
      await _pumpView(
        tester,
        timetable: _timetable(const []),
        teachingWeek: 2,
        today: DateTime(2026, 9, 9),
      );

      expect(find.byKey(WeeklyTimetableView.todayColumnKey), findsNothing);
      for (
        var weekday = DateTime.monday;
        weekday <= DateTime.friday;
        weekday++
      ) {
        final semantics = tester.getSemantics(
          find.byKey(WeeklyTimetableView.weekdayHeaderKey(weekday)),
        );
        expect(semantics.label, isNot(contains('今天')));
      }
    });

    testWidgets('空周仍显示日期表头和网格空态', (tester) async {
      await _pumpView(tester, timetable: _timetable(const []), teachingWeek: 1);

      expect(find.byType(TimetableEmptyState), findsOneWidget);
      expect(
        find.byKey(WeeklyTimetableView.weekdayHeaderKey(1)),
        findsOneWidget,
      );
      expect(
        find.byKey(WeeklyTimetableView.weekdayHeaderKey(5)),
        findsOneWidget,
      );
      expect(
        tester
            .getSemantics(find.byKey(WeeklyTimetableView.weekdayHeaderKey(1)))
            .label,
        contains('9月7日'),
      );
    });

    testWidgets('320 宽大字体无布局异常', (tester) async {
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
      ]);

      await _pumpView(
        tester,
        timetable: timetable,
        teachingWeek: 1,
        width: 320,
        textScaler: const TextScaler.linear(2),
      );

      expect(find.text('名称很长但必须优先显示的课程'), findsOneWidget);
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

    testWidgets('点击课程卡回传课程和 session', (tester) async {
      final course = _course(
        id: 'tap-course',
        name: '可点击课程',
        sessions: [
          _session(id: 'tap-session', courseId: 'tap-course', weeks: {1}),
        ],
      );
      CourseWithSessions? tappedCourse;
      CourseSession? tappedSession;

      await _pumpView(
        tester,
        timetable: _timetable([course]),
        teachingWeek: 1,
        onCourseTap: (selectedCourse, selectedSession) {
          tappedCourse = selectedCourse;
          tappedSession = selectedSession;
        },
      );
      await tester.tap(find.text('可点击课程'));
      await tester.pump();

      expect(tappedCourse, same(course));
      expect(tappedSession, same(course.sessions.single));
    });
  });
}

ScrollPosition _horizontalPosition(WidgetTester tester) {
  final scrollView = tester.widget<SingleChildScrollView>(
    find.byKey(WeeklyTimetableView.gridHorizontalScrollKey),
  );
  return scrollView.controller!.position;
}

Future<void> _pumpView(
  WidgetTester tester, {
  required SemesterTimetable timetable,
  required int teachingWeek,
  bool showWeekend = false,
  CourseSessionTapCallback? onCourseTap,
  DateTime? today,
  double width = 800,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  await tester.binding.setSurfaceSize(Size(width, 700));
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
            height: 650,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

SemesterTimetable _timetable(List<CourseWithSessions> courses) {
  return SemesterTimetable(
    semester: Semester(
      id: 'semester',
      academicYear: '2026-2027',
      term: '1',
      name: '测试学期',
      startDate: DateTime(2026, 9, 7),
      teachingWeeks: 20,
    ),
    courses: courses,
    periodDefinitions: const [],
  );
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

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schedulr/features/timetable/domain/timetable_models.dart';
import 'package:schedulr/features/timetable/presentation/timetable_week_pager.dart';
import 'package:schedulr/features/timetable/presentation/weekly_timetable_view.dart';

void main() {
  group('TimetableWeekPager', () {
    testWidgets('builds chronological weeks and swipes the whole surface', (
      tester,
    ) async {
      final changedWeeks = <int>[];
      await _pumpPager(
        tester,
        timetable: _timetable(),
        teachingWeek: 2,
        onWeekChanged: changedWeeks.add,
      );

      expect(find.text('第二周课程'), findsOneWidget);
      expect(find.byType(PageView), findsOneWidget);

      await tester.drag(
        find.byKey(const ValueKey('timetable-week-pager')),
        const Offset(-320, 0),
      );
      await tester.pumpAndSettle();

      expect(changedWeeks, [3]);
      expect(find.text('第三周课程'), findsOneWidget);
    });

    testWidgets('empty and configuration error pages participate in swipes', (
      tester,
    ) async {
      final changedWeeks = <int>[];
      await _pumpPager(
        tester,
        timetable: _timetable(includeBrokenWeek: true),
        teachingWeek: 1,
        onWeekChanged: changedWeeks.add,
      );

      expect(find.byType(TimetableEmptyState), findsOneWidget);
      await tester.drag(
        find.byKey(const ValueKey('timetable-week-pager')),
        const Offset(-320, 0),
      );
      await tester.pumpAndSettle();
      expect(changedWeeks.last, 2);
      expect(find.text('第二周课程'), findsOneWidget);

      await tester.drag(
        find.byKey(const ValueKey('timetable-week-pager')),
        const Offset(-320, 0),
      );
      await tester.pumpAndSettle();
      expect(changedWeeks.last, 3);
      expect(find.byType(TimetableConfigurationErrorState), findsOneWidget);
    });

    testWidgets(
      'external changes animate through the controller without callback',
      (tester) async {
        final changedWeeks = <int>[];
        late StateSetter setHostState;
        var selectedWeek = 1;
        await _pumpStatefulPager(
          tester,
          timetable: _timetable(),
          selectedWeek: () => selectedWeek,
          onStateReady: (setState) => setHostState = setState,
          onWeekChanged: changedWeeks.add,
        );

        setHostState(() => selectedWeek = 3);
        await tester.pump();
        expect(find.text('第三周课程'), findsNothing);
        await tester.pump(const Duration(milliseconds: 120));
        expect(find.text('第三周课程'), findsWidgets);
        await tester.pumpAndSettle();

        expect(changedWeeks, isEmpty);
        expect(find.text('第三周课程'), findsOneWidget);
      },
    );

    testWidgets('reduced motion jumps external changes without callback', (
      tester,
    ) async {
      final changedWeeks = <int>[];
      late StateSetter setHostState;
      var selectedWeek = 1;
      await _pumpStatefulPager(
        tester,
        timetable: _timetable(),
        selectedWeek: () => selectedWeek,
        onStateReady: (setState) => setHostState = setState,
        onWeekChanged: changedWeeks.add,
        disableAnimations: true,
      );

      setHostState(() => selectedWeek = 3);
      await tester.pump();

      expect(changedWeeks, isEmpty);
      expect(find.text('第三周课程'), findsOneWidget);
    });

    testWidgets('vertical scrolling wins and offset is restored per week', (
      tester,
    ) async {
      final changedWeeks = <int>[];
      await _pumpPager(
        tester,
        timetable: _timetable(periodCount: 12),
        teachingWeek: 2,
        onWeekChanged: changedWeeks.add,
        height: 320,
      );

      final scrollFinder = find.byKey(
        WeeklyTimetableView.gridVerticalScrollKey,
      );
      await tester.drag(scrollFinder, const Offset(0, -180));
      await tester.pumpAndSettle();
      final savedOffset = _verticalOffset(tester);
      expect(savedOffset, greaterThan(0));
      expect(changedWeeks, isEmpty);

      await tester.drag(
        find.byKey(const ValueKey('timetable-week-pager')),
        const Offset(-320, 0),
      );
      await tester.pumpAndSettle();
      expect(changedWeeks.last, 3);

      await tester.drag(
        find.byKey(const ValueKey('timetable-week-pager')),
        const Offset(320, 0),
      );
      await tester.pumpAndSettle();
      expect(changedWeeks.last, 2);
      expect(_verticalOffset(tester), closeTo(savedOffset, 0.5));
    });

    testWidgets('viewport clips interactive transition without overflow', (
      tester,
    ) async {
      await _pumpPager(
        tester,
        timetable: _timetable(),
        teachingWeek: 2,
        onWeekChanged: (_) {},
        width: 320,
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('timetable-week-pager'))),
      );
      await gesture.moveBy(const Offset(-120, 0));
      await tester.pump();

      final pagerRect = tester.getRect(
        find.byKey(const ValueKey('timetable-week-pager')),
      );
      for (final view in find.byType(WeeklyTimetableView).evaluate()) {
        final rect = tester.getRect(find.byWidget(view.widget));
        expect(rect.right, greaterThan(pagerRect.left));
        expect(rect.left, lessThan(pagerRect.right));
      }
      expect(tester.takeException(), isNull);
      await gesture.up();
      await tester.pumpAndSettle();
    });
  });
}

Future<void> _pumpPager(
  WidgetTester tester, {
  required SemesterTimetable timetable,
  required int teachingWeek,
  required ValueChanged<int> onWeekChanged,
  double width = 400,
  double height = 500,
}) async {
  await tester.binding.setSurfaceSize(Size(width, height + 40));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: TimetableWeekPager(
          timetable: timetable,
          teachingWeek: teachingWeek,
          height: height,
          onWeekChanged: onWeekChanged,
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _pumpStatefulPager(
  WidgetTester tester, {
  required SemesterTimetable timetable,
  required int Function() selectedWeek,
  required ValueChanged<StateSetter> onStateReady,
  required ValueChanged<int> onWeekChanged,
  bool disableAnimations = false,
}) async {
  await tester.binding.setSurfaceSize(const Size(400, 540));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              onStateReady(setState);
              return TimetableWeekPager(
                timetable: timetable,
                teachingWeek: selectedWeek(),
                height: 500,
                onWeekChanged: onWeekChanged,
              );
            },
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

double _verticalOffset(WidgetTester tester) {
  return tester
      .widget<SingleChildScrollView>(
        find.byKey(WeeklyTimetableView.gridVerticalScrollKey),
      )
      .controller!
      .offset;
}

SemesterTimetable _timetable({
  int periodCount = 8,
  bool includeBrokenWeek = false,
}) {
  final courses = <CourseWithSessions>[
    _course('第二周课程', 2, endPeriod: 2),
    _course(
      includeBrokenWeek ? '错误课程' : '第三周课程',
      3,
      startPeriod: includeBrokenWeek ? periodCount + 1 : 2,
      endPeriod: includeBrokenWeek ? periodCount + 1 : 3,
    ),
  ];
  return SemesterTimetable(
    semester: Semester(
      id: 'semester',
      academicYear: '2026-2027',
      term: '1',
      name: '测试学期',
      timetableName: '测试课表',
      startDate: DateTime(2026, 9, 7),
      teachingWeeks: 4,
    ),
    courses: courses,
    periodDefinitions: [
      for (var index = 0; index < periodCount; index++)
        PeriodDefinition(
          id: 'period-${index + 1}',
          semesterId: 'semester',
          period: index + 1,
          startTime: '${(8 + index ~/ 2).toString().padLeft(2, '0')}:00',
          endTime: '${(8 + index ~/ 2).toString().padLeft(2, '0')}:45',
          group: index < 4
              ? PeriodGroup.morning
              : index < 8
              ? PeriodGroup.afternoon
              : PeriodGroup.evening,
        ),
    ],
  );
}

CourseWithSessions _course(
  String name,
  int week, {
  int startPeriod = 1,
  int endPeriod = 2,
}) {
  final id = 'course-$week';
  return CourseWithSessions(
    course: Course(
      id: id,
      semesterId: 'semester',
      name: name,
      colorValue: 0xFF00695C,
    ),
    sessions: [
      CourseSession(
        id: 'session-$week',
        courseId: id,
        weekday: DateTime.monday,
        startPeriod: startPeriod,
        endPeriod: endPeriod,
        weeks: {week},
      ),
    ],
  );
}

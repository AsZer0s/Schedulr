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
      expect(find.text('周五'), findsOneWidget);
      expect(find.text('周六'), findsNothing);
      expect(find.text('周末课程'), findsNothing);

      await _pumpView(
        tester,
        timetable: timetable,
        teachingWeek: 1,
        showWeekend: true,
      );
      expect(find.text('周六'), findsOneWidget);
      expect(find.text('周日'), findsOneWidget);
      expect(find.text('周末课程'), findsOneWidget);
    });

    testWidgets('冲突课程横向分栏且两张卡都存在', (tester) async {
      final timetable = _timetable([
        _course(
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
        ),
        _course(
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
        ),
      ]);

      await _pumpView(tester, timetable: timetable, teachingWeek: 1);

      final first = find.byKey(
        const ValueKey<String>('course-session-conflict-a-session'),
      );
      final second = find.byKey(
        const ValueKey<String>('course-session-conflict-b-session'),
      );
      expect(first, findsOneWidget);
      expect(second, findsOneWidget);
      expect(tester.getTopLeft(first).dx, isNot(tester.getTopLeft(second).dx));
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

Future<void> _pumpView(
  WidgetTester tester, {
  required SemesterTimetable timetable,
  required int teachingWeek,
  bool showWeekend = false,
  CourseSessionTapCallback? onCourseTap,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: WeeklyTimetableView(
          timetable: timetable,
          teachingWeek: teachingWeek,
          showWeekend: showWeekend,
          onCourseTap: onCourseTap,
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

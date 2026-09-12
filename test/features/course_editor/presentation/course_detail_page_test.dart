import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schedulr/features/course_editor/presentation/course_detail_page.dart';
import 'package:schedulr/features/timetable/domain/timetable_models.dart';

void main() {
  testWidgets('显示课程信息、所有安排并触发编辑入口', (tester) async {
    var editCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: CourseDetailPage(
          course: _courseWithSessions(),
          onEdit: () async => editCount++,
        ),
      ),
    );

    expect(find.text('操作系统'), findsOneWidget);
    expect(find.textContaining('刘老师'), findsOneWidget);
    expect(find.text('安排 1'), findsOneWidget);
    expect(find.text('安排 2'), findsOneWidget);
    expect(find.textContaining('星期一 第1-2节'), findsOneWidget);
    expect(find.textContaining('星期三 第5-6节'), findsOneWidget);
    expect(find.textContaining('第1-4周'), findsOneWidget);
    expect(find.textContaining('第5-8周'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('期末闭卷'),
      300,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('期末闭卷'), findsOneWidget);

    await tester.tap(find.byKey(const Key('course-detail-edit')));
    await tester.pump();
    expect(editCount, 1);
  });
}

CourseWithSessions _courseWithSessions() {
  const courseId = 'course-detail';
  return CourseWithSessions(
    course: Course(
      id: courseId,
      semesterId: 'semester-1',
      name: '操作系统',
      teacher: '刘老师',
      notes: '期末闭卷',
    ),
    sessions: [
      CourseSession(
        id: 'session-1',
        courseId: courseId,
        weekday: DateTime.monday,
        startPeriod: 1,
        endPeriod: 2,
        location: '计算机楼 101',
        weeks: {1, 2, 3, 4},
      ),
      CourseSession(
        id: 'session-2',
        courseId: courseId,
        weekday: DateTime.wednesday,
        startPeriod: 5,
        endPeriod: 6,
        location: '实验楼 302',
        weeks: {5, 6, 7, 8},
      ),
    ],
  );
}

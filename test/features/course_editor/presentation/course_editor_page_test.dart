import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schedulr/features/course_editor/presentation/course_editor_page.dart';
import 'package:schedulr/features/timetable/domain/timetable_models.dart';

void main() {
  late Semester semester;

  setUp(() {
    semester = Semester(
      id: 'semester-1',
      academicYear: '2026-2027',
      term: '1',
      name: '2026-2027 第一学期',
      timetableName: '测试课表',
      startDate: DateTime(2026, 9, 1),
      teachingWeeks: 16,
    );
  });

  Future<void> pumpEditor(
    WidgetTester tester, {
    CourseWithSessions? initialCourse,
    List<PeriodDefinition> periodDefinitions = const [],
    required Future<void> Function(CourseWithSessions course) onSave,
    Future<CourseSaveResult> Function(
      CourseWithSessions course, {
      required Set<String> acceptedConflictKeys,
    })?
    saveWithConflictCheck,
    Future<void> Function()? onDelete,
    TargetPlatform platform = TargetPlatform.android,
  }) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: platform),
        home: CourseEditorPage(
          semester: semester,
          periodDefinitions: periodDefinitions,
          initialCourse: initialCourse,
          onSave: onSave,
          saveWithConflictCheck: saveWithConflictCheck,
          onDelete: onDelete,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('iOS picker 选择星期和节次后可保存', (tester) async {
    CourseWithSessions? saved;
    final periods = [
      for (var period = 1; period <= 4; period++)
        PeriodDefinition(
          id: 'period-$period',
          semesterId: semester.id,
          period: period,
          startTime: '${(7 + period).toString().padLeft(2, '0')}:00',
          endTime: '${(7 + period).toString().padLeft(2, '0')}:45',
          group: PeriodGroup.morning,
        ),
    ];
    await pumpEditor(
      tester,
      platform: TargetPlatform.iOS,
      periodDefinitions: periods,
      onSave: (course) async => saved = course,
    );

    expect(find.byType(CupertinoNavigationBar), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<int>), findsNothing);
    await tester.enterText(
      find.byKey(const Key('course-name-field')),
      'iOS 课程',
    );
    await tester.tap(find.byKey(const Key('session-0-weekday')));
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoPicker), findsOneWidget);
    await tester.drag(find.byType(CupertinoPicker), const Offset(0, -90));
    await tester.pumpAndSettle();
    await tester.tap(find.text('完成'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('session-0-start-period')));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CupertinoPicker), const Offset(0, -45));
    await tester.pumpAndSettle();
    await tester.tap(find.text('完成'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('course-editor-save')));
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    expect(saved!.sessions.single.weekday, greaterThan(DateTime.monday));
    expect(saved!.sessions.single.startPeriod, greaterThan(1));
  });

  testWidgets('新建课程保存生成 UUID 和手动来源', (tester) async {
    CourseWithSessions? saved;
    await pumpEditor(tester, onSave: (course) async => saved = course);

    await tester.enterText(
      find.byKey(const Key('course-name-field')),
      '移动应用开发',
    );
    await tester.enterText(
      find.byKey(const Key('course-teacher-field')),
      '陈老师',
    );
    await tester.enterText(
      find.byKey(const Key('session-0-location')),
      '教学楼 A101',
    );
    await tester.enterText(find.byKey(const Key('session-0-weeks')), '1-15单');

    await tester.tap(find.byKey(const Key('course-editor-save')));
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    expect(saved!.course.id, isNotEmpty);
    expect(saved!.course.semesterId, semester.id);
    expect(saved!.course.name, '移动应用开发');
    expect(saved!.course.teacher, '陈老师');
    expect(saved!.course.source, CourseSource.manual);
    expect(saved!.course.isLocallyModified, isTrue);
    expect(saved!.sessions, hasLength(1));
    expect(saved!.sessions.single.courseId, saved!.course.id);
    expect(saved!.sessions.single.location, '教学楼 A101');
    expect(saved!.sessions.single.weeks, {1, 3, 5, 7, 9, 11, 13, 15});
  });

  testWidgets('无效周次与结束节次阻止保存', (tester) async {
    var saveCount = 0;
    await pumpEditor(tester, onSave: (_) async => saveCount++);

    await tester.enterText(find.byKey(const Key('course-name-field')), '编译原理');
    await tester.enterText(
      find.byKey(const Key('session-0-start-period')),
      '4',
    );
    await tester.enterText(find.byKey(const Key('session-0-end-period')), '2');
    await tester.enterText(find.byKey(const Key('session-0-weeks')), '1-20');

    await tester.tap(find.byKey(const Key('course-editor-save')));
    await tester.pumpAndSettle();

    expect(find.text('结束节次不能早于开始节次'), findsOneWidget);
    expect(find.text('周次不能超过第 16 周'), findsOneWidget);
    expect(saveCount, 0);
  });

  testWidgets('编辑保存保留课程和安排 ID', (tester) async {
    final initial = _courseWithSessions(semester);
    CourseWithSessions? saved;
    await pumpEditor(
      tester,
      initialCourse: initial,
      onSave: (course) async => saved = course,
    );

    await tester.enterText(
      find.byKey(const Key('course-name-field')),
      '高等数学（编辑）',
    );
    await tester.tap(find.byKey(const Key('course-editor-save')));
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    expect(saved!.course.id, initial.course.id);
    expect(saved!.course.semesterId, initial.course.semesterId);
    expect(saved!.course.source, initial.course.source);
    expect(saved!.course.sourceId, initial.course.sourceId);
    expect(saved!.course.isLocallyModified, isTrue);
    expect(saved!.sessions.single.id, initial.sessions.single.id);
    expect(saved!.sessions.single.courseId, initial.course.id);
  });

  testWidgets('学校作息存在时只能选择有效节次', (tester) async {
    CourseWithSessions? saved;
    final periods = [
      for (var period = 1; period <= 10; period++)
        PeriodDefinition(
          id: 'period-$period',
          semesterId: semester.id,
          period: period,
          startTime: '${(7 + period).toString().padLeft(2, '0')}:00',
          endTime: '${(7 + period).toString().padLeft(2, '0')}:45',
          group: period <= 4
              ? PeriodGroup.morning
              : period <= 8
              ? PeriodGroup.afternoon
              : PeriodGroup.evening,
        ),
    ];
    await pumpEditor(
      tester,
      periodDefinitions: periods,
      onSave: (course) async => saved = course,
    );

    await tester.enterText(find.byKey(const Key('course-name-field')), '数据库');
    await tester.tap(find.byKey(const Key('session-0-start-period')));
    await tester.pumpAndSettle();

    expect(find.textContaining('第10节'), findsOneWidget);
    expect(find.textContaining('第11节'), findsNothing);

    await tester.tap(find.textContaining('第5节'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('course-editor-save')));
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    expect(saved!.sessions.single.startPeriod, 5);
    expect(saved!.sessions.single.endPeriod, 5);
  });

  testWidgets('冲突返回修改不写入且再次确认传入 keys', (tester) async {
    var calls = 0;
    Set<String>? accepted;
    final conflict = CourseConflictReport(
      kind: CourseConflictKind.existingCourse,
      candidateSession: _courseWithSessions(semester).sessions.single,
      candidateSessionIndex: 0,
      conflictingSession: _courseWithSessions(semester).sessions.single,
      conflictingSessionIndex: 0,
      conflictingCourse: _courseWithSessions(semester),
      weekday: DateTime.monday,
      startPeriod: 1,
      endPeriod: 2,
      weeks: {1, 2},
    );
    await pumpEditor(
      tester,
      onSave: (_) async {},
      saveWithConflictCheck: (_, {required acceptedConflictKeys}) async {
        calls++;
        accepted = acceptedConflictKeys;
        return calls == 1 || acceptedConflictKeys.isEmpty
            ? CourseConflictConfirmationRequired(conflicts: [conflict])
            : const CourseSaved();
      },
    );
    await tester.enterText(find.byKey(const Key('course-name-field')), '冲突课程');
    await tester.tap(find.byKey(const Key('course-editor-save')));
    await tester.pumpAndSettle();
    expect(find.text('课程时间有冲突'), findsOneWidget);
    expect(find.text('返回修改'), findsOneWidget);
    expect(find.text('仍然保存'), findsOneWidget);
    await tester.tap(find.text('返回修改'));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(accepted, isEmpty);
    expect(find.byKey(const Key('course-editor-save')), findsOneWidget);
    await tester.tap(find.byKey(const Key('course-editor-save')));
    await tester.pumpAndSettle();
    expect(find.text('仍然保存'), findsOneWidget);
    await tester.tap(find.text('仍然保存'));
    await tester.pumpAndSettle();
    expect(calls, 3);
    expect(accepted, contains(conflict.key));
  });

  testWidgets('保存异常保留表单并显示错误提示', (tester) async {
    await pumpEditor(tester, onSave: (_) async => throw StateError('failed'));
    await tester.enterText(find.byKey(const Key('course-name-field')), '保存失败');
    await tester.tap(find.byKey(const Key('course-editor-save')));
    await tester.pumpAndSettle();
    expect(find.text('课程保存失败，请稍后重试'), findsOneWidget);
    expect(find.byKey(const Key('course-name-field')), findsOneWidget);
  });

  testWidgets('编辑态删除需要确认', (tester) async {
    var deleteCount = 0;
    await pumpEditor(
      tester,
      initialCourse: _courseWithSessions(semester),
      onSave: (_) async {},
      onDelete: () async => deleteCount++,
    );

    final deleteButton = find.byKey(const Key('course-editor-delete'));
    await tester.ensureVisible(deleteButton);
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    expect(find.text('删除课程？'), findsOneWidget);
    expect(deleteCount, 0);

    await tester.tap(find.widgetWithText(TextButton, '取消'));
    await tester.pumpAndSettle();
    expect(deleteCount, 0);

    await tester.tap(deleteButton);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '删除'));
    await tester.pumpAndSettle();

    expect(deleteCount, 1);
  });
}

CourseWithSessions _courseWithSessions(Semester semester) {
  const courseId = 'course-existing';
  return CourseWithSessions(
    course: Course(
      id: courseId,
      semesterId: semester.id,
      name: '高等数学',
      teacher: '王老师',
      colorValue: 0xFF1976D2,
      notes: '带计算器',
      source: CourseSource.zfsoft,
      sourceId: 'zf-42',
    ),
    sessions: [
      CourseSession(
        id: 'session-existing',
        courseId: courseId,
        weekday: DateTime.tuesday,
        startPeriod: 3,
        endPeriod: 4,
        location: '理科楼 201',
        weeks: {1, 2, 3, 4},
      ),
    ],
  );
}

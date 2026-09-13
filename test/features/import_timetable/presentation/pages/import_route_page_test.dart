import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schedulr/features/import_timetable/presentation/pages/import_route_page.dart';
import 'package:schedulr/features/timetable/data/providers.dart';
import 'package:schedulr/features/timetable/domain/timetable_models.dart';

void main() {
  testWidgets('target 参数固定读取指定课表而不是全局 current', (tester) async {
    final current = _timetable(id: 'current', timetableName: '我的课表');
    final target = _timetable(id: 'target', timetableName: '小明');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentTimetableProvider.overrideWith((ref) => Stream.value(current)),
          semesterTimetableByIdProvider.overrideWith(
            (ref, id) => Stream.value(id == target.semester.id ? target : null),
          ),
        ],
        child: const TestApp(
          child: ImportRoutePage(
            targetSemesterId: 'target',
            initialSource: 'bitc',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('导入到'), findsOneWidget);
    expect(find.text('小明'), findsOneWidget);
    expect(find.text('我的课表'), findsNothing);
  });

  testWidgets('不存在的 target 显示明确错误', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          semesterTimetableByIdProvider.overrideWith(
            (ref, id) => Stream.value(null),
          ),
        ],
        child: const TestApp(
          child: ImportRoutePage(targetSemesterId: 'missing'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('目标课表不存在或已被删除'), findsOneWidget);
  });
}

class TestApp extends StatelessWidget {
  const TestApp({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => MaterialApp(home: child);
}

SemesterTimetable _timetable({
  required String id,
  required String timetableName,
}) {
  return SemesterTimetable(
    semester: Semester(
      id: id,
      academicYear: '2026-2027',
      term: '1',
      name: '2026-2027 第一学期',
      timetableName: timetableName,
      startDate: DateTime(2026, 9, 7),
      teachingWeeks: 20,
      isCurrent: id == 'current',
    ),
    courses: const [],
    periodDefinitions: const [],
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schedulr/features/import_timetable/domain/import_timetable.dart';
import 'package:schedulr/features/import_timetable/presentation/import_preview_page.dart';

void main() {
  testWidgets('作息摘要展示三时段且 metadata-only 可以提交', (tester) async {
    var committed = false;
    final schedule = ImportedPeriodSchedule(
      periods: [
        ..._periods(1, 4, ImportedPeriodGroup.morning, 8),
        ..._periods(5, 8, ImportedPeriodGroup.afternoon, 14),
        ..._periods(9, 10, ImportedPeriodGroup.evening, 19),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ImportPreviewPage(
          preview: ImportPreview(
            strategy: ImportStrategy.merge,
            items: const [],
          ),
          sourceName: '虚构教务',
          targetTimetableName: '测试课表',
          timingProfile: ImportedTimingProfile(
            id: 'profile-0',
            name: '星河校区（虚构）',
            schedule: schedule,
          ),
          onCommit: () async => committed = true,
        ),
      ),
    );

    expect(find.text('导入到：测试课表'), findsOneWidget);
    expect(find.textContaining('上午 4 节'), findsOneWidget);
    expect(find.textContaining('下午 4 节'), findsOneWidget);
    expect(find.textContaining('晚上 2 节'), findsOneWidget);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNotNull);
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(committed, isTrue);
  });
}

List<ImportedPeriod> _periods(
  int start,
  int end,
  ImportedPeriodGroup group,
  int firstHour,
) {
  return [
    for (var number = start; number <= end; number += 1)
      ImportedPeriod(
        number: number,
        startTime:
            '${(firstHour + number - start).toString().padLeft(2, '0')}:00',
        endTime:
            '${(firstHour + number - start).toString().padLeft(2, '0')}:45',
        group: group,
      ),
  ];
}

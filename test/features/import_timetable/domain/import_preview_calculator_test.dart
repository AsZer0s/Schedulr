import 'package:flutter_test/flutter_test.dart';
import 'package:schedulr/features/import_timetable/domain/import_timetable.dart';

void main() {
  const calculator = ImportPreviewCalculator();

  test('区分新增、可能重复和时间冲突', () {
    final existing = [
      ExistingTimetableEntry(
        id: 'existing-math',
        sourceExternalId: 'source-math',
        title: '高等数学',
        dayOfWeek: 1,
        startPeriod: 1,
        endPeriod: 2,
        weeks: {1, 2, 3},
      ),
      ExistingTimetableEntry(
        id: 'existing-physics',
        title: '大学物理',
        dayOfWeek: 2,
        startPeriod: 3,
        endPeriod: 4,
        weeks: {1, 2, 3},
      ),
    ];
    final imported = [
      ImportedTimetableEntry(
        externalId: 'source-math',
        title: '另一个标题也应按 source id 判重',
        dayOfWeek: 1,
        startPeriod: 1,
        endPeriod: 2,
        weeks: {1, 2, 3},
      ),
      ImportedTimetableEntry(
        externalId: 'new-conflict',
        title: '冲突课程',
        dayOfWeek: 2,
        startPeriod: 4,
        endPeriod: 5,
        weeks: {2, 4},
      ),
      ImportedTimetableEntry(
        externalId: 'new-safe',
        title: '无冲突课程',
        dayOfWeek: 4,
        startPeriod: 7,
        endPeriod: 8,
        weeks: {1, 2, 3},
      ),
    ];

    final preview = calculator.calculate(
      imported: imported,
      existing: existing,
      strategy: ImportStrategy.merge,
    );

    expect(preview.addedCount, 1);
    expect(preview.possibleDuplicateCount, 1);
    expect(preview.conflictCount, 1);
    expect(preview.canCommit, isTrue);
    expect(preview.items[0].existingEntry?.id, 'existing-math');
    expect(preview.items[1].issue?.code, ImportIssueCode.scheduleConflict);
  });

  test('检测同一批导入数据中的重复项', () {
    ImportedTimetableEntry course(String id, String title) {
      return ImportedTimetableEntry(
        externalId: id,
        title: title,
        dayOfWeek: 3,
        startPeriod: 1,
        endPeriod: 2,
        weeks: {1, 2},
      );
    }

    final preview = calculator.calculate(
      imported: [course('a', '程序设计'), course('b', '  程序设计  ')],
      existing: const [],
      strategy: ImportStrategy.replace,
    );

    expect(preview.strategy, ImportStrategy.replace);
    expect(preview.addedCount, 1);
    expect(preview.possibleDuplicateCount, 1);
    expect(ImportCommitRequest(preview: preview).entriesToAdd, hasLength(1));
  });
}

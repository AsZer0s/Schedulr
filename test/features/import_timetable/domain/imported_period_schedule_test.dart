import 'package:flutter_test/flutter_test.dart';
import 'package:schedulr/features/import_timetable/domain/import_timetable.dart';

void main() {
  test('ImportedPeriod 校验正数节次、HH:mm 和时间顺序', () {
    expect(
      () => ImportedPeriod(
        number: 0,
        startTime: '08:00',
        endTime: '08:45',
        group: ImportedPeriodGroup.morning,
      ),
      throwsArgumentError,
    );
    expect(
      () => ImportedPeriod(
        number: 1,
        startTime: '8:00',
        endTime: '08:45',
        group: ImportedPeriodGroup.morning,
      ),
      throwsFormatException,
    );
    expect(
      () => ImportedPeriod(
        number: 1,
        startTime: '09:00',
        endTime: '08:45',
        group: ImportedPeriodGroup.morning,
      ),
      throwsArgumentError,
    );
  });

  test('ImportedPeriodSchedule 要求唯一且从 1 连续', () {
    ImportedPeriod period(int number) => ImportedPeriod(
      number: number,
      startTime: '08:00',
      endTime: '08:45',
      group: ImportedPeriodGroup.morning,
    );
    expect(
      () => ImportedPeriodSchedule(periods: [period(1), period(1)]),
      throwsArgumentError,
    );
    expect(
      () => ImportedPeriodSchedule(periods: [period(1), period(3)]),
      throwsArgumentError,
    );
  });

  test('ImportedTimetable 拒绝 entry 引用未知 profile', () {
    expect(
      () => ImportedTimetable(
        sourceName: '虚构来源',
        term: const ImportTermRequest(academicYear: '2026-2027', term: 1),
        entries: [
          ImportedTimetableEntry(
            externalId: 'course-1',
            title: '虚构课程',
            dayOfWeek: 1,
            startPeriod: 1,
            endPeriod: 2,
            weeks: const {1},
            timingProfileId: 'profile-missing',
          ),
        ],
      ),
      throwsArgumentError,
    );
  });
}

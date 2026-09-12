import 'package:flutter_test/flutter_test.dart';
import 'package:schedulr/core/time/teaching_calendar.dart';
import 'package:schedulr/features/timetable/domain/semester.dart';

void main() {
  final semester = Semester(
    id: '2026-fall',
    academicYear: '2026-2027',
    term: '1',
    name: '2026 秋季学期',
    startDate: DateTime(2026, 9, 2),
    teachingWeeks: 2,
  );

  test(
    'teaching week starts on Monday containing the configured start date',
    () {
      expect(semesterWeekStart(semester), DateTime(2026, 8, 31));
      expect(teachingWeekForDate(semester, DateTime(2026, 8, 30)), isNull);
      expect(teachingWeekForDate(semester, DateTime(2026, 8, 31)), 1);
      expect(teachingWeekForDate(semester, DateTime(2026, 9, 6, 23, 59)), 1);
      expect(teachingWeekForDate(semester, DateTime(2026, 9, 7)), 2);
      expect(teachingWeekForDate(semester, DateTime(2026, 9, 13)), 2);
      expect(teachingWeekForDate(semester, DateTime(2026, 9, 14)), isNull);
    },
  );

  test('maps teaching week and weekday back to a date', () {
    expect(
      dateForTeachingWeekday(semester, 1, DateTime.wednesday),
      DateTime(2026, 9, 2),
    );
    expect(
      dateForTeachingWeekday(semester, 2, DateTime.sunday),
      DateTime(2026, 9, 13),
    );
    expect(
      () => dateForTeachingWeekday(semester, 3, DateTime.monday),
      throwsRangeError,
    );
  });
}

import '../../features/timetable/domain/semester.dart';

DateTime dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

DateTime semesterWeekStart(Semester semester) {
  final start = dateOnly(semester.startDate);
  return start.subtract(Duration(days: start.weekday - DateTime.monday));
}

int? teachingWeekForDate(Semester semester, DateTime date) {
  final day = dateOnly(date);
  final weekStart = semesterWeekStart(semester);
  final difference = day.difference(weekStart).inDays;
  if (difference < 0) {
    return null;
  }

  final week = difference ~/ DateTime.daysPerWeek + 1;
  if (week > semester.teachingWeeks) {
    return null;
  }
  return week;
}

DateTime dateForTeachingWeekday(
  Semester semester,
  int teachingWeek,
  int weekday,
) {
  if (teachingWeek < 1 || teachingWeek > semester.teachingWeeks) {
    throw RangeError.range(
      teachingWeek,
      1,
      semester.teachingWeeks,
      'teachingWeek',
    );
  }
  if (weekday < DateTime.monday || weekday > DateTime.sunday) {
    throw RangeError.range(
      weekday,
      DateTime.monday,
      DateTime.sunday,
      'weekday',
    );
  }

  return semesterWeekStart(semester).add(
    Duration(days: (teachingWeek - 1) * DateTime.daysPerWeek + weekday - 1),
  );
}

DateTime teachingWeekEnd(Semester semester, int teachingWeek) {
  return dateForTeachingWeekday(semester, teachingWeek, DateTime.sunday);
}

bool isDateInTeachingSemester(Semester semester, DateTime date) {
  return teachingWeekForDate(semester, date) != null;
}

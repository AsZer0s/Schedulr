import 'package:schedulr/core/presentation/location_formatter.dart';
import 'package:schedulr/core/time/teaching_calendar.dart';
import 'package:schedulr/features/timetable/domain/semester_timetable.dart';

import 'widget_snapshot.dart';

class WidgetSnapshotProjector {
  const WidgetSnapshotProjector({
    this.expiryGrace = const Duration(hours: 2),
    this.projectionDays = WidgetSnapshot.defaultProjectionDays,
  }) : assert(projectionDays >= 2, 'projectionDays must be at least 2');

  final Duration expiryGrace;
  final int projectionDays;

  WidgetSnapshot project(SemesterTimetable timetable, DateTime now) {
    final localNow = now.toLocal();
    final todayDate = dateOnly(localNow);
    final days = List<WidgetDay>.generate(projectionDays, (index) {
      final day = _calendarDate(todayDate, index);
      final week = teachingWeekForDate(timetable.semester, day);
      return WidgetDay(
        date: _dateString(day),
        weekday: day.weekday,
        teachingWeek: week,
        courses: _coursesForDate(timetable, day, week),
      );
    }, growable: false);

    final today = days[0];
    final tomorrow = days[1];
    final next = _nextCourse(today, localNow);
    final lastDay = _calendarDate(todayDate, projectionDays - 1);
    final expiresAt = DateTime(
      lastDay.year,
      lastDay.month,
      lastDay.day,
      23,
      59,
      59,
    ).add(expiryGrace);
    final inside = teachingWeekForDate(timetable.semester, todayDate) != null;

    return WidgetSnapshot(
      schemaVersion: WidgetSnapshot.currentSchemaVersion,
      state: inside
          ? WidgetSnapshotState.ready
          : WidgetSnapshotState.outsideSemester,
      generatedAt: localNow,
      expiresAt: expiresAt,
      timetableName: timetable.semester.timetableName,
      semesterName: timetable.semester.name,
      today: today,
      tomorrow: tomorrow,
      futureDays: days.skip(2).toList(growable: false),
      next: next,
    );
  }

  List<WidgetCourse> _coursesForDate(
    SemesterTimetable timetable,
    DateTime date,
    int? teachingWeek,
  ) {
    if (teachingWeek == null) return const <WidgetCourse>[];
    final periods = {
      for (final definition in timetable.periodDefinitions)
        definition.period: definition,
    };
    final courses = <WidgetCourse>[];
    for (final courseWithSessions in timetable.courses) {
      final course = courseWithSessions.course;
      for (final session in courseWithSessions.sessions) {
        if (session.weekday != date.weekday ||
            !session.weeks.contains(teachingWeek)) {
          continue;
        }
        final start = periods[session.startPeriod];
        final end = periods[session.endPeriod];
        courses.add(
          WidgetCourse(
            courseId: course.id,
            sessionId: session.id,
            courseName: course.name,
            teacher: _clean(course.teacher),
            location: compactLocationLabel(session.location),
            time: start == null || end == null
                ? null
                : '${start.startTime}-${end.endTime}',
            startPeriod: session.startPeriod,
            endPeriod: session.endPeriod,
            color: course.colorValue,
          ),
        );
      }
    }
    courses.sort(_courseOrdering);
    return courses;
  }

  WidgetCourse? _nextCourse(WidgetDay today, DateTime now) {
    final minute = now.hour * 60 + now.minute;
    WidgetCourse? active;
    final future = <WidgetCourse>[];
    for (final course in today.courses) {
      final start = _startMinutes(course.time);
      final end = _endMinutes(course.time);
      if (start == null || end == null) continue;
      if (minute >= start && minute < end) {
        active ??= _withOngoing(course);
      } else if (start > minute) {
        future.add(course);
      }
    }
    return active ?? (future.isEmpty ? null : future.first);
  }

  WidgetCourse _withOngoing(WidgetCourse course) {
    return WidgetCourse(
      courseId: course.courseId,
      sessionId: course.sessionId,
      courseName: course.courseName,
      teacher: course.teacher,
      location: course.location,
      time: course.time,
      startPeriod: course.startPeriod,
      endPeriod: course.endPeriod,
      color: course.color,
      ongoing: true,
    );
  }

  int _courseOrdering(WidgetCourse first, WidgetCourse second) {
    final timeCompare = (_startMinutes(first.time) ?? 1 << 30).compareTo(
      _startMinutes(second.time) ?? 1 << 30,
    );
    if (timeCompare != 0) return timeCompare;
    final periodCompare = (first.startPeriod ?? 1 << 30).compareTo(
      second.startPeriod ?? 1 << 30,
    );
    if (periodCompare != 0) return periodCompare;
    final endCompare = (first.endPeriod ?? 1 << 30).compareTo(
      second.endPeriod ?? 1 << 30,
    );
    if (endCompare != 0) return endCompare;
    final courseCompare = first.courseId.compareTo(second.courseId);
    if (courseCompare != 0) return courseCompare;
    return first.sessionId.compareTo(second.sessionId);
  }

  int? _startMinutes(String? value) {
    if (value == null) return null;
    final match = RegExp(r'^(\d{2}):(\d{2})-').firstMatch(value);
    return match == null
        ? null
        : int.parse(match.group(1)!) * 60 + int.parse(match.group(2)!);
  }

  int? _endMinutes(String? value) {
    if (value == null) return null;
    final match = RegExp(r'-(\d{2}):(\d{2})$').firstMatch(value);
    return match == null
        ? null
        : int.parse(match.group(1)!) * 60 + int.parse(match.group(2)!);
  }

  String? _clean(String? value) {
    final cleaned = value?.trim();
    return cleaned == null || cleaned.isEmpty ? null : cleaned;
  }

  String _dateString(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year.toString().padLeft(4, '0')}-$month-$day';
  }

  DateTime _calendarDate(DateTime value, int daysFromToday) {
    return DateTime(value.year, value.month, value.day + daysFromToday);
  }
}

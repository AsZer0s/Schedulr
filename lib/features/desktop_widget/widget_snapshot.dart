// ignore_for_file: sort_constructors_first

import 'dart:convert';

import 'package:collection/collection.dart';

/// The states a widget snapshot can represent.
enum WidgetSnapshotState { noTimetable, outsideSemester, ready }

class WidgetCourse {
  const WidgetCourse({
    required this.courseId,
    required this.sessionId,
    required this.courseName,
    required this.teacher,
    required this.location,
    required this.time,
    required this.startPeriod,
    required this.endPeriod,
    required this.color,
    this.ongoing = false,
  });

  final String courseId;
  final String sessionId;
  final String courseName;
  final String? teacher;
  final String? location;
  final String? time;
  final int? startPeriod;
  final int? endPeriod;
  final int color;
  final bool ongoing;

  Map<String, Object?> toMap() => <String, Object?>{
    'courseId': courseId,
    'sessionId': sessionId,
    'courseName': courseName,
    'teacher': teacher,
    'location': location,
    'time': time,
    'startPeriod': startPeriod,
    'endPeriod': endPeriod,
    'color': color,
    'ongoing': ongoing,
  };

  factory WidgetCourse.fromMap(Map<String, Object?> map) {
    return WidgetCourse(
      courseId: _requiredString(map, 'courseId'),
      sessionId: _requiredString(map, 'sessionId'),
      courseName: _requiredString(map, 'courseName'),
      teacher: map['teacher'] as String?,
      location: map['location'] as String?,
      time: map['time'] as String?,
      startPeriod: map['startPeriod'] as int?,
      endPeriod: map['endPeriod'] as int?,
      color: _requiredInt(map, 'color'),
      ongoing: map['ongoing'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is WidgetCourse &&
      const DeepCollectionEquality().equals(toMap(), other.toMap());

  @override
  int get hashCode => const DeepCollectionEquality().hash(toMap());
}

class WidgetDay {
  WidgetDay({
    required this.date,
    required this.weekday,
    required this.teachingWeek,
    required List<WidgetCourse> courses,
  }) : courses = List.unmodifiable(courses);

  final String date;
  final int weekday;
  final int? teachingWeek;
  final List<WidgetCourse> courses;

  Map<String, Object?> toMap() => <String, Object?>{
    'date': date,
    'weekday': weekday,
    'teachingWeek': teachingWeek,
    'courses': courses.map((course) => course.toMap()).toList(growable: false),
  };

  factory WidgetDay.fromMap(Map<String, Object?> map) {
    final rawCourses = map['courses'];
    if (rawCourses is! List) {
      throw const FormatException('courses must be a list.');
    }
    return WidgetDay(
      date: _requiredString(map, 'date'),
      weekday: _requiredInt(map, 'weekday'),
      teachingWeek: map['teachingWeek'] as int?,
      courses: rawCourses
          .map(
            (course) =>
                WidgetCourse.fromMap(Map<String, Object?>.from(course as Map)),
          )
          .toList(growable: false),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is WidgetDay &&
      const DeepCollectionEquality().equals(toMap(), other.toMap());

  @override
  int get hashCode => const DeepCollectionEquality().hash(toMap());
}

/// Versioned, privacy-minimal data exchanged with the platform widget.
class WidgetSnapshot {
  WidgetSnapshot({
    required this.schemaVersion,
    required this.state,
    required this.generatedAt,
    required this.expiresAt,
    required this.timetableName,
    required this.semesterName,
    required this.today,
    required this.next,
    this.nextDate,
    required this.tomorrow,
    required List<WidgetDay> futureDays,
  }) : futureDays = List.unmodifiable(futureDays);

  static const int currentSchemaVersion = 1;
  static const int defaultProjectionDays = 14;

  factory WidgetSnapshot.noTimetable(
    DateTime now, {
    int? days,
    int? projectionDays,
  }) {
    final projectionLength = projectionDays ?? days ?? defaultProjectionDays;
    if (projectionLength < 2) {
      throw ArgumentError.value(projectionLength, 'days', 'must be at least 2');
    }
    final localNow = now.toLocal();
    final projectedDays = List<WidgetDay>.generate(projectionLength, (index) {
      final date = _calendarDate(localNow, index);
      return WidgetDay(
        date: _snapshotDateString(date),
        weekday: date.weekday,
        teachingWeek: null,
        courses: const <WidgetCourse>[],
      );
    }, growable: false);
    return WidgetSnapshot(
      schemaVersion: currentSchemaVersion,
      state: WidgetSnapshotState.noTimetable,
      generatedAt: localNow,
      expiresAt: localNow.add(const Duration(hours: 2)),
      timetableName: null,
      semesterName: null,
      today: projectedDays[0],
      next: null,
      nextDate: null,
      tomorrow: projectedDays[1],
      futureDays: projectedDays.skip(2).toList(growable: false),
    );
  }

  final int schemaVersion;
  final WidgetSnapshotState state;
  final DateTime generatedAt;
  final DateTime expiresAt;
  final String? timetableName;
  final String? semesterName;
  final WidgetDay today;
  final WidgetCourse? next;
  final String? nextDate;
  final WidgetDay tomorrow;
  final List<WidgetDay> futureDays;

  List<WidgetDay> get days => <WidgetDay>[today, tomorrow, ...futureDays];

  Map<String, Object?> toMap() => <String, Object?>{
    'schemaVersion': schemaVersion,
    'state': state.name,
    'generatedAt': generatedAt.toUtc().toIso8601String(),
    'expiresAt': expiresAt.toUtc().toIso8601String(),
    'timetableName': timetableName,
    'semesterName': semesterName,
    'today': today.toMap(),
    'next': next?.toMap(),
    'nextDate': nextDate,
    'tomorrow': tomorrow.toMap(),
    'futureDays': futureDays.map((day) => day.toMap()).toList(growable: false),
  };

  String toJson() => jsonEncode(toMap());

  factory WidgetSnapshot.fromMap(Map<String, Object?> map) {
    final rawFutureDays = map['futureDays'];
    if (rawFutureDays is! List) {
      throw const FormatException('futureDays must be a list.');
    }
    final rawNext = map['next'];
    return WidgetSnapshot(
      schemaVersion: _requiredInt(map, 'schemaVersion'),
      state: WidgetSnapshotState.values.byName(_requiredString(map, 'state')),
      generatedAt: DateTime.parse(_requiredString(map, 'generatedAt')),
      expiresAt: DateTime.parse(_requiredString(map, 'expiresAt')),
      timetableName: map['timetableName'] as String?,
      semesterName: map['semesterName'] as String?,
      today: WidgetDay.fromMap(Map<String, Object?>.from(map['today'] as Map)),
      next: rawNext == null
          ? null
          : WidgetCourse.fromMap(Map<String, Object?>.from(rawNext as Map)),
      nextDate: map['nextDate'] as String?,
      tomorrow: WidgetDay.fromMap(
        Map<String, Object?>.from(map['tomorrow'] as Map),
      ),
      futureDays: rawFutureDays
          .map(
            (day) => WidgetDay.fromMap(Map<String, Object?>.from(day as Map)),
          )
          .toList(growable: false),
    );
  }

  factory WidgetSnapshot.fromJson(String value) {
    final decoded = jsonDecode(value);
    if (decoded is! Map) {
      throw const FormatException('Snapshot must be an object.');
    }
    return WidgetSnapshot.fromMap(Map<String, Object?>.from(decoded));
  }

  @override
  bool operator ==(Object other) =>
      other is WidgetSnapshot &&
      const DeepCollectionEquality().equals(toMap(), other.toMap());

  @override
  int get hashCode => const DeepCollectionEquality().hash(toMap());
}

class WidgetCatalogEntry {
  const WidgetCatalogEntry({
    required this.timetableId,
    required this.timetableName,
    required this.semesterName,
    required this.snapshot,
  });

  final String timetableId;
  final String timetableName;
  final String semesterName;
  final WidgetSnapshot snapshot;

  Map<String, Object?> toMap() => <String, Object?>{
    'timetableId': timetableId,
    'timetableName': timetableName,
    'semesterName': semesterName,
    'snapshot': snapshot.toMap(),
  };

  factory WidgetCatalogEntry.fromMap(Map<String, Object?> map) {
    final rawSnapshot = map['snapshot'];
    if (rawSnapshot is! Map) {
      throw const FormatException('snapshot must be an object.');
    }
    return WidgetCatalogEntry(
      timetableId: _requiredString(map, 'timetableId'),
      timetableName: _requiredString(map, 'timetableName'),
      semesterName: _requiredString(map, 'semesterName'),
      snapshot: WidgetSnapshot.fromMap(Map<String, Object?>.from(rawSnapshot)),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is WidgetCatalogEntry &&
      const DeepCollectionEquality().equals(toMap(), other.toMap());

  @override
  int get hashCode => const DeepCollectionEquality().hash(toMap());
}

class WidgetCatalog {
  WidgetCatalog({
    required this.schemaVersion,
    required this.generatedAt,
    required this.defaultTimetableId,
    required List<WidgetCatalogEntry> entries,
  }) : entries = List.unmodifiable(entries);

  static const int currentSchemaVersion = 2;

  final int schemaVersion;
  final DateTime generatedAt;
  final String? defaultTimetableId;
  final List<WidgetCatalogEntry> entries;

  WidgetCatalogEntry? entryFor(String timetableId) {
    for (final entry in entries) {
      if (entry.timetableId == timetableId) return entry;
    }
    return null;
  }

  Map<String, Object?> toMap() => <String, Object?>{
    'schemaVersion': schemaVersion,
    'generatedAt': generatedAt.toUtc().toIso8601String(),
    'defaultTimetableId': defaultTimetableId,
    'timetables': entries.map((entry) => entry.toMap()).toList(growable: false),
  };

  String toJson() => jsonEncode(toMap());

  factory WidgetCatalog.fromMap(Map<String, Object?> map) {
    final rawEntries = map['timetables'];
    if (rawEntries is! List) {
      throw const FormatException('timetables must be a list.');
    }
    return WidgetCatalog(
      schemaVersion: _requiredInt(map, 'schemaVersion'),
      generatedAt: DateTime.parse(_requiredString(map, 'generatedAt')),
      defaultTimetableId: map['defaultTimetableId'] as String?,
      entries: rawEntries
          .map(
            (entry) => WidgetCatalogEntry.fromMap(
              Map<String, Object?>.from(entry as Map),
            ),
          )
          .toList(growable: false),
    );
  }

  factory WidgetCatalog.fromJson(String value) {
    final decoded = jsonDecode(value);
    if (decoded is! Map) {
      throw const FormatException('Catalog must be an object.');
    }
    return WidgetCatalog.fromMap(Map<String, Object?>.from(decoded));
  }

  @override
  bool operator ==(Object other) =>
      other is WidgetCatalog &&
      const DeepCollectionEquality().equals(toMap(), other.toMap());

  @override
  int get hashCode => const DeepCollectionEquality().hash(toMap());
}

String _requiredString(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! String) throw FormatException('$key must be a string.');
  return value;
}

int _requiredInt(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! int) throw FormatException('$key must be an integer.');
  return value;
}

String _snapshotDateString(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year.toString().padLeft(4, '0')}-$month-$day';
}

DateTime _calendarDate(DateTime value, int daysFromToday) {
  return DateTime(value.year, value.month, value.day + daysFromToday);
}

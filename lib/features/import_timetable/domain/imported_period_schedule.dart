import 'package:collection/collection.dart';

enum ImportedPeriodGroup { morning, afternoon, evening }

final class ImportedPeriod {
  ImportedPeriod({
    required this.number,
    required this.startTime,
    required this.endTime,
    required this.group,
  }) {
    if (number < 1) {
      throw ArgumentError.value(number, 'number', 'Must be positive.');
    }
    final start = _minutesFromMidnight(startTime);
    final end = _minutesFromMidnight(endTime);
    if (start >= end) {
      throw ArgumentError('endTime must be after startTime.');
    }
  }

  final int number;
  final String startTime;
  final String endTime;
  final ImportedPeriodGroup group;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ImportedPeriod &&
            other.number == number &&
            other.startTime == startTime &&
            other.endTime == endTime &&
            other.group == group;
  }

  @override
  int get hashCode => Object.hash(number, startTime, endTime, group);
}

final class ImportedPeriodSchedule {
  ImportedPeriodSchedule({required Iterable<ImportedPeriod> periods})
    : periods = List.unmodifiable(periods) {
    if (this.periods.isEmpty) {
      throw ArgumentError.value(periods, 'periods', 'Must not be empty.');
    }
    final numbers = this.periods.map((period) => period.number).toList();
    if (numbers.toSet().length != numbers.length) {
      throw ArgumentError.value(periods, 'periods', 'Numbers must be unique.');
    }
    final sorted = [...numbers]..sort();
    for (var index = 0; index < sorted.length; index += 1) {
      if (sorted[index] != index + 1) {
        throw ArgumentError.value(
          periods,
          'periods',
          'Numbers must be continuous from 1.',
        );
      }
    }
  }

  static const ListEquality<ImportedPeriod> _periodEquality =
      ListEquality<ImportedPeriod>();

  final List<ImportedPeriod> periods;

  int countFor(ImportedPeriodGroup group) =>
      periods.where((period) => period.group == group).length;

  ImportedPeriod? firstFor(ImportedPeriodGroup group) {
    final matches = periods.where((period) => period.group == group).toList()
      ..sort((first, second) => first.number.compareTo(second.number));
    return matches.isEmpty ? null : matches.first;
  }

  ImportedPeriod? lastFor(ImportedPeriodGroup group) {
    final matches = periods.where((period) => period.group == group).toList()
      ..sort((first, second) => first.number.compareTo(second.number));
    return matches.isEmpty ? null : matches.last;
  }

  bool covers(int startPeriod, int endPeriod) {
    if (startPeriod < 1 || endPeriod < startPeriod) return false;
    final numbers = periods.map((period) => period.number).toSet();
    for (var number = startPeriod; number <= endPeriod; number += 1) {
      if (!numbers.contains(number)) return false;
    }
    return true;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ImportedPeriodSchedule &&
            _periodEquality.equals(other.periods, periods);
  }

  @override
  int get hashCode => _periodEquality.hash(periods);
}

final class ImportedTimingProfile {
  ImportedTimingProfile({required this.id, required this.name, this.schedule}) {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'Must not be empty.');
    }
    if (name.trim().isEmpty) {
      throw ArgumentError.value(name, 'name', 'Must not be empty.');
    }
  }

  final String id;
  final String name;

  /// Null means the source profile was identified but its timing response was
  /// unavailable or invalid. Importers surface the reason as an [ImportIssue].
  final ImportedPeriodSchedule? schedule;

  bool get hasValidSchedule => schedule != null;
}

int _minutesFromMidnight(String value) {
  final match = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(value);
  if (match == null) {
    throw FormatException('Time must use HH:mm format.', value);
  }
  final hour = int.parse(match.group(1)!);
  final minute = int.parse(match.group(2)!);
  if (hour > 23 || minute > 59) {
    throw FormatException('Invalid time.', value);
  }
  return hour * 60 + minute;
}

enum PeriodGroup { morning, afternoon, evening }

class PeriodDefinition {
  PeriodDefinition({
    required this.id,
    required this.semesterId,
    required this.period,
    required this.startTime,
    required this.endTime,
    required this.group,
  }) {
    if (id.isEmpty) {
      throw ArgumentError.value(id, 'id', 'Must not be empty.');
    }
    if (semesterId.isEmpty) {
      throw ArgumentError.value(semesterId, 'semesterId', 'Must not be empty.');
    }
    if (period < 1) {
      throw ArgumentError.value(period, 'period', 'Must be positive.');
    }
    if (startMinutes >= endMinutes) {
      throw ArgumentError('endTime must be after startTime.');
    }
  }

  final String id;
  final String semesterId;
  final int period;
  final String startTime;
  final String endTime;
  final PeriodGroup group;

  int get startMinutes => _minutesFromMidnight(startTime);
  int get endMinutes => _minutesFromMidnight(endTime);

  PeriodDefinition copyWith({
    String? id,
    String? semesterId,
    int? period,
    String? startTime,
    String? endTime,
    PeriodGroup? group,
  }) {
    return PeriodDefinition(
      id: id ?? this.id,
      semesterId: semesterId ?? this.semesterId,
      period: period ?? this.period,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      group: group ?? this.group,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PeriodDefinition &&
            other.id == id &&
            other.semesterId == semesterId &&
            other.period == period &&
            other.startTime == startTime &&
            other.endTime == endTime &&
            other.group == group;
  }

  @override
  int get hashCode =>
      Object.hash(id, semesterId, period, startTime, endTime, group);

  @override
  String toString() {
    return 'PeriodDefinition(id: $id, semesterId: $semesterId, '
        'period: $period, startTime: $startTime, endTime: $endTime, '
        'group: $group)';
  }
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

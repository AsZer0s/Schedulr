import 'package:collection/collection.dart';

class CourseSession {
  CourseSession({
    required this.id,
    required this.courseId,
    required this.weekday,
    required this.startPeriod,
    required this.endPeriod,
    required Set<int> weeks,
    this.location,
  }) : weeks = UnmodifiableSetView(Set<int>.from(weeks)) {
    if (id.isEmpty) {
      throw ArgumentError.value(id, 'id', 'Must not be empty.');
    }
    if (courseId.isEmpty) {
      throw ArgumentError.value(courseId, 'courseId', 'Must not be empty.');
    }
    if (weekday < DateTime.monday || weekday > DateTime.sunday) {
      throw ArgumentError.value(weekday, 'weekday', 'Must be from 1 to 7.');
    }
    if (startPeriod < 1) {
      throw ArgumentError.value(
        startPeriod,
        'startPeriod',
        'Must be positive.',
      );
    }
    if (endPeriod < startPeriod) {
      throw ArgumentError.value(
        endPeriod,
        'endPeriod',
        'Must not precede startPeriod.',
      );
    }
    if (weeks.isEmpty || weeks.any((week) => week < 1)) {
      throw ArgumentError.value(
        weeks,
        'weeks',
        'Must contain positive week numbers.',
      );
    }
  }

  static const SetEquality<int> _setEquality = SetEquality<int>();

  final String id;
  final String courseId;
  final int weekday;
  final int startPeriod;
  final int endPeriod;
  final String? location;
  final Set<int> weeks;

  CourseSession copyWith({
    String? id,
    String? courseId,
    int? weekday,
    int? startPeriod,
    int? endPeriod,
    String? Function()? location,
    Set<int>? weeks,
  }) {
    return CourseSession(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      weekday: weekday ?? this.weekday,
      startPeriod: startPeriod ?? this.startPeriod,
      endPeriod: endPeriod ?? this.endPeriod,
      location: location == null ? this.location : location(),
      weeks: weeks ?? this.weeks,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CourseSession &&
            other.id == id &&
            other.courseId == courseId &&
            other.weekday == weekday &&
            other.startPeriod == startPeriod &&
            other.endPeriod == endPeriod &&
            other.location == location &&
            _setEquality.equals(other.weeks, weeks);
  }

  @override
  int get hashCode => Object.hash(
    id,
    courseId,
    weekday,
    startPeriod,
    endPeriod,
    location,
    _setEquality.hash(weeks),
  );

  @override
  String toString() {
    return 'CourseSession(id: $id, courseId: $courseId, weekday: $weekday, '
        'startPeriod: $startPeriod, endPeriod: $endPeriod, '
        'location: $location, weeks: $weeks)';
  }
}

import 'package:collection/collection.dart';

import 'course_with_sessions.dart';
import 'period_definition.dart';
import 'semester.dart';

class SemesterTimetable {
  SemesterTimetable({
    required this.semester,
    required List<CourseWithSessions> courses,
    required List<PeriodDefinition> periodDefinitions,
  }) : courses = List.unmodifiable(courses),
       periodDefinitions = List.unmodifiable(periodDefinitions);

  static const ListEquality<CourseWithSessions> _courseEquality =
      ListEquality<CourseWithSessions>();
  static const ListEquality<PeriodDefinition> _periodEquality =
      ListEquality<PeriodDefinition>();

  final Semester semester;
  final List<CourseWithSessions> courses;
  final List<PeriodDefinition> periodDefinitions;

  SemesterTimetable copyWith({
    Semester? semester,
    List<CourseWithSessions>? courses,
    List<PeriodDefinition>? periodDefinitions,
  }) {
    return SemesterTimetable(
      semester: semester ?? this.semester,
      courses: courses ?? this.courses,
      periodDefinitions: periodDefinitions ?? this.periodDefinitions,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SemesterTimetable &&
            other.semester == semester &&
            _courseEquality.equals(other.courses, courses) &&
            _periodEquality.equals(other.periodDefinitions, periodDefinitions);
  }

  @override
  int get hashCode => Object.hash(
    semester,
    _courseEquality.hash(courses),
    _periodEquality.hash(periodDefinitions),
  );
}

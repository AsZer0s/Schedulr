import 'package:collection/collection.dart';

import 'course.dart';
import 'course_session.dart';

class CourseWithSessions {
  CourseWithSessions({
    required this.course,
    required List<CourseSession> sessions,
  }) : sessions = List.unmodifiable(sessions);

  static const ListEquality<CourseSession> _listEquality =
      ListEquality<CourseSession>();

  final Course course;
  final List<CourseSession> sessions;

  CourseWithSessions copyWith({Course? course, List<CourseSession>? sessions}) {
    return CourseWithSessions(
      course: course ?? this.course,
      sessions: sessions ?? this.sessions,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CourseWithSessions &&
            other.course == course &&
            _listEquality.equals(other.sessions, sessions);
  }

  @override
  int get hashCode => Object.hash(course, _listEquality.hash(sessions));

  @override
  String toString() {
    return 'CourseWithSessions(course: $course, sessions: $sessions)';
  }
}

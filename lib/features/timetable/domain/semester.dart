class Semester {
  Semester({
    required this.id,
    required this.academicYear,
    required this.term,
    required this.name,
    required DateTime startDate,
    required this.teachingWeeks,
    this.timeZone = 'local',
    this.isCurrent = false,
  }) : startDate = DateTime(startDate.year, startDate.month, startDate.day) {
    if (id.isEmpty) {
      throw ArgumentError.value(id, 'id', 'Must not be empty.');
    }
    if (academicYear.isEmpty) {
      throw ArgumentError.value(
        academicYear,
        'academicYear',
        'Must not be empty.',
      );
    }
    if (term.isEmpty) {
      throw ArgumentError.value(term, 'term', 'Must not be empty.');
    }
    if (name.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Must not be empty.');
    }
    if (teachingWeeks < 1) {
      throw ArgumentError.value(
        teachingWeeks,
        'teachingWeeks',
        'Must be positive.',
      );
    }
  }

  final String id;
  final String academicYear;
  final String term;
  final String name;
  final DateTime startDate;
  final int teachingWeeks;
  final String timeZone;
  final bool isCurrent;

  Semester copyWith({
    String? id,
    String? academicYear,
    String? term,
    String? name,
    DateTime? startDate,
    int? teachingWeeks,
    String? timeZone,
    bool? isCurrent,
  }) {
    return Semester(
      id: id ?? this.id,
      academicYear: academicYear ?? this.academicYear,
      term: term ?? this.term,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      teachingWeeks: teachingWeeks ?? this.teachingWeeks,
      timeZone: timeZone ?? this.timeZone,
      isCurrent: isCurrent ?? this.isCurrent,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Semester &&
            other.id == id &&
            other.academicYear == academicYear &&
            other.term == term &&
            other.name == name &&
            other.startDate == startDate &&
            other.teachingWeeks == teachingWeeks &&
            other.timeZone == timeZone &&
            other.isCurrent == isCurrent;
  }

  @override
  int get hashCode => Object.hash(
    id,
    academicYear,
    term,
    name,
    startDate,
    teachingWeeks,
    timeZone,
    isCurrent,
  );

  @override
  String toString() {
    return 'Semester(id: $id, academicYear: $academicYear, term: $term, '
        'name: $name, startDate: $startDate, teachingWeeks: $teachingWeeks, '
        'timeZone: $timeZone, isCurrent: $isCurrent)';
  }
}

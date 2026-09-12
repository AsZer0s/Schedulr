import 'course_source.dart';

class Course {
  Course({
    required this.id,
    required this.semesterId,
    required this.name,
    this.code,
    this.teacher,
    this.teachingClass,
    this.colorValue = 0xFF3F51B5,
    this.notes,
    this.source = CourseSource.manual,
    this.sourceId,
    this.isLocallyModified = false,
  }) {
    if (id.isEmpty) {
      throw ArgumentError.value(id, 'id', 'Must not be empty.');
    }
    if (semesterId.isEmpty) {
      throw ArgumentError.value(semesterId, 'semesterId', 'Must not be empty.');
    }
    if (name.trim().isEmpty) {
      throw ArgumentError.value(name, 'name', 'Must not be empty.');
    }
  }

  final String id;
  final String semesterId;
  final String name;
  final String? code;
  final String? teacher;
  final String? teachingClass;
  final int colorValue;
  final String? notes;
  final CourseSource source;
  final String? sourceId;
  final bool isLocallyModified;

  Course copyWith({
    String? id,
    String? semesterId,
    String? name,
    String? Function()? code,
    String? Function()? teacher,
    String? Function()? teachingClass,
    int? colorValue,
    String? Function()? notes,
    CourseSource? source,
    String? Function()? sourceId,
    bool? isLocallyModified,
  }) {
    return Course(
      id: id ?? this.id,
      semesterId: semesterId ?? this.semesterId,
      name: name ?? this.name,
      code: code == null ? this.code : code(),
      teacher: teacher == null ? this.teacher : teacher(),
      teachingClass: teachingClass == null
          ? this.teachingClass
          : teachingClass(),
      colorValue: colorValue ?? this.colorValue,
      notes: notes == null ? this.notes : notes(),
      source: source ?? this.source,
      sourceId: sourceId == null ? this.sourceId : sourceId(),
      isLocallyModified: isLocallyModified ?? this.isLocallyModified,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Course &&
            other.id == id &&
            other.semesterId == semesterId &&
            other.name == name &&
            other.code == code &&
            other.teacher == teacher &&
            other.teachingClass == teachingClass &&
            other.colorValue == colorValue &&
            other.notes == notes &&
            other.source == source &&
            other.sourceId == sourceId &&
            other.isLocallyModified == isLocallyModified;
  }

  @override
  int get hashCode => Object.hash(
    id,
    semesterId,
    name,
    code,
    teacher,
    teachingClass,
    colorValue,
    notes,
    source,
    sourceId,
    isLocallyModified,
  );

  @override
  String toString() {
    return 'Course(id: $id, semesterId: $semesterId, name: $name, '
        'code: $code, teacher: $teacher, teachingClass: $teachingClass, '
        'colorValue: $colorValue, notes: $notes, source: $source, '
        'sourceId: $sourceId, isLocallyModified: $isLocallyModified)';
  }
}

/// A source-neutral timetable row produced by an importer.
///
/// This deliberately does not depend on the application's timetable domain.
/// The repository layer is expected to map it to the canonical timetable model.
final class ImportedTimetableEntry {
  ImportedTimetableEntry({
    required this.externalId,
    required this.title,
    required this.dayOfWeek,
    required this.startPeriod,
    required this.endPeriod,
    required Iterable<int> weeks,
    this.teacher,
    this.location,
    this.notes,
    this.timingProfileId,
  }) : weeks = Set.unmodifiable(weeks) {
    if (externalId.trim().isEmpty) {
      throw ArgumentError.value(externalId, 'externalId', 'Must not be empty');
    }
    if (title.trim().isEmpty) {
      throw ArgumentError.value(title, 'title', 'Must not be empty');
    }
    if (dayOfWeek < 1 || dayOfWeek > 7) {
      throw RangeError.range(dayOfWeek, 1, 7, 'dayOfWeek');
    }
    if (startPeriod < 1) {
      throw RangeError.value(startPeriod, 'startPeriod', 'Must be positive');
    }
    if (endPeriod < startPeriod) {
      throw RangeError.range(endPeriod, startPeriod, null, 'endPeriod');
    }
    if (this.weeks.isEmpty || this.weeks.any((week) => week < 1)) {
      throw ArgumentError.value(weeks, 'weeks', 'Must contain positive weeks');
    }
    if (timingProfileId != null && timingProfileId!.trim().isEmpty) {
      throw ArgumentError.value(
        timingProfileId,
        'timingProfileId',
        'Must not be empty when provided',
      );
    }
  }

  final String externalId;
  final String title;
  final String? teacher;
  final String? location;
  final String? notes;
  final String? timingProfileId;

  /// ISO weekday: Monday is 1 and Sunday is 7.
  final int dayOfWeek;
  final int startPeriod;
  final int endPeriod;
  final Set<int> weeks;

  bool overlaps(ImportedTimetableEntry other) {
    if (dayOfWeek != other.dayOfWeek) return false;
    if (endPeriod < other.startPeriod || other.endPeriod < startPeriod) {
      return false;
    }
    return weeks.any(other.weeks.contains);
  }
}

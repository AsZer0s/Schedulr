final class ImportTermRequest {
  const ImportTermRequest({required this.academicYear, required this.term});

  final String academicYear;
  final int term;
}

/// Verified semester calendar metadata supplied by an importer.
final class ImportedSemesterCalendar {
  ImportedSemesterCalendar({required DateTime startDate, this.teachingWeeks})
    : startDate = DateTime(startDate.year, startDate.month, startDate.day) {
    final weeks = teachingWeeks;
    if (weeks != null && weeks < 1) {
      throw ArgumentError.value(
        weeks,
        'teachingWeeks',
        'Must be positive when provided.',
      );
    }
  }

  final DateTime startDate;
  final int? teachingWeeks;
}

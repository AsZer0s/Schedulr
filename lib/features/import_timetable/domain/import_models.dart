import 'import_metadata.dart';
import 'imported_period_schedule.dart';
import 'imported_timetable_entry.dart';

/// How imported data should be persisted after the user accepts a preview.
enum ImportStrategy { merge, replace }

enum ImportIssueSeverity { warning, error }

enum ImportIssueCode {
  possibleDuplicate,
  scheduleConflict,
  invalidSourceData,
  unsupportedSourceData,
}

/// A UI-safe issue. Source-specific exceptions and school details stay behind
/// the importer boundary.
final class ImportIssue {
  const ImportIssue({
    required this.code,
    required this.message,
    required this.severity,
    this.importedExternalId,
    this.existingEntryId,
  });

  final ImportIssueCode code;
  final String message;
  final ImportIssueSeverity severity;
  final String? importedExternalId;
  final String? existingEntryId;
}

/// Minimal view of an existing repository entry required by the diff engine.
final class ExistingTimetableEntry {
  ExistingTimetableEntry({
    required this.id,
    required this.title,
    required this.dayOfWeek,
    required this.startPeriod,
    required this.endPeriod,
    required Iterable<int> weeks,
    this.teacher,
    this.location,
    this.sourceExternalId,
  }) : weeks = Set.unmodifiable(weeks);

  final String id;
  final String title;
  final String? teacher;
  final String? location;
  final String? sourceExternalId;
  final int dayOfWeek;
  final int startPeriod;
  final int endPeriod;
  final Set<int> weeks;

  bool overlaps(ImportedTimetableEntry imported) {
    if (dayOfWeek != imported.dayOfWeek) return false;
    if (endPeriod < imported.startPeriod || imported.endPeriod < startPeriod) {
      return false;
    }
    return weeks.any(imported.weeks.contains);
  }
}

enum ImportPreviewItemKind { added, possibleDuplicate, conflict }

final class ImportPreviewItem {
  const ImportPreviewItem({
    required this.imported,
    required this.kind,
    this.existingEntry,
    this.issue,
  });

  final ImportedTimetableEntry imported;
  final ImportPreviewItemKind kind;
  final ExistingTimetableEntry? existingEntry;
  final ImportIssue? issue;
}

final class ImportPreview {
  ImportPreview({
    required this.strategy,
    required Iterable<ImportPreviewItem> items,
    Iterable<ImportIssue> issues = const [],
  }) : items = List.unmodifiable(items),
       issues = List.unmodifiable(issues);

  final ImportStrategy strategy;
  final List<ImportPreviewItem> items;
  final List<ImportIssue> issues;

  int get addedCount => _count(ImportPreviewItemKind.added);
  int get possibleDuplicateCount =>
      _count(ImportPreviewItemKind.possibleDuplicate);
  int get conflictCount => _count(ImportPreviewItemKind.conflict);
  bool get canCommit =>
      issues.every((issue) => issue.severity != ImportIssueSeverity.error);

  int _count(ImportPreviewItemKind kind) =>
      items.where((item) => item.kind == kind).length;
}

/// Data the application repository needs to persist an accepted preview.
/// Persistence itself intentionally remains outside this module.
final class ImportCommitRequest {
  const ImportCommitRequest({
    required this.preview,
    this.term,
    this.calendar,
    this.timingProfile,
  });

  final ImportPreview preview;
  final ImportTermRequest? term;
  final ImportedSemesterCalendar? calendar;
  final ImportedTimingProfile? timingProfile;

  ImportStrategy get strategy => preview.strategy;
  Iterable<ImportedTimetableEntry> get entriesToAdd => preview.items
      .where((item) => item.kind == ImportPreviewItemKind.added)
      .map((item) => item.imported);

  bool get hasMetadataUpdate =>
      term != null || calendar != null || timingProfile?.schedule != null;
}

final class ImportCommitResult {
  const ImportCommitResult({
    required this.createdCount,
    required this.skippedCount,
    required this.replacedCount,
    this.issues = const [],
  });

  final int createdCount;
  final int skippedCount;
  final int replacedCount;
  final List<ImportIssue> issues;

  bool get succeeded =>
      issues.every((issue) => issue.severity != ImportIssueSeverity.error);
}

import 'import_models.dart';
import 'imported_timetable_entry.dart';

/// Pure diff logic. It has no database, Flutter, or source integration
/// dependency and is safe to run before repository submission.
final class ImportPreviewCalculator {
  const ImportPreviewCalculator();

  ImportPreview calculate({
    required Iterable<ImportedTimetableEntry> imported,
    required Iterable<ExistingTimetableEntry> existing,
    ImportStrategy strategy = ImportStrategy.merge,
  }) {
    final existingEntries = List<ExistingTimetableEntry>.unmodifiable(existing);
    final seenImported = <String, ImportedTimetableEntry>{};
    final items = <ImportPreviewItem>[];
    final issues = <ImportIssue>[];

    for (final candidate in imported) {
      final duplicateInBatch = seenImported[_identityKey(candidate)];
      if (duplicateInBatch != null) {
        final issue = ImportIssue(
          code: ImportIssueCode.possibleDuplicate,
          severity: ImportIssueSeverity.warning,
          message: '导入数据中存在重复课程。',
          importedExternalId: candidate.externalId,
        );
        issues.add(issue);
        items.add(
          ImportPreviewItem(
            imported: candidate,
            kind: ImportPreviewItemKind.possibleDuplicate,
            issue: issue,
          ),
        );
        continue;
      }
      seenImported[_identityKey(candidate)] = candidate;

      final exactDuplicate = _firstWhereOrNull(
        existingEntries,
        (entry) => _isPossibleDuplicate(entry, candidate),
      );
      if (exactDuplicate != null) {
        final issue = ImportIssue(
          code: ImportIssueCode.possibleDuplicate,
          severity: ImportIssueSeverity.warning,
          message: '已有相同或高度相似的课程。',
          importedExternalId: candidate.externalId,
          existingEntryId: exactDuplicate.id,
        );
        issues.add(issue);
        items.add(
          ImportPreviewItem(
            imported: candidate,
            kind: ImportPreviewItemKind.possibleDuplicate,
            existingEntry: exactDuplicate,
            issue: issue,
          ),
        );
        continue;
      }

      final conflict = _firstWhereOrNull(
        existingEntries,
        (entry) => entry.overlaps(candidate),
      );
      if (conflict != null) {
        final issue = ImportIssue(
          code: ImportIssueCode.scheduleConflict,
          severity: ImportIssueSeverity.warning,
          message: '该课程与现有课程时间冲突。',
          importedExternalId: candidate.externalId,
          existingEntryId: conflict.id,
        );
        issues.add(issue);
        items.add(
          ImportPreviewItem(
            imported: candidate,
            kind: ImportPreviewItemKind.conflict,
            existingEntry: conflict,
            issue: issue,
          ),
        );
        continue;
      }

      items.add(
        ImportPreviewItem(
          imported: candidate,
          kind: ImportPreviewItemKind.added,
        ),
      );
    }

    return ImportPreview(strategy: strategy, items: items, issues: issues);
  }

  bool _isPossibleDuplicate(
    ExistingTimetableEntry existing,
    ImportedTimetableEntry imported,
  ) {
    final sameSourceId = imported.externalId == existing.sourceExternalId;
    if (sameSourceId) return true;

    return _normalize(existing.title) == _normalize(imported.title) &&
        existing.dayOfWeek == imported.dayOfWeek &&
        existing.startPeriod == imported.startPeriod &&
        existing.endPeriod == imported.endPeriod &&
        _setsEqual(existing.weeks, imported.weeks);
  }

  String _identityKey(ImportedTimetableEntry entry) {
    final weeks = entry.weeks.toList()..sort();
    return [
      _normalize(entry.title),
      entry.dayOfWeek,
      entry.startPeriod,
      entry.endPeriod,
      weeks.join(','),
    ].join('|');
  }

  String _normalize(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  bool _setsEqual(Set<int> left, Set<int> right) =>
      left.length == right.length && left.containsAll(right);

  T? _firstWhereOrNull<T>(Iterable<T> values, bool Function(T) predicate) {
    for (final value in values) {
      if (predicate(value)) return value;
    }
    return null;
  }
}

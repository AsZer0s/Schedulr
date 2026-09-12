import 'import_models.dart';
import 'imported_timetable_entry.dart';

enum ImportAuthRequestKind { credentials, verificationCode, browserSession }

/// Credentials are request-scoped only. Importers must not persist them.
sealed class ImportAuthRequest {
  const ImportAuthRequest({required this.kind});

  final ImportAuthRequestKind kind;
}

final class CredentialAuthRequest extends ImportAuthRequest {
  const CredentialAuthRequest({required this.username, required this.password})
    : super(kind: ImportAuthRequestKind.credentials);

  final String username;
  final String password;
}

final class VerificationCodeAuthRequest extends ImportAuthRequest {
  const VerificationCodeAuthRequest({
    required this.challengeId,
    required this.code,
  }) : super(kind: ImportAuthRequestKind.verificationCode);

  final String challengeId;
  final String code;
}

/// Marks that the caller has completed authentication in an external browser
/// session. No cookie, token, username, or password crosses this boundary.
final class BrowserSessionAuthRequest extends ImportAuthRequest {
  const BrowserSessionAuthRequest()
    : super(kind: ImportAuthRequestKind.browserSession);
}

enum ImportAuthStatusKind {
  notStarted,
  authenticating,
  verificationRequired,
  authenticated,
  failed,
}

final class ImportAuthStatus {
  const ImportAuthStatus._({
    required this.kind,
    this.message,
    this.challengeId,
  });

  const ImportAuthStatus.notStarted()
    : this._(kind: ImportAuthStatusKind.notStarted);
  const ImportAuthStatus.authenticating()
    : this._(kind: ImportAuthStatusKind.authenticating);
  const ImportAuthStatus.authenticated()
    : this._(kind: ImportAuthStatusKind.authenticated);
  const ImportAuthStatus.verificationRequired({
    required String challengeId,
    String? message,
  }) : this._(
         kind: ImportAuthStatusKind.verificationRequired,
         challengeId: challengeId,
         message: message,
       );
  const ImportAuthStatus.failed(String message)
    : this._(kind: ImportAuthStatusKind.failed, message: message);

  final ImportAuthStatusKind kind;
  final String? message;
  final String? challengeId;

  bool get isAuthenticated => kind == ImportAuthStatusKind.authenticated;
}

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

final class ImportedTimetable {
  ImportedTimetable({
    required this.sourceName,
    required this.term,
    required Iterable<ImportedTimetableEntry> entries,
    Iterable<ImportIssue> issues = const [],
    this.calendar,
  }) : entries = List.unmodifiable(entries),
       issues = List.unmodifiable(issues);

  final String sourceName;
  final ImportTermRequest term;
  final List<ImportedTimetableEntry> entries;
  final List<ImportIssue> issues;
  final ImportedSemesterCalendar? calendar;
}

enum TimetableImportFailureKind {
  invalidCredentials,
  verificationRequired,
  authenticationExpired,
  sourceUnavailable,
  unsupportedSchool,
  invalidResponse,
  parseFailed,
  cancelled,
  unknown,
}

final class TimetableImportException implements Exception {
  const TimetableImportException({
    required this.kind,
    required this.message,
    this.cause,
  });

  final TimetableImportFailureKind kind;
  final String message;
  final Object? cause;

  @override
  String toString() => 'TimetableImportException($kind, $message)';
}

abstract interface class TimetableImporter {
  String get sourceId;
  String get displayName;
  ImportAuthStatus get authStatus;

  Future<ImportAuthStatus> authenticate(ImportAuthRequest request);

  Future<ImportedTimetable> fetchTimetable(ImportTermRequest term);

  Future<void> signOut();
}

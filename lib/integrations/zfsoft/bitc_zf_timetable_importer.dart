import '../../features/import_timetable/domain/import_timetable.dart';
import 'bitc_v9_timetable_json_parser.dart';
import 'zf_errors.dart';
import 'zf_school_profile.dart';
import 'zf_timetable_parser.dart';

/// BITC Zhengfang V9 importer backed by a caller-owned authenticated Web session.
final class BitcZfTimetableImporter implements TimetableImporter {
  BitcZfTimetableImporter({
    required this.fetchPayload,
    this.parser = const BitcV9TimetableJsonParser(),
    ZfSchoolProfile? profile,
  }) : profile = profile ?? ZfSchoolProfile.bitc;

  final Future<String> Function(ImportTermRequest term) fetchPayload;
  final BitcV9TimetableJsonParser parser;
  final ZfSchoolProfile profile;

  ImportAuthStatus _authStatus = const ImportAuthStatus.notStarted();

  @override
  String get sourceId => profile.id;

  @override
  String get displayName => profile.displayName;

  @override
  ImportAuthStatus get authStatus => _authStatus;

  @override
  Future<ImportAuthStatus> authenticate(ImportAuthRequest request) async {
    _authStatus = const ImportAuthStatus.authenticating();
    if (request is! BrowserSessionAuthRequest) {
      _authStatus = const ImportAuthStatus.failed('BITC 导入仅接受已登录的 Web 会话。');
      throw const TimetableImportException(
        kind: TimetableImportFailureKind.authenticationExpired,
        message: 'BITC 导入仅接受已登录的 Web 会话。',
      );
    }
    _authStatus = const ImportAuthStatus.authenticated();
    return _authStatus;
  }

  @override
  Future<ImportedTimetable> fetchTimetable(ImportTermRequest term) async {
    if (!_authStatus.isAuthenticated) {
      throw const TimetableImportException(
        kind: TimetableImportFailureKind.authenticationExpired,
        message: '请先在 BITC 登录入口完成 Web 会话认证。',
      );
    }

    try {
      final protocolTerm = toProtocolTerm(term);
      final payload = await fetchPayload(protocolTerm);
      final result = parser.parseResult(
        ZfTimetableResponseDto(
          body: payload,
          contentType: 'application/json; charset=utf-8',
        ),
      );
      final issues = <ImportIssue>[
        ...result.calendarIssues,
        ...result.timingIssues,
      ];
      if (result.unscheduledCourseCount > 0) {
        issues.add(
          ImportIssue(
            code: ImportIssueCode.unsupportedSourceData,
            severity: ImportIssueSeverity.warning,
            message: '另有 ${result.unscheduledCourseCount} 门无固定星期或节次的课程未导入。',
          ),
        );
      }
      return ImportedTimetable(
        sourceName: displayName,
        term: term,
        entries: result.courses.map(_toImportedEntry),
        issues: issues,
        calendar: result.calendar,
        timingProfiles: result.timingProfiles,
      );
    } on TimetableImportException {
      rethrow;
    } on ZfException catch (error) {
      if (error.kind == ZfFailureKind.authenticationExpired) {
        _authStatus = const ImportAuthStatus.notStarted();
      }
      throw _toImportException(error);
    } on FormatException catch (error) {
      throw TimetableImportException(
        kind: TimetableImportFailureKind.invalidResponse,
        message: error.message,
        cause: error,
      );
    } on Object catch (error) {
      throw TimetableImportException(
        kind: TimetableImportFailureKind.sourceUnavailable,
        message: 'BITC 课表数据获取失败。',
        cause: error,
      );
    }
  }

  @override
  Future<void> signOut() async {
    _authStatus = const ImportAuthStatus.notStarted();
  }

  /// Maps app terms to BITC's `xnm` and `xqm` values.
  static ImportTermRequest toProtocolTerm(ImportTermRequest term) {
    final match = RegExp(r'^(\d{4})(?:-\d{4})?$')
        .firstMatch(term.academicYear.trim());
    if (match == null) {
      throw FormatException('BITC 学年必须是 2026 或 2026-2027 形式。');
    }
    final termCode = switch (term.term) {
      1 => 3,
      2 => 12,
      3 => 16,
      _ => throw FormatException('BITC 学期仅支持第一、第二或第三学期。'),
    };
    return ImportTermRequest(academicYear: match.group(1)!, term: termCode);
  }

  ImportedTimetableEntry _toImportedEntry(ZfCourseDto course) {
    return ImportedTimetableEntry(
      externalId: course.sourceId,
      title: course.name,
      teacher: course.teacher,
      location: course.location,
      notes: course.notes,
      dayOfWeek: course.weekday,
      startPeriod: course.startPeriod,
      endPeriod: course.endPeriod,
      weeks: course.weeks,
      timingProfileId: course.timingProfileId,
    );
  }

  TimetableImportException _toImportException(ZfException error) {
    final kind = switch (error.kind) {
      ZfFailureKind.invalidCredentials =>
        TimetableImportFailureKind.invalidCredentials,
      ZfFailureKind.verificationRequired =>
        TimetableImportFailureKind.verificationRequired,
      ZfFailureKind.authenticationExpired =>
        TimetableImportFailureKind.authenticationExpired,
      ZfFailureKind.networkUnavailable || ZfFailureKind.endpointRejected =>
        TimetableImportFailureKind.sourceUnavailable,
      ZfFailureKind.unsupportedProfile =>
        TimetableImportFailureKind.unsupportedSchool,
      ZfFailureKind.malformedResponse =>
        TimetableImportFailureKind.invalidResponse,
      ZfFailureKind.unsupportedLayout ||
      ZfFailureKind.parseFailed => TimetableImportFailureKind.parseFailed,
      ZfFailureKind.unknown => TimetableImportFailureKind.unknown,
    };
    return TimetableImportException(
      kind: kind,
      message: error.message,
      cause: error,
    );
  }
}

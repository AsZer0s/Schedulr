import '../../features/import_timetable/domain/import_timetable.dart';
import 'zf_demo_fixture.dart';
import 'zf_errors.dart';
import 'zf_school_profile.dart';
import 'zf_timetable_parser.dart';

/// Local-only importer for UI development and tests.
///
/// Demo credentials are `demo` / `demo`. They are checked and immediately
/// discarded; no password, cookie, token, WebView, or network is used.
final class MockZfTimetableImporter implements TimetableImporter {
  MockZfTimetableImporter({
    ZfSchoolProfile? profile,
    this.parser = const ZfFixtureJsonParser(),
    this.simulatedDelay = const Duration(milliseconds: 250),
  }) : profile = profile ?? ZfSchoolProfile.demo {
    if (!this.profile.isDemo) {
      throw const ZfException(
        kind: ZfFailureKind.unsupportedProfile,
        message: 'Mock importer 仅允许演示 profile。',
      );
    }
  }

  final ZfSchoolProfile profile;
  final ZfTimetableParser parser;
  final Duration simulatedDelay;

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
    await Future<void>.delayed(simulatedDelay);

    if (request is! CredentialAuthRequest) {
      _authStatus = const ImportAuthStatus.failed('演示导入仅支持账号密码步骤。');
      throw const TimetableImportException(
        kind: TimetableImportFailureKind.invalidCredentials,
        message: '演示导入仅支持账号密码步骤。',
      );
    }

    // Compare without retaining the request or copying either credential.
    if (request.username != 'demo' || request.password != 'demo') {
      _authStatus = const ImportAuthStatus.failed('演示账号或密码错误。');
      throw const TimetableImportException(
        kind: TimetableImportFailureKind.invalidCredentials,
        message: '演示账号或密码错误。',
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
        message: '请先完成演示认证。',
      );
    }

    await Future<void>.delayed(simulatedDelay);
    try {
      final courses = parser.parse(
        const ZfTimetableResponseDto(
          body: zfDemoTimetableFixture,
          contentType: 'application/json; charset=utf-8',
        ),
      );
      return ImportedTimetable(
        sourceName: displayName,
        term: term,
        entries: courses.map(_toImportedEntry),
      );
    } on ZfException catch (error) {
      throw _toImportException(error);
    } on Object catch (error) {
      throw TimetableImportException(
        kind: TimetableImportFailureKind.parseFailed,
        message: '演示课表解析失败。',
        cause: error,
      );
    }
  }

  @override
  Future<void> signOut() async {
    _authStatus = const ImportAuthStatus.notStarted();
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

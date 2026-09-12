import 'package:flutter_test/flutter_test.dart';
import 'package:schedulr/features/import_timetable/domain/import_timetable.dart';
import 'package:schedulr/integrations/zfsoft/zfsoft.dart';

void main() {
  test('模拟认证、拉取和解析完整流程', () async {
    final importer = MockZfTimetableImporter(simulatedDelay: Duration.zero);

    expect(importer.authStatus.kind, ImportAuthStatusKind.notStarted);
    final status = await importer.authenticate(
      const CredentialAuthRequest(username: 'demo', password: 'demo'),
    );
    expect(status.isAuthenticated, isTrue);

    final result = await importer.fetchTimetable(
      const ImportTermRequest(academicYear: '2026-2027', term: 1),
    );

    expect(result.sourceName, contains('演示'));
    expect(result.entries, hasLength(3));
    expect(result.entries.first.externalId, 'demo-linear-algebra');
    expect(result.entries.first.weeks, containsAll(<int>[1, 8]));

    await importer.signOut();
    expect(importer.authStatus.kind, ImportAuthStatusKind.notStarted);
  });

  test('错误演示凭据返回明确的通用错误类型', () async {
    final importer = MockZfTimetableImporter(simulatedDelay: Duration.zero);

    await expectLater(
      importer.authenticate(
        const CredentialAuthRequest(username: 'wrong', password: 'secret'),
      ),
      throwsA(
        isA<TimetableImportException>().having(
          (error) => error.kind,
          'kind',
          TimetableImportFailureKind.invalidCredentials,
        ),
      ),
    );
    expect(importer.authStatus.kind, ImportAuthStatusKind.failed);
  });

  test('未认证拉取返回认证过期错误', () async {
    final importer = MockZfTimetableImporter(simulatedDelay: Duration.zero);

    await expectLater(
      importer.fetchTimetable(
        const ImportTermRequest(academicYear: '2026-2027', term: 1),
      ),
      throwsA(
        isA<TimetableImportException>().having(
          (error) => error.kind,
          'kind',
          TimetableImportFailureKind.authenticationExpired,
        ),
      ),
    );
  });

  test('Mock importer 拒绝非演示学校 profile', () {
    final realLikeProfile = ZfSchoolProfile(
      id: 'not-supported',
      displayName: '未支持学校',
      baseUri: Uri.parse('https://example.invalid'),
      authStrategy: ZfAuthStrategy.credentialForm,
      loginPath: '/login',
      timetableEndpoint: const ZfTimetableEndpoint(path: '/timetable'),
    );

    expect(
      () => MockZfTimetableImporter(profile: realLikeProfile),
      throwsA(
        isA<ZfException>().having(
          (error) => error.kind,
          'kind',
          ZfFailureKind.unsupportedProfile,
        ),
      ),
    );
  });
}

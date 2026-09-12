import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:schedulr/features/import_timetable/domain/import_timetable.dart';
import 'package:schedulr/integrations/zfsoft/zfsoft.dart';

void main() {
  test('BITC profile 配置 Web 会话和已验证端点参数', () {
    final profile = ZfSchoolProfile.bitc;

    expect(profile.isDemo, isFalse);
    expect(profile.authStrategy, ZfAuthStrategy.webSession);
    expect(profile.baseUri, Uri.parse('https://jwxt.vpn.bitc.edu.cn'));
    expect(
      profile.loginPath,
      '/kbcx/xskbcx_cxXskbcxIndex.html?gnmkdm=N2151&layout=default',
    );
    expect(profile.timetableEndpoint.path, '/kbcx/xskbcx_cxXsgrkb.html');
    expect(profile.timetableEndpoint.method, ZfHttpMethod.post);
    expect(profile.timetableEndpoint.academicYearParameter, 'xnm');
    expect(profile.timetableEndpoint.termParameter, 'xqm');
    expect(profile.timetableEndpoint.fixedParameters, {
      'kzlx': 'ck',
      'xsdm': '',
    });
  });

  test('学期代码映射为 BITC xnm/xqm', () {
    expect(
      BitcZfTimetableImporter.toProtocolTerm(
        const ImportTermRequest(academicYear: '2026-2027', term: 1),
      ).academicYear,
      '2026',
    );
    expect(
      BitcZfTimetableImporter.toProtocolTerm(
        const ImportTermRequest(academicYear: '2026-2027', term: 1),
      ).term,
      3,
    );
    expect(
      BitcZfTimetableImporter.toProtocolTerm(
        const ImportTermRequest(academicYear: '2026', term: 2),
      ).term,
      12,
    );
    expect(
      BitcZfTimetableImporter.toProtocolTerm(
        const ImportTermRequest(academicYear: '2026', term: 3),
      ).term,
      16,
    );
  });

  test('Web auth 后传入协议学期并生成无固定时间 warning', () async {
    ImportTermRequest? fetchedTerm;
    final importer = BitcZfTimetableImporter(
      fetchPayload: (term) async {
        fetchedTerm = term;
        return _fixturePayload();
      },
    );

    final status = await importer.authenticate(
      const BrowserSessionAuthRequest(),
    );
    expect(status.isAuthenticated, isTrue);

    final result = await importer.fetchTimetable(
      const ImportTermRequest(academicYear: '2026-2027', term: 2),
    );

    expect(fetchedTerm?.academicYear, '2026');
    expect(fetchedTerm?.term, 12);
    expect(result.term.academicYear, '2026-2027');
    expect(result.entries, hasLength(3));
    expect(result.calendar?.startDate, DateTime(2026, 9, 7));
    expect(result.calendar?.teachingWeeks, isNull);
    expect(result.issues, hasLength(1));
    expect(result.issues.single.code, ImportIssueCode.unsupportedSourceData);
    expect(result.issues.single.severity, ImportIssueSeverity.warning);
    expect(result.issues.single.message, contains('1'));
    expect(result.issues.single.message, isNot(contains('课程名')));
  });

  test('合并 parser 校历 warning 和无固定时间 warning', () async {
    final importer = BitcZfTimetableImporter(
      fetchPayload: (term) async => '''
        {
          "kbList": [{
            "jxb_id": "demo-warning",
            "kch": "DEMO-WARNING",
            "kcmc": "告警测试课程（虚构）",
            "xqj": 1,
            "jcs": "1-2",
            "zcd": "1周"
          }],
          "sjkList": [{}],
          "rqazcList": [{
            "rq": "2026-09-21",
            "xqj": 1
          }]
        }
      ''',
    );
    await importer.authenticate(const BrowserSessionAuthRequest());

    final result = await importer.fetchTimetable(
      const ImportTermRequest(academicYear: '2026-2027', term: 1),
    );

    expect(result.calendar, isNull);
    expect(
      result.issues.map((issue) => issue.message),
      containsAll([contains('教学周次'), contains('1 门')]),
    );
  });

  test('未 Web auth 时拒绝 fetch 且不调用 closure', () async {
    var called = false;
    final importer = BitcZfTimetableImporter(
      fetchPayload: (term) async {
        called = true;
        return _fixturePayload();
      },
    );

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
    expect(called, isFalse);
  });

  test('拒绝非 BrowserSessionAuthRequest', () async {
    final importer = BitcZfTimetableImporter(
      fetchPayload: (term) async => _fixturePayload(),
    );

    await expectLater(
      importer.authenticate(
        const CredentialAuthRequest(username: 'not-used', password: 'not-used'),
      ),
      throwsA(
        isA<TimetableImportException>().having(
          (error) => error.kind,
          'kind',
          TimetableImportFailureKind.authenticationExpired,
        ),
      ),
    );
    expect(importer.authStatus.kind, ImportAuthStatusKind.failed);
  });

  test('登录 HTML 统一映射异常并清除认证状态', () async {
    final importer = BitcZfTimetableImporter(
      fetchPayload: (term) async =>
          '<html><body><form action="/iam/login">登录</form></body></html>',
    );
    await importer.authenticate(const BrowserSessionAuthRequest());

    await expectLater(
      importer.fetchTimetable(
        const ImportTermRequest(academicYear: '2026', term: 1),
      ),
      throwsA(
        isA<TimetableImportException>().having(
          (error) => error.kind,
          'kind',
          TimetableImportFailureKind.authenticationExpired,
        ),
      ),
    );
    expect(importer.authStatus.kind, ImportAuthStatusKind.notStarted);
  });

  test('signOut 清除 Web 会话可用标记', () async {
    final importer = BitcZfTimetableImporter(
      fetchPayload: (term) async => _fixturePayload(),
    );
    await importer.authenticate(const BrowserSessionAuthRequest());

    await importer.signOut();

    expect(importer.authStatus.kind, ImportAuthStatusKind.notStarted);
    await expectLater(
      importer.fetchTimetable(
        const ImportTermRequest(academicYear: '2026', term: 1),
      ),
      throwsA(isA<TimetableImportException>()),
    );
  });
}

String _fixturePayload() {
  return File(
    'lib/integrations/zfsoft/fixtures/bitc_v9_timetable_sanitized.json',
  ).readAsStringSync();
}

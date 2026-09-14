import 'package:flutter_test/flutter_test.dart';
import 'package:schedulr/features/import_timetable/presentation/bitc/bitc_web_session_page.dart';

void main() {
  test('BITC 账号预填脚本只写账号且不读取密码或回传字段', () {
    final script = buildBitcAccountPrefillScript('student-001');

    expect(script, contains('student-001'));
    expect(script, contains("element.type !== 'password'"));
    expect(script, contains('field.value = account'));
    expect(script, isNot(contains('SchedulrBridge.postMessage')));
    expect(script, isNot(contains('document.cookie')));
    expect(script, isNot(contains('input[type="password"]')));
    expect(buildBitcAccountPrefillScript('   '), isEmpty);
  });

  test('BITC bridge 只传递课程和校历白名单字段', () {
    final script = buildBitcTimetableBridgeScript(
      academicYearStart: '2026',
      termCode: '3',
    );

    for (final field in <String>[
      'jxb_id',
      'kch',
      'kcmc',
      'xm',
      'xqj',
      'jcs',
      'jcor',
      'zcd',
      'xqmc',
      'cdmc',
      'rq',
      'zc',
    ]) {
      expect(script, contains("'$field'"));
    }
    expect(script, contains('rawPayload.rqazcList'));
    expect(script, contains('rawPayload.zs'));

    for (final personalField in <String>[
      'xsxx',
      'xh',
      'xsmc',
      'sjhm',
      'sfzh',
      'email',
    ]) {
      expect(script, isNot(contains("'$personalField'")));
    }
  });

  test('BITC bridge 校历锚点仅允许 rq、xqj、zc', () {
    final script = buildBitcTimetableBridgeScript(
      academicYearStart: '2026',
      termCode: '12',
    );

    expect(script, contains("const calendarKeys = ['rq', 'xqj', 'zc'];"));
    expect(script, contains('typeof rawPayload.zs'));
    expect(script, contains("'boolean'"));
    expect(script, contains('rawPayload.zs === null'));
    expect(script, isNot(contains('rawPayload.qsxqj')));
  });

  test('BITC bridge 使用批准端点、逐校区参数和安全 profile id', () {
    final script = buildBitcTimetableBridgeScript(
      academicYearStart: '2026',
      termCode: '3',
    );

    expect(script, contains('/kbcx/xskbcx_cxRsd.html?gnmkdm=N2151'));
    expect(script, contains('/kbcx/xskbcx_cxRjc.html?gnmkdm=N2151'));
    expect(script, contains('xnm:'));
    expect(script, contains('xqm:'));
    expect(script, contains('xqh_id: campus.sourceId'));
    expect(script, contains("id: 'profile-' + index"));
    expect(script, contains('timingProfileId'));
    expect(script, contains("'xm'"));
    expect(script, isNot(contains('queryModel')));
    expect(script, isNot(contains('userModel')));
    expect(script, isNot(contains('cookie')));
  });
}

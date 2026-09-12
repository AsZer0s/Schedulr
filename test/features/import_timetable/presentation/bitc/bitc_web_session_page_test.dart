import 'package:flutter_test/flutter_test.dart';
import 'package:schedulr/features/import_timetable/presentation/bitc/bitc_web_session_page.dart';

void main() {
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
}

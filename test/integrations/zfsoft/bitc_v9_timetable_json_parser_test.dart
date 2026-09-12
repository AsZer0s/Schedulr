import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:schedulr/features/import_timetable/domain/import_timetable.dart';
import 'package:schedulr/integrations/zfsoft/zfsoft.dart';

void main() {
  const parser = BitcV9TimetableJsonParser();

  test('解析同教学班 sourceId、复杂周次、节次和纯文本课程名', () {
    final result = parser.parseResult(_fixtureResponse());

    expect(result.courses, hasLength(3));
    expect(result.unscheduledCourseCount, 1);
    expect(result.calendar?.startDate, DateTime(2026, 9, 7));
    expect(result.calendar?.teachingWeeks, isNull);
    expect(result.calendarIssues, isEmpty);

    final first = result.courses[0];
    final second = result.courses[1];
    expect(first.sourceId, 'demo-class-orbit-01');
    expect(second.sourceId, first.sourceId);
    expect(first.name, '星云导航导论（虚构）');
    expect(first.name, isNot(contains('<span>')));
    expect(first.startPeriod, 1);
    expect(first.endPeriod, 2);
    expect(first.weeks, {2, 4, 5, 7, 8, 9, 10, 11, 12, 13, 14});
    expect(second.weeks, {1, 3, 5, 7, 9});

    final fallback = result.courses[2];
    expect(fallback.sourceId, 'DEMO-202::量子园艺实践（虚构）');
    expect(fallback.teacher, isNull);
    expect(fallback.location, isNull);
    expect(fallback.weeks, {1, 2, 3, 6, 10, 12});
  });

  test('row.zc 支持数字和字符串且多个锚点推导一致', () {
    final result = parser.parseResult(
      _responseWithCalendar(
        rqazcList: [
          {'rq': '2026-09-21', 'xqj': '1', 'zc': '3'},
          {'rq': '2026-09-27', 'xqj': 7, 'zc': 3},
        ],
        extra: {'qsxqj': 6},
      ),
    );

    expect(result.calendar?.startDate, DateTime(2026, 9, 7));
    expect(result.calendarIssues, isEmpty);
  });

  test('缺 row.zc 时使用 top-level zs 数字或字符串', () {
    for (final zs in <Object>[3, '3']) {
      final result = parser.parseResult(
        _responseWithCalendar(
          rqazcList: [
            {'rq': '2026-09-22', 'xqj': 2},
          ],
          extra: {'zs': zs, 'qsxqj': 7},
        ),
      );

      expect(result.calendar?.startDate, DateTime(2026, 9, 7));
      expect(result.calendarIssues, isEmpty);
    }
  });

  test('日期与星期不一致时 warning 且不返回 calendar', () {
    final result = parser.parseResult(
      _responseWithCalendar(
        rqazcList: [
          {'rq': '2026-09-21', 'xqj': 2, 'zc': 3},
        ],
      ),
    );

    expect(result.calendar, isNull);
    expect(
      result.calendarIssues.map((issue) => issue.message),
      contains(contains('星期')),
    );
  });

  test('多个有效锚点推导冲突时 warning 且不返回 calendar', () {
    final result = parser.parseResult(
      _responseWithCalendar(
        rqazcList: [
          {'rq': '2026-09-21', 'xqj': 1, 'zc': 3},
          {'rq': '2026-09-28', 'xqj': 1, 'zc': 3},
        ],
      ),
    );

    expect(result.calendar, isNull);
    expect(
      result.calendarIssues.map((issue) => issue.message),
      contains(contains('冲突')),
    );
  });

  test('缺少周次时 warning 且不把 qsxqj 当作当前周', () {
    final result = parser.parseResult(
      _responseWithCalendar(
        rqazcList: [
          {'rq': '2026-09-21', 'xqj': 1},
        ],
        extra: {'qsxqj': 3},
      ),
    );

    expect(result.calendar, isNull);
    expect(
      result.calendarIssues.map((issue) => issue.message),
      contains(contains('缺少教学周次')),
    );
  });

  test('无 rqazcList 时课程照常解析并返回 UI-safe warning', () {
    final result = parser.parseResult(_responseWithCalendar());

    expect(result.courses, hasLength(1));
    expect(result.calendar, isNull);
    expect(result.calendarIssues, isNotEmpty);
    expect(
      result.calendarIssues,
      everyElement(
        isA<ImportIssue>()
            .having(
              (issue) => issue.severity,
              'severity',
              ImportIssueSeverity.warning,
            )
            .having(
              (issue) => issue.code,
              'code',
              ImportIssueCode.invalidSourceData,
            ),
      ),
    );
  });

  test('识别 Web 会话失效的 HTML 登录页', () {
    const response = ZfTimetableResponseDto(
      body: '<!doctype html><html><body><form action="https://vpn.bitc.edu.cn/iam/login">登录</form></body></html>',
      contentType: 'text/html; charset=utf-8',
    );

    expect(
      () => parser.parse(response),
      throwsA(
        isA<ZfException>().having(
          (error) => error.kind,
          'kind',
          ZfFailureKind.authenticationExpired,
        ),
      ),
    );
  });

  test('非 JSON 响应返回明确布局错误', () {
    const response = ZfTimetableResponseDto(
      body: 'not-json',
      contentType: 'text/plain',
    );

    expect(
      () => parser.parse(response),
      throwsA(
        isA<ZfException>().having(
          (error) => error.kind,
          'kind',
          ZfFailureKind.unsupportedLayout,
        ),
      ),
    );
  });

  test('缺少 kbList 等字段返回 malformedResponse', () {
    const response = ZfTimetableResponseDto(
      body: '{"sjkList":[]}',
      contentType: 'application/json',
    );

    expect(
      () => parser.parse(response),
      throwsA(
        isA<ZfException>()
            .having(
              (error) => error.kind,
              'kind',
              ZfFailureKind.malformedResponse,
            )
            .having((error) => error.message, 'message', contains('kbList')),
      ),
    );
  });
}

ZfTimetableResponseDto _responseWithCalendar({
  List<Map<String, Object?>>? rqazcList,
  Map<String, Object?> extra = const {},
}) {
  final payload = <String, Object?>{
    'kbList': [
      {
        'jxb_id': 'calendar-test-course',
        'kch': 'DEMO-CALENDAR',
        'kcmc': '校历测试课程（虚构）',
        'xqj': 1,
        'jcs': '1-2',
        'zcd': '1-2周',
      },
    ],
    'sjkList': <Object?>[],
    ...extra,
  };
  if (rqazcList != null) payload['rqazcList'] = rqazcList;
  return ZfTimetableResponseDto(
    body: jsonEncode(payload),
    contentType: 'application/json',
  );
}

ZfTimetableResponseDto _fixtureResponse() {
  final body = File(
    'lib/integrations/zfsoft/fixtures/bitc_v9_timetable_sanitized.json',
  ).readAsStringSync();
  return ZfTimetableResponseDto(
    body: body,
    contentType: 'application/json; charset=utf-8',
  );
}

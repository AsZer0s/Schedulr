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

  test('解析 10 节 4/4/2 profile、规范化时间并关联课程', () {
    final result = parser.parseResult(
      _timingResponse(periodCount: 10, groupCounts: const [4, 4, 2]),
    );

    expect(result.timingIssues, isEmpty);
    expect(result.timingProfiles, hasLength(1));
    final schedule = result.timingProfiles.single.schedule!;
    expect(schedule.periods, hasLength(10));
    expect(schedule.periods.first.startTime, '08:00');
    expect(schedule.countFor(ImportedPeriodGroup.morning), 4);
    expect(schedule.countFor(ImportedPeriodGroup.afternoon), 4);
    expect(schedule.countFor(ImportedPeriodGroup.evening), 2);
    expect(result.courses.single.timingProfileId, 'profile-0');
  });

  test('支持 8/12 节与数字或字符串节次', () {
    for (final count in [8, 12]) {
      final result = parser.parseResult(
        _timingResponse(
          periodCount: count,
          groupCounts: count == 8 ? const [4, 4, 0] : const [4, 4, 4],
          numberAsString: count == 12,
        ),
      );
      expect(result.timingProfiles.single.schedule!.periods, hasLength(count));
    }
  });

  test('重复、倒置、count、group 和课程覆盖问题使 profile invalid', () {
    for (final mutation in [
      'duplicate',
      'inverted',
      'overlap',
      'count',
      'group',
      'groupOrder',
      'coverage',
    ]) {
      final result = parser.parseResult(
        _timingResponse(
          periodCount: 10,
          groupCounts: const [4, 4, 2],
          mutation: mutation,
        ),
      );
      expect(result.timingProfiles.single.schedule, isNull, reason: mutation);
      expect(result.timingIssues, isNotEmpty, reason: mutation);
    }
  });

  test('多个 profile 保持顺序且可包含失败 profile', () {
    final payload = jsonDecode(
      _timingResponse(periodCount: 10, groupCounts: const [4, 4, 2]).body,
    ) as Map<String, Object?>;
    final first = (payload['timingProfiles'] as List).single;
    payload['timingProfiles'] = [
      first,
      {'id': 'profile-1', 'name': '月湾校区（虚构）', 'warning': '学校作息接口请求失败'},
    ];
    final result = parser.parseResult(
      ZfTimetableResponseDto(
        body: jsonEncode(payload),
        contentType: 'application/json',
      ),
    );
    expect(result.timingProfiles.map((profile) => profile.id), [
      'profile-0',
      'profile-1',
    ]);
    expect(result.timingProfiles.last.schedule, isNull);
    expect(result.timingIssues, isNotEmpty);
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

ZfTimetableResponseDto _timingResponse({
  required int periodCount,
  required List<int> groupCounts,
  bool numberAsString = false,
  String? mutation,
}) {
  final groups = <Map<String, Object?>>[];
  final labels = ['上午', '下午', '晚上'];
  for (var index = 0; index < groupCounts.length; index += 1) {
    if (groupCounts[index] == 0) continue;
    groups.add({
      'code': 'g$index',
      'name': labels[index],
      'count': mutation == 'count' && index == 0
          ? groupCounts[index] + 1
          : groupCounts[index],
    });
  }
  final periods = <Map<String, Object?>>[];
  var number = 1;
  for (var group = 0; group < groupCounts.length; group += 1) {
    for (var offset = 0; offset < groupCounts[group]; offset += 1) {
      final hour = 8 + number;
      periods.add({
        'number': numberAsString ? '$number' : number,
        'startTime': number == 1
            ? '8:00'
            : '${hour.toString().padLeft(2, '0')}:00',
        'endTime': mutation == 'inverted' && number == 1
            ? '07:45'
            : (number == 1 ? '8:45' : '${hour.toString().padLeft(2, '0')}:45'),
        'groupCode': mutation == 'group' && number == 1 ? 'missing' : 'g$group',
      });
      number += 1;
    }
  }
  if (mutation == 'duplicate') periods[1]['number'] = periods[0]['number'];
  if (mutation == 'overlap') periods[1]['startTime'] = '8:30';
  if (mutation == 'groupOrder') {
    periods[3]['groupCode'] = 'g1';
    periods[4]['groupCode'] = 'g0';
  }
  return ZfTimetableResponseDto(
    body: jsonEncode({
      'kbList': [
        {
          'jxb_id': 'fictional-course',
          'kch': 'FICTION-101',
          'kcmc': '星际园艺（虚构）',
          'xm': '虚构教师',
          'xqj': 1,
          'jcs': mutation == 'coverage' ? '1-${periodCount + 1}' : '1-2',
          'zcd': '1-2周',
          'timingProfileId': 'profile-0',
        },
      ],
      'sjkList': <Object?>[],
      'timingProfiles': [
        {
          'id': 'profile-0',
          'name': '星河校区（虚构）',
          'groups': groups,
          'periods': periods,
        },
      ],
    }),
    contentType: 'application/json',
  );
}

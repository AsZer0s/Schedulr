import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:schedulr/integrations/zfsoft/zfsoft.dart';

void main() {
  const parser = BitcV9TimetableJsonParser();

  test('解析同教学班 sourceId、复杂周次、节次和纯文本课程名', () {
    final result = parser.parseResult(_fixtureResponse());

    expect(result.courses, hasLength(3));
    expect(result.unscheduledCourseCount, 1);

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

ZfTimetableResponseDto _fixtureResponse() {
  final body = File(
    'lib/integrations/zfsoft/fixtures/bitc_v9_timetable_sanitized.json',
  ).readAsStringSync();
  return ZfTimetableResponseDto(
    body: body,
    contentType: 'application/json; charset=utf-8',
  );
}

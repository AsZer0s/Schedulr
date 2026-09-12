import 'package:flutter_test/flutter_test.dart';
import 'package:schedulr/integrations/zfsoft/zfsoft.dart';

void main() {
  const parser = ZfFixtureJsonParser();

  test('解析脱敏 JSON fixture', () {
    const response = ZfTimetableResponseDto(
      contentType: 'application/json',
      body: '''
      {
        "courses": [
          {
            "id": "demo-course",
            "name": "示例课程",
            "teacher": "示例教师",
            "weekday": 4,
            "periods": [4, 3],
            "weeks": [1, 3, 5]
          }
        ]
      }
      ''',
    );

    final result = parser.parse(response);

    expect(result, hasLength(1));
    expect(result.single.startPeriod, 3);
    expect(result.single.endPeriod, 4);
    expect(result.single.weeks, {1, 3, 5});
  });

  test('非 JSON 布局返回 unsupportedLayout', () {
    const response = ZfTimetableResponseDto(
      contentType: 'text/html',
      body: '<html></html>',
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

  test('畸形课程响应返回 malformedResponse', () {
    const response = ZfTimetableResponseDto(
      contentType: 'application/json',
      body: '{"courses":[{"id":"x"}]}',
    );

    expect(
      () => parser.parse(response),
      throwsA(
        isA<ZfException>().having(
          (error) => error.kind,
          'kind',
          ZfFailureKind.malformedResponse,
        ),
      ),
    );
  });

  test('端点状态错误保留 endpointRejected 分类', () {
    const response = ZfTimetableResponseDto(
      contentType: 'application/json',
      body: '{}',
      statusCode: 503,
    );

    expect(
      () => parser.parse(response),
      throwsA(
        isA<ZfException>()
            .having(
              (error) => error.kind,
              'kind',
              ZfFailureKind.endpointRejected,
            )
            .having((error) => error.statusCode, 'statusCode', 503),
      ),
    );
  });
}

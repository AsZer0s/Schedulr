import 'package:flutter_test/flutter_test.dart';
import 'package:schedulr/core/time/week_set.dart';

void main() {
  test('creates odd and even week ranges', () {
    expect(oddWeeks(1, 8), {1, 3, 5, 7});
    expect(evenWeeks(1, 8), {2, 4, 6, 8});
  });

  test('parses discontinuous and parity week expressions', () {
    expect(parseWeekExpression('1-4,7-9,12周'), {1, 2, 3, 4, 7, 8, 9, 12});
    expect(parseWeekExpression('1-8单, 10, 12'), {1, 3, 5, 7, 10, 12});
    expect(parseWeekExpression('2-10双'), {2, 4, 6, 8, 10});
  });

  test('formats discontinuous weeks into stable compact storage', () {
    const weeks = {1, 2, 3, 6, 8, 9, 10, 14};
    expect(formatWeekExpression(weeks), '1-3,6,8-10,14');
    expect(parseWeekExpression(formatWeekExpression(weeks)), weeks);
  });
}

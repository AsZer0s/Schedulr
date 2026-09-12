import 'package:flutter_test/flutter_test.dart';
import 'package:schedulr/features/import_timetable/presentation/bitc/bitc_term_mapping.dart';

void main() {
  test('maps BITC academic year and Zhengfang term codes', () {
    expect(BitcTermMapping.academicYearStart('2026-2027'), '2026');
    expect(BitcTermMapping.termCode(1), '3');
    expect(BitcTermMapping.termCode(2), '12');
    expect(BitcTermMapping.termCode(3), '16');
  });

  test('rejects invalid academic year and term', () {
    expect(
      () => BitcTermMapping.academicYearStart('2026'),
      throwsFormatException,
    );
    expect(() => BitcTermMapping.termCode(4), throwsRangeError);
  });
}

class BitcTermMapping {
  const BitcTermMapping._();

  static String academicYearStart(String academicYear) {
    final match = RegExp(r'^(\d{4})-\d{4}$').firstMatch(academicYear.trim());
    if (match == null) {
      throw FormatException('学年必须使用 YYYY-YYYY 格式。', academicYear);
    }
    return match.group(1)!;
  }

  static String termCode(int term) {
    return switch (term) {
      1 => '3',
      2 => '12',
      3 => '16',
      _ => throw RangeError.range(term, 1, 3, 'term'),
    };
  }
}

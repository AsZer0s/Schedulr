enum WeekParity { all, odd, even }

Set<int> weekRange(int start, int end, {WeekParity parity = WeekParity.all}) {
  if (start < 1 || end < start) {
    throw ArgumentError('Expected 1 <= start <= end.');
  }

  return {
    for (var week = start; week <= end; week++)
      if (_matchesParity(week, parity)) week,
  };
}

Set<int> oddWeeks(int start, int end) {
  return weekRange(start, end, parity: WeekParity.odd);
}

Set<int> evenWeeks(int start, int end) {
  return weekRange(start, end, parity: WeekParity.even);
}

Set<int> parseWeekExpression(String expression, {int? maximumWeek}) {
  final normalized = expression
      .replaceAll('，', ',')
      .replaceAll('、', ',')
      .replaceAll('－', '-')
      .replaceAll('—', '-')
      .replaceAll('至', '-')
      .replaceAll(RegExp(r'\s+'), '')
      .replaceAll('周', '');

  if (normalized.isEmpty) {
    return <int>{};
  }

  final result = <int>{};
  for (final rawPart in normalized.split(',')) {
    if (rawPart.isEmpty) {
      continue;
    }

    var part = rawPart;
    var parity = WeekParity.all;
    if (part.endsWith('单')) {
      parity = WeekParity.odd;
      part = part.substring(0, part.length - 1);
    } else if (part.endsWith('双')) {
      parity = WeekParity.even;
      part = part.substring(0, part.length - 1);
    }

    final rangeMatch = RegExp(r'^(\d+)-(\d+)$').firstMatch(part);
    if (rangeMatch != null) {
      final start = int.parse(rangeMatch.group(1)!);
      final end = int.parse(rangeMatch.group(2)!);
      result.addAll(weekRange(start, end, parity: parity));
      continue;
    }

    final week = int.tryParse(part);
    if (week == null || !_matchesParity(week, parity)) {
      throw FormatException('Invalid week expression segment.', rawPart);
    }
    if (week < 1) {
      throw FormatException('Week numbers must be positive.', rawPart);
    }
    result.add(week);
  }

  if (maximumWeek != null && result.any((week) => week > maximumWeek)) {
    throw RangeError('Week expression exceeds maximumWeek $maximumWeek.');
  }
  return result;
}

String formatWeekExpression(Set<int> weeks) {
  if (weeks.isEmpty) {
    return '';
  }

  final sorted = weeks.toList()..sort();
  final parts = <String>[];
  var start = sorted.first;
  var end = start;

  for (final week in sorted.skip(1)) {
    if (week == end + 1) {
      end = week;
      continue;
    }
    parts.add(start == end ? '$start' : '$start-$end');
    start = week;
    end = week;
  }
  parts.add(start == end ? '$start' : '$start-$end');
  return parts.join(',');
}

bool weeksOverlap(Set<int> first, Set<int> second) {
  final smaller = first.length <= second.length ? first : second;
  final larger = identical(smaller, first) ? second : first;
  return smaller.any(larger.contains);
}

bool _matchesParity(int week, WeekParity parity) {
  return switch (parity) {
    WeekParity.all => true,
    WeekParity.odd => week.isOdd,
    WeekParity.even => week.isEven,
  };
}

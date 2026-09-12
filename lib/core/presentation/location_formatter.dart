String? compactLocationLabel(String? location) {
  final raw = location?.trim();
  if (raw == null || raw.isEmpty) return null;

  final normalized = raw
      .replaceAll(RegExp(r'[－—–]'), '-')
      .replaceAll(RegExp(r'\s+'), ' ');

  final explicitBuildingMatches = RegExp(
    r'(?<!\d)(\d{1,3})\s*(?:号)?楼\s*[- ]?\s*(\d{2,4})\s*(?:室|教室)',
  ).allMatches(normalized).toList();
  if (explicitBuildingMatches.length == 1) {
    final match = explicitBuildingMatches.single;
    return '${match.group(1)}-${match.group(2)}';
  }
  if (explicitBuildingMatches.length > 1) return raw;

  final numericCandidates = <String>[];
  for (final match in RegExp(r'(\d{1,3})-(\d{2,4})').allMatches(normalized)) {
    if (_isPartOfLongNumericSequence(normalized, match.start, match.end)) {
      continue;
    }
    numericCandidates.add('${match.group(1)}-${match.group(2)}');
  }
  final uniqueNumericCandidates = numericCandidates.toSet();
  if (uniqueNumericCandidates.length == 1) {
    return uniqueNumericCandidates.single;
  }
  if (uniqueNumericCandidates.length > 1) return raw;

  final letterCandidates = RegExp(
    r'(?<![A-Za-z0-9])([A-Za-z])-(\d{2,4})(?![A-Za-z0-9-])',
  ).allMatches(normalized).toList();
  if (letterCandidates.length == 1) {
    final match = letterCandidates.single;
    return '${match.group(1)!.toUpperCase()}-${match.group(2)}';
  }

  return raw;
}

bool _isPartOfLongNumericSequence(String source, int start, int end) {
  final previous = start > 0 ? source[start - 1] : null;
  final next = end < source.length ? source[end] : null;
  return previous != null && RegExp(r'[\d-]').hasMatch(previous) ||
      next != null && RegExp(r'[\d-]').hasMatch(next);
}

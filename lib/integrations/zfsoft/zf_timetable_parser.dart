import 'dart:convert';

import 'zf_errors.dart';

final class ZfTimetableResponseDto {
  const ZfTimetableResponseDto({
    required this.body,
    required this.contentType,
    this.statusCode = 200,
  });

  final String body;
  final String contentType;
  final int statusCode;
}

final class ZfCourseDto {
  ZfCourseDto({
    required this.sourceId,
    required this.name,
    required this.weekday,
    required this.startPeriod,
    required this.endPeriod,
    required Iterable<int> weeks,
    this.teacher,
    this.location,
    this.notes,
    this.timingProfileId,
  }) : weeks = Set.unmodifiable(weeks);

  final String sourceId;
  final String name;
  final String? teacher;
  final String? location;
  final String? notes;
  final String? timingProfileId;
  final int weekday;
  final int startPeriod;
  final int endPeriod;
  final Set<int> weeks;
}

abstract interface class ZfTimetableParser {
  List<ZfCourseDto> parse(ZfTimetableResponseDto response);
}

/// Parser for a deliberately small, documented JSON interchange shape.
/// It is useful for sanitized fixtures and adapters, but does not claim to parse
/// arbitrary real Zhengfang deployments or HTML layouts.
final class ZfFixtureJsonParser implements ZfTimetableParser {
  const ZfFixtureJsonParser();

  @override
  List<ZfCourseDto> parse(ZfTimetableResponseDto response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ZfException(
        kind: ZfFailureKind.endpointRejected,
        message: '课表端点返回非成功状态。',
        statusCode: response.statusCode,
      );
    }
    if (!response.contentType.toLowerCase().contains('json')) {
      throw const ZfException(
        kind: ZfFailureKind.unsupportedLayout,
        message: '当前解析器只接受脱敏 JSON fixture 格式。',
      );
    }

    try {
      final value = _decodeJson(response.body);
      if (value is! Map<String, Object?>) {
        throw const FormatException('Root must be an object');
      }
      final courses = value['courses'];
      if (courses is! List<Object?>) {
        throw const FormatException('courses must be an array');
      }
      return List.unmodifiable(courses.map(_parseCourse));
    } on ZfException {
      rethrow;
    } on Object catch (error) {
      throw ZfException(
        kind: ZfFailureKind.malformedResponse,
        message: '课表数据格式无效。',
        cause: error,
      );
    }
  }

  ZfCourseDto _parseCourse(Object? value) {
    if (value is! Map<String, Object?>) {
      throw const FormatException('Course must be an object');
    }
    final periods = _requiredIntList(value, 'periods');
    final weeks = _requiredIntList(value, 'weeks').toSet();
    if (periods.isEmpty || weeks.isEmpty) {
      throw const FormatException('periods and weeks must not be empty');
    }
    periods.sort();
    return ZfCourseDto(
      sourceId: _requiredString(value, 'id'),
      name: _requiredString(value, 'name'),
      teacher: _optionalString(value, 'teacher'),
      location: _optionalString(value, 'location'),
      notes: _optionalString(value, 'notes'),
      weekday: _requiredInt(value, 'weekday'),
      startPeriod: periods.first,
      endPeriod: periods.last,
      weeks: weeks,
    );
  }

  Object? _decodeJson(String source) {
    // Kept behind a helper so this parser remains easy to replace with a
    // school-specific adapter without changing its interface.
    return jsonDecode(source);
  }

  String _requiredString(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('$key must be a non-empty string');
    }
    return value;
  }

  String? _optionalString(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value == null) return null;
    if (value is! String) throw FormatException('$key must be a string');
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  int _requiredInt(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is! int) throw FormatException('$key must be an integer');
    return value;
  }

  List<int> _requiredIntList(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is! List<Object?> || value.any((item) => item is! int)) {
      throw FormatException('$key must be an integer array');
    }
    return value.cast<int>().toList();
  }
}

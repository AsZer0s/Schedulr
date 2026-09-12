import 'dart:convert';

import 'package:html/parser.dart' as html_parser;

import '../../features/import_timetable/domain/import_timetable.dart';
import 'zf_errors.dart';
import 'zf_timetable_parser.dart';

final class BitcV9TimetableParseResult {
  BitcV9TimetableParseResult({
    required Iterable<ZfCourseDto> courses,
    required this.unscheduledCourseCount,
    this.calendar,
    Iterable<ImportIssue> calendarIssues = const [],
  }) : courses = List.unmodifiable(courses),
       calendarIssues = List.unmodifiable(calendarIssues);

  final List<ZfCourseDto> courses;
  final int unscheduledCourseCount;
  final ImportedSemesterCalendar? calendar;
  final List<ImportIssue> calendarIssues;
}

/// Parser for the verified BITC Zhengfang V9 personal timetable JSON response.
final class BitcV9TimetableJsonParser implements ZfTimetableParser {
  const BitcV9TimetableJsonParser();

  @override
  List<ZfCourseDto> parse(ZfTimetableResponseDto response) {
    return parseResult(response).courses;
  }

  BitcV9TimetableParseResult parseResult(ZfTimetableResponseDto response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ZfException(
        kind: ZfFailureKind.endpointRejected,
        message: 'BITC 课表端点返回非成功状态。',
        statusCode: response.statusCode,
      );
    }

    final body = response.body.trim();
    if (_looksLikeHtml(body)) {
      if (_looksLikeLoginPage(body)) {
        throw const ZfException(
          kind: ZfFailureKind.authenticationExpired,
          message: 'BITC Web 会话未登录或已失效。',
        );
      }
      throw const ZfException(
        kind: ZfFailureKind.unsupportedLayout,
        message: 'BITC 课表端点返回了 HTML，而不是 JSON。',
      );
    }
    if (!response.contentType.toLowerCase().contains('json')) {
      throw const ZfException(
        kind: ZfFailureKind.unsupportedLayout,
        message: 'BITC 课表响应不是 JSON。',
      );
    }

    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map) {
        throw const FormatException('响应顶层必须是对象');
      }
      final root = decoded.cast<String, Object?>();
      final kbList = _requiredObjectList(root, 'kbList');
      final sjkList = _requiredObjectList(root, 'sjkList');
      final calendarResult = _parseCalendar(root);
      return BitcV9TimetableParseResult(
        courses: kbList.map(_parseCourse),
        unscheduledCourseCount: sjkList.length,
        calendar: calendarResult.calendar,
        calendarIssues: calendarResult.issues,
      );
    } on ZfException {
      rethrow;
    } on FormatException catch (error) {
      throw ZfException(
        kind: ZfFailureKind.malformedResponse,
        message: 'BITC 课表 JSON 字段格式无效：${error.message}',
        cause: error,
      );
    } on Object catch (error) {
      throw ZfException(
        kind: ZfFailureKind.malformedResponse,
        message: 'BITC 课表响应不是有效 JSON。',
        cause: error,
      );
    }
  }

  _CalendarParseResult _parseCalendar(Map<String, Object?> root) {
    final issues = <ImportIssue>[];
    final rawAnchors = root['rqazcList'];
    if (rawAnchors == null) {
      issues.add(_calendarWarning('未提供可验证的校历日期，已保留本地开学日期。'));
      return _CalendarParseResult(issues: issues);
    }
    if (rawAnchors is! List) {
      issues.add(_calendarWarning('校历日期格式无效，已保留本地开学日期。'));
      return _CalendarParseResult(issues: issues);
    }

    final topLevelWeek = _positiveInt(root['zs']);
    if (root.containsKey('zs') && root['zs'] != null && topLevelWeek == null) {
      issues.add(_calendarWarning('校历当前周次无效，已忽略该字段。'));
    }

    final inferredStartDates = <DateTime>{};
    var missingWeek = false;
    var invalidDate = false;
    var invalidWeekday = false;
    var invalidWeek = false;

    for (final value in rawAnchors) {
      if (value is! Map) {
        invalidDate = true;
        continue;
      }
      final anchor = value.cast<Object?, Object?>();
      final date = _calendarDate(anchor['rq']);
      final weekday = _boundedInt(anchor['xqj'], minimum: 1, maximum: 7);
      final hasRowWeek = anchor.containsKey('zc') && anchor['zc'] != null;
      final rowWeek = _positiveInt(anchor['zc']);
      final week = hasRowWeek ? rowWeek : topLevelWeek;

      if (date == null) invalidDate = true;
      if (weekday == null) invalidWeekday = true;
      if (hasRowWeek && rowWeek == null) invalidWeek = true;
      if (!hasRowWeek && topLevelWeek == null) missingWeek = true;
      if (date == null || weekday == null || week == null) continue;
      if (date.weekday != weekday) {
        invalidWeekday = true;
        continue;
      }

      final daysFromSemesterStart = weekday - 1 + (week - 1) * 7;
      inferredStartDates.add(
        _subtractCalendarDays(date, daysFromSemesterStart),
      );
    }

    if (invalidDate) {
      issues.add(_calendarWarning('部分校历日期无效，已忽略对应日期锚点。'));
    }
    if (invalidWeekday) {
      issues.add(_calendarWarning('部分校历星期无效或与日期不一致，已忽略对应日期锚点。'));
    }
    if (invalidWeek) {
      issues.add(_calendarWarning('部分校历周次无效，已忽略对应日期锚点。'));
    }
    if (missingWeek) {
      issues.add(_calendarWarning('校历日期缺少教学周次，无法据此定位开学日期。'));
    }
    if (inferredStartDates.isEmpty) {
      issues.add(_calendarWarning('没有可验证的校历日期锚点，已保留本地开学日期。'));
      return _CalendarParseResult(issues: issues);
    }
    if (inferredStartDates.length > 1) {
      issues.add(_calendarWarning('校历日期锚点推导结果冲突，已保留本地开学日期。'));
      return _CalendarParseResult(issues: issues);
    }

    return _CalendarParseResult(
      calendar: ImportedSemesterCalendar(startDate: inferredStartDates.single),
      issues: issues,
    );
  }

  ImportIssue _calendarWarning(String message) {
    return ImportIssue(
      code: ImportIssueCode.invalidSourceData,
      message: message,
      severity: ImportIssueSeverity.warning,
    );
  }

  DateTime? _calendarDate(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(trimmed);
    if (match == null) return null;
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return date;
  }

  DateTime _subtractCalendarDays(DateTime date, int days) {
    return DateTime(date.year, date.month, date.day - days);
  }

  int? _positiveInt(Object? value) {
    final parsed = switch (value) {
      final int number => number,
      final String text => int.tryParse(text.trim()),
      _ => null,
    };
    return parsed != null && parsed > 0 ? parsed : null;
  }

  int? _boundedInt(
    Object? value, {
    required int minimum,
    required int maximum,
  }) {
    final parsed = switch (value) {
      final int number => number,
      final String text => int.tryParse(text.trim()),
      _ => null,
    };
    if (parsed == null || parsed < minimum || parsed > maximum) return null;
    return parsed;
  }

  ZfCourseDto _parseCourse(Object? value) {
    if (value is! Map) {
      throw const FormatException('kbList 项必须是对象');
    }
    final course = value.cast<String, Object?>();
    final name = _plainTextName(_requiredString(course, 'kcmc'));
    final teachingClassId = _optionalString(course, 'jxb_id');
    final sourceId =
        teachingClassId ?? '${_requiredString(course, 'kch')}::$name';
    final periods = _parsePeriods(
      _optionalString(course, 'jcs') ?? _requiredString(course, 'jcor'),
    );

    return ZfCourseDto(
      sourceId: sourceId,
      name: name,
      teacher: _optionalString(course, 'xm'),
      location: _location(course),
      weekday: _requiredInt(course, 'xqj', minimum: 1, maximum: 7),
      startPeriod: periods.$1,
      endPeriod: periods.$2,
      weeks: _parseWeeks(_requiredString(course, 'zcd')),
    );
  }

  List<Object?> _requiredObjectList(Map<String, Object?> root, String key) {
    final value = root[key];
    if (value is! List) {
      throw FormatException('$key 必须是数组');
    }
    return value.cast<Object?>();
  }

  String _requiredString(Map<String, Object?> map, String key) {
    final value = _optionalString(map, key);
    if (value == null) {
      throw FormatException('$key 必须是非空字符串');
    }
    return value;
  }

  String? _optionalString(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value == null) return null;
    if (value is! String) {
      throw FormatException('$key 必须是字符串');
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  int _requiredInt(
    Map<String, Object?> map,
    String key, {
    required int minimum,
    required int maximum,
  }) {
    final parsed = _boundedInt(map[key], minimum: minimum, maximum: maximum);
    if (parsed == null) {
      throw FormatException('$key 必须是 $minimum-$maximum 的整数');
    }
    return parsed;
  }

  String _plainTextName(String rawName) {
    final name = (html_parser.parseFragment(rawName).text ?? '').trim();
    if (name.isEmpty) {
      throw const FormatException('kcmc 去除 HTML 后不能为空');
    }
    return name;
  }

  String? _location(Map<String, Object?> course) {
    final campus = _optionalString(course, 'xqmc');
    final room = _optionalString(course, 'cdmc');
    if (campus == null) return room;
    if (room == null) return campus;
    return '$campus · $room';
  }

  (int, int) _parsePeriods(String source) {
    final matches = RegExp(r'\d+').allMatches(source).toList();
    if (matches.isEmpty || matches.length > 2) {
      throw FormatException('jcs/jcor 节次格式无效：$source');
    }
    final start = int.parse(matches.first.group(0)!);
    final end = matches.length == 1 ? start : int.parse(matches.last.group(0)!);
    if (start < 1 || end < start) {
      throw FormatException('jcs/jcor 节次范围无效：$source');
    }
    return (start, end);
  }

  Set<int> _parseWeeks(String source) {
    final weeks = <int>{};
    final parts = source
        .replaceAll('，', ',')
        .split(',')
        .map((part) => part.replaceAll(RegExp(r'\s+'), ''))
        .where((part) => part.isNotEmpty);
    final pattern = RegExp(r'^(\d+)(?:-(\d+))?周(?:\(([单双])\))?$');

    for (final part in parts) {
      final match = pattern.firstMatch(part);
      if (match == null) {
        throw FormatException('zcd 周次格式无效：$part');
      }
      final start = int.parse(match.group(1)!);
      final end = int.parse(match.group(2) ?? match.group(1)!);
      final parity = match.group(3);
      if (start < 1 || end < start) {
        throw FormatException('zcd 周次范围无效：$part');
      }
      for (var week = start; week <= end; week += 1) {
        if (parity == '单' && week.isEven) continue;
        if (parity == '双' && week.isOdd) continue;
        weeks.add(week);
      }
    }
    if (weeks.isEmpty) {
      throw FormatException('zcd 未产生有效周次：$source');
    }
    return weeks;
  }

  bool _looksLikeHtml(String body) {
    final lower = body.toLowerCase();
    return lower.startsWith('<!doctype html') ||
        lower.startsWith('<html') ||
        lower.contains('<body');
  }

  bool _looksLikeLoginPage(String body) {
    final lower = body.toLowerCase();
    return lower.contains('vpn.bitc.edu.cn/iam/login') ||
        lower.contains('/iam/login') ||
        lower.contains('统一身份认证') ||
        lower.contains('登录');
  }
}

final class _CalendarParseResult {
  _CalendarParseResult({this.calendar, required Iterable<ImportIssue> issues})
    : issues = List.unmodifiable(issues);

  final ImportedSemesterCalendar? calendar;
  final List<ImportIssue> issues;
}

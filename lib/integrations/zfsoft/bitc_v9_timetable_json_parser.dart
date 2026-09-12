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
    Iterable<ImportedTimingProfile> timingProfiles = const [],
    Iterable<ImportIssue> timingIssues = const [],
  }) : courses = List.unmodifiable(courses),
       calendarIssues = List.unmodifiable(calendarIssues),
       timingProfiles = List.unmodifiable(timingProfiles),
       timingIssues = List.unmodifiable(timingIssues);

  final List<ZfCourseDto> courses;
  final int unscheduledCourseCount;
  final ImportedSemesterCalendar? calendar;
  final List<ImportIssue> calendarIssues;
  final List<ImportedTimingProfile> timingProfiles;
  final List<ImportIssue> timingIssues;
}

/// Parser for the minimized BITC Zhengfang V9 bridge response.
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
      final courses = kbList.map(_parseCourse).toList(growable: false);
      final calendarResult = _parseCalendar(root);
      final timingResult = _parseTimingProfiles(root, courses);
      return BitcV9TimetableParseResult(
        courses: courses,
        unscheduledCourseCount: sjkList.length,
        calendar: calendarResult.calendar,
        calendarIssues: calendarResult.issues,
        timingProfiles: timingResult.profiles,
        timingIssues: timingResult.issues,
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

  _TimingParseResult _parseTimingProfiles(
    Map<String, Object?> root,
    List<ZfCourseDto> courses,
  ) {
    final rawProfiles = root['timingProfiles'];
    if (rawProfiles == null) {
      return const _TimingParseResult();
    }
    if (rawProfiles is! List) {
      return _TimingParseResult(
        issues: [_timingWarning('作息 profile 列表格式无效，已保留本地作息。')],
      );
    }

    final profiles = <ImportedTimingProfile>[];
    final issues = <ImportIssue>[];
    final ids = <String>{};
    for (final value in rawProfiles) {
      if (value is! Map) {
        issues.add(_timingWarning('发现格式无效的校区作息，已忽略。'));
        continue;
      }
      final profile = value.cast<String, Object?>();
      final id = _safeOptionalString(profile, 'id');
      final name = _safeOptionalString(profile, 'name');
      if (id == null || name == null || !ids.add(id)) {
        issues.add(_timingWarning('校区作息缺少安全标识、名称或标识重复，已忽略。'));
        continue;
      }

      final sourceWarning = _safeOptionalString(profile, 'warning');
      if (sourceWarning != null) {
        profiles.add(ImportedTimingProfile(id: id, name: name));
        issues.add(_timingWarning('$name：$sourceWarning'));
        continue;
      }

      try {
        final schedule = _parseSchedule(profile);
        final used = courses.where((course) => course.timingProfileId == id);
        final uncovered = used.where(
          (course) => !schedule.covers(course.startPeriod, course.endPeriod),
        );
        if (uncovered.isNotEmpty) {
          throw const FormatException('作息未覆盖该校区导入课程使用的全部节次');
        }
        profiles.add(
          ImportedTimingProfile(id: id, name: name, schedule: schedule),
        );
      } on Object catch (error) {
        profiles.add(ImportedTimingProfile(id: id, name: name));
        final detail = error is FormatException ? error.message : '作息字段校验失败';
        issues.add(_timingWarning('$name：$detail，已保留本地作息。'));
      }
    }
    return _TimingParseResult(profiles: profiles, issues: issues);
  }

  ImportedPeriodSchedule _parseSchedule(Map<String, Object?> profile) {
    final rawGroups = profile['groups'];
    final rawPeriods = profile['periods'];
    if (rawGroups is! List || rawPeriods is! List) {
      throw const FormatException('作息 groups/periods 必须是数组');
    }
    if (rawGroups.isEmpty || rawPeriods.isEmpty) {
      throw const FormatException('作息 groups/periods 不能为空');
    }

    final groups = <String, _PeriodGroupRecord>{};
    final groupCodesByName = <String, String>{};
    for (final value in rawGroups) {
      if (value is! Map) throw const FormatException('group 必须是对象');
      final map = value.cast<String, Object?>();
      final code = _requiredString(map, 'code');
      final name = _requiredString(map, 'name');
      final count = _requiredPositiveInt(map, 'count');
      if (groups.containsKey(code)) {
        throw FormatException('group code 重复：$code');
      }
      groups[code] = _PeriodGroupRecord(
        group: _periodGroup(name, _safeOptionalString(map, 'englishName')),
        expectedCount: count,
      );
      groupCodesByName[name] = code;
    }

    final periods = <ImportedPeriod>[];
    final numbers = <int>{};
    final actualCounts = <String, int>{};
    for (final value in rawPeriods) {
      if (value is! Map) throw const FormatException('period 必须是对象');
      final map = value.cast<String, Object?>();
      final number = _requiredPositiveInt(map, 'number');
      if (!numbers.add(number)) {
        throw FormatException('节次编号重复：$number');
      }
      final rawGroupCode = _safeOptionalString(map, 'groupCode');
      final fallbackGroupName = _safeOptionalString(map, 'groupName');
      final groupCode = rawGroupCode ?? groupCodesByName[fallbackGroupName];
      if (groupCode == null) {
        throw FormatException('节次 $number 缺少可识别的 group 关联');
      }
      final group = groups[groupCode];
      if (group == null) {
        throw FormatException('节次 $number 关联了未知 group');
      }
      final start = _normalizedTime(map['startTime'], 'startTime');
      final end = _normalizedTime(map['endTime'], 'endTime');
      if (_minutes(start) >= _minutes(end)) {
        throw FormatException('节次 $number 的开始时间必须早于结束时间');
      }
      actualCounts[groupCode] = (actualCounts[groupCode] ?? 0) + 1;
      periods.add(
        ImportedPeriod(
          number: number,
          startTime: start,
          endTime: end,
          group: group.group,
        ),
      );
    }

    for (final entry in groups.entries) {
      if ((actualCounts[entry.key] ?? 0) != entry.value.expectedCount) {
        throw FormatException('group ${entry.key} 的实际节数与 count 不一致');
      }
    }
    periods.sort((first, second) => first.number.compareTo(second.number));
    for (var index = 1; index < periods.length; index += 1) {
      final previous = periods[index - 1];
      final current = periods[index];
      if (_minutes(previous.endTime) > _minutes(current.startTime)) {
        throw FormatException(
          '节次 ${previous.number} 与 ${current.number} 时间重叠或倒序',
        );
      }
      if (_groupRank(previous.group) > _groupRank(current.group)) {
        throw FormatException('上午、下午、晚上分组顺序发生交错');
      }
    }
    return ImportedPeriodSchedule(periods: periods);
  }

  int _groupRank(ImportedPeriodGroup group) => switch (group) {
    ImportedPeriodGroup.morning => 0,
    ImportedPeriodGroup.afternoon => 1,
    ImportedPeriodGroup.evening => 2,
  };

  ImportedPeriodGroup _periodGroup(String name, String? englishName) {
    final label = '$name ${englishName ?? ''}'.toLowerCase();
    if (label.contains('上午') || label.contains('morning')) {
      return ImportedPeriodGroup.morning;
    }
    if (label.contains('下午') || label.contains('afternoon')) {
      return ImportedPeriodGroup.afternoon;
    }
    if (label.contains('晚上') ||
        label.contains('晚间') ||
        label.contains('evening')) {
      return ImportedPeriodGroup.evening;
    }
    throw FormatException('无法识别作息分组：$name');
  }

  String _normalizedTime(Object? value, String key) {
    if (value is! String) throw FormatException('$key 必须是时间字符串');
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value.trim());
    if (match == null) throw FormatException('$key 必须是 H:mm 或 HH:mm');
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    if (hour > 23 || minute > 59) throw FormatException('$key 时间无效');
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  int _minutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
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
      inferredStartDates.add(
        DateTime(
          date.year,
          date.month,
          date.day - (weekday - 1 + (week - 1) * 7),
        ),
      );
    }

    if (invalidDate) issues.add(_calendarWarning('部分校历日期无效，已忽略对应日期锚点。'));
    if (invalidWeekday) {
      issues.add(_calendarWarning('部分校历星期无效或与日期不一致，已忽略对应日期锚点。'));
    }
    if (invalidWeek) issues.add(_calendarWarning('部分校历周次无效，已忽略对应日期锚点。'));
    if (missingWeek) issues.add(_calendarWarning('校历日期缺少教学周次，无法据此定位开学日期。'));
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

  ImportIssue _calendarWarning(String message) => ImportIssue(
    code: ImportIssueCode.invalidSourceData,
    message: message,
    severity: ImportIssueSeverity.warning,
  );

  ImportIssue _timingWarning(String message) => ImportIssue(
    code: ImportIssueCode.invalidSourceData,
    message: message,
    severity: ImportIssueSeverity.warning,
  );

  DateTime? _calendarDate(Object? value) {
    if (value is! String) return null;
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value.trim());
    if (match == null) return null;
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final date = DateTime(year, month, day);
    return date.year == year && date.month == month && date.day == day
        ? date
        : null;
  }

  int? _positiveInt(Object? value) {
    final parsed = switch (value) {
      final int number => number,
      final String text => int.tryParse(text.trim()),
      _ => null,
    };
    return parsed != null && parsed > 0 ? parsed : null;
  }

  int _requiredPositiveInt(Map<String, Object?> map, String key) {
    final value = _positiveInt(map[key]);
    if (value == null) throw FormatException('$key 必须是正整数');
    return value;
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
    return parsed != null && parsed >= minimum && parsed <= maximum
        ? parsed
        : null;
  }

  ZfCourseDto _parseCourse(Object? value) {
    if (value is! Map) throw const FormatException('kbList 项必须是对象');
    final course = value.cast<String, Object?>();
    final name = _plainTextName(_requiredString(course, 'kcmc'));
    final teachingClassId = _safeOptionalString(course, 'jxb_id');
    final sourceId =
        teachingClassId ?? '${_requiredString(course, 'kch')}::$name';
    final periods = _parsePeriods(
      _safeOptionalString(course, 'jcs') ?? _requiredString(course, 'jcor'),
    );
    return ZfCourseDto(
      sourceId: sourceId,
      name: name,
      teacher: _safeOptionalString(course, 'xm'),
      location: _location(course),
      weekday: _requiredInt(course, 'xqj', minimum: 1, maximum: 7),
      startPeriod: periods.$1,
      endPeriod: periods.$2,
      weeks: _parseWeeks(_requiredString(course, 'zcd')),
      timingProfileId: _safeOptionalString(course, 'timingProfileId'),
    );
  }

  List<Object?> _requiredObjectList(Map<String, Object?> root, String key) {
    final value = root[key];
    if (value is! List) throw FormatException('$key 必须是数组');
    return value.cast<Object?>();
  }

  String _requiredString(Map<String, Object?> map, String key) {
    final value = _safeOptionalString(map, key);
    if (value == null) throw FormatException('$key 必须是非空字符串');
    return value;
  }

  String? _safeOptionalString(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value == null) return null;
    if (value is! String) throw FormatException('$key 必须是字符串');
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
    if (parsed == null) throw FormatException('$key 必须是 $minimum-$maximum 的整数');
    return parsed;
  }

  String _plainTextName(String rawName) {
    final name = (html_parser.parseFragment(rawName).text ?? '').trim();
    if (name.isEmpty) throw const FormatException('kcmc 去除 HTML 后不能为空');
    return name;
  }

  String? _location(Map<String, Object?> course) {
    final campus = _safeOptionalString(course, 'xqmc');
    final room = _safeOptionalString(course, 'cdmc');
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
      if (match == null) throw FormatException('zcd 周次格式无效：$part');
      final start = int.parse(match.group(1)!);
      final end = int.parse(match.group(2) ?? match.group(1)!);
      final parity = match.group(3);
      if (start < 1 || end < start) throw FormatException('zcd 周次范围无效：$part');
      for (var week = start; week <= end; week += 1) {
        if (parity == '单' && week.isEven) continue;
        if (parity == '双' && week.isOdd) continue;
        weeks.add(week);
      }
    }
    if (weeks.isEmpty) throw FormatException('zcd 未产生有效周次：$source');
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

final class _PeriodGroupRecord {
  const _PeriodGroupRecord({required this.group, required this.expectedCount});

  final ImportedPeriodGroup group;
  final int expectedCount;
}

final class _TimingParseResult {
  const _TimingParseResult({this.profiles = const [], this.issues = const []});

  final List<ImportedTimingProfile> profiles;
  final List<ImportIssue> issues;
}

final class _CalendarParseResult {
  _CalendarParseResult({this.calendar, required Iterable<ImportIssue> issues})
    : issues = List.unmodifiable(issues);

  final ImportedSemesterCalendar? calendar;
  final List<ImportIssue> issues;
}

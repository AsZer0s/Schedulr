import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/timetable_models.dart';

typedef CourseSessionTapCallback = void Function(
  CourseWithSessions course,
  CourseSession session,
);

class WeeklyTimetableView extends StatefulWidget {
  const WeeklyTimetableView({
    required this.timetable,
    required this.teachingWeek,
    this.showWeekend = false,
    this.onCourseTap,
    this.height = 600,
    this.dayWidth = 120,
    this.periodRowHeight = 68,
    this.periodAxisWidth = 64,
    super.key,
  }) : assert(height > 0),
       assert(dayWidth > 0),
       assert(periodRowHeight > 0),
       assert(periodAxisWidth > 0);

  final SemesterTimetable timetable;
  final int teachingWeek;
  final bool showWeekend;
  final CourseSessionTapCallback? onCourseTap;
  final double height;
  final double dayWidth;
  final double periodRowHeight;
  final double periodAxisWidth;

  @override
  State<WeeklyTimetableView> createState() => _WeeklyTimetableViewState();
}

class _WeeklyTimetableViewState extends State<WeeklyTimetableView> {
  static const double _headerHeight = 52;

  final ScrollController _headerHorizontalController = ScrollController();
  final ScrollController _gridHorizontalController = ScrollController();
  final ScrollController _axisVerticalController = ScrollController();
  final ScrollController _gridVerticalController = ScrollController();
  bool _synchronizingScroll = false;

  @override
  void initState() {
    super.initState();
    _headerHorizontalController.addListener(_syncHeaderToGrid);
    _gridHorizontalController.addListener(_syncGridToHeader);
    _axisVerticalController.addListener(_syncAxisToGrid);
    _gridVerticalController.addListener(_syncGridToAxis);
  }

  @override
  void dispose() {
    _headerHorizontalController.dispose();
    _gridHorizontalController.dispose();
    _axisVerticalController.dispose();
    _gridVerticalController.dispose();
    super.dispose();
  }

  void _syncHeaderToGrid() {
    _syncScroll(_headerHorizontalController, _gridHorizontalController);
  }

  void _syncGridToHeader() {
    _syncScroll(_gridHorizontalController, _headerHorizontalController);
  }

  void _syncAxisToGrid() {
    _syncScroll(_axisVerticalController, _gridVerticalController);
  }

  void _syncGridToAxis() {
    _syncScroll(_gridVerticalController, _axisVerticalController);
  }

  void _syncScroll(ScrollController source, ScrollController target) {
    if (_synchronizingScroll || !source.hasClients || !target.hasClients) {
      return;
    }
    final targetOffset = source.offset.clamp(
      target.position.minScrollExtent,
      target.position.maxScrollExtent,
    );
    if ((target.offset - targetOffset).abs() < 0.5) {
      return;
    }
    _synchronizingScroll = true;
    target.jumpTo(targetOffset);
    _synchronizingScroll = false;
  }

  @override
  Widget build(BuildContext context) {
    final periods = _displayPeriods(widget.timetable.periodDefinitions);
    final weekdays = widget.showWeekend ? 7 : 5;
    final entries = _visibleEntries(
      timetable: widget.timetable,
      teachingWeek: widget.teachingWeek,
      weekdays: weekdays,
      periods: periods,
    );
    final placements = _placeEntries(entries);
    final gridWidth = weekdays * widget.dayWidth;
    final gridHeight = periods.length * widget.periodRowHeight;

    if (entries.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: const TimetableEmptyState(),
      );
    }

    return SizedBox(
      height: widget.height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Row(
            children: [
              SizedBox(
                width: widget.periodAxisWidth,
                child: Column(
                  children: [
                    const SizedBox(height: _headerHeight),
                    Divider(height: 1, color: Theme.of(context).dividerColor),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _axisVerticalController,
                        physics: const ClampingScrollPhysics(),
                        child: _PeriodAxis(
                          periods: periods,
                          width: widget.periodAxisWidth,
                          rowHeight: widget.periodRowHeight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              VerticalDivider(
                width: 1,
                thickness: 1,
                color: Theme.of(context).dividerColor,
              ),
              Expanded(
                child: Column(
                  children: [
                    SizedBox(
                      height: _headerHeight,
                      child: SingleChildScrollView(
                        controller: _headerHorizontalController,
                        scrollDirection: Axis.horizontal,
                        physics: const ClampingScrollPhysics(),
                        child: _WeekdayHeader(
                          weekdays: weekdays,
                          dayWidth: widget.dayWidth,
                        ),
                      ),
                    ),
                    Divider(height: 1, color: Theme.of(context).dividerColor),
                    Expanded(
                      child: Scrollbar(
                        controller: _gridHorizontalController,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: _gridHorizontalController,
                          scrollDirection: Axis.horizontal,
                          physics: const ClampingScrollPhysics(),
                          child: SizedBox(
                            width: gridWidth,
                            child: Scrollbar(
                              controller: _gridVerticalController,
                              thumbVisibility: true,
                              child: SingleChildScrollView(
                                controller: _gridVerticalController,
                                physics: const ClampingScrollPhysics(),
                                child: SizedBox(
                                  width: gridWidth,
                                  height: gridHeight,
                                  child: Stack(
                                    clipBehavior: Clip.hardEdge,
                                    children: [
                                      Positioned.fill(
                                        child: CustomPaint(
                                          painter: _TimetableGridPainter(
                                            weekdays: weekdays,
                                            periods: periods.length,
                                            dayWidth: widget.dayWidth,
                                            rowHeight: widget.periodRowHeight,
                                            lineColor: Theme.of(context)
                                                .dividerColor,
                                          ),
                                        ),
                                      ),
                                      for (final placement in placements)
                                        _CourseCardPositioned(
                                          placement: placement,
                                          teachingWeek: widget.teachingWeek,
                                          dayWidth: widget.dayWidth,
                                          rowHeight: widget.periodRowHeight,
                                          onTap: widget.onCourseTap,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TimetableEmptyState extends StatelessWidget {
  const TimetableEmptyState({
    this.title = '本周暂无课程',
    this.message = '当前教学周没有可显示的课程安排。',
    super.key,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      label: '$title。$message',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_view_week_outlined,
                size: 48,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DisplayPeriod {
  const _DisplayPeriod({required this.period, required this.label});

  final int period;
  final String label;
}

List<_DisplayPeriod> _displayPeriods(List<PeriodDefinition> definitions) {
  if (definitions.isEmpty) {
    return List<_DisplayPeriod>.generate(
      12,
      (index) => _DisplayPeriod(period: index + 1, label: '第${index + 1}节'),
    );
  }

  final sorted = definitions.toList()
    ..sort((first, second) => first.period.compareTo(second.period));
  return [
    for (final definition in sorted)
      _DisplayPeriod(
        period: definition.period,
        label:
            '第${definition.period}节\n${definition.startTime}–${definition.endTime}',
      ),
  ];
}

class _VisibleEntry {
  const _VisibleEntry({
    required this.courseWithSessions,
    required this.session,
    required this.startRow,
    required this.endRow,
  });

  final CourseWithSessions courseWithSessions;
  final CourseSession session;
  final int startRow;
  final int endRow;
}

List<_VisibleEntry> _visibleEntries({
  required SemesterTimetable timetable,
  required int teachingWeek,
  required int weekdays,
  required List<_DisplayPeriod> periods,
}) {
  final rowByPeriod = <int, int>{
    for (var index = 0; index < periods.length; index++)
      periods[index].period: index,
  };
  final entries = <_VisibleEntry>[];

  for (final courseWithSessions in timetable.courses) {
    for (final session in courseWithSessions.sessions) {
      if (!session.weeks.contains(teachingWeek) || session.weekday > weekdays) {
        continue;
      }
      final startRow = rowByPeriod[session.startPeriod];
      final endRow = rowByPeriod[session.endPeriod];
      if (startRow == null || endRow == null || endRow < startRow) {
        continue;
      }
      entries.add(
        _VisibleEntry(
          courseWithSessions: courseWithSessions,
          session: session,
          startRow: startRow,
          endRow: endRow,
        ),
      );
    }
  }

  entries.sort(_compareEntries);
  return entries;
}

int _compareEntries(_VisibleEntry first, _VisibleEntry second) {
  var comparison = first.session.weekday.compareTo(second.session.weekday);
  if (comparison != 0) {
    return comparison;
  }
  comparison = first.startRow.compareTo(second.startRow);
  if (comparison != 0) {
    return comparison;
  }
  comparison = first.endRow.compareTo(second.endRow);
  if (comparison != 0) {
    return comparison;
  }
  comparison = first.courseWithSessions.course.id.compareTo(
    second.courseWithSessions.course.id,
  );
  if (comparison != 0) {
    return comparison;
  }
  return first.session.id.compareTo(second.session.id);
}

class _Placement {
  const _Placement({
    required this.entry,
    required this.column,
    required this.columnCount,
  });

  final _VisibleEntry entry;
  final int column;
  final int columnCount;
}

List<_Placement> _placeEntries(List<_VisibleEntry> entries) {
  final placements = <_Placement>[];
  for (var weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++) {
    final dayEntries = [
      for (final entry in entries)
        if (entry.session.weekday == weekday) entry,
    ];
    var groupStart = 0;
    while (groupStart < dayEntries.length) {
      var groupEnd = groupStart + 1;
      var occupiedThrough = dayEntries[groupStart].endRow;
      while (groupEnd < dayEntries.length &&
          dayEntries[groupEnd].startRow <= occupiedThrough) {
        occupiedThrough = math.max(
          occupiedThrough,
          dayEntries[groupEnd].endRow,
        );
        groupEnd++;
      }

      final group = dayEntries.sublist(groupStart, groupEnd);
      final columnEndRows = <int>[];
      final columns = <int>[];
      for (final entry in group) {
        var column = 0;
        while (column < columnEndRows.length &&
            columnEndRows[column] >= entry.startRow) {
          column++;
        }
        if (column == columnEndRows.length) {
          columnEndRows.add(entry.endRow);
        } else {
          columnEndRows[column] = entry.endRow;
        }
        columns.add(column);
      }
      for (var index = 0; index < group.length; index++) {
        placements.add(
          _Placement(
            entry: group[index],
            column: columns[index],
            columnCount: columnEndRows.length,
          ),
        );
      }
      groupStart = groupEnd;
    }
  }
  return placements;
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader({required this.weekdays, required this.dayWidth});

  static const labels = <String>['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

  final int weekdays;
  final double dayWidth;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < weekdays; index++)
          SizedBox(
            width: dayWidth,
            child: Center(
              child: Text(
                labels[index],
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ),
      ],
    );
  }
}

class _PeriodAxis extends StatelessWidget {
  const _PeriodAxis({
    required this.periods,
    required this.width,
    required this.rowHeight,
  });

  final List<_DisplayPeriod> periods;
  final double width;
  final double rowHeight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        children: [
          for (final period in periods)
            Container(
              width: width,
              height: rowHeight,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: Text(
                period.label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
        ],
      ),
    );
  }
}

class _CourseCardPositioned extends StatelessWidget {
  const _CourseCardPositioned({
    required this.placement,
    required this.teachingWeek,
    required this.dayWidth,
    required this.rowHeight,
    required this.onTap,
  });

  final _Placement placement;
  final int teachingWeek;
  final double dayWidth;
  final double rowHeight;
  final CourseSessionTapCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const gap = 2.0;
    final entry = placement.entry;
    final session = entry.session;
    final courseWithSessions = entry.courseWithSessions;
    final course = courseWithSessions.course;
    final columnWidth = dayWidth / placement.columnCount;
    final color = Color(course.colorValue);
    final foreground =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black87;
    final location = session.location?.trim();
    final locationLabel = location == null || location.isEmpty
        ? '地点未注明'
        : location;
    final weekdayLabel = _WeekdayHeader.labels[session.weekday - 1];
    final semanticsLabel =
        '${course.name}，$locationLabel，$weekdayLabel，'
        '第${session.startPeriod}至${session.endPeriod}节，第$teachingWeek周';

    return Positioned(
      key: ValueKey<String>('course-session-${session.id}'),
      left:
          (session.weekday - 1) * dayWidth +
          placement.column * columnWidth +
          gap,
      top: entry.startRow * rowHeight + gap,
      width: math.max(0, columnWidth - gap * 2),
      height: math.max(
        0,
        (entry.endRow - entry.startRow + 1) * rowHeight - gap * 2,
      ),
      child: Semantics(
        container: true,
        button: onTap != null,
        label: semanticsLabel,
        hint: onTap == null ? null : '点击查看课程',
        child: Material(
          color: color,
          borderRadius: BorderRadius.circular(8),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap == null
                ? null
                : () => onTap!(courseWithSessions, session),
            child: Padding(
              padding: const EdgeInsets.all(7),
              child: DefaultTextStyle(
                style: Theme.of(context).textTheme.labelMedium!
                    .copyWith(color: foreground),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.name,
                      style: TextStyle(
                        color: foreground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(locationLabel),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TimetableGridPainter extends CustomPainter {
  const _TimetableGridPainter({
    required this.weekdays,
    required this.periods,
    required this.dayWidth,
    required this.rowHeight,
    required this.lineColor,
  });

  final int weekdays;
  final int periods;
  final double dayWidth;
  final double rowHeight;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;
    for (var day = 1; day < weekdays; day++) {
      final x = day * dayWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var period = 1; period < periods; period++) {
      final y = period * rowHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_TimetableGridPainter oldDelegate) {
    return oldDelegate.weekdays != weekdays ||
        oldDelegate.periods != periods ||
        oldDelegate.dayWidth != dayWidth ||
        oldDelegate.rowHeight != rowHeight ||
        oldDelegate.lineColor != lineColor;
  }
}

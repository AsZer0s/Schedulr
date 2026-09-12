import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/time/teaching_calendar.dart';
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
    this.today,
    this.height = 600,
    this.dayWidth = 120,
    this.periodRowHeight = 68,
    this.periodAxisWidth = 64,
    super.key,
  }) : assert(height > 0),
       assert(dayWidth > 0),
       assert(periodRowHeight > 0),
       assert(periodAxisWidth > 0);

  static const Key headerHorizontalScrollKey = ValueKey<String>(
    'weekly-timetable-header-horizontal-scroll',
  );
  static const Key gridHorizontalScrollKey = ValueKey<String>(
    'weekly-timetable-grid-horizontal-scroll',
  );
  static const Key todayColumnKey = ValueKey<String>(
    'weekly-timetable-today-column',
  );

  static Key weekdayHeaderKey(int weekday) =>
      ValueKey<String>('weekly-timetable-weekday-header-$weekday');

  final SemesterTimetable timetable;
  final int teachingWeek;
  final bool showWeekend;
  final CourseSessionTapCallback? onCourseTap;
  final DateTime? today;
  final double height;

  /// Preferred day width. Five-day mode always fits all workdays; in seven-day
  /// mode a compact minimum derived from this value is used before scrolling.
  final double dayWidth;
  final double periodRowHeight;
  final double periodAxisWidth;

  @override
  State<WeeklyTimetableView> createState() => _WeeklyTimetableViewState();
}

class _WeeklyTimetableViewState extends State<WeeklyTimetableView> {
  static const double _headerHeight = 58;
  static const double _minimumAxisWidth = 42;
  static const double _maximumCompactDayWidth = 72;

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
    final dates = [
      for (var weekday = DateTime.monday; weekday <= weekdays; weekday++)
        dateForTeachingWeekday(
          widget.timetable.semester,
          widget.teachingWeek,
          weekday,
        ),
    ];
    final currentDay = dateOnly(widget.today ?? DateTime.now());
    final todayIndex = dates.indexWhere(
      (date) => DateUtils.isSameDay(date, currentDay),
    );

    return SizedBox(
      height: widget.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.hasBoundedWidth
              ? constraints.maxWidth
              : MediaQuery.sizeOf(context).width;
          final axisWidth = math.min(
            widget.periodAxisWidth,
            math.max(_minimumAxisWidth, availableWidth * 0.15),
          );
          final gridViewportWidth = math.max(0, availableWidth - axisWidth - 1);
          final minimumSevenDayWidth = math.min(
            widget.dayWidth,
            _maximumCompactDayWidth,
          );
          final effectiveDayWidth = widget.showWeekend
              ? math.max(gridViewportWidth / weekdays, minimumSevenDayWidth)
              : gridViewportWidth / weekdays;
          final gridWidth = effectiveDayWidth * weekdays;
          final gridHeight = periods.length * widget.periodRowHeight;
          final canScrollHorizontally = gridWidth - gridViewportWidth > 0.01;
          final horizontalPhysics = canScrollHorizontally
              ? const ClampingScrollPhysics()
              : const NeverScrollableScrollPhysics();

          return DecoratedBox(
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
                    width: axisWidth,
                    child: Column(
                      children: [
                        const SizedBox(height: _headerHeight),
                        Divider(
                          height: 1,
                          color: Theme.of(context).dividerColor,
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            controller: _axisVerticalController,
                            physics: const ClampingScrollPhysics(),
                            child: _PeriodAxis(
                              periods: periods,
                              width: axisWidth,
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
                            key: WeeklyTimetableView.headerHorizontalScrollKey,
                            controller: _headerHorizontalController,
                            scrollDirection: Axis.horizontal,
                            physics: horizontalPhysics,
                            child: _WeekdayHeader(
                              dates: dates,
                              dayWidth: effectiveDayWidth,
                              todayIndex: todayIndex,
                            ),
                          ),
                        ),
                        Divider(
                          height: 1,
                          color: Theme.of(context).dividerColor,
                        ),
                        Expanded(
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Scrollbar(
                                  controller: _gridHorizontalController,
                                  thumbVisibility: canScrollHorizontally,
                                  child: SingleChildScrollView(
                                    key: WeeklyTimetableView
                                        .gridHorizontalScrollKey,
                                    controller: _gridHorizontalController,
                                    scrollDirection: Axis.horizontal,
                                    physics: horizontalPhysics,
                                    child: SizedBox(
                                      width: gridWidth,
                                      child: Scrollbar(
                                        controller: _gridVerticalController,
                                        thumbVisibility: true,
                                        child: SingleChildScrollView(
                                          controller: _gridVerticalController,
                                          physics:
                                              const ClampingScrollPhysics(),
                                          child: SizedBox(
                                            width: gridWidth,
                                            height: gridHeight,
                                            child: Stack(
                                              clipBehavior: Clip.hardEdge,
                                              children: [
                                                if (todayIndex >= 0)
                                                  Positioned(
                                                    key: WeeklyTimetableView
                                                        .todayColumnKey,
                                                    left:
                                                        todayIndex *
                                                        effectiveDayWidth,
                                                    top: 0,
                                                    bottom: 0,
                                                    width: effectiveDayWidth,
                                                    child: Semantics(
                                                      container: true,
                                                      label: '今天课程列',
                                                      child: ColoredBox(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .primaryContainer
                                                            .withValues(
                                                              alpha: 0.32,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                Positioned.fill(
                                                  child: CustomPaint(
                                                    painter:
                                                        _TimetableGridPainter(
                                                          weekdays: weekdays,
                                                          periods:
                                                              periods.length,
                                                          dayWidth:
                                                              effectiveDayWidth,
                                                          rowHeight: widget
                                                              .periodRowHeight,
                                                          lineColor: Theme.of(
                                                            context,
                                                          ).dividerColor,
                                                        ),
                                                  ),
                                                ),
                                                for (final placement
                                                    in placements)
                                                  _CourseCardPositioned(
                                                    placement: placement,
                                                    teachingWeek:
                                                        widget.teachingWeek,
                                                    dayWidth: effectiveDayWidth,
                                                    rowHeight:
                                                        widget.periodRowHeight,
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
                              if (entries.isEmpty)
                                const Positioned.fill(
                                  child: IgnorePointer(
                                    child: TimetableEmptyState(),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
  const _WeekdayHeader({
    required this.dates,
    required this.dayWidth,
    required this.todayIndex,
  });

  static const labels = <String>['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  static const shortLabels = <String>['一', '二', '三', '四', '五', '六', '日'];

  final List<DateTime> dates;
  final double dayWidth;
  final int todayIndex;

  @override
  Widget build(BuildContext context) {
    final useShortLabels = dayWidth < 64;
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (var index = 0; index < dates.length; index++)
          Semantics(
            key: WeeklyTimetableView.weekdayHeaderKey(index + 1),
            container: true,
            header: true,
            selected: index == todayIndex,
            label:
                '${index == todayIndex ? '今天，' : ''}${labels[index]}，'
                '${dates[index].month}月${dates[index].day}日',
            child: ExcludeSemantics(
              child: Container(
                width: dayWidth,
                height: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
                decoration: BoxDecoration(
                  color: index == todayIndex
                      ? colorScheme.primaryContainer.withValues(alpha: 0.72)
                      : null,
                  border: Border(
                    right: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        useShortLabels ? shortLabels[index] : labels[index],
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: index == todayIndex
                              ? colorScheme.onPrimaryContainer
                              : null,
                          fontWeight: index == todayIndex
                              ? FontWeight.w700
                              : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${dates[index].month}/${dates[index].day}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: index == todayIndex
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
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
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  width < 56 ? '${period.period}节' : period.label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
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
    final entry = placement.entry;
    final session = entry.session;
    final courseWithSessions = entry.courseWithSessions;
    final course = courseWithSessions.course;
    final columnWidth = dayWidth / placement.columnCount;
    final gap = columnWidth < 32 ? 0.5 : 2.0;
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
      width: math.max(1, columnWidth - gap * 2),
      height: math.max(
        1,
        (entry.endRow - entry.startRow + 1) * rowHeight - gap * 2,
      ),
      child: Semantics(
        container: true,
        excludeSemantics: true,
        button: onTap != null,
        label: semanticsLabel,
        hint: onTap == null ? null : '点击查看课程',
        child: Material(
          color: color,
          borderRadius: BorderRadius.circular(columnWidth < 36 ? 4 : 8),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap == null
                ? null
                : () => onTap!(courseWithSessions, session),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final padding = constraints.maxWidth < 36
                    ? 2.0
                    : constraints.maxWidth < 60
                    ? 4.0
                    : 7.0;
                final showLocation =
                    constraints.maxWidth >= 70 && constraints.maxHeight >= 52;
                return Padding(
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            course.name,
                            maxLines: showLocation ? 2 : 4,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: foreground,
                                  fontWeight: FontWeight.w700,
                                  height: 1.05,
                                ),
                          ),
                        ),
                      ),
                      if (showLocation) ...[
                        const SizedBox(height: 2),
                        Text(
                          locationLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: foreground, height: 1.05),
                        ),
                      ],
                    ],
                  ),
                );
              },
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

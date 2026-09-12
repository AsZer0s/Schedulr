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
  static const Key axisVerticalScrollKey = ValueKey<String>(
    'weekly-timetable-axis-vertical-scroll',
  );
  static const Key gridVerticalScrollKey = ValueKey<String>(
    'weekly-timetable-grid-vertical-scroll',
  );
  static const Key gridBodyKey = ValueKey<String>('weekly-timetable-grid-body');
  static const Key todayColumnKey = ValueKey<String>(
    'weekly-timetable-today-column',
  );

  static Key weekdayHeaderKey(int weekday) =>
      ValueKey<String>('weekly-timetable-weekday-header-$weekday');

  static Key periodCellKey(int period) =>
      ValueKey<String>('weekly-timetable-period-cell-$period');

  static Key groupLabelKey(PeriodGroup group) =>
      ValueKey<String>('weekly-timetable-group-label-${group.name}');

  static Key groupSeparatorKey(PeriodGroup group) =>
      ValueKey<String>('weekly-timetable-group-separator-${group.name}');

  final SemesterTimetable timetable;
  final int teachingWeek;
  final bool showWeekend;
  final CourseSessionTapCallback? onCourseTap;
  final DateTime? today;
  final double height;

  /// Preferred day width. Five-day mode always fits all workdays; in seven-day
  /// mode a compact minimum derived from this value is used before scrolling.
  final double dayWidth;

  /// Preferred maximum row height. Rows shrink to fit when that remains
  /// readable, and the timetable scrolls vertically otherwise.
  final double periodRowHeight;
  final double periodAxisWidth;

  @override
  State<WeeklyTimetableView> createState() => _WeeklyTimetableViewState();
}

class _WeeklyTimetableViewState extends State<WeeklyTimetableView> {
  static const double _headerHeight = 58;
  static const double _minimumAxisWidth = 42;
  static const double _maximumCompactDayWidth = 72;
  static const double _groupGap = 10;
  static const double _baseMinimumRowHeight = 48;

  final ScrollController _headerHorizontalController = ScrollController();
  final ScrollController _gridHorizontalController = ScrollController();
  final ScrollController _axisVerticalController = ScrollController();
  final ScrollController _gridVerticalController = ScrollController();
  bool _synchronizingScroll = false;
  bool _verticalClampScheduled = false;

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

  void _scheduleVerticalScrollClamp() {
    if (_verticalClampScheduled) {
      return;
    }
    _verticalClampScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verticalClampScheduled = false;
      if (!mounted) {
        return;
      }
      _synchronizingScroll = true;
      for (final controller in <ScrollController>[
        _axisVerticalController,
        _gridVerticalController,
      ]) {
        if (!controller.hasClients) {
          continue;
        }
        final clampedOffset = controller.offset.clamp(
          controller.position.minScrollExtent,
          controller.position.maxScrollExtent,
        );
        if ((controller.offset - clampedOffset).abs() >= 0.5) {
          controller.jumpTo(clampedOffset);
        }
      }
      _synchronizingScroll = false;
      if (_gridVerticalController.hasClients &&
          _axisVerticalController.hasClients) {
        _syncGridToAxis();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final weekdays = widget.showWeekend ? 7 : 5;
    final scheduledEntries = _scheduledEntries(
      timetable: widget.timetable,
      teachingWeek: widget.teachingWeek,
    );
    final visibleScheduledEntries = [
      for (final entry in scheduledEntries)
        if (entry.session.weekday <= weekdays) entry,
    ];

    if (visibleScheduledEntries.isEmpty) {
      final weekendOnly =
          !widget.showWeekend &&
          scheduledEntries.any(
            (entry) => entry.session.weekday >= DateTime.saturday,
          );
      return SizedBox(
        height: widget.height,
        child: TimetableEmptyState(
          title: weekendOnly ? '工作日暂无课程' : '本周暂无课程',
          message: weekendOnly
              ? '本周课程仅安排在周末，开启“显示周末”后可查看。'
              : '当前教学周没有可显示的课程安排。',
        ),
      );
    }

    final periods = _displayPeriods(widget.timetable.periodDefinitions);
    final resolution = _resolveVisibleEntries(
      scheduledEntries: visibleScheduledEntries,
      periods: periods,
    );
    if (resolution.hasConfigurationError) {
      return SizedBox(
        height: widget.height,
        child: const TimetableConfigurationErrorState(),
      );
    }

    final entries = resolution.entries;
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
          final availableHeight = constraints.hasBoundedHeight
              ? constraints.maxHeight
              : widget.height;
          final bodyViewportHeight = math.max(
            0,
            availableHeight - _headerHeight - 1,
          );
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
          final separatorCount = _separatorCount(periods);
          final textScale = _effectiveTextScale(context);
          final minimumRowHeight = _baseMinimumRowHeight + (textScale - 1) * 16;
          final maximumRowHeight = math.max(
            minimumRowHeight,
            widget.periodRowHeight,
          );
          final availableRowsHeight = math.max(
            0,
            bodyViewportHeight - separatorCount * _groupGap,
          );
          final fittingRowHeight = periods.isEmpty
              ? maximumRowHeight
              : availableRowsHeight / periods.length;
          final rowHeight = fittingRowHeight.clamp(
            minimumRowHeight,
            maximumRowHeight,
          );
          final metrics = _TimetableVerticalMetrics(
            periods: periods,
            rowHeight: rowHeight,
            groupGap: _groupGap,
          );
          final canScrollHorizontally = gridWidth - gridViewportWidth > 0.01;
          final canScrollVertically =
              metrics.totalHeight - bodyViewportHeight > 0.01;
          final horizontalPhysics = canScrollHorizontally
              ? const ClampingScrollPhysics()
              : const NeverScrollableScrollPhysics();
          final verticalPhysics = canScrollVertically
              ? const ClampingScrollPhysics()
              : const NeverScrollableScrollPhysics();

          _scheduleVerticalScrollClamp();

          final axisScrollView = SingleChildScrollView(
            key: WeeklyTimetableView.axisVerticalScrollKey,
            controller: _axisVerticalController,
            physics: verticalPhysics,
            child: _PeriodAxis(
              periods: periods,
              metrics: metrics,
              width: axisWidth,
            ),
          );
          Widget gridVerticalScrollView = SingleChildScrollView(
            key: WeeklyTimetableView.gridVerticalScrollKey,
            controller: _gridVerticalController,
            physics: verticalPhysics,
            child: SizedBox(
              key: WeeklyTimetableView.gridBodyKey,
              width: gridWidth,
              height: metrics.totalHeight,
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  if (todayIndex >= 0)
                    Positioned(
                      key: WeeklyTimetableView.todayColumnKey,
                      left: todayIndex * effectiveDayWidth,
                      top: 0,
                      height: metrics.totalHeight,
                      width: effectiveDayWidth,
                      child: Semantics(
                        container: true,
                        label: '今天课程列',
                        child: ColoredBox(
                          color: Theme.of(context).colorScheme.primaryContainer
                              .withValues(alpha: 0.32),
                        ),
                      ),
                    ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _TimetableGridPainter(
                        weekdays: weekdays,
                        dayWidth: effectiveDayWidth,
                        metrics: metrics,
                        lineColor: Theme.of(context).dividerColor,
                        separatorColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                      ),
                    ),
                  ),
                  for (final placement in placements)
                    _CourseCardPositioned(
                      placement: placement,
                      teachingWeek: widget.teachingWeek,
                      dayWidth: effectiveDayWidth,
                      metrics: metrics,
                      onTap: widget.onCourseTap,
                    ),
                ],
              ),
            ),
          );
          if (canScrollVertically) {
            gridVerticalScrollView = Scrollbar(
              controller: _gridVerticalController,
              thumbVisibility: true,
              child: gridVerticalScrollView,
            );
          }

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
                        Expanded(child: axisScrollView),
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
                          child: Scrollbar(
                            controller: _gridHorizontalController,
                            thumbVisibility: canScrollHorizontally,
                            child: SingleChildScrollView(
                              key: WeeklyTimetableView.gridHorizontalScrollKey,
                              controller: _gridHorizontalController,
                              scrollDirection: Axis.horizontal,
                              physics: horizontalPhysics,
                              child: SizedBox(
                                width: gridWidth,
                                child: gridVerticalScrollView,
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

class TimetableConfigurationErrorState extends StatelessWidget {
  const TimetableConfigurationErrorState({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      label: '作息配置不完整。课程节次无法与当前作息对应，请检查作息设置。',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.schedule_outlined, size: 48, color: colorScheme.error),
              const SizedBox(height: 12),
              Text('作息配置不完整', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                '课程节次无法与当前作息对应，请检查作息设置。',
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
  const _DisplayPeriod({
    required this.period,
    required this.group,
    this.startTime,
    this.endTime,
  });

  final int period;
  final PeriodGroup group;
  final String? startTime;
  final String? endTime;

  bool get hasTimes => startTime != null && endTime != null;
}

List<_DisplayPeriod> _displayPeriods(List<PeriodDefinition> definitions) {
  if (definitions.isEmpty) {
    return List<_DisplayPeriod>.generate(12, (index) {
      final period = index + 1;
      return _DisplayPeriod(
        period: period,
        group: period <= 4
            ? PeriodGroup.morning
            : period <= 8
            ? PeriodGroup.afternoon
            : PeriodGroup.evening,
      );
    });
  }

  return [
    for (final group in PeriodGroup.values)
      for (final definition
          in (definitions
              .where((definition) => definition.group == group)
              .toList()
            ..sort((first, second) => first.period.compareTo(second.period))))
        _DisplayPeriod(
          period: definition.period,
          group: definition.group,
          startTime: definition.startTime,
          endTime: definition.endTime,
        ),
  ];
}

class _ScheduledEntry {
  const _ScheduledEntry({
    required this.courseWithSessions,
    required this.session,
  });

  final CourseWithSessions courseWithSessions;
  final CourseSession session;
}

List<_ScheduledEntry> _scheduledEntries({
  required SemesterTimetable timetable,
  required int teachingWeek,
}) {
  return [
    for (final courseWithSessions in timetable.courses)
      for (final session in courseWithSessions.sessions)
        if (session.weeks.contains(teachingWeek))
          _ScheduledEntry(
            courseWithSessions: courseWithSessions,
            session: session,
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

class _VisibleEntryResolution {
  const _VisibleEntryResolution({
    required this.entries,
    required this.hasConfigurationError,
  });

  final List<_VisibleEntry> entries;
  final bool hasConfigurationError;
}

_VisibleEntryResolution _resolveVisibleEntries({
  required List<_ScheduledEntry> scheduledEntries,
  required List<_DisplayPeriod> periods,
}) {
  final rowByPeriod = <int, int>{
    for (final index in Iterable<int>.generate(periods.length))
      periods[index].period: index,
  };
  final entries = <_VisibleEntry>[];

  for (final scheduledEntry in scheduledEntries) {
    final session = scheduledEntry.session;
    final startRow = rowByPeriod[session.startPeriod];
    final endRow = rowByPeriod[session.endPeriod];
    if (startRow == null || endRow == null || endRow < startRow) {
      return const _VisibleEntryResolution(
        entries: [],
        hasConfigurationError: true,
      );
    }
    entries.add(
      _VisibleEntry(
        courseWithSessions: scheduledEntry.courseWithSessions,
        session: session,
        startRow: startRow,
        endRow: endRow,
      ),
    );
  }

  entries.sort(_compareEntries);
  return _VisibleEntryResolution(
    entries: entries,
    hasConfigurationError: false,
  );
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

class _GroupSeparatorMetric {
  const _GroupSeparatorMetric({
    required this.beforeGroup,
    required this.top,
    required this.bottom,
  });

  final PeriodGroup beforeGroup;
  final double top;
  final double bottom;
}

class _TimetableVerticalMetrics {
  _TimetableVerticalMetrics({
    required List<_DisplayPeriod> periods,
    required this.rowHeight,
    required this.groupGap,
  }) {
    var offset = 0.0;
    for (var index = 0; index < periods.length; index++) {
      if (index > 0 && periods[index - 1].group != periods[index].group) {
        separators.add(
          _GroupSeparatorMetric(
            beforeGroup: periods[index].group,
            top: offset,
            bottom: offset + groupGap,
          ),
        );
        offset += groupGap;
      }
      periodTops.add(offset);
      offset += rowHeight;
      periodBottoms.add(offset);
    }
    totalHeight = offset;
  }

  final double rowHeight;
  final double groupGap;
  final List<double> periodTops = [];
  final List<double> periodBottoms = [];
  final List<_GroupSeparatorMetric> separators = [];
  late final double totalHeight;

  double periodTop(int row) => periodTops[row];

  double periodBottom(int row) => periodBottoms[row];
}

class _PeriodAxis extends StatelessWidget {
  const _PeriodAxis({
    required this.periods,
    required this.metrics,
    required this.width,
  });

  final List<_DisplayPeriod> periods;
  final _TimetableVerticalMetrics metrics;
  final double width;

  @override
  Widget build(BuildContext context) {
    final groupCounts = <PeriodGroup, int>{
      for (final group in PeriodGroup.values)
        group: periods.where((period) => period.group == group).length,
    };
    return SizedBox(
      width: width,
      height: metrics.totalHeight,
      child: Stack(
        children: [
          for (final separator in metrics.separators)
            Positioned(
              key: WeeklyTimetableView.groupSeparatorKey(separator.beforeGroup),
              left: 0,
              right: 0,
              top: separator.top,
              height: separator.bottom - separator.top,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  border: Border.symmetric(
                    horizontal: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                ),
              ),
            ),
          for (var index = 0; index < periods.length; index++)
            Positioned(
              key: WeeklyTimetableView.periodCellKey(periods[index].period),
              left: 0,
              right: 0,
              top: metrics.periodTop(index),
              height: metrics.rowHeight,
              child: _PeriodAxisCell(
                period: periods[index],
                groupCount: groupCounts[periods[index].group]!,
                showGroupLabel:
                    index == 0 ||
                    periods[index - 1].group != periods[index].group,
              ),
            ),
        ],
      ),
    );
  }
}

class _PeriodAxisCell extends StatelessWidget {
  const _PeriodAxisCell({
    required this.period,
    required this.groupCount,
    required this.showGroupLabel,
  });

  final _DisplayPeriod period;
  final int groupCount;
  final bool showGroupLabel;

  @override
  Widget build(BuildContext context) {
    final groupLabel = switch (period.group) {
      PeriodGroup.morning => '上午',
      PeriodGroup.afternoon => '下午',
      PeriodGroup.evening => '晚上',
    };
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      label: period.hasTimes
          ? '第${period.period}节，${period.startTime}至${period.endTime}'
          : '第${period.period}节',
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: Stack(
            children: [
              if (showGroupLabel)
                Positioned(
                  key: WeeklyTimetableView.groupLabelKey(period.group),
                  left: 2,
                  right: 2,
                  top: 1,
                  child: Text(
                    '$groupLabel · $groupCount节',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 9,
                      height: 1.05,
                    ),
                  ),
                ),
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    2,
                    showGroupLabel ? 14 : 2,
                    2,
                    2,
                  ),
                  child: Center(
                    child: Text(
                      period.hasTimes
                          ? '第${period.period}节\n${period.startTime}–${period.endTime}'
                          : '第${period.period}节',
                      maxLines: period.hasTimes ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(height: 1.05),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseCardPositioned extends StatelessWidget {
  const _CourseCardPositioned({
    required this.placement,
    required this.teachingWeek,
    required this.dayWidth,
    required this.metrics,
    required this.onTap,
  });

  final _Placement placement;
  final int teachingWeek;
  final double dayWidth;
  final _TimetableVerticalMetrics metrics;
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
    final top = metrics.periodTop(entry.startRow);
    final bottom = metrics.periodBottom(entry.endRow);

    return Positioned(
      key: ValueKey<String>('course-session-${session.id}'),
      left:
          (session.weekday - 1) * dayWidth +
          placement.column * columnWidth +
          gap,
      top: top + gap,
      width: math.max(1, columnWidth - gap * 2),
      height: math.max(1, bottom - top - gap * 2),
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
    required this.dayWidth,
    required this.metrics,
    required this.lineColor,
    required this.separatorColor,
  });

  final int weekdays;
  final double dayWidth;
  final _TimetableVerticalMetrics metrics;
  final Color lineColor;
  final Color separatorColor;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;
    final separatorPaint = Paint()..color = separatorColor;
    for (final separator in metrics.separators) {
      canvas.drawRect(
        Rect.fromLTRB(0, separator.top, size.width, separator.bottom),
        separatorPaint,
      );
      canvas.drawLine(
        Offset(0, separator.top),
        Offset(size.width, separator.top),
        linePaint,
      );
      canvas.drawLine(
        Offset(0, separator.bottom),
        Offset(size.width, separator.bottom),
        linePaint,
      );
    }
    for (var day = 1; day < weekdays; day++) {
      final x = day * dayWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (final bottom in metrics.periodBottoms) {
      if (bottom < size.height - 0.01) {
        canvas.drawLine(
          Offset(0, bottom),
          Offset(size.width, bottom),
          linePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_TimetableGridPainter oldDelegate) {
    return oldDelegate.weekdays != weekdays ||
        oldDelegate.dayWidth != dayWidth ||
        oldDelegate.metrics.totalHeight != metrics.totalHeight ||
        oldDelegate.metrics.rowHeight != metrics.rowHeight ||
        oldDelegate.metrics.groupGap != metrics.groupGap ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.separatorColor != separatorColor;
  }
}

int _separatorCount(List<_DisplayPeriod> periods) {
  var count = 0;
  for (var index = 1; index < periods.length; index++) {
    if (periods[index - 1].group != periods[index].group) {
      count++;
    }
  }
  return count;
}

double _effectiveTextScale(BuildContext context) {
  final scaler = MediaQuery.textScalerOf(context);
  return (scaler.scale(14) / 14).clamp(1, 3);
}

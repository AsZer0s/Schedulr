import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/presentation/location_formatter.dart';
import '../../../core/time/teaching_calendar.dart';
import '../domain/timetable_models.dart';

typedef CourseSessionTapCallback = void Function(
  CourseWithSessions course,
  CourseSession session,
);

typedef ConflictTapCallback = void Function(
  List<CourseSessionViewEntry> entries,
);

@immutable
class CourseSessionViewEntry {
  const CourseSessionViewEntry({
    required this.courseWithSessions,
    required this.session,
  });

  final CourseWithSessions courseWithSessions;
  final CourseSession session;
}

class WeeklyTimetableView extends StatefulWidget {
  const WeeklyTimetableView({
    required this.timetable,
    required this.teachingWeek,
    this.showWeekend = true,
    this.onCourseTap,
    this.onConflictTap,
    this.onPreviousWeek,
    this.onNextWeek,
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

  static Key courseTitleKey(String sessionId) =>
      ValueKey<String>('course-title-$sessionId');

  static Key conflictCardKey(int weekday, int startPeriod, int endPeriod) =>
      ValueKey<String>('course-conflict-$weekday-$startPeriod-$endPeriod');

  static Key weekdayHeaderKey(int weekday) =>
      ValueKey<String>('weekly-timetable-weekday-header-$weekday');

  static Key periodCellKey(int period) =>
      ValueKey<String>('weekly-timetable-period-cell-$period');

  static Key periodNumberKey(int period) =>
      ValueKey<String>('weekly-timetable-period-number-$period');

  static Key startTimeKey(int period) =>
      ValueKey<String>('weekly-timetable-start-time-$period');

  static Key endTimeKey(int period) =>
      ValueKey<String>('weekly-timetable-end-time-$period');

  static Key groupLabelKey(PeriodGroup group) =>
      ValueKey<String>('weekly-timetable-group-label-${group.name}');

  static Key groupSeparatorKey(PeriodGroup group) =>
      ValueKey<String>('weekly-timetable-group-separator-${group.name}');

  static Key groupGridHeaderKey(PeriodGroup group) =>
      ValueKey<String>('weekly-timetable-group-grid-header-${group.name}');

  static Key courseTeacherKey(String sessionId) =>
      ValueKey<String>('course-teacher-$sessionId');

  static Key courseLocationKey(String sessionId) =>
      ValueKey<String>('course-location-$sessionId');

  final SemesterTimetable timetable;
  final int teachingWeek;
  final bool showWeekend;
  final CourseSessionTapCallback? onCourseTap;
  final ConflictTapCallback? onConflictTap;
  final VoidCallback? onPreviousWeek;
  final VoidCallback? onNextWeek;
  final DateTime? today;
  final double height;

  /// Preferred day width retained for callers that explicitly use five-day
  /// mode. Seven-day product mode always fits the full week to the viewport.
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
  static const double _minimumAxisWidth = 60;
  static const double _groupHeaderHeight = 18;
  static const double _baseMinimumRowHeight = 50;
  static const double _minimumReadableCourseWidth = 40;
  static const TextStyle _courseTitleStyle = TextStyle(
    fontSize: 10.5,
    fontWeight: FontWeight.w700,
    height: 1,
  );
  static const TextStyle _courseMetadataStyle = TextStyle(
    fontSize: 9,
    height: 1,
  );

  final ScrollController _headerHorizontalController = ScrollController();
  final ScrollController _gridHorizontalController = ScrollController();
  final ScrollController _axisVerticalController = ScrollController();
  final ScrollController _gridVerticalController = ScrollController();
  bool _synchronizingScroll = false;
  bool _verticalClampScheduled = false;
  double _horizontalDragDistance = 0;
  double _gestureWidth = 0;

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

  void _startHorizontalDrag(DragStartDetails details) {
    _horizontalDragDistance = 0;
    _gestureWidth = context.size?.width ?? 0;
  }

  void _updateHorizontalDrag(DragUpdateDetails details) {
    _horizontalDragDistance += details.primaryDelta ?? 0;
  }

  void _endHorizontalDrag(DragEndDetails details) {
    final distance = _horizontalDragDistance;
    final velocity = details.primaryVelocity ?? 0;
    final distanceThreshold = math.min(72.0, _gestureWidth * 0.18);
    final distanceQualified = distance.abs() >= distanceThreshold;
    final flingQualified = velocity.abs() >= 600 && distance.abs() >= 20;
    _cancelHorizontalDrag();
    if (!distanceQualified && !flingQualified) return;
    if (distance < 0) {
      widget.onNextWeek?.call();
    } else if (distance > 0) {
      widget.onPreviousWeek?.call();
    }
  }

  void _cancelHorizontalDrag() {
    _horizontalDragDistance = 0;
    _gestureWidth = 0;
  }

  Widget _withWeekSwipe(Widget child) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: _startHorizontalDrag,
      onHorizontalDragUpdate: _updateHorizontalDrag,
      onHorizontalDragEnd: _endHorizontalDrag,
      onHorizontalDragCancel: _cancelHorizontalDrag,
      child: child,
    );
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
      return _withWeekSwipe(
        SizedBox(
          height: widget.height,
          child: TimetableEmptyState(
            title: weekendOnly ? '工作日暂无课程' : '本周暂无课程',
            message: weekendOnly
                ? '本周课程仅安排在周末，开启“显示周末”后可查看。'
                : '当前教学周没有可显示的课程安排。',
          ),
        ),
      );
    }

    final periods = _displayPeriods(widget.timetable.periodDefinitions);
    final resolution = _resolveVisibleEntries(
      scheduledEntries: visibleScheduledEntries,
      periods: periods,
    );
    if (resolution.hasConfigurationError) {
      return _withWeekSwipe(
        SizedBox(
          height: widget.height,
          child: const TimetableConfigurationErrorState(),
        ),
      );
    }

    final entries = resolution.entries;
    final placementGroups = _placeEntryGroups(entries);
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

    return _withWeekSwipe(
      SizedBox(
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
              0.0,
              availableHeight - _headerHeight - 1,
            );
            final preferredAxisWidth = math.min(
              widget.periodAxisWidth,
              math.max(_minimumAxisWidth, availableWidth * 0.16),
            );
            final axisWidth = math.min(
              preferredAxisWidth,
              math.max(0.0, availableWidth - 1.01),
            );
            final gridViewportWidth = math.max(
              0.01,
              availableWidth - axisWidth - 1,
            );
            final effectiveDayWidth = gridViewportWidth / weekdays;
            final gridWidth = gridViewportWidth;
            final groupHeaderCount = _nonEmptyGroupCount(periods);
            final textScale = _effectiveTextScale(context);
            final courseTextScaler = MediaQuery.textScalerOf(context)
                .clamp(maxScaleFactor: 1.2);
            final minimumRowHeight =
                _baseMinimumRowHeight + (textScale - 1) * 26;
            final maximumRowHeight = math.max(
              minimumRowHeight,
              widget.periodRowHeight,
            );
            final availableRowsHeight = math.max(
              0.0,
              bodyViewportHeight - groupHeaderCount * _groupHeaderHeight,
            );
            final fittingRowHeight = periods.isEmpty
                ? maximumRowHeight
                : availableRowsHeight / periods.length;
            final initialRowHeight = fittingRowHeight.clamp(
              minimumRowHeight,
              maximumRowHeight,
            );
            final renderItems = _resolveRenderItems(
              placementGroups: placementGroups,
              dayWidth: effectiveDayWidth,
              minimumReadableWidth: _minimumReadableCourseWidth,
            );
            final rowHeights = List<double>.filled(
              periods.length,
              initialRowHeight,
            );
            _growRowsForContent(
              periods: periods,
              rowHeights: rowHeights,
              renderItems: renderItems,
              dayWidth: effectiveDayWidth,
              textDirection: Directionality.of(context),
              textScaler: courseTextScaler,
              titleStyle: _courseTitleStyle,
            );
            _distributeViewportSurplus(
              rowHeights: rowHeights,
              availableRowsHeight: availableRowsHeight,
            );
            final metrics = _TimetableVerticalMetrics(
              periods: periods,
              rowHeights: rowHeights,
              groupHeaderHeight: _groupHeaderHeight,
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
                            color: Theme.of(context)
                                .colorScheme
                                .primaryContainer
                                .withValues(alpha: 0.32),
                          ),
                        ),
                      ),
                    for (final header in metrics.groupHeaders)
                      Positioned(
                        key: WeeklyTimetableView.groupGridHeaderKey(
                          header.group,
                        ),
                        left: 0,
                        right: 0,
                        top: header.top,
                        height: header.bottom - header.top,
                        child: ColoredBox(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
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
                    for (final item in renderItems)
                      if (item.isAggregate)
                        _ConflictCardPositioned(
                          item: item,
                          teachingWeek: widget.teachingWeek,
                          dayWidth: effectiveDayWidth,
                          metrics: metrics,
                          onConflictTap: widget.onConflictTap,
                          onCourseTap: widget.onCourseTap,
                        )
                      else
                        _CourseCardPositioned(
                          item: item,
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
                              key:
                                  WeeklyTimetableView.headerHorizontalScrollKey,
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
                                key:
                                    WeeklyTimetableView.gridHorizontalScrollKey,
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

class _PlacementGroup {
  const _PlacementGroup({
    required this.entries,
    required this.placements,
    required this.startRow,
    required this.endRow,
    required this.columnCount,
  });

  final List<_VisibleEntry> entries;
  final List<_Placement> placements;
  final int startRow;
  final int endRow;
  final int columnCount;
}

class _RenderItem {
  _RenderItem.course(_Placement coursePlacement)
    : placement = coursePlacement,
      aggregateEntries = const [],
      weekday = coursePlacement.entry.session.weekday,
      startRow = coursePlacement.entry.startRow,
      endRow = coursePlacement.entry.endRow,
      column = coursePlacement.column,
      columnCount = coursePlacement.columnCount;

  const _RenderItem.aggregate({
    required this.aggregateEntries,
    required this.weekday,
    required this.startRow,
    required this.endRow,
  }) : placement = null,
       column = 0,
       columnCount = 1;

  final _Placement? placement;
  final List<_VisibleEntry> aggregateEntries;
  final int weekday;
  final int startRow;
  final int endRow;
  final int column;
  final int columnCount;

  bool get isAggregate => placement == null;

  _VisibleEntry get entry => placement!.entry;

  double cardWidth(double dayWidth) {
    final columnWidth = dayWidth / columnCount;
    final gap = _courseCardGap(columnWidth);
    return math.max(1, columnWidth - gap * 2);
  }
}

List<_PlacementGroup> _placeEntryGroups(List<_VisibleEntry> entries) {
  final groups = <_PlacementGroup>[];
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
      final placements = <_Placement>[
        for (var index = 0; index < group.length; index++)
          _Placement(
            entry: group[index],
            column: columns[index],
            columnCount: columnEndRows.length,
          ),
      ];
      groups.add(
        _PlacementGroup(
          entries: group,
          placements: placements,
          startRow: group.first.startRow,
          endRow: occupiedThrough,
          columnCount: columnEndRows.length,
        ),
      );
      groupStart = groupEnd;
    }
  }
  return groups;
}

List<_RenderItem> _resolveRenderItems({
  required List<_PlacementGroup> placementGroups,
  required double dayWidth,
  required double minimumReadableWidth,
}) {
  return [
    for (final group in placementGroups)
      if (group.columnCount > 1 &&
          dayWidth / group.columnCount < minimumReadableWidth)
        _RenderItem.aggregate(
          aggregateEntries: group.entries,
          weekday: group.entries.first.session.weekday,
          startRow: group.startRow,
          endRow: group.endRow,
        )
      else
        for (final placement in group.placements) _RenderItem.course(placement),
  ];
}

void _growRowsForContent({
  required List<_DisplayPeriod> periods,
  required List<double> rowHeights,
  required List<_RenderItem> renderItems,
  required double dayWidth,
  required TextDirection textDirection,
  required TextScaler textScaler,
  required TextStyle titleStyle,
}) {
  for (final item in renderItems) {
    if (item.isAggregate) {
      continue;
    }
    final entry = item.entry;
    final cardWidth = item.cardWidth(dayWidth);
    final padding = _courseCardPadding(cardWidth);
    final contentWidth = math.max(1.0, cardWidth - padding * 2);
    final titleHeight = _measureText(
      entry.courseWithSessions.course.name,
      style: titleStyle,
      textDirection: textDirection,
      textScaler: textScaler,
      maxWidth: contentWidth,
    ).height;
    final metadataStyle = _WeeklyTimetableViewState._courseMetadataStyle;
    final metadataLineHeight = _measureText(
      'Hg',
      style: metadataStyle,
      textDirection: textDirection,
      textScaler: textScaler,
      maxWidth: contentWidth,
      maxLines: 1,
    ).height;
    var optionalMetadataHeight = 0.0;
    final teacher = entry.courseWithSessions.course.teacher?.trim();
    if (teacher?.isNotEmpty == true &&
        _fitsSingleLine(
          text: teacher!,
          style: metadataStyle,
          textDirection: textDirection,
          textScaler: textScaler,
          maxWidth: contentWidth,
        )) {
      optionalMetadataHeight += metadataLineHeight;
    }
    final compactLocation = compactLocationLabel(entry.session.location);
    if (compactLocation != null &&
        _fitsSingleLine(
          text: compactLocation,
          style: metadataStyle,
          textDirection: textDirection,
          textScaler: textScaler,
          maxWidth: contentWidth,
        )) {
      optionalMetadataHeight += metadataLineHeight;
    }
    final columnWidth = dayWidth / item.columnCount;
    final gap = _courseCardGap(columnWidth);
    final requiredOuterHeight =
        titleHeight + padding * 2 + gap * 2 + optionalMetadataHeight;
    final currentSpanHeight = _rowSpanHeight(
      periods: periods,
      rowHeights: rowHeights,
      startRow: item.startRow,
      endRow: item.endRow,
    );
    final deficit = requiredOuterHeight - currentSpanHeight;
    if (deficit <= 0.01) {
      continue;
    }
    final coveredRows = item.endRow - item.startRow + 1;
    final increment = deficit / coveredRows;
    for (var row = item.startRow; row <= item.endRow; row++) {
      rowHeights[row] += increment;
    }
  }
}

double _rowSpanHeight({
  required List<_DisplayPeriod> periods,
  required List<double> rowHeights,
  required int startRow,
  required int endRow,
}) {
  var result = 0.0;
  for (var row = startRow; row <= endRow; row++) {
    result += rowHeights[row];
    if (row > startRow && periods[row - 1].group != periods[row].group) {
      result += _WeeklyTimetableViewState._groupHeaderHeight;
    }
  }
  return result;
}

TextPainter _measureText(
  String text, {
  required TextStyle style,
  required TextDirection textDirection,
  required TextScaler textScaler,
  required double maxWidth,
  int? maxLines,
}) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: textDirection,
    textScaler: textScaler,
    maxLines: maxLines,
  )..layout(maxWidth: math.max(1, maxWidth));
  return painter;
}

bool _fitsSingleLine({
  required String text,
  required TextStyle style,
  required TextDirection textDirection,
  required TextScaler textScaler,
  required double maxWidth,
}) {
  final painter = _measureText(
    text,
    style: style,
    textDirection: textDirection,
    textScaler: textScaler,
    maxWidth: maxWidth,
    maxLines: 1,
  );
  return !painter.didExceedMaxLines && painter.width <= maxWidth + 0.01;
}

void _distributeViewportSurplus({
  required List<double> rowHeights,
  required double availableRowsHeight,
}) {
  if (rowHeights.isEmpty) {
    return;
  }
  final usedHeight = rowHeights.fold<double>(0, (sum, height) => sum + height);
  final surplus = availableRowsHeight - usedHeight;
  if (surplus <= 0.01) {
    return;
  }
  final extra = surplus / rowHeights.length;
  for (var index = 0; index < rowHeights.length; index++) {
    rowHeights[index] += extra;
  }
}

double _courseCardGap(double columnWidth) => columnWidth < 32 ? 0.5 : 2.0;

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

class _GroupHeaderMetric {
  const _GroupHeaderMetric({
    required this.group,
    required this.top,
    required this.bottom,
    required this.periodCount,
  });

  final PeriodGroup group;
  final double top;
  final double bottom;
  final int periodCount;
}

class _TimetableVerticalMetrics {
  _TimetableVerticalMetrics({
    required List<_DisplayPeriod> periods,
    required List<double> rowHeights,
    required this.groupHeaderHeight,
  }) : rowHeights = List<double>.unmodifiable(rowHeights) {
    assert(periods.length == rowHeights.length);
    var offset = 0.0;
    for (var index = 0; index < periods.length; index++) {
      final startsGroup =
          index == 0 || periods[index - 1].group != periods[index].group;
      if (startsGroup) {
        final group = periods[index].group;
        final periodCount = periods
            .where((period) => period.group == group)
            .length;
        groupHeaders.add(
          _GroupHeaderMetric(
            group: group,
            top: offset,
            bottom: offset + groupHeaderHeight,
            periodCount: periodCount,
          ),
        );
        offset += groupHeaderHeight;
      }
      periodTops.add(offset);
      offset += rowHeights[index];
      periodBottoms.add(offset);
    }
    totalHeight = offset;
  }

  final List<double> rowHeights;
  final double groupHeaderHeight;
  final List<double> periodTops = [];
  final List<double> periodBottoms = [];
  final List<_GroupHeaderMetric> groupHeaders = [];
  late final double totalHeight;

  double periodTop(int row) => periodTops[row];

  double periodBottom(int row) => periodBottoms[row];

  double rowHeight(int row) => rowHeights[row];
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
    return SizedBox(
      width: width,
      height: metrics.totalHeight,
      child: Stack(
        children: [
          for (final header in metrics.groupHeaders)
            Positioned(
              key: WeeklyTimetableView.groupSeparatorKey(header.group),
              left: 0,
              right: 0,
              top: header.top,
              height: header.bottom - header.top,
              child: Semantics(
                key: WeeklyTimetableView.groupLabelKey(header.group),
                container: true,
                header: true,
                label:
                    '${_periodGroupLabel(header.group)}，共${header.periodCount}节',
                child: ExcludeSemantics(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      border: Border.symmetric(
                        horizontal: BorderSide(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${_periodGroupLabel(header.group)} · ${header.periodCount}节',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 9,
                          height: 1,
                        ),
                      ),
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
              height: metrics.rowHeight(index),
              child: _PeriodAxisCell(period: periods[index]),
            ),
        ],
      ),
    );
  }
}

class _PeriodAxisCell extends StatelessWidget {
  const _PeriodAxisCell({required this.period});

  final _DisplayPeriod period;

  @override
  Widget build(BuildContext context) {
    final startTime = period.startTime ?? '--:--';
    final endTime = period.endTime ?? '--:--';
    final semanticsLabel = period.hasTimes
        ? '第${period.period}节，上课时间$startTime，下课时间$endTime'
        : '第${period.period}节，上课时间未提供，下课时间未提供';
    final timeStyle = TextStyle(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      fontSize: 9.5,
      height: 1,
    );

    return Semantics(
      container: true,
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 2),
            child: Center(
              child: MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.5,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      key: WeeklyTimetableView.periodNumberKey(period.period),
                      '第${period.period}节',
                      maxLines: 1,
                      softWrap: false,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      key: WeeklyTimetableView.startTimeKey(period.period),
                      startTime,
                      maxLines: 1,
                      softWrap: false,
                      style: timeStyle,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      key: WeeklyTimetableView.endTimeKey(period.period),
                      endTime,
                      maxLines: 1,
                      softWrap: false,
                      style: timeStyle,
                    ),
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

String _periodGroupLabel(PeriodGroup group) {
  return switch (group) {
    PeriodGroup.morning => '上午',
    PeriodGroup.afternoon => '下午',
    PeriodGroup.evening => '晚上',
  };
}

class _CourseCardPositioned extends StatelessWidget {
  const _CourseCardPositioned({
    required this.item,
    required this.teachingWeek,
    required this.dayWidth,
    required this.metrics,
    required this.onTap,
  });

  final _RenderItem item;
  final int teachingWeek;
  final double dayWidth;
  final _TimetableVerticalMetrics metrics;
  final CourseSessionTapCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final placement = item.placement!;
    final entry = placement.entry;
    final session = entry.session;
    final courseWithSessions = entry.courseWithSessions;
    final course = courseWithSessions.course;
    final columnWidth = dayWidth / placement.columnCount;
    final gap = _courseCardGap(columnWidth);
    final cardWidth = math.max(1.0, columnWidth - gap * 2);
    final padding = _courseCardPadding(cardWidth);
    final color = Color(course.colorValue);
    final foreground =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black87;
    final fullLocation = session.location?.trim();
    final locationLabel = fullLocation == null || fullLocation.isEmpty
        ? '地点未注明'
        : fullLocation;
    final teacher = course.teacher?.trim();
    final teacherLabel = teacher == null || teacher.isEmpty ? '教师未注明' : teacher;
    final compactLocation = compactLocationLabel(fullLocation);
    final weekdayLabel = _WeekdayHeader.labels[session.weekday - 1];
    final semanticsLabel =
        '${course.name}，$teacherLabel，$locationLabel，$weekdayLabel，'
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
      width: cardWidth,
      height: math.max(1, bottom - top - gap * 2),
      child: Semantics(
        container: true,
        excludeSemantics: true,
        button: onTap != null,
        label: semanticsLabel,
        hint: onTap == null ? null : '点击查看课程',
        child: Material(
          color: color,
          borderRadius: BorderRadius.circular(cardWidth < 36 ? 4 : 8),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap == null
                ? null
                : () => onTap!(courseWithSessions, session),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final textScaler = MediaQuery.textScalerOf(context)
                    .clamp(maxScaleFactor: 1.2);
                final titleStyle = _WeeklyTimetableViewState._courseTitleStyle
                    .copyWith(color: foreground);
                final metadataStyle = _WeeklyTimetableViewState
                    ._courseMetadataStyle
                    .copyWith(color: foreground.withValues(alpha: 0.92));
                final contentWidth = math.max(
                  1.0,
                  constraints.maxWidth - padding * 2,
                );
                final titleHeight = _measureText(
                  course.name,
                  style: titleStyle,
                  textDirection: Directionality.of(context),
                  textScaler: textScaler,
                  maxWidth: contentWidth,
                ).height;
                final metadataLineHeight = _measureText(
                  'Hg',
                  style: metadataStyle,
                  textDirection: Directionality.of(context),
                  textScaler: textScaler,
                  maxWidth: contentWidth,
                  maxLines: 1,
                ).height;
                var remainingHeight =
                    constraints.maxHeight - padding * 2 - titleHeight;
                final showTeacher =
                    teacher?.isNotEmpty == true &&
                    remainingHeight + 0.01 >= metadataLineHeight &&
                    _fitsSingleLine(
                      text: teacher!,
                      style: metadataStyle,
                      textDirection: Directionality.of(context),
                      textScaler: textScaler,
                      maxWidth: contentWidth,
                    );
                if (showTeacher) {
                  remainingHeight -= metadataLineHeight;
                }
                final showLocation =
                    compactLocation != null &&
                    remainingHeight + 0.01 >= metadataLineHeight &&
                    _fitsSingleLine(
                      text: compactLocation,
                      style: metadataStyle,
                      textDirection: Directionality.of(context),
                      textScaler: textScaler,
                      maxWidth: contentWidth,
                    );
                return Padding(
                  padding: EdgeInsets.all(padding),
                  child: MediaQuery.withClampedTextScaling(
                    maxScaleFactor: 1.2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          key: WeeklyTimetableView.courseTitleKey(session.id),
                          course.name,
                          softWrap: true,
                          maxLines: null,
                          style: titleStyle,
                        ),
                        if (showTeacher)
                          Text(
                            key: WeeklyTimetableView.courseTeacherKey(
                              session.id,
                            ),
                            teacher,
                            softWrap: false,
                            maxLines: 1,
                            style: metadataStyle,
                          ),
                        if (showLocation)
                          Text(
                            key: WeeklyTimetableView.courseLocationKey(
                              session.id,
                            ),
                            compactLocation,
                            softWrap: false,
                            maxLines: 1,
                            style: metadataStyle,
                          ),
                      ],
                    ),
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

double _courseCardPadding(double width) {
  return width < 36
      ? 1.5
      : width < 60
      ? 2.5
      : 4.0;
}

class _ConflictCardPositioned extends StatelessWidget {
  const _ConflictCardPositioned({
    required this.item,
    required this.teachingWeek,
    required this.dayWidth,
    required this.metrics,
    required this.onConflictTap,
    required this.onCourseTap,
  });

  final _RenderItem item;
  final int teachingWeek;
  final double dayWidth;
  final _TimetableVerticalMetrics metrics;
  final ConflictTapCallback? onConflictTap;
  final CourseSessionTapCallback? onCourseTap;

  @override
  Widget build(BuildContext context) {
    final entries = [
      for (final entry in item.aggregateEntries)
        CourseSessionViewEntry(
          courseWithSessions: entry.courseWithSessions,
          session: entry.session,
        ),
    ];
    final count = entries.length;
    final startPeriod = item.aggregateEntries
        .map((entry) => entry.session.startPeriod)
        .reduce(math.min);
    final endPeriod = item.aggregateEntries
        .map((entry) => entry.session.endPeriod)
        .reduce(math.max);
    final names = entries
        .map((entry) => entry.courseWithSessions.course.name)
        .join('、');
    final top = metrics.periodTop(item.startRow);
    final bottom = metrics.periodBottom(item.endRow);
    const gap = 2.0;
    return Positioned(
      key: WeeklyTimetableView.conflictCardKey(
        item.weekday,
        startPeriod,
        endPeriod,
      ),
      left: (item.weekday - 1) * dayWidth + gap,
      top: top + gap,
      width: math.max(1, dayWidth - gap * 2),
      height: math.max(1, bottom - top - gap * 2),
      child: Semantics(
        container: true,
        excludeSemantics: true,
        button: true,
        label: '$count门课程冲突：$names',
        hint: '点击查看全部冲突课程',
        child: Material(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(8),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              final callback = onConflictTap;
              if (callback != null) {
                callback(entries);
                return;
              }
              _showDefaultConflictSheet(
                context,
                entries: entries,
                teachingWeek: teachingWeek,
                onCourseTap: onCourseTap,
              );
            },
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Text(
                  '$count门课程冲突',
                  softWrap: true,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _showDefaultConflictSheet(
  BuildContext context, {
  required List<CourseSessionViewEntry> entries,
  required int teachingWeek,
  required CourseSessionTapCallback? onCourseTap,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      return SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Text(
              '${entries.length}门课程冲突',
              style: Theme.of(sheetContext).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            for (final entry in entries)
              ListTile(
                contentPadding: EdgeInsets.zero,
                isThreeLine: true,
                title: Text(entry.courseWithSessions.course.name),
                subtitle: Text(
                  _conflictEntryDetails(entry, teachingWeek),
                  maxLines: null,
                ),
                onTap: onCourseTap == null
                    ? null
                    : () {
                        Navigator.of(sheetContext).pop();
                        onCourseTap(entry.courseWithSessions, entry.session);
                      },
              ),
          ],
        ),
      );
    },
  );
}

String _conflictEntryDetails(CourseSessionViewEntry entry, int teachingWeek) {
  final teacher = entry.courseWithSessions.course.teacher?.trim();
  final location = entry.session.location?.trim();
  final weeks = entry.session.weeks.toList()..sort();
  return [
    if (teacher?.isNotEmpty == true) teacher!,
    if (location?.isNotEmpty == true) location!,
    '第${entry.session.startPeriod}至${entry.session.endPeriod}节',
    '周次：${weeks.join('、')}（当前第$teachingWeek周）',
  ].join('\n');
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
    final headerPaint = Paint()..color = separatorColor;
    for (final header in metrics.groupHeaders) {
      canvas.drawRect(
        Rect.fromLTRB(0, header.top, size.width, header.bottom),
        headerPaint,
      );
      canvas.drawLine(
        Offset(0, header.top),
        Offset(size.width, header.top),
        linePaint,
      );
      canvas.drawLine(
        Offset(0, header.bottom),
        Offset(size.width, header.bottom),
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
        !_sameDoubles(oldDelegate.metrics.rowHeights, metrics.rowHeights) ||
        oldDelegate.metrics.groupHeaderHeight != metrics.groupHeaderHeight ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.separatorColor != separatorColor;
  }
}

bool _sameDoubles(List<double> first, List<double> second) {
  if (first.length != second.length) {
    return false;
  }
  for (var index = 0; index < first.length; index++) {
    if (first[index] != second[index]) {
      return false;
    }
  }
  return true;
}

int _nonEmptyGroupCount(List<_DisplayPeriod> periods) {
  return PeriodGroup.values
      .where((group) => periods.any((period) => period.group == group))
      .length;
}

double _effectiveTextScale(BuildContext context) {
  final scaler = MediaQuery.textScalerOf(context);
  return (scaler.scale(14) / 14).clamp(1, 3);
}

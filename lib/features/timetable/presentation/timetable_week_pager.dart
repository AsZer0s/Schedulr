import 'package:flutter/material.dart';

import '../domain/timetable_models.dart';
import 'weekly_timetable_view.dart';

/// Displays all teaching weeks in chronological order through one pager.
class TimetableWeekPager extends StatefulWidget {
  const TimetableWeekPager({
    required this.timetable,
    required this.teachingWeek,
    required this.height,
    required this.onWeekChanged,
    this.onCourseTap,
    this.onConflictTap,
    this.today,
    this.showWeekend = true,
    super.key,
  });

  final SemesterTimetable timetable;
  final int teachingWeek;
  final double height;
  final ValueChanged<int> onWeekChanged;
  final CourseSessionTapCallback? onCourseTap;
  final ConflictTapCallback? onConflictTap;
  final DateTime? today;
  final bool showWeekend;

  @override
  State<TimetableWeekPager> createState() => _TimetableWeekPagerState();
}

class _TimetableWeekPagerState extends State<TimetableWeekPager> {
  static const _pageDuration = Duration(milliseconds: 240);
  static const _pageCurve = Curves.easeOutCubic;

  late final PageController _pageController;
  final Map<int, double> _verticalOffsets = <int, double>{};
  int? _pendingProgrammaticPage;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.teachingWeek - 1);
  }

  @override
  void didUpdateWidget(covariant TimetableWeekPager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.teachingWeek != widget.teachingWeek) {
      _moveToWeek(widget.teachingWeek);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _moveToWeek(int week) {
    if (!_pageController.hasClients) {
      return;
    }
    final page = week - 1;
    if ((_pageController.page ?? _pageController.initialPage).round() == page) {
      return;
    }
    _pendingProgrammaticPage = page;
    if (MediaQuery.disableAnimationsOf(context)) {
      _pageController.jumpToPage(page);
      if (_pendingProgrammaticPage == page) {
        _pendingProgrammaticPage = null;
      }
      return;
    }
    _pageController
        .animateToPage(page, duration: _pageDuration, curve: _pageCurve)
        .whenComplete(() {
          if (mounted && _pendingProgrammaticPage == page) {
            _pendingProgrammaticPage = null;
          }
        });
  }

  void _onPageChanged(int page) {
    final week = page + 1;
    if (_pendingProgrammaticPage != null) {
      if (_pendingProgrammaticPage == page &&
          (_pageController.page ?? page.toDouble()).round() == page) {
        return;
      }
      return;
    }
    widget.onWeekChanged(week);
  }

  void _rememberVerticalOffset(int week, double offset) {
    if ((offset - (_verticalOffsets[week] ?? 0)).abs() >= 0.5) {
      _verticalOffsets[week] = offset;
    }
  }

  @override
  Widget build(BuildContext context) {
    final teachingWeeks = widget.timetable.semester.teachingWeeks;
    return ClipRect(
      child: PageView.builder(
        key: const ValueKey<String>('timetable-week-pager'),
        controller: _pageController,
        itemCount: teachingWeeks,
        onPageChanged: _onPageChanged,
        clipBehavior: Clip.hardEdge,
        itemBuilder: (context, index) {
          final week = index + 1;
          return KeyedSubtree(
            key: ValueKey<String>('timetable-week-page-$week'),
            child: WeeklyTimetableView(
              timetable: widget.timetable,
              teachingWeek: week,
              showWeekend: widget.showWeekend,
              onCourseTap: widget.onCourseTap,
              onConflictTap: widget.onConflictTap,
              today: widget.today,
              height: widget.height,
              initialVerticalOffset: _verticalOffsets[week] ?? 0,
              onVerticalOffsetChanged: (offset) =>
                  _rememberVerticalOffset(week, offset),
            ),
          );
        },
      ),
    );
  }
}

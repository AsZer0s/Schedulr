import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/time/teaching_calendar.dart';
import '../../data/providers.dart';
import '../../domain/timetable_models.dart';
import '../weekly_timetable_view.dart';

class TimetableHomePage extends ConsumerStatefulWidget {
  const TimetableHomePage({super.key});

  @override
  ConsumerState<TimetableHomePage> createState() => _TimetableHomePageState();
}

class _TimetableHomePageState extends ConsumerState<TimetableHomePage> {
  int? _selectedWeek;
  _SemesterCalendar? _semesterCalendar;
  _SemesterCalendar? _pendingSemesterCalendar;

  void _selectWeek(Semester semester, DateTime today, int delta) {
    final current = _effectiveWeek(semester, today, _selectionFor(semester));
    if (current == null) {
      return;
    }
    _setSelectedWeek(semester, current + delta);
  }

  void _setSelectedWeek(Semester semester, int week) {
    setState(() {
      _semesterCalendar = _SemesterCalendar.fromSemester(semester);
      _pendingSemesterCalendar = null;
      _selectedWeek = week.clamp(1, semester.teachingWeeks);
    });
  }

  void _followToday(Semester semester) {
    setState(() {
      _semesterCalendar = _SemesterCalendar.fromSemester(semester);
      _pendingSemesterCalendar = null;
      _selectedWeek = null;
    });
  }

  int? _selectionFor(Semester semester) {
    final calendar = _SemesterCalendar.fromSemester(semester);
    return calendar == _semesterCalendar ? _selectedWeek : null;
  }

  int? _effectiveWeek(Semester semester, DateTime today, int? selectedWeek) {
    if (selectedWeek != null) {
      return selectedWeek.clamp(1, semester.teachingWeeks);
    }
    return teachingWeekForDate(semester, today);
  }

  void _synchronizeSemesterCalendar(Semester semester) {
    final calendar = _SemesterCalendar.fromSemester(semester);
    if (calendar == _semesterCalendar || calendar == _pendingSemesterCalendar) {
      return;
    }
    _pendingSemesterCalendar = calendar;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _pendingSemesterCalendar != calendar) {
        return;
      }
      setState(() {
        _semesterCalendar = calendar;
        _pendingSemesterCalendar = null;
        _selectedWeek = null;
      });
    });
  }

  void _openCourse(CourseWithSessions course, CourseSession _) {
    context.push('/course/${course.course.id}');
  }

  @override
  Widget build(BuildContext context) {
    final timetable = ref.watch(currentTimetableProvider);
    final today = ref.watch(currentDateProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('课程表'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'import':
                  context.push('/import');
                case 'settings':
                  context.push('/settings');
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'import', child: Text('导入课表')),
              PopupMenuItem(value: 'settings', child: Text('设置')),
            ],
          ),
        ],
      ),
      body: timetable.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _LoadFailure(
          onRetry: () => ref.invalidate(currentTimetableProvider),
        ),
        data: (value) {
          if (value == null) {
            return const Center(child: Text('正在初始化本地学期…'));
          }

          final semester = value.semester;
          _synchronizeSemesterCalendar(semester);
          final selectedWeek = _selectionFor(semester);
          final week = _effectiveWeek(semester, today, selectedWeek);
          if (week == null) {
            return _TodayOutsideSemester(
              semester: semester,
              today: today,
              onViewFirstWeek: () => _setSelectedWeek(semester, 1),
              onOpenSemesterSettings: () => context.push('/settings/semester'),
            );
          }

          return Column(
            children: [
              _WeekSelector(
                semester: semester,
                week: week,
                followsToday: selectedWeek == null,
                onPrevious: week > 1
                    ? () => _selectWeek(semester, today, -1)
                    : null,
                onNext: week < semester.teachingWeeks
                    ? () => _selectWeek(semester, today, 1)
                    : null,
                onToday: () => _followToday(semester),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: LayoutBuilder(
                    builder: (context, constraints) => WeeklyTimetableView(
                      timetable: value,
                      teachingWeek: week,
                      today: today,
                      height: constraints.maxHeight,
                      onCourseTap: _openCourse,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/course/new'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('添加课程'),
      ),
    );
  }
}

class _SemesterCalendar {
  const _SemesterCalendar({
    required this.id,
    required this.startDate,
    required this.teachingWeeks,
  });

  factory _SemesterCalendar.fromSemester(Semester semester) {
    return _SemesterCalendar(
      id: semester.id,
      startDate: semester.startDate,
      teachingWeeks: semester.teachingWeeks,
    );
  }

  final String id;
  final DateTime startDate;
  final int teachingWeeks;

  @override
  bool operator ==(Object other) {
    return other is _SemesterCalendar &&
        other.id == id &&
        other.startDate == startDate &&
        other.teachingWeeks == teachingWeeks;
  }

  @override
  int get hashCode => Object.hash(id, startDate, teachingWeeks);
}

class _WeekSelector extends StatelessWidget {
  const _WeekSelector({
    required this.semester,
    required this.week,
    required this.followsToday,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
  });

  final Semester semester;
  final int week;
  final bool followsToday;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final start = dateForTeachingWeekday(semester, week, DateTime.monday);
    final end = dateForTeachingWeekday(semester, week, DateTime.sunday);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: Row(
        children: [
          IconButton(
            tooltip: '上一周',
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onToday,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    Text(
                      followsToday ? '第 $week 周 · 今天' : '第 $week 周',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      followsToday
                          ? '${start.month}/${start.day} - ${end.month}/${end.day} · ${semester.name}'
                          : '${start.month}/${start.day} - ${end.month}/${end.day} · 回到本周',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: '下一周',
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

class _TodayOutsideSemester extends StatelessWidget {
  const _TodayOutsideSemester({
    required this.semester,
    required this.today,
    required this.onViewFirstWeek,
    required this.onOpenSemesterSettings,
  });

  final Semester semester;
  final DateTime today;
  final VoidCallback onViewFirstWeek;
  final VoidCallback onOpenSemesterSettings;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_busy_rounded, size: 48),
            const SizedBox(height: 12),
            Text('当前日期不在本学期', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              '${today.year}/${today.month}/${today.day} 不在“${semester.name}”的教学周范围内。',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onViewFirstWeek,
              child: const Text('查看第1周'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: onOpenSemesterSettings,
              child: const Text('设置学期校历'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadFailure extends StatelessWidget {
  const _LoadFailure({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, size: 44),
          const SizedBox(height: 12),
          const Text('无法读取本地课表'),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }
}

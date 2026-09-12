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
  bool _showWeekend = false;

  void _selectWeek(Semester semester, int delta) {
    final current = _effectiveWeek(semester);
    setState(
      () => _selectedWeek = (current + delta).clamp(1, semester.teachingWeeks),
    );
  }

  int _effectiveWeek(Semester semester) {
    return _selectedWeek ?? teachingWeekForDate(semester, DateTime.now()) ?? 1;
  }

  void _openCourse(CourseWithSessions course, CourseSession _) {
    context.push('/course/${course.course.id}');
  }

  @override
  Widget build(BuildContext context) {
    final timetable = ref.watch(currentTimetableProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('课程表'),
        actions: [
          IconButton(
            tooltip: _showWeekend ? '隐藏周末' : '显示周末',
            onPressed: () => setState(() => _showWeekend = !_showWeekend),
            icon: Icon(
              _showWeekend
                  ? Icons.calendar_view_week_rounded
                  : Icons.workspaces_outline,
            ),
          ),
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
          final week = _effectiveWeek(value.semester);
          return Column(
            children: [
              _WeekSelector(
                semester: value.semester,
                week: week,
                onPrevious: week > 1
                    ? () => _selectWeek(value.semester, -1)
                    : null,
                onNext: week < value.semester.teachingWeeks
                    ? () => _selectWeek(value.semester, 1)
                    : null,
                onToday: () => setState(() {
                  _selectedWeek =
                      teachingWeekForDate(value.semester, DateTime.now()) ?? 1;
                }),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: LayoutBuilder(
                    builder: (context, constraints) => WeeklyTimetableView(
                      timetable: value,
                      teachingWeek: week,
                      showWeekend: _showWeekend,
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

class _WeekSelector extends StatelessWidget {
  const _WeekSelector({
    required this.semester,
    required this.week,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
  });

  final Semester semester;
  final int week;
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
                      '第 $week 周',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${start.month}/${start.day} - ${end.month}/${end.day} · ${semester.name}',
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
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
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

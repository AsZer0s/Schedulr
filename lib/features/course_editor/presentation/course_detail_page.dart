import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../app/widgets/adaptive_scaffold.dart';

import '../../../core/platform/adaptive_ui.dart';
import '../../../core/time/week_set.dart';
import '../../timetable/domain/timetable_models.dart';

class CourseDetailPage extends StatefulWidget {
  const CourseDetailPage({
    required this.course,
    this.periodDefinitions = const [],
    this.onEdit,
    this.onDelete,
    super.key,
  });

  final CourseWithSessions course;
  final List<PeriodDefinition> periodDefinitions;
  final Future<void> Function()? onEdit;
  final Future<void> Function()? onDelete;

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  bool _isDeleting = false;

  Future<void> _delete() async {
    final onDelete = widget.onDelete;
    if (onDelete == null) return;
    final confirmed = await showAdaptiveConfirmationDialog(
      context,
      title: '删除课程？',
      message: '课程及其所有安排将被删除，此操作无法撤销。',
      confirmLabel: '删除',
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      await onDelete();
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final course = widget.course.course;
    final theme = Theme.of(context);
    final teacher = _displayValue(course.teacher);
    final notes = _displayValue(course.notes);

    final isCupertino = usesCupertinoConventions(context);
    final actions = [
      if (widget.onEdit != null)
        isCupertino
            ? CupertinoButton(
                key: const Key('course-detail-edit'),
                padding: EdgeInsets.zero,
                onPressed: _isDeleting ? null : widget.onEdit,
                child: const Icon(CupertinoIcons.pencil),
              )
            : IconButton(
                key: const Key('course-detail-edit'),
                tooltip: '编辑课程',
                onPressed: _isDeleting ? null : widget.onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
      if (widget.onDelete != null)
        isCupertino
            ? CupertinoButton(
                key: const Key('course-detail-delete'),
                padding: EdgeInsets.zero,
                onPressed: _isDeleting ? null : _delete,
                child: _isDeleting
                    ? const CupertinoActivityIndicator()
                    : const Icon(CupertinoIcons.delete),
              )
            : IconButton(
                key: const Key('course-detail-delete'),
                tooltip: '删除课程',
                onPressed: _isDeleting ? null : _delete,
                icon: _isDeleting
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_outline_rounded),
              ),
    ];

    return AdaptiveScaffold(
      title: const Text('课程详情'),
      actions: isCupertino ? const [] : actions,
      cupertinoTrailing: isCupertino
          ? Row(mainAxisSize: MainAxisSize.min, children: actions)
          : null,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 8,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Color(course.colorValue),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course.name,
                            style: theme.textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 10),
                          _DetailLine(
                            icon: Icons.person_outline_rounded,
                            label: '教师',
                            value: teacher,
                          ),
                          const SizedBox(height: 6),
                          _DetailLine(
                            icon: Icons.place_outlined,
                            label: '地点',
                            value: _allLocations(widget.course.sessions),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('课程安排', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (widget.course.sessions.isEmpty)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.event_busy_outlined),
                  title: Text('暂无课程安排'),
                ),
              )
            else
              for (
                var index = 0;
                index < widget.course.sessions.length;
                index++
              ) ...[
                _SessionDetailCard(
                  index: index,
                  session: widget.course.sessions[index],
                  periodDefinitions: widget.periodDefinitions,
                  semesterId: widget.course.course.semesterId,
                ),
                const SizedBox(height: 10),
              ],
            const SizedBox(height: 10),
            Text('备注', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.notes_rounded),
                    const SizedBox(width: 12),
                    Expanded(child: Text(notes)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _displayValue(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? '未填写' : trimmed;
  }

  String _allLocations(List<CourseSession> sessions) {
    final locations = <String>{
      for (final session in sessions)
        if (session.location?.trim().isNotEmpty ?? false)
          session.location!.trim(),
    };
    return locations.isEmpty ? '未填写' : locations.join('、');
  }
}

class _SessionDetailCard extends StatelessWidget {
  const _SessionDetailCard({
    required this.index,
    required this.session,
    required this.periodDefinitions,
    required this.semesterId,
  });

  final int index;
  final CourseSession session;
  final List<PeriodDefinition> periodDefinitions;
  final String semesterId;

  @override
  Widget build(BuildContext context) {
    final location = session.location?.trim();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '安排 ${index + 1}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 10),
            _DetailLine(
              icon: Icons.schedule_outlined,
              label: '时间',
              value: _timeLabel(),
            ),
            const SizedBox(height: 8),
            _DetailLine(
              icon: Icons.date_range_outlined,
              label: '周次',
              value: '第${formatWeekExpression(session.weeks)}周',
            ),
            const SizedBox(height: 8),
            _DetailLine(
              icon: Icons.place_outlined,
              label: '地点',
              value: location == null || location.isEmpty ? '未填写' : location,
            ),
          ],
        ),
      ),
    );
  }

  String _timeLabel() {
    final base =
        '星期${_weekdayName(session.weekday)} '
        '第${session.startPeriod}-${session.endPeriod}节';
    final byPeriod = <int, PeriodDefinition>{
      for (final definition in periodDefinitions)
        if (definition.semesterId == semesterId) definition.period: definition,
    };
    final start = byPeriod[session.startPeriod];
    final end = byPeriod[session.endPeriod];
    if (start == null || end == null || start.startMinutes >= end.endMinutes) {
      return '$base · 具体时间未配置';
    }
    return '$base · ${start.startTime}–${end.endTime}';
  }

  static String _weekdayName(int weekday) {
    return const ['一', '二', '三', '四', '五', '六', '日'][weekday - 1];
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$label：',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

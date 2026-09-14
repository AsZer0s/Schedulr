import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../app/widgets/adaptive_scaffold.dart';
import '../../../core/platform/adaptive_ui.dart';
import '../../timetable/domain/course_with_sessions.dart';
import '../domain/bitc_refresh_reconciler.dart';

class BitcRefreshPreviewPage extends StatefulWidget {
  const BitcRefreshPreviewPage({
    required this.plan,
    required this.timetableName,
    required this.onCommit,
    super.key,
  });

  final BitcRefreshPlan plan;
  final String timetableName;
  final Future<void> Function() onCommit;

  @override
  State<BitcRefreshPreviewPage> createState() => _BitcRefreshPreviewPageState();
}

class _BitcRefreshPreviewPageState extends State<BitcRefreshPreviewPage> {
  bool _committing = false;
  String? _error;

  Future<void> _commit() async {
    if (_committing) return;
    setState(() {
      _committing = true;
      _error = null;
    });
    try {
      await widget.onCommit();
      if (mounted) Navigator.of(context).pop(true);
    } on Object {
      if (!mounted) return;
      setState(() {
        _committing = false;
        _error = '刷新课表失败，请重试。';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final isCupertino = usesCupertinoConventions(context);
    final summary = [
      _RefreshCount('新增', plan.addedCount, Colors.green),
      _RefreshCount('更新', plan.updatedCount, Colors.blue),
      _RefreshCount('删除', plan.removedCount, Colors.orange),
      _RefreshCount(
        '保留本地修改',
        plan.locallyModifiedPreservedCount,
        Colors.purple,
      ),
    ];
    final body = Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('刷新到：${widget.timetableName}'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [for (final item in summary) item],
              ),
              if (plan.locallyModifiedPreservedCount > 0) ...[
                const SizedBox(height: 12),
                Text(
                  '有 ${plan.locallyModifiedPreservedCount} 门课程存在本地修改，已保留本地版本，不会被教务数据覆盖。',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
              ],
              if (plan.manualCoursesPreservedCount > 0) ...[
                const SizedBox(height: 8),
                Text('手动添加的 ${plan.manualCoursesPreservedCount} 门课程会完整保留。'),
              ],
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ..._section('新增课程', plan.added, Icons.add_circle_outline),
              ..._section('更新课程', plan.updated, Icons.sync),
              ..._section('移除课程', plan.removed, Icons.remove_circle_outline),
              ..._section(
                '保留本地修改',
                plan.locallyModifiedPreserved,
                Icons.edit_note,
              ),
              if (plan.addedCount == 0 &&
                  plan.updatedCount == 0 &&
                  plan.removedCount == 0)
                const ListTile(
                  leading: Icon(Icons.check_circle_outline),
                  title: Text('教务课表没有变化'),
                ),
            ],
          ),
        ),
        if (_error case final message?)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              message,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        if (!isCupertino)
          SafeArea(
            minimum: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const ValueKey('bitc-refresh-commit'),
                onPressed: _committing ? null : _commit,
                icon: _committing
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync),
                label: Text(_committing ? '正在应用…' : '应用刷新结果'),
              ),
            ),
          ),
      ],
    );
    return AdaptiveScaffold(
      title: const Text('刷新预览'),
      body: body,
      cupertinoBottomAction: isCupertino
          ? SafeArea(
              minimum: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  key: const ValueKey('bitc-refresh-commit'),
                  onPressed: _committing ? null : _commit,
                  child: Text(_committing ? '正在应用…' : '应用刷新结果'),
                ),
              ),
            )
          : null,
    );
  }

  List<Widget> _section(
    String title,
    List<CourseWithSessions> courses,
    IconData icon,
  ) {
    if (courses.isEmpty) return const [];
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
        child: Text(title, style: Theme.of(context).textTheme.titleSmall),
      ),
      for (final item in courses)
        ListTile(
          leading: Icon(icon),
          title: Text(item.course.name),
          subtitle: Text(item.course.teacher ?? '教师待定'),
        ),
    ];
  }
}

class _RefreshCount extends StatelessWidget {
  const _RefreshCount(this.label, this.count, this.color);

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: color,
        foregroundColor: Colors.white,
        child: Text('$count'),
      ),
      label: Text(label),
    );
  }
}

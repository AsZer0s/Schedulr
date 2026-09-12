import 'package:flutter/material.dart';

import '../domain/import_timetable.dart';

class ImportPreviewPage extends StatelessWidget {
  const ImportPreviewPage({
    required this.preview,
    required this.sourceName,
    required this.onCommit,
    super.key,
  });

  final ImportPreview preview;
  final String sourceName;
  final Future<void> Function() onCommit;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('导入预览')),
      body: SafeArea(
        child: Column(
          children: [
            _ImportSummary(preview: preview, sourceName: sourceName),
            if (preview.issues.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  children: [
                    for (final issue in preview.issues)
                      Card(
                        color: issue.severity == ImportIssueSeverity.error
                            ? Theme.of(context).colorScheme.errorContainer
                            : Theme.of(context).colorScheme.tertiaryContainer,
                        child: ListTile(
                          dense: true,
                          leading: Icon(
                            issue.severity == ImportIssueSeverity.error
                                ? Icons.error_outline_rounded
                                : Icons.info_outline_rounded,
                          ),
                          title: Text(issue.message),
                        ),
                      ),
                  ],
                ),
              ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: preview.items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  return _PreviewItemTile(item: preview.items[index]);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: preview.canCommit && preview.addedCount > 0
                      ? () async => onCommit()
                      : null,
                  icon: const Icon(Icons.download_done_rounded),
                  label: Text('导入 ${preview.addedCount} 条新安排'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImportSummary extends StatelessWidget {
  const _ImportSummary({required this.preview, required this.sourceName});

  final ImportPreview preview;
  final String sourceName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(sourceName, style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            preview.strategy == ImportStrategy.merge
                ? '合并模式：保留现有课表，只写入确认的新安排。'
                : '替换模式：提交时由本地仓库事务替换当前学期数据。',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _CountChip(
                label: '新增',
                count: preview.addedCount,
                color: theme.colorScheme.primary,
              ),
              _CountChip(
                label: '可能重复',
                count: preview.possibleDuplicateCount,
                color: theme.colorScheme.tertiary,
              ),
              _CountChip(
                label: '冲突',
                count: preview.conflictCount,
                color: theme.colorScheme.error,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: color,
        foregroundColor: Theme.of(context).colorScheme.surface,
        child: Text('$count'),
      ),
      label: Text(label),
    );
  }
}

class _PreviewItemTile extends StatelessWidget {
  const _PreviewItemTile({required this.item});

  final ImportPreviewItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, color, status) = switch (item.kind) {
      ImportPreviewItemKind.added => (
        Icons.add_circle_outline_rounded,
        theme.colorScheme.primary,
        '将导入',
      ),
      ImportPreviewItemKind.possibleDuplicate => (
        Icons.content_copy_rounded,
        theme.colorScheme.tertiary,
        '将跳过：可能重复',
      ),
      ImportPreviewItemKind.conflict => (
        Icons.warning_amber_rounded,
        theme.colorScheme.error,
        '将跳过：时间冲突',
      ),
    };
    final entry = item.imported;

    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(entry.title),
        subtitle: Text(
          '周${_weekday(entry.dayOfWeek)} · 第${entry.startPeriod}-${entry.endPeriod}节'
          '${entry.location == null ? '' : ' · ${entry.location}'}\n$status',
        ),
        isThreeLine: true,
      ),
    );
  }

  String _weekday(int weekday) =>
      const ['一', '二', '三', '四', '五', '六', '日'][weekday - 1];
}

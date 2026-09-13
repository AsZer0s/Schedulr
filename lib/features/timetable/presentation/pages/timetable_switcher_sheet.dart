import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/platform/adaptive_ui.dart';

class TimetableSwitcherItem {
  const TimetableSwitcherItem({
    required this.id,
    required this.timetableName,
    required this.semesterName,
    required this.isCurrent,
  });

  final String id;
  final String timetableName;
  final String semesterName;
  final bool isCurrent;
}

enum TimetableAddMethod { blank, bitc }

typedef TimetableRenameCallback = Future<void> Function(
  TimetableSwitcherItem timetable,
  String name,
);
typedef TimetableDeleteCallback = Future<void> Function(
  TimetableSwitcherItem timetable,
);

class TimetableSwitcherSheet extends StatelessWidget {
  const TimetableSwitcherSheet({
    required this.timetables,
    required this.onSelect,
    required this.onRename,
    required this.onDelete,
    required this.onAdd,
    super.key,
  });

  final List<TimetableSwitcherItem> timetables;
  final Future<void> Function(String id) onSelect;
  final TimetableRenameCallback onRename;
  final TimetableDeleteCallback onDelete;
  final Future<void> Function(TimetableAddMethod method, String name) onAdd;

  Future<void> _select(
    BuildContext context,
    TimetableSwitcherItem timetable,
  ) async {
    if (timetable.isCurrent) {
      Navigator.pop(context);
      return;
    }
    await onSelect(timetable.id);
    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _rename(
    BuildContext context,
    TimetableSwitcherItem timetable,
  ) async {
    final name = await showTimetableNameDialog(
      context,
      title: '重命名课表',
      initialValue: timetable.timetableName,
      confirmLabel: '保存',
    );
    if (name == null) return;
    await onRename(timetable, name);
    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _delete(
    BuildContext context,
    TimetableSwitcherItem timetable,
  ) async {
    final confirmed = await showAdaptiveConfirmationDialog(
      context,
      title: '删除“${timetable.timetableName}”？',
      message: '只会删除保存在此设备上的课表数据，不会影响教务系统中的课程。删除最后一份课表后会自动创建一份空白课表。',
      confirmLabel: '删除',
      destructive: true,
    );
    if (!confirmed) return;
    await onDelete(timetable);
    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _add(BuildContext context) async {
    final method = await showAdaptiveActionSheet<TimetableAddMethod>(
      context,
      title: '添加课表',
      actions: const [
        AdaptiveActionSheetAction(
          label: '新建空白',
          value: TimetableAddMethod.blank,
        ),
        AdaptiveActionSheetAction(
          label: '同学登录导入',
          value: TimetableAddMethod.bitc,
        ),
      ],
    );
    if (method == null || !context.mounted) return;
    final name = await showTimetableNameDialog(context, title: '设置本地课表名称');
    if (name == null) return;
    await onAdd(method, name);
  }

  Future<void> _showActions(
    BuildContext context,
    TimetableSwitcherItem timetable,
  ) async {
    final action = await showAdaptiveActionSheet<_TimetableAction>(
      context,
      title: timetable.timetableName,
      actions: const [
        AdaptiveActionSheetAction(label: '重命名', value: _TimetableAction.rename),
        AdaptiveActionSheetAction(
          label: '删除',
          value: _TimetableAction.delete,
          isDestructive: true,
        ),
      ],
    );
    if (!context.mounted) return;
    switch (action) {
      case _TimetableAction.rename:
        await _rename(context, timetable);
      case _TimetableAction.delete:
        await _delete(context, timetable);
      case null:
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '选择课程表',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: '关闭',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: timetables.length,
                itemBuilder: (context, index) {
                  final timetable = timetables[index];
                  return ListTile(
                    key: ValueKey('timetable-${timetable.id}'),
                    onTap: () => _select(context, timetable),
                    leading: SizedBox(
                      width: 24,
                      child: timetable.isCurrent
                          ? Icon(
                              Icons.check_rounded,
                              key: ValueKey('current-${timetable.id}'),
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : null,
                    ),
                    title: Text(
                      timetable.timetableName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      timetable.semesterName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: usesCupertinoConventions(context)
                        ? CupertinoButton(
                            key: ValueKey('timetable-actions-${timetable.id}'),
                            padding: EdgeInsets.zero,
                            onPressed: () => _showActions(context, timetable),
                            child: const Icon(CupertinoIcons.ellipsis_circle),
                          )
                        : PopupMenuButton<_TimetableAction>(
                            tooltip: '${timetable.timetableName}的更多操作',
                            onSelected: (action) {
                              switch (action) {
                                case _TimetableAction.rename:
                                  unawaited(_rename(context, timetable));
                                case _TimetableAction.delete:
                                  unawaited(_delete(context, timetable));
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: _TimetableAction.rename,
                                child: Text('重命名'),
                              ),
                              PopupMenuItem(
                                value: _TimetableAction.delete,
                                child: Text('删除'),
                              ),
                            ],
                          ),
                  );
                },
              ),
            ),
            const Divider(height: 1),
            ListTile(
              key: const ValueKey('add-timetable'),
              leading: const Icon(Icons.add_rounded),
              title: const Text('添加课表'),
              onTap: () => _add(context),
            ),
          ],
        ),
      ),
    );
  }
}

enum _TimetableAction { rename, delete }

Future<String?> showTimetableNameDialog(
  BuildContext context, {
  required String title,
  String initialValue = '',
  String confirmLabel = '继续',
}) {
  return showAdaptiveTextInputDialog(
    context,
    title: title,
    initialValue: initialValue,
    confirmLabel: confirmLabel,
    labelText: '本地别名',
    hintText: '例如：大二上',
    maxLength: 80,
    fieldKey: const ValueKey('timetable-name-field'),
    validator: (value) =>
        value == null || value.trim().isEmpty ? '请输入课表名称' : null,
  );
}

import 'dart:async';

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
    final method = await showModalBottomSheet<TimetableAddMethod>(
      context: context,
      useSafeArea: true,
      builder: (context) => const _AddMethodSheet(),
    );
    if (method == null || !context.mounted) return;
    final name = await showTimetableNameDialog(context, title: '设置本地课表名称');
    if (name == null) return;
    await onAdd(method, name);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
                  trailing: PopupMenuButton<_TimetableAction>(
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
    );
  }
}

enum _TimetableAction { rename, delete }

class _AddMethodSheet extends StatelessWidget {
  const _AddMethodSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '添加课表',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.note_add_outlined),
            title: const Text('新建空白'),
            subtitle: const Text('复制当前课表的学期和作息设置'),
            onTap: () => Navigator.pop(context, TimetableAddMethod.blank),
          ),
          ListTile(
            leading: const Icon(Icons.school_outlined),
            title: const Text('同学登录导入'),
            subtitle: const Text('先创建本地课表，再登录教务系统导入'),
            onTap: () => Navigator.pop(context, TimetableAddMethod.bitc),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

Future<String?> showTimetableNameDialog(
  BuildContext context, {
  required String title,
  String initialValue = '',
  String confirmLabel = '继续',
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _TimetableNameDialog(
      title: title,
      initialValue: initialValue,
      confirmLabel: confirmLabel,
    ),
  );
}

class _TimetableNameDialog extends StatefulWidget {
  const _TimetableNameDialog({
    required this.title,
    required this.initialValue,
    required this.confirmLabel,
  });

  final String title;
  final String initialValue;
  final String confirmLabel;

  @override
  State<_TimetableNameDialog> createState() => _TimetableNameDialogState();
}

class _TimetableNameDialogState extends State<_TimetableNameDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, _controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: TextFormField(
          key: const ValueKey('timetable-name-field'),
          controller: _controller,
          autofocus: true,
          maxLength: 80,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: '本地别名',
            hintText: '例如：大二上',
          ),
          validator: (value) =>
              value == null || value.trim().isEmpty ? '请输入课表名称' : null,
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _submit, child: Text(widget.confirmLabel)),
      ],
    );
  }
}

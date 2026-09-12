import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../../../core/platform/adaptive_ui.dart';
import '../../../core/time/week_set.dart';
import '../../timetable/domain/timetable_models.dart';

class CourseEditorPage extends StatefulWidget {
  const CourseEditorPage({
    required this.semester,
    required this.onSave,
    this.initialCourse,
    this.onDelete,
    super.key,
  });

  final Semester semester;
  final CourseWithSessions? initialCourse;
  final Future<void> Function(CourseWithSessions course) onSave;
  final Future<void> Function()? onDelete;

  bool get isEditing => initialCourse != null;

  @override
  State<CourseEditorPage> createState() => _CourseEditorPageState();
}

class _CourseEditorPageState extends State<CourseEditorPage> {
  static const _uuid = Uuid();
  static const _courseColors = <int>[
    0xFF3F51B5,
    0xFF1976D2,
    0xFF00897B,
    0xFF43A047,
    0xFFF57C00,
    0xFFE53935,
    0xFF8E24AA,
    0xFF6D4C41,
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _teacherController;
  late final TextEditingController _notesController;
  late final List<_SessionDraft> _sessions;
  late int _colorValue;

  bool _isDirty = false;
  bool _allowPop = false;
  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialCourse;
    _nameController = TextEditingController(text: initial?.course.name ?? '');
    _teacherController = TextEditingController(
      text: initial?.course.teacher ?? '',
    );
    _notesController = TextEditingController(text: initial?.course.notes ?? '');
    _colorValue = initial?.course.colorValue ?? _courseColors.first;
    _sessions = initial == null || initial.sessions.isEmpty
        ? [_SessionDraft.createDefault(widget.semester.teachingWeeks)]
        : initial.sessions.map(_SessionDraft.fromSession).toList();

    _nameController.addListener(_markDirty);
    _teacherController.addListener(_markDirty);
    _notesController.addListener(_markDirty);
    for (final session in _sessions) {
      session.addListener(_markDirty);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _teacherController.dispose();
    _notesController.dispose();
    for (final session in _sessions) {
      session.dispose();
    }
    super.dispose();
  }

  void _markDirty() {
    if (!_isDirty && mounted) {
      setState(() => _isDirty = true);
    }
  }

  String? _requiredNameValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '请输入课程名称';
    }
    return null;
  }

  String? _positivePeriodValidator(String? value) {
    final period = int.tryParse(value ?? '');
    if (period == null || period < 1) {
      return '请输入大于 0 的节次';
    }
    return null;
  }

  String? _endPeriodValidator(_SessionDraft session, String? value) {
    final basicError = _positivePeriodValidator(value);
    if (basicError != null) return basicError;
    final start = int.tryParse(session.startPeriodController.text);
    final end = int.parse(value!);
    if (start != null && end < start) {
      return '结束节次不能早于开始节次';
    }
    return null;
  }

  String? _weekExpressionValidator(String? value) {
    try {
      final weeks = parseWeekExpression(
        value ?? '',
        maximumWeek: widget.semester.teachingWeeks,
      );
      if (weeks.isEmpty) {
        return '请输入至少一个教学周';
      }
    } on FormatException {
      return '周次表达式格式无效';
    } on RangeError {
      return '周次不能超过第 ${widget.semester.teachingWeeks} 周';
    } on ArgumentError {
      return '周次范围无效';
    }
    return null;
  }

  String? _nullableTrimmed(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);
    try {
      final initial = widget.initialCourse;
      final courseId = initial?.course.id ?? _uuid.v4();
      final course = Course(
        id: courseId,
        semesterId: initial?.course.semesterId ?? widget.semester.id,
        name: _nameController.text.trim(),
        code: initial?.course.code,
        teacher: _nullableTrimmed(_teacherController.text),
        teachingClass: initial?.course.teachingClass,
        colorValue: _colorValue,
        notes: _nullableTrimmed(_notesController.text),
        source: initial?.course.source ?? CourseSource.manual,
        sourceId: initial?.course.sourceId,
        isLocallyModified: true,
      );
      final sessions = [
        for (final draft in _sessions)
          CourseSession(
            id: draft.id ?? _uuid.v4(),
            courseId: courseId,
            weekday: draft.weekday,
            startPeriod: int.parse(draft.startPeriodController.text),
            endPeriod: int.parse(draft.endPeriodController.text),
            location: _nullableTrimmed(draft.locationController.text),
            weeks: parseWeekExpression(
              draft.weeksController.text,
              maximumWeek: widget.semester.teachingWeeks,
            ),
          ),
      ];
      await widget.onSave(
        CourseWithSessions(course: course, sessions: sessions),
      );
      if (mounted) {
        setState(() {
          _isDirty = false;
          _allowPop = true;
        });
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _addSession() {
    final draft = _SessionDraft.createDefault(widget.semester.teachingWeeks)
      ..addListener(_markDirty);
    setState(() {
      _sessions.add(draft);
      _isDirty = true;
    });
  }

  void _removeSession(int index) {
    if (_sessions.length == 1) return;
    final removed = _sessions.removeAt(index);
    removed.dispose();
    setState(() => _isDirty = true);
  }

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
      if (mounted) {
        setState(() {
          _isDirty = false;
          _allowPop = true;
        });
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  Future<void> _handlePopAttempt(bool didPop, Object? result) async {
    if (didPop || _allowPop || !_isDirty) return;
    final discard = await showAdaptiveConfirmationDialog(
      context,
      title: '放弃未保存的修改？',
      message: '当前修改尚未保存，返回后将丢失。',
      confirmLabel: '放弃修改',
      destructive: true,
    );
    if (!discard || !mounted) return;
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop(result);
    });
  }

  @override
  Widget build(BuildContext context) {
    final busy = _isSaving || _isDeleting;
    return PopScope<Object?>(
      canPop: _allowPop || !_isDirty,
      onPopInvokedWithResult: _handlePopAttempt,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isEditing ? '编辑课程' : '新建课程'),
          actions: [
            TextButton(
              key: const Key('course-editor-save'),
              onPressed: busy ? null : _save,
              child: _isSaving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('保存'),
            ),
          ],
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                TextFormField(
                  key: const Key('course-name-field'),
                  controller: _nameController,
                  enabled: !busy,
                  autofocus: !widget.isEditing,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: '课程名称',
                    prefixIcon: Icon(Icons.menu_book_outlined),
                  ),
                  validator: _requiredNameValidator,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('course-teacher-field'),
                  controller: _teacherController,
                  enabled: !busy,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: '教师',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                Text('课程颜色', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final colorValue in _courseColors)
                      _ColorChoice(
                        colorValue: colorValue,
                        selected: colorValue == _colorValue,
                        onTap: busy
                            ? null
                            : () {
                                setState(() {
                                  _colorValue = colorValue;
                                  _isDirty = true;
                                });
                              },
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '课程安排',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    TextButton.icon(
                      key: const Key('course-editor-add-session'),
                      onPressed: busy ? null : _addSession,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('添加安排'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                for (var index = 0; index < _sessions.length; index++) ...[
                  _SessionEditorCard(
                    key: ValueKey(_sessions[index]),
                    index: index,
                    draft: _sessions[index],
                    enabled: !busy,
                    canRemove: _sessions.length > 1,
                    maximumWeek: widget.semester.teachingWeeks,
                    positivePeriodValidator: _positivePeriodValidator,
                    endPeriodValidator: _endPeriodValidator,
                    weekExpressionValidator: _weekExpressionValidator,
                    onChanged: _markDirty,
                    onRemove: () => _removeSession(index),
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  key: const Key('course-notes-field'),
                  controller: _notesController,
                  enabled: !busy,
                  minLines: 3,
                  maxLines: 6,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    labelText: '备注',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                ),
                if (widget.isEditing && widget.onDelete != null) ...[
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    key: const Key('course-editor-delete'),
                    onPressed: busy ? null : _delete,
                    icon: _isDeleting
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.delete_outline_rounded),
                    label: const Text('删除课程'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SessionDraft {
  _SessionDraft({
    required this.id,
    required this.weekday,
    required String startPeriod,
    required String endPeriod,
    required String location,
    required String weeks,
  }) : startPeriodController = TextEditingController(text: startPeriod),
       endPeriodController = TextEditingController(text: endPeriod),
       locationController = TextEditingController(text: location),
       weeksController = TextEditingController(text: weeks);

  factory _SessionDraft.createDefault(int teachingWeeks) {
    return _SessionDraft(
      id: null,
      weekday: DateTime.monday,
      startPeriod: '1',
      endPeriod: '2',
      location: '',
      weeks: '1-$teachingWeeks',
    );
  }

  factory _SessionDraft.fromSession(CourseSession session) {
    return _SessionDraft(
      id: session.id,
      weekday: session.weekday,
      startPeriod: '${session.startPeriod}',
      endPeriod: '${session.endPeriod}',
      location: session.location ?? '',
      weeks: formatWeekExpression(session.weeks),
    );
  }

  final String? id;
  int weekday;
  final TextEditingController startPeriodController;
  final TextEditingController endPeriodController;
  final TextEditingController locationController;
  final TextEditingController weeksController;

  void addListener(VoidCallback listener) {
    startPeriodController.addListener(listener);
    endPeriodController.addListener(listener);
    locationController.addListener(listener);
    weeksController.addListener(listener);
  }

  void dispose() {
    startPeriodController.dispose();
    endPeriodController.dispose();
    locationController.dispose();
    weeksController.dispose();
  }
}

class _SessionEditorCard extends StatelessWidget {
  const _SessionEditorCard({
    required this.index,
    required this.draft,
    required this.enabled,
    required this.canRemove,
    required this.maximumWeek,
    required this.positivePeriodValidator,
    required this.endPeriodValidator,
    required this.weekExpressionValidator,
    required this.onChanged,
    required this.onRemove,
    super.key,
  });

  final int index;
  final _SessionDraft draft;
  final bool enabled;
  final bool canRemove;
  final int maximumWeek;
  final String? Function(String? value) positivePeriodValidator;
  final String? Function(_SessionDraft session, String? value)
  endPeriodValidator;
  final String? Function(String? value) weekExpressionValidator;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '安排 ${index + 1}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                if (canRemove)
                  IconButton(
                    tooltip: '删除此安排',
                    onPressed: enabled ? onRemove : null,
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              key: Key('session-$index-weekday'),
              initialValue: draft.weekday,
              decoration: const InputDecoration(
                labelText: '星期',
                prefixIcon: Icon(Icons.calendar_today_outlined),
              ),
              items: [
                for (var weekday = 1; weekday <= 7; weekday++)
                  DropdownMenuItem(
                    value: weekday,
                    child: Text('星期${_weekdayName(weekday)}'),
                  ),
              ],
              onChanged: enabled
                  ? (value) {
                      if (value == null) return;
                      draft.weekday = value;
                      onChanged();
                    }
                  : null,
              validator: (value) {
                if (value == null || value < 1 || value > 7) {
                  return '星期必须为 1 到 7';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    key: Key('session-$index-start-period'),
                    controller: draft.startPeriodController,
                    enabled: enabled,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: '开始节次'),
                    validator: positivePeriodValidator,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    key: Key('session-$index-end-period'),
                    controller: draft.endPeriodController,
                    enabled: enabled,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: '结束节次'),
                    validator: (value) => endPeriodValidator(draft, value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: Key('session-$index-location'),
              controller: draft.locationController,
              enabled: enabled,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: '地点',
                prefixIcon: Icon(Icons.place_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: Key('session-$index-weeks'),
              controller: draft.weeksController,
              enabled: enabled,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: '周次表达式',
                hintText: '例如：1-16、1-15单、2-16双',
                helperText: '本学期共 $maximumWeek 个教学周',
                prefixIcon: const Icon(Icons.date_range_outlined),
              ),
              validator: weekExpressionValidator,
            ),
          ],
        ),
      ),
    );
  }

  static String _weekdayName(int weekday) {
    return const ['一', '二', '三', '四', '五', '六', '日'][weekday - 1];
  }
}

class _ColorChoice extends StatelessWidget {
  const _ColorChoice({
    required this.colorValue,
    required this.selected,
    required this.onTap,
  });

  final int colorValue;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '课程颜色 ${colorValue.toRadixString(16)}',
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color(colorValue),
            border: selected
                ? Border.all(
                    color: Theme.of(context).colorScheme.onSurface,
                    width: 3,
                  )
                : null,
          ),
          child: selected
              ? const Icon(Icons.check_rounded, color: Colors.white)
              : null,
        ),
      ),
    );
  }
}

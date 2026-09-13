import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/platform/adaptive_ui.dart';
import '../../timetable/data/providers.dart';

enum OnboardingCompletion { blank, importBitc }

typedef OnboardingSubmit = Future<String> Function({
  required String timetableName,
  required String academicYear,
  required int term,
  required DateTime startDate,
  required int teachingWeeks,
});

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({this.onSubmit, super.key});

  final OnboardingSubmit? onSubmit;

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _nameController = TextEditingController(text: '我的课表');
  final _academicYearController = TextEditingController();
  final _weeksController = TextEditingController(text: '20');

  int _step = 0;
  int _term = 1;
  late DateTime _startDate;
  bool _busy = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final now = ref.read(clockProvider)();
    final today = DateTime(now.year, now.month, now.day);
    final academicYearStart = today.month >= DateTime.august
        ? today.year
        : today.year - 1;
    _academicYearController.text =
        '$academicYearStart-${academicYearStart + 1}';
    _startDate = today;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _academicYearController.dispose();
    _weeksController.dispose();
    super.dispose();
  }

  String? _validateName() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return '请输入课表名称。';
    if (name.length > 80) return '课表名称不能超过 80 个字符。';
    return null;
  }

  String? _validateCalendar() {
    final value = _academicYearController.text.trim();
    final match = RegExp(r'^(\d{4})-(\d{4})$').firstMatch(value);
    if (match == null ||
        int.parse(match.group(2)!) != int.parse(match.group(1)!) + 1) {
      return '学年需使用连续的 YYYY-YYYY 格式。';
    }
    final weeks = int.tryParse(_weeksController.text.trim());
    if (weeks == null || weeks < 1 || weeks > 40) {
      return '教学周数需为 1 到 40。';
    }
    return null;
  }

  void _next() {
    final error = _step == 0 ? _validateName() : _validateCalendar();
    if (error != null) {
      setState(() => _errorMessage = error);
      return;
    }
    setState(() {
      _errorMessage = null;
      _step++;
    });
  }

  void _goBack() {
    setState(() {
      _step--;
      _errorMessage = null;
    });
  }

  Future<void> _selectStartDate() async {
    final selected = await showAdaptiveDatePicker(
      context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selected != null) setState(() => _startDate = selected);
  }

  Future<void> _complete(OnboardingCompletion completion) async {
    if (_busy) return;
    final nameError = _validateName();
    final calendarError = _validateCalendar();
    if (nameError != null || calendarError != null) {
      setState(() => _errorMessage = nameError ?? calendarError);
      return;
    }
    setState(() {
      _busy = true;
      _errorMessage = null;
    });
    try {
      final submit = widget.onSubmit;
      final id = submit == null
          ? (await ref
                    .read(timetableRepositoryProvider)
                    .createInitialTimetable(
                      timetableName: _nameController.text.trim(),
                      academicYear: _academicYearController.text.trim(),
                      term: _term,
                      startDate: _startDate,
                      teachingWeeks: int.parse(_weeksController.text.trim()),
                    ))
                .id
          : await submit(
              timetableName: _nameController.text.trim(),
              academicYear: _academicYearController.text.trim(),
              term: _term,
              startDate: _startDate,
              teachingWeeks: int.parse(_weeksController.text.trim()),
            );
      if (!mounted) return;
      if (completion == OnboardingCompletion.importBitc) {
        context.go('/import?target=$id&source=bitc');
      } else {
        context.go('/');
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() => _errorMessage = '首次设置保存失败：$error');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCupertino = usesCupertinoConventions(context);
    final body = SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('第 ${_step + 1} 步，共 3 步', style: theme.textTheme.labelLarge),
          const SizedBox(height: 16),
          if (_step == 0) _buildNameStep(theme),
          if (_step == 1) _buildCalendarStep(theme),
          if (_step == 2) _buildConfirmationStep(theme),
          if (_errorMessage case final message?) ...[
            const SizedBox(height: 16),
            Text(message, style: TextStyle(color: theme.colorScheme.error)),
          ],
          const SizedBox(height: 24),
          if (_step < 2)
            isCupertino
                ? CupertinoButton.filled(
                    key: const ValueKey('onboarding-next'),
                    onPressed: _busy ? null : _next,
                    child: const Text('下一步'),
                  )
                : FilledButton(
                    key: const ValueKey('onboarding-next'),
                    onPressed: _busy ? null : _next,
                    child: const Text('下一步'),
                  ),
          if (_step > 0) ...[
            const SizedBox(height: 8),
            isCupertino
                ? CupertinoButton(
                    onPressed: _busy ? null : _goBack,
                    child: const Text('上一步'),
                  )
                : TextButton(
                    onPressed: _busy ? null : _goBack,
                    child: const Text('上一步'),
                  ),
          ],
        ],
      ),
    );
    if (isCupertino) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(middle: Text('首次设置')),
        child: Material(type: MaterialType.transparency, child: body),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('首次设置')),
      body: body,
    );
  }

  Widget _buildNameStep(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('创建本地课表', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text('名称只保存在此设备，之后可以在课表列表中修改。'),
        const SizedBox(height: 20),
        TextField(
          key: const ValueKey('onboarding-name'),
          controller: _nameController,
          maxLength: 80,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(labelText: '课表名称'),
        ),
      ],
    );
  }

  Widget _buildCalendarStep(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('设置学期校历', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text('请选择开学日期；该日期所在周的周一会作为第 1 教学周的开始。'),
        const SizedBox(height: 20),
        TextField(
          key: const ValueKey('onboarding-academic-year'),
          controller: _academicYearController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '学年',
            hintText: 'YYYY-YYYY',
          ),
        ),
        const SizedBox(height: 16),
        if (usesCupertinoConventions(context))
          CupertinoSlidingSegmentedControl<int>(
            groupValue: _term,
            children: const {
              1: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('第一学期'),
              ),
              2: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('第二学期'),
              ),
              3: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('第三学期'),
              ),
            },
            onValueChanged: (value) {
              if (value != null) setState(() => _term = value);
            },
          )
        else
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 1, label: Text('第一学期')),
              ButtonSegment(value: 2, label: Text('第二学期')),
              ButtonSegment(value: 3, label: Text('第三学期')),
            ],
            selected: {_term},
            onSelectionChanged: (selection) =>
                setState(() => _term = selection.single),
          ),
        const SizedBox(height: 12),
        ListTile(
          key: const ValueKey('onboarding-start-date'),
          contentPadding: EdgeInsets.zero,
          title: const Text('开学日期（请确认）'),
          subtitle: Text(DateFormat('yyyy年M月d日').format(_startDate)),
          trailing: const Icon(Icons.calendar_month_outlined),
          onTap: _selectStartDate,
        ),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('onboarding-weeks'),
          controller: _weeksController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: '教学周数（1-40）'),
        ),
      ],
    );
  }

  Widget _buildConfirmationStep(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('确认并开始使用', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('课表：${_nameController.text.trim()}'),
                Text('学年：${_academicYearController.text.trim()}'),
                Text('学期：第 $_term 学期'),
                Text('开学日期：${DateFormat('yyyy年M月d日').format(_startDate)}'),
                Text('教学周数：${_weeksController.text.trim()}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (usesCupertinoConventions(context)) ...[
          CupertinoButton.filled(
            key: const ValueKey('onboarding-import'),
            onPressed: _busy
                ? null
                : () => _complete(OnboardingCompletion.importBitc),
            child: Text(_busy ? '正在创建…' : '现在导入 BITC'),
          ),
          const SizedBox(height: 10),
          CupertinoButton(
            key: const ValueKey('onboarding-blank'),
            onPressed: _busy
                ? null
                : () => _complete(OnboardingCompletion.blank),
            child: const Text('先使用空白课表'),
          ),
        ] else ...[
          FilledButton.icon(
            key: const ValueKey('onboarding-import'),
            onPressed: _busy
                ? null
                : () => _complete(OnboardingCompletion.importBitc),
            icon: _busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.school_outlined),
            label: Text(_busy ? '正在创建…' : '现在导入 BITC'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            key: const ValueKey('onboarding-blank'),
            onPressed: _busy
                ? null
                : () => _complete(OnboardingCompletion.blank),
            child: const Text('先使用空白课表'),
          ),
        ],
      ],
    );
  }
}

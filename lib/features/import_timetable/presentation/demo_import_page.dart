import 'package:flutter/material.dart';

import '../../../integrations/zfsoft/zfsoft.dart';
import '../domain/import_timetable.dart';
import 'import_preview_page.dart';

class DemoImportPage extends StatefulWidget {
  const DemoImportPage({
    required this.existingEntries,
    required this.onCommit,
    super.key,
  });

  final List<ExistingTimetableEntry> existingEntries;
  final Future<void> Function(ImportCommitRequest request) onCommit;

  @override
  State<DemoImportPage> createState() => _DemoImportPageState();
}

class _DemoImportPageState extends State<DemoImportPage> {
  final _usernameController = TextEditingController(text: 'demo');
  final _passwordController = TextEditingController(text: 'demo');
  final _academicYearController = TextEditingController(text: '2026-2027');
  final TimetableImporter _importer = MockZfTimetableImporter();

  ImportStrategy _strategy = ImportStrategy.merge;
  int _term = 1;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _academicYearController.dispose();
    super.dispose();
  }

  Future<void> _startImport() async {
    if (_usernameController.text.trim().isEmpty ||
        _passwordController.text.isEmpty ||
        _academicYearController.text.trim().isEmpty) {
      setState(() => _errorMessage = '请完整填写演示登录和学年信息。');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _importer.authenticate(
        CredentialAuthRequest(
          username: _usernameController.text.trim(),
          password: _passwordController.text,
        ),
      );
      final timetable = await _importer.fetchTimetable(
        ImportTermRequest(
          academicYear: _academicYearController.text.trim(),
          term: _term,
        ),
      );
      final preview = const ImportPreviewCalculator().calculate(
        imported: timetable.entries,
        existing: _strategy == ImportStrategy.replace
            ? const []
            : widget.existingEntries,
        strategy: _strategy,
      );
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (context) => ImportPreviewPage(
            preview: preview,
            sourceName: timetable.sourceName,
            targetTimetableName: '当前课表',
            onCommit: () async {
              await widget.onCommit(ImportCommitRequest(preview: preview));
              if (!context.mounted) return;
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('已导入 ${preview.addedCount} 条新安排。')),
              );
            },
          ),
        ),
      );
    } on TimetableImportException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } on Object {
      if (mounted) setState(() => _errorMessage = '导入演示数据时发生未知错误。');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('正方教务导入')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              color: theme.colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('当前为本地演示适配器', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 6),
                    const Text(
                      '不会连接真实教务系统，也不会保存账号或密码。试点学校 URL 与脱敏样本接入后，再启用真实适配器。',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _usernameController,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: '演示账号',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: '演示密码',
                prefixIcon: Icon(Icons.lock_outline_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _academicYearController,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: '学年',
                hintText: '2026-2027',
                prefixIcon: Icon(Icons.calendar_today_outlined),
              ),
            ),
            const SizedBox(height: 16),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 1, label: Text('第一学期')),
                ButtonSegment(value: 2, label: Text('第二学期')),
              ],
              selected: {_term},
              onSelectionChanged: (selection) {
                setState(() => _term = selection.single);
              },
            ),
            const SizedBox(height: 16),
            SegmentedButton<ImportStrategy>(
              segments: const [
                ButtonSegment(
                  value: ImportStrategy.merge,
                  label: Text('合并'),
                  icon: Icon(Icons.merge_rounded),
                ),
                ButtonSegment(
                  value: ImportStrategy.replace,
                  label: Text('替换'),
                  icon: Icon(Icons.swap_horiz_rounded),
                ),
              ],
              selected: {_strategy},
              onSelectionChanged: (selection) {
                setState(() => _strategy = selection.single);
              },
            ),
            if (_errorMessage case final message?) ...[
              const SizedBox(height: 14),
              Text(message, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isLoading ? null : _startImport,
              icon: _isLoading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_download_outlined),
              label: Text(_isLoading ? '正在生成预览…' : '登录并预览课表'),
            ),
          ],
        ),
      ),
    );
  }
}

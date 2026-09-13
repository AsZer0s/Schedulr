import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../app/widgets/adaptive_scaffold.dart';
import '../../../core/platform/adaptive_ui.dart';

import '../../../integrations/zfsoft/zfsoft.dart';
import '../domain/import_timetable.dart';
import 'bitc/bitc_web_session_page.dart';
import 'import_preview_page.dart';

enum ImportSourceChoice { bitc, demo }

class TimetableImportPage extends StatefulWidget {
  const TimetableImportPage({
    required this.existingEntries,
    required this.onCommit,
    required this.targetTimetableName,
    required this.initialAcademicYear,
    required this.initialTerm,
    this.initialSource = ImportSourceChoice.bitc,
    super.key,
  });

  final List<ExistingTimetableEntry> existingEntries;
  final Future<void> Function(ImportCommitRequest request) onCommit;
  final String targetTimetableName;
  final String initialAcademicYear;
  final int initialTerm;
  final ImportSourceChoice initialSource;

  @override
  State<TimetableImportPage> createState() => _TimetableImportPageState();
}

class _TimetableImportPageState extends State<TimetableImportPage> {
  final _usernameController = TextEditingController(text: 'demo');
  final _passwordController = TextEditingController(text: 'demo');
  late final TextEditingController _academicYearController;

  late ImportSourceChoice _source;
  ImportStrategy _strategy = ImportStrategy.merge;
  late int _term;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _source = widget.initialSource;
    _academicYearController = TextEditingController(
      text: widget.initialAcademicYear,
    );
    _term = widget.initialTerm.clamp(1, 3);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _academicYearController.dispose();
    super.dispose();
  }

  Future<void> _startImport() async {
    if (_academicYearController.text.trim().isEmpty) {
      setState(() => _errorMessage = '请填写学年。');
      return;
    }
    if (_source == ImportSourceChoice.demo &&
        (_usernameController.text.trim().isEmpty ||
            _passwordController.text.isEmpty)) {
      setState(() => _errorMessage = '请填写演示账号和密码。');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final timetable = switch (_source) {
        ImportSourceChoice.bitc => await _fetchBitcTimetable(),
        ImportSourceChoice.demo => await _fetchDemoTimetable(),
      };
      if (timetable == null || !mounted) return;
      final selectedProfile = await _selectTimingProfile(timetable);
      if (!mounted) return;
      final calculated = const ImportPreviewCalculator().calculate(
        imported: timetable.entries,
        existing: _strategy == ImportStrategy.replace
            ? const []
            : widget.existingEntries,
        strategy: _strategy,
      );
      final preview = ImportPreview(
        strategy: calculated.strategy,
        items: calculated.items,
        issues: [...timetable.issues, ...calculated.issues],
      );
      await Navigator.of(context).push<void>(
        adaptivePageRoute<void>(
          context: context,
          builder: (context) => ImportPreviewPage(
            preview: preview,
            sourceName: timetable.sourceName,
            targetTimetableName: widget.targetTimetableName,
            timingProfile: selectedProfile,
            hasCalendarUpdate: timetable.calendar != null,
            onCommit: () async {
              await widget.onCommit(
                ImportCommitRequest(
                  preview: preview,
                  term: timetable.term,
                  calendar: timetable.calendar,
                  timingProfile: selectedProfile,
                ),
              );
              if (!context.mounted) return;
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    preview.addedCount > 0
                        ? '已导入 ${preview.addedCount} 条新安排。'
                        : selectedProfile?.schedule != null &&
                              timetable.calendar != null
                        ? '校历与作息已更新。'
                        : selectedProfile?.schedule != null
                        ? '作息已更新。'
                        : '校历已更新。',
                  ),
                ),
              );
            },
          ),
        ),
      );
    } on FormatException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } on TimetableImportException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } on Object {
      if (mounted) setState(() => _errorMessage = '读取课表时发生未知错误。');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<ImportedTimingProfile?> _selectTimingProfile(
    ImportedTimetable timetable,
  ) async {
    final selection = selectTimingProfilesForImport(
      profiles: timetable.timingProfiles,
      entries: timetable.entries,
    );
    if (selection.defaultProfile == null) return null;
    if (!selection.requiresUserChoice) return selection.defaultProfile;

    final unique = selection.options;
    final counts = <String, int>{};
    for (final entry in timetable.entries) {
      final id = entry.timingProfileId;
      if (id != null) counts[id] = (counts[id] ?? 0) + 1;
    }
    var selected = selection.defaultProfile!;
    if (usesCupertinoConventions(context)) {
      final chosen = await showAdaptiveActionSheet<String>(
        context,
        title: '选择本学期作息校区',
        message: '检测到不同校区使用不同作息。只会将所选校区作息应用到本学期。',
        actions: [
          for (final profile in unique)
            AdaptiveActionSheetAction(
              label: '${profile.name}（${counts[profile.id] ?? 0} 条安排）',
              value: profile.id,
            ),
        ],
      );
      if (chosen == null) return null;
      return unique.firstWhere((profile) => profile.id == chosen);
    }
    return showDialog<ImportedTimingProfile>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('选择本学期作息校区'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('检测到不同校区使用不同作息。只会将所选校区作息应用到本学期。'),
              const SizedBox(height: 12),
              for (final profile in unique)
                ListTile(
                  leading: Icon(
                    profile.id == selected.id
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                  ),
                  title: Text(profile.name),
                  subtitle: Text('${counts[profile.id] ?? 0} 条课程安排'),
                  onTap: () {
                    setDialogState(() => selected = profile);
                  },
                ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(selected),
              child: const Text('使用此作息'),
            ),
          ],
        ),
      ),
    );
  }

  Future<ImportedTimetable?> _fetchBitcTimetable() async {
    final request = ImportTermRequest(
      academicYear: _academicYearController.text.trim(),
      term: _term,
    );
    final protocolTerm = BitcZfTimetableImporter.toProtocolTerm(request);
    String? payload;
    final importer = BitcZfTimetableImporter(
      fetchPayload: (_) async {
        final result = await Navigator.of(context).push<String>(
          adaptivePageRoute<String>(
            context: context,
            builder: (context) => BitcWebSessionPage(
              request: BitcTimetableWebRequest(
                academicYearStart: protocolTerm.academicYear,
                termCode: '${protocolTerm.term}',
              ),
            ),
          ),
        );
        if (result == null) {
          throw const TimetableImportException(
            kind: TimetableImportFailureKind.cancelled,
            message: '已取消 BITC 教务导入。',
          );
        }
        payload = result;
        return result;
      },
    );
    await importer.authenticate(const BrowserSessionAuthRequest());
    final timetable = await importer.fetchTimetable(request);
    if (payload == null) return null;
    return timetable;
  }

  Future<ImportedTimetable> _fetchDemoTimetable() async {
    final importer = MockZfTimetableImporter();
    await importer.authenticate(
      CredentialAuthRequest(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      ),
    );
    return importer.fetchTimetable(
      ImportTermRequest(
        academicYear: _academicYearController.text.trim(),
        term: _term,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBitc = _source == ImportSourceChoice.bitc;
    final isCupertino = usesCupertinoConventions(context);
    final body = ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          color: theme.colorScheme.primaryContainer,
          child: ListTile(
            leading: const Icon(Icons.table_chart_outlined),
            title: const Text('导入到'),
            subtitle: Text(
              widget.targetTimetableName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SegmentedButton<ImportSourceChoice>(
          segments: const [
            ButtonSegment(
              value: ImportSourceChoice.bitc,
              label: Text('BITC 教务'),
              icon: Icon(Icons.school_outlined),
            ),
            ButtonSegment(
              value: ImportSourceChoice.demo,
              label: Text('本地演示'),
              icon: Icon(Icons.science_outlined),
            ),
          ],
          selected: {_source},
          onSelectionChanged: _isLoading
              ? null
              : (selection) => setState(() {
                  _source = selection.single;
                  _errorMessage = null;
                }),
        ),
        const SizedBox(height: 16),
        Card(
          color: theme.colorScheme.secondaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              isBitc
                  ? '将在受限 WebView 中打开学校 VPN/IAM 登录。密码只提交给学校页面，App 不读取或保存；登录后仅传回课表必需字段。'
                  : '本地演示不会联网。演示账号和密码均为 demo。',
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (!isBitc) ...[
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
        ],
        TextField(
          controller: _academicYearController,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: '学年',
            hintText: 'YYYY-YYYY',
            prefixIcon: Icon(Icons.calendar_today_outlined),
          ),
        ),
        const SizedBox(height: 16),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 1, label: Text('第一学期')),
            ButtonSegment(value: 2, label: Text('第二学期')),
            ButtonSegment(value: 3, label: Text('第三学期')),
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
        if (!isCupertino)
          FilledButton.icon(
            key: const ValueKey('import-primary-action'),
            onPressed: _isLoading ? null : _startImport,
            icon: _isLoading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    isBitc
                        ? Icons.open_in_browser_rounded
                        : Icons.cloud_download_outlined,
                  ),
            label: Text(
              _isLoading
                  ? '正在生成预览…'
                  : isBitc
                  ? '登录 BITC 并读取课表'
                  : '登录并预览演示课表',
            ),
          ),
      ],
    );
    return AdaptiveScaffold(
      title: const Text('正方教务导入'),
      body: body,
      cupertinoBottomAction: isCupertino
          ? SafeArea(
              minimum: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  key: const ValueKey('import-primary-action'),
                  onPressed: _isLoading ? null : _startImport,
                  child: Text(
                    _isLoading
                        ? '正在生成预览…'
                        : isBitc
                        ? '登录 BITC 并读取课表'
                        : '登录并预览演示课表',
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

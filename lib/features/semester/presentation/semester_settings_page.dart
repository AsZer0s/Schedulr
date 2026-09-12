import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../timetable/domain/semester.dart';

class SemesterSettingsPage extends StatefulWidget {
  const SemesterSettingsPage({
    required this.semester,
    required this.onSave,
    super.key,
  });

  final Semester semester;
  final Future<void> Function(Semester semester) onSave;

  @override
  State<SemesterSettingsPage> createState() => _SemesterSettingsPageState();
}

class _SemesterSettingsPageState extends State<SemesterSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _academicYearController;
  late final TextEditingController _termController;
  late final TextEditingController _weeksController;
  late DateTime _startDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.semester.name);
    _academicYearController = TextEditingController(
      text: widget.semester.academicYear,
    );
    _termController = TextEditingController(text: widget.semester.term);
    _weeksController = TextEditingController(
      text: '${widget.semester.teachingWeeks}',
    );
    _startDate = widget.semester.startDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _academicYearController.dispose();
    _termController.dispose();
    _weeksController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
      initialDate: _startDate,
    );
    if (selected != null) setState(() => _startDate = selected);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await widget.onSave(
        widget.semester.copyWith(
          name: _nameController.text.trim(),
          academicYear: _academicYearController.text.trim(),
          term: _termController.text.trim(),
          startDate: _startDate,
          teachingWeeks: int.parse(_weeksController.text),
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return '此项不能为空';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('学期设置')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: '学期名称'),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _academicYearController,
                decoration: const InputDecoration(labelText: '学年'),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _termController,
                decoration: const InputDecoration(labelText: '学期'),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _weeksController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '教学周数'),
                validator: (value) {
                  final weeks = int.tryParse(value ?? '');
                  if (weeks == null || weeks < 1 || weeks > 40) {
                    return '请输入 1 到 40 之间的教学周数';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                title: const Text('开学日期'),
                subtitle: Text(DateFormat('yyyy年M月d日').format(_startDate)),
                trailing: const Icon(Icons.calendar_month_outlined),
                onTap: _selectStartDate,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: const Icon(Icons.save_outlined),
                label: Text(_isSaving ? '正在保存…' : '保存学期设置'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

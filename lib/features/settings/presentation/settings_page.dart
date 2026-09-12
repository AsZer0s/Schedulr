import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    required this.onEditSemester,
    required this.onClearSession,
    required this.onClearAllData,
    super.key,
  });

  final VoidCallback onEditSemester;
  final Future<void> Function() onClearSession;
  final Future<void> Function() onClearAllData;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          const _SectionHeader('课程表'),
          ListTile(
            leading: const Icon(Icons.calendar_month_outlined),
            title: const Text('学期与校历'),
            subtitle: const Text('修改开学日期、学年和教学周数'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: onEditSemester,
          ),
          const _SectionHeader('隐私与数据'),
          const ListTile(
            leading: Icon(Icons.offline_bolt_outlined),
            title: Text('纯本地数据'),
            subtitle: Text('课程、学期和设置仅保存在本设备，不使用云端账号。'),
          ),
          ListTile(
            leading: const Icon(Icons.logout_rounded),
            title: const Text('清除教务会话'),
            subtitle: const Text('清除学校网页登录 Cookie；不会删除已导入课程。'),
            onTap: () async {
              await onClearSession();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('教务会话已清除。')));
            },
          ),
          ListTile(
            leading: Icon(
              Icons.delete_forever_outlined,
              color: theme.colorScheme.error,
            ),
            title: Text(
              '删除全部本地数据',
              style: TextStyle(color: theme.colorScheme.error),
            ),
            subtitle: const Text('删除所有课程和学期，此操作不可撤销。'),
            onTap: () async => onClearAllData(),
          ),
          const _SectionHeader('正方教务导入'),
          const ListTile(
            leading: Icon(Icons.school_outlined),
            title: Text('北京信息职业技术学院'),
            subtitle: Text(
              '已实现 BITC VPN/IAM 登录与正方 V9 课表读取，等待 Android/iOS 真机验收。',
            ),
          ),
          const AboutListTile(
            applicationName: '课程表',
            applicationVersion: '1.0.0',
            applicationLegalese: '本应用默认不长期保存教务密码。',
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge
            ?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}

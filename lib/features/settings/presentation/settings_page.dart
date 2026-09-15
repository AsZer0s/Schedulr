import 'package:flutter/material.dart';

import '../../../app/widgets/adaptive_scaffold.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    required this.onEditSemester,
    required this.onClearSession,
    required this.onDeleteSavedAccounts,
    required this.onClearAllData,
    required this.onRefreshWidget,
    required this.savedAccountCount,
    super.key,
  });

  final VoidCallback onEditSemester;
  final Future<void> Function() onClearSession;
  final Future<void> Function() onDeleteSavedAccounts;
  final Future<void> Function() onClearAllData;
  final Future<void> Function() onRefreshWidget;
  final int savedAccountCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AdaptiveScaffold(
      title: const Text('设置'),
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
            title: const Text('退出教务网页登录'),
            subtitle: const Text('清除学校 WebView Cookie；保留已保存账号和课程。'),
            onTap: () async {
              await onClearSession();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('教务网页登录已退出。')));
            },
          ),
          ListTile(
            key: const ValueKey('delete-saved-bitc-accounts'),
            leading: const Icon(Icons.no_accounts_outlined),
            title: const Text('删除已保存教务账号'),
            subtitle: Text(
              savedAccountCount == 0
                  ? '当前没有保存账号；密码从不由 App 保存。'
                  : '已保存 $savedAccountCount 个账号；删除后仍保留课程。',
            ),
            enabled: savedAccountCount > 0,
            onTap: savedAccountCount == 0
                ? null
                : () async {
                    await onDeleteSavedAccounts();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已保存教务账号已删除。')),
                    );
                  },
          ),
          ListTile(
            key: const ValueKey('refresh-desktop-widget'),
            leading: const Icon(Icons.widgets_outlined),
            title: const Text('刷新桌面小组件'),
            subtitle: const Text('重新写入当前课表快照并通知系统刷新。'),
            onTap: () async {
              try {
                await onRefreshWidget();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已请求刷新桌面小组件，系统可能需要几秒生效。')),
                );
              } on Object {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('小组件同步失败，请检查安装包签名或稍后重试。')),
                );
              }
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
            subtitle: const Text('删除所有课程和学期，并重新进行首次设置。'),
            onTap: () async => onClearAllData(),
          ),
          const AboutListTile(
            applicationName: '课程表',
            applicationVersion: '1.1.14',
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

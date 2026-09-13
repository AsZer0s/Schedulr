import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/platform/adaptive_ui.dart';

class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({
    required this.title,
    required this.body,
    super.key,
    this.actions = const [],
    this.leading,
    this.floatingActionButton,
    this.cupertinoTrailing,
    this.bottomNavigationBar,
    this.cupertinoBottomAction,
  });

  final Widget title;
  final Widget body;
  final List<Widget> actions;
  final Widget? leading;
  final Widget? floatingActionButton;
  final Widget? cupertinoTrailing;
  final Widget? bottomNavigationBar;
  final Widget? cupertinoBottomAction;

  @override
  Widget build(BuildContext context) {
    if (usesCupertinoConventions(context)) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: title,
          leading: leading,
          trailing:
              cupertinoTrailing ??
              (actions.isEmpty
                  ? null
                  : Row(mainAxisSize: MainAxisSize.min, children: actions)),
        ),
        child: SafeArea(
          bottom: false,
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              children: [
                Expanded(child: body),
                ?cupertinoBottomAction,
                if (cupertinoBottomAction == null) ?bottomNavigationBar,
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(leading: leading, title: title, actions: actions),
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

class AdaptiveStatusPage extends StatelessWidget {
  const AdaptiveStatusPage({
    required this.message,
    super.key,
    this.title = const SizedBox.shrink(),
    this.loading = false,
  });

  final Widget title;
  final String message;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      title: title,
      body: Center(
        child: loading
            ? usesCupertinoConventions(context)
                  ? const CupertinoActivityIndicator()
                  : const CircularProgressIndicator()
            : Text(message),
      ),
    );
  }
}

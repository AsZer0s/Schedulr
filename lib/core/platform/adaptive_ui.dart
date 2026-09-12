import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

bool get usesCupertinoConventions => Platform.isIOS;

Future<bool> showAdaptiveConfirmationDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = '确认',
  String cancelLabel = '取消',
  bool destructive = false,
}) async {
  if (usesCupertinoConventions) {
    return await showCupertinoDialog<bool>(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context, false),
                child: Text(cancelLabel),
              ),
              CupertinoDialogAction(
                isDestructiveAction: destructive,
                onPressed: () => Navigator.pop(context, true),
                child: Text(confirmLabel),
              ),
            ],
          ),
        ) ??
        false;
  }

  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(cancelLabel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: destructive
                  ? TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    )
                  : null,
              child: Text(confirmLabel),
            ),
          ],
        ),
      ) ??
      false;
}

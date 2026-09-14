import 'package:flutter/services.dart';

const nativeDialogChannelName = 'app.schedulr/native_dialogs';

class NativeDialogAction {
  const NativeDialogAction({
    required this.id,
    required this.label,
    this.destructive = false,
  });

  final String id;
  final String label;
  final bool destructive;

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'label': label,
    'destructive': destructive,
  };
}

abstract interface class NativeDialogBridge {
  Future<String?> showActionSheet({
    String? title,
    String? message,
    required List<NativeDialogAction> actions,
    required String cancelLabel,
  });

  Future<bool?> showConfirmation({
    required String title,
    required String message,
    required String confirmLabel,
    required String cancelLabel,
    required bool destructive,
  });

  Future<String?> showTextInput({
    required String title,
    String? message,
    required String initialValue,
    required String confirmLabel,
    required String cancelLabel,
    String? placeholder,
    int? maxLength,
  });
}

class MethodChannelNativeDialogBridge implements NativeDialogBridge {
  const MethodChannelNativeDialogBridge({
    this.channel = const MethodChannel(nativeDialogChannelName),
  });

  final MethodChannel channel;

  @override
  Future<String?> showActionSheet({
    String? title,
    String? message,
    required List<NativeDialogAction> actions,
    required String cancelLabel,
  }) {
    return channel.invokeMethod<String>('showActionSheet', <String, Object?>{
      'title': title,
      'message': message,
      'cancelLabel': cancelLabel,
      'actions': actions
          .map((action) => action.toMap())
          .toList(growable: false),
    });
  }

  @override
  Future<bool?> showConfirmation({
    required String title,
    required String message,
    required String confirmLabel,
    required String cancelLabel,
    required bool destructive,
  }) {
    return channel.invokeMethod<bool>('showConfirmation', <String, Object?>{
      'title': title,
      'message': message,
      'confirmLabel': confirmLabel,
      'cancelLabel': cancelLabel,
      'destructive': destructive,
    });
  }

  @override
  Future<String?> showTextInput({
    required String title,
    String? message,
    required String initialValue,
    required String confirmLabel,
    required String cancelLabel,
    String? placeholder,
    int? maxLength,
  }) {
    return channel.invokeMethod<String>('showTextInput', <String, Object?>{
      'title': title,
      'message': message,
      'initialValue': initialValue,
      'confirmLabel': confirmLabel,
      'cancelLabel': cancelLabel,
      'placeholder': placeholder,
      'maxLength': maxLength,
    });
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schedulr/core/platform/adaptive_ui.dart';
import 'package:schedulr/core/platform/native_dialog_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(nativeDialogChannelName);
  const bridge = MethodChannelNativeDialogBridge(channel: channel);

  setUp(() {
    debugDefaultTargetPlatformOverride = null;
    nativeDialogBridge = const MethodChannelNativeDialogBridge();
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    nativeDialogBridge = const MethodChannelNativeDialogBridge();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('action sheet sends stable ids and destructive metadata', () async {
    MethodCall? received;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          received = call;
          return 'delete';
        });

    final result = await bridge.showActionSheet(
      title: '更多操作',
      message: '请选择',
      cancelLabel: '取消',
      actions: const [
        NativeDialogAction(id: 'edit', label: '编辑'),
        NativeDialogAction(id: 'delete', label: '删除', destructive: true),
      ],
    );

    expect(result, 'delete');
    expect(received?.method, 'showActionSheet');
    expect(received?.arguments, {
      'title': '更多操作',
      'message': '请选择',
      'cancelLabel': '取消',
      'actions': [
        {'id': 'edit', 'label': '编辑', 'destructive': false},
        {'id': 'delete', 'label': '删除', 'destructive': true},
      ],
    });
  });

  test(
    'confirmation sends destructive intent and accepts cancellation',
    () async {
      MethodCall? received;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            received = call;
            return null;
          });

      final result = await bridge.showConfirmation(
        title: '放弃未保存的修改？',
        message: '当前修改尚未保存。',
        confirmLabel: '放弃修改',
        cancelLabel: '继续编辑',
        destructive: true,
      );

      expect(result, isNull);
      expect(received?.method, 'showConfirmation');
      expect(received?.arguments, {
        'title': '放弃未保存的修改？',
        'message': '当前修改尚未保存。',
        'confirmLabel': '放弃修改',
        'cancelLabel': '继续编辑',
        'destructive': true,
      });
    },
  );

  testWidgets('adaptive APIs use the native bridge on a real iOS platform', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final fake = _FakeNativeDialogBridge(
      actionResults: ['action-1'],
      confirmationResults: [true],
      textResults: ['', '同学课表'],
    );
    nativeDialogBridge = fake;
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: Builder(
          builder: (value) {
            context = value;
            return const SizedBox();
          },
        ),
      ),
    );

    final action = await showAdaptiveActionSheet<String>(
      context,
      title: '更多操作',
      actions: const [
        AdaptiveActionSheetAction(label: '导入', value: 'import'),
        AdaptiveActionSheetAction(label: '设置', value: 'settings'),
      ],
    );
    final confirmed = await showAdaptiveConfirmationDialog(
      context,
      title: '放弃未保存的修改？',
      message: '返回后将丢失。',
      confirmLabel: '放弃修改',
      destructive: true,
    );
    final name = await showAdaptiveTextInputDialog(
      context,
      title: '课表名称',
      validator: (value) => value == null || value.isEmpty ? '请输入课表名称' : null,
    );

    expect(action, 'settings');
    expect(confirmed, isTrue);
    expect(name, '同学课表');
    expect(fake.textMessages, [null, '请输入课表名称']);
    debugDefaultTargetPlatformOverride = null;
    nativeDialogBridge = const MethodChannelNativeDialogBridge();
  });

  testWidgets('adaptive native dialogs retry while UIKit is dismissing', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final fake = _BusyThenConfirmationBridge();
    nativeDialogBridge = fake;
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: Builder(
          builder: (value) {
            context = value;
            return const SizedBox();
          },
        ),
      ),
    );

    final future = showAdaptiveConfirmationDialog(
      context,
      title: '删除课程？',
      message: '无法撤销。',
      confirmLabel: '删除',
      destructive: true,
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(await future, isTrue);
    expect(fake.attempts, 2);
    debugDefaultTargetPlatformOverride = null;
    nativeDialogBridge = const MethodChannelNativeDialogBridge();
  });

  test('text input sends initial value, placeholder, and max length', () async {
    MethodCall? received;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          received = call;
          return '同学课表';
        });

    final result = await bridge.showTextInput(
      title: '重命名课表',
      message: '请输入名称',
      initialValue: '旧名称',
      confirmLabel: '保存',
      cancelLabel: '取消',
      placeholder: '例如：大二上',
      maxLength: 80,
    );

    expect(result, '同学课表');
    expect(received?.method, 'showTextInput');
    expect(received?.arguments, {
      'title': '重命名课表',
      'message': '请输入名称',
      'initialValue': '旧名称',
      'confirmLabel': '保存',
      'cancelLabel': '取消',
      'placeholder': '例如：大二上',
      'maxLength': 80,
    });
  });
}

class _BusyThenConfirmationBridge implements NativeDialogBridge {
  int attempts = 0;

  @override
  Future<String?> showActionSheet({
    String? title,
    String? message,
    required List<NativeDialogAction> actions,
    required String cancelLabel,
  }) async => null;

  @override
  Future<bool?> showConfirmation({
    required String title,
    required String message,
    required String confirmLabel,
    required String cancelLabel,
    required bool destructive,
  }) async {
    attempts++;
    if (attempts == 1) {
      throw PlatformException(code: 'presentation_in_progress');
    }
    return true;
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
  }) async => null;
}

class _FakeNativeDialogBridge implements NativeDialogBridge {
  _FakeNativeDialogBridge({
    this.actionResults = const [],
    this.confirmationResults = const [],
    this.textResults = const [],
  });

  final List<String?> actionResults;
  final List<bool?> confirmationResults;
  final List<String?> textResults;
  final textMessages = <String?>[];
  int _actionIndex = 0;
  int _confirmationIndex = 0;
  int _textIndex = 0;

  @override
  Future<String?> showActionSheet({
    String? title,
    String? message,
    required List<NativeDialogAction> actions,
    required String cancelLabel,
  }) async => actionResults[_actionIndex++];

  @override
  Future<bool?> showConfirmation({
    required String title,
    required String message,
    required String confirmLabel,
    required String cancelLabel,
    required bool destructive,
  }) async => confirmationResults[_confirmationIndex++];

  @override
  Future<String?> showTextInput({
    required String title,
    String? message,
    required String initialValue,
    required String confirmLabel,
    required String cancelLabel,
    String? placeholder,
    int? maxLength,
  }) async {
    textMessages.add(message);
    return textResults[_textIndex++];
  }
}

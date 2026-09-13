import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schedulr/core/platform/adaptive_ui.dart';

void main() {
  testWidgets('平台约定和页面路由由 ThemeData.platform 决定', (tester) async {
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

    expect(usesCupertinoConventions(context), isTrue);
    expect(
      adaptivePageRoute<void>(
        context: context,
        builder: (_) => const SizedBox(),
      ),
      isA<CupertinoPageRoute<void>>(),
    );
  });

  testWidgets('iOS action sheet 使用 CupertinoActionSheet', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: Builder(
          builder: (context) => CupertinoButton(
            onPressed: () => showAdaptiveActionSheet<String>(
              context,
              title: '操作',
              actions: const [
                AdaptiveActionSheetAction(label: '选择', value: 'selected'),
              ],
            ),
            child: const Text('打开'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoActionSheet), findsOneWidget);
    expect(find.text('选择'), findsOneWidget);
  });

  testWidgets('iOS text input dialog 校验并返回文本', (tester) async {
    String? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: Builder(
          builder: (context) => CupertinoButton(
            onPressed: () async {
              result = await showAdaptiveTextInputDialog(
                context,
                title: '命名',
                validator: (value) =>
                    value == null || value.isEmpty ? '必填' : null,
              );
            },
            child: const Text('打开'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoAlertDialog), findsOneWidget);
    expect(find.byType(CupertinoTextField), findsOneWidget);
    await tester.tap(find.text('确定'));
    await tester.pump();
    expect(find.text('必填'), findsOneWidget);
    await tester.enterText(find.byType(CupertinoTextField), '新名称');
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    expect(result, '新名称');
  });

  testWidgets('iOS date picker 显示滚轮和取消完成动作', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: Builder(
          builder: (context) => CupertinoButton(
            onPressed: () => showAdaptiveDatePicker(
              context,
              initialDate: DateTime(2026, 9, 13),
              firstDate: DateTime(2020),
              lastDate: DateTime(2040),
            ),
            child: const Text('选日期'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('选日期'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('adaptive-date-picker')), findsOneWidget);
    expect(find.byType(CupertinoDatePicker), findsOneWidget);
    expect(find.byKey(const ValueKey('adaptive-date-cancel')), findsOneWidget);
    expect(find.byKey(const ValueKey('adaptive-date-done')), findsOneWidget);
  });

  testWidgets('adaptive picker 在 iOS 打开 CupertinoPicker', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: Scaffold(
          body: AdaptivePickerFormField<int>(
            values: const [1, 2, 3],
            labelBuilder: (value) => '第$value项',
            value: 1,
            onChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.byType(DropdownButtonFormField<int>), findsNothing);
    await tester.tap(find.text('第1项'));
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoPicker), findsOneWidget);
  });
}

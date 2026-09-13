import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Whether iOS conventions should be used for this widget tree.
///
/// The decision intentionally comes from [ThemeData.platform], rather than
/// dart:io, so widget tests can exercise iOS UI on Linux.
bool usesCupertinoConventions(BuildContext context) {
  return Theme.of(context).platform == TargetPlatform.iOS;
}

class AdaptiveActionSheetAction<T> {
  const AdaptiveActionSheetAction({
    required this.label,
    required this.value,
    this.isDestructive = false,
  });

  final String label;
  final T value;
  final bool isDestructive;
}

Future<T?> showAdaptiveActionSheet<T>(
  BuildContext context, {
  String? title,
  String? message,
  required List<AdaptiveActionSheetAction<T>> actions,
  String cancelLabel = '取消',
}) {
  if (usesCupertinoConventions(context)) {
    return showCupertinoModalPopup<T>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: title == null ? null : Text(title),
        message: message == null ? null : Text(message),
        actions: [
          for (final action in actions)
            CupertinoActionSheetAction(
              isDestructiveAction: action.isDestructive,
              onPressed: () => Navigator.of(context).pop(action.value),
              child: Text(action.label),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(cancelLabel),
        ),
      ),
    );
  }
  return showModalBottomSheet<T>(
    context: context,
    useSafeArea: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
          if (message != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(message),
              ),
            ),
          for (final action in actions)
            ListTile(
              title: Text(action.label),
              textColor: action.isDestructive
                  ? Theme.of(context).colorScheme.error
                  : null,
              onTap: () => Navigator.of(context).pop(action.value),
            ),
          ListTile(
            title: Text(cancelLabel),
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    ),
  );
}

Future<T?> showAdaptiveContentSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool useSafeArea = true,
  bool isScrollControlled = true,
}) {
  if (usesCupertinoConventions(context)) {
    return showCupertinoModalPopup<T>(
      context: context,
      builder: (context) => CupertinoPopupSurface(
        isSurfacePainted: true,
        child: SafeArea(
          top: false,
          child: Material(
            type: MaterialType.transparency,
            child: builder(context),
          ),
        ),
      ),
    );
  }
  return showModalBottomSheet<T>(
    context: context,
    useSafeArea: useSafeArea,
    isScrollControlled: isScrollControlled,
    builder: builder,
  );
}

Future<T?> showAdaptiveLongSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool enableDrag = true,
}) {
  if (usesCupertinoConventions(context)) {
    return showCupertinoSheet<T>(
      context: context,
      enableDrag: enableDrag,
      scrollableBuilder: (context, scrollController) =>
          Material(type: MaterialType.transparency, child: builder(context)),
    );
  }
  return showModalBottomSheet<T>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: builder,
  );
}

Future<String?> showAdaptiveTextInputDialog(
  BuildContext context, {
  required String title,
  String initialValue = '',
  String confirmLabel = '确定',
  String cancelLabel = '取消',
  String? labelText,
  String? hintText,
  int? maxLength,
  String? Function(String?)? validator,
  ValueKey<String> fieldKey = const ValueKey('adaptive-text-input'),
}) {
  if (usesCupertinoConventions(context)) {
    return showCupertinoDialog<String>(
      context: context,
      builder: (dialogContext) => _AdaptiveCupertinoTextInputDialog(
        title: title,
        initialValue: initialValue,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        hintText: hintText ?? labelText,
        maxLength: maxLength,
        validator: validator,
        fieldKey: fieldKey,
      ),
    );
  }
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => _AdaptiveMaterialTextInputDialog(
      title: title,
      initialValue: initialValue,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      labelText: labelText,
      hintText: hintText,
      maxLength: maxLength,
      validator: validator,
      fieldKey: fieldKey,
    ),
  );
}

class _AdaptiveCupertinoTextInputDialog extends StatefulWidget {
  const _AdaptiveCupertinoTextInputDialog({
    required this.title,
    required this.initialValue,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.fieldKey,
    this.hintText,
    this.maxLength,
    this.validator,
  });

  final String title;
  final String initialValue;
  final String confirmLabel;
  final String cancelLabel;
  final String? hintText;
  final int? maxLength;
  final String? Function(String?)? validator;
  final ValueKey<String> fieldKey;

  @override
  State<_AdaptiveCupertinoTextInputDialog> createState() =>
      _AdaptiveCupertinoTextInputDialogState();
}

class _AdaptiveCupertinoTextInputDialogState
    extends State<_AdaptiveCupertinoTextInputDialog> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    final error = widget.validator?.call(value);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: Text(widget.title),
      content: Column(
        children: [
          const SizedBox(height: 14),
          CupertinoTextField(
            key: widget.fieldKey,
            controller: _controller,
            autofocus: true,
            maxLength: widget.maxLength,
            placeholder: widget.hintText,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          if (_error case final error?) ...[
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(color: CupertinoColors.systemRed),
            ),
          ],
        ],
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.cancelLabel),
        ),
        CupertinoDialogAction(
          onPressed: _submit,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

class _AdaptiveMaterialTextInputDialog extends StatefulWidget {
  const _AdaptiveMaterialTextInputDialog({
    required this.title,
    required this.initialValue,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.fieldKey,
    this.labelText,
    this.hintText,
    this.maxLength,
    this.validator,
  });

  final String title;
  final String initialValue;
  final String confirmLabel;
  final String cancelLabel;
  final String? labelText;
  final String? hintText;
  final int? maxLength;
  final String? Function(String?)? validator;
  final ValueKey<String> fieldKey;

  @override
  State<_AdaptiveMaterialTextInputDialog> createState() =>
      _AdaptiveMaterialTextInputDialogState();
}

class _AdaptiveMaterialTextInputDialogState
    extends State<_AdaptiveMaterialTextInputDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: TextFormField(
          key: widget.fieldKey,
          controller: _controller,
          autofocus: true,
          maxLength: widget.maxLength,
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
          ),
          textInputAction: TextInputAction.done,
          validator: widget.validator,
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.cancelLabel),
        ),
        FilledButton(onPressed: _submit, child: Text(widget.confirmLabel)),
      ],
    );
  }
}

Future<DateTime?> showAdaptiveDatePicker(
  BuildContext context, {
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String confirmLabel = '完成',
  String cancelLabel = '取消',
}) {
  if (!usesCupertinoConventions(context)) {
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
  }

  var selected = initialDate;
  return showCupertinoModalPopup<DateTime>(
    context: context,
    builder: (context) => CupertinoPopupSurface(
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 330,
          child: Column(
            children: [
              SizedBox(
                height: 52,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      key: const ValueKey('adaptive-date-cancel'),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(cancelLabel),
                    ),
                    CupertinoButton(
                      key: const ValueKey('adaptive-date-done'),
                      onPressed: () => Navigator.of(context).pop(selected),
                      child: Text(confirmLabel),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  key: const ValueKey('adaptive-date-picker'),
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: initialDate,
                  minimumDate: firstDate,
                  maximumDate: lastDate,
                  onDateTimeChanged: (value) => selected = value,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class AdaptivePickerFormField<T> extends StatefulWidget {
  const AdaptivePickerFormField({
    required this.values,
    required this.labelBuilder,
    required this.value,
    required this.onChanged,
    super.key,
    this.validator,
    this.decoration = const InputDecoration(),
    this.enabled = true,
  });

  final List<T> values;
  final String Function(T value) labelBuilder;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final FormFieldValidator<T>? validator;
  final InputDecoration decoration;
  final bool enabled;

  @override
  State<AdaptivePickerFormField<T>> createState() =>
      _AdaptivePickerFormFieldState<T>();
}

class _AdaptivePickerFormFieldState<T>
    extends State<AdaptivePickerFormField<T>> {
  @override
  Widget build(BuildContext context) {
    return FormField<T>(
      initialValue: widget.value,
      validator: widget.validator,
      builder: (state) => _AdaptivePickerField<T>(
        values: widget.values,
        labelBuilder: widget.labelBuilder,
        value: widget.value,
        onChanged: widget.enabled
            ? (next) {
                state.didChange(next);
                widget.onChanged?.call(next);
              }
            : null,
        decoration: widget.decoration.copyWith(errorText: state.errorText),
      ),
    );
  }
}

class _AdaptivePickerField<T> extends StatelessWidget {
  const _AdaptivePickerField({
    required this.values,
    required this.labelBuilder,
    required this.value,
    required this.onChanged,
    required this.decoration,
  });

  final List<T> values;
  final String Function(T value) labelBuilder;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final InputDecoration decoration;

  @override
  Widget build(BuildContext context) {
    if (!usesCupertinoConventions(context)) {
      final effectiveValue = values.contains(value) ? value : null;
      return DropdownButtonFormField<T>(
        initialValue: effectiveValue,
        decoration: decoration,
        items: [
          for (final item in values)
            DropdownMenuItem(value: item, child: Text(labelBuilder(item))),
        ],
        onChanged: onChanged,
      );
    }

    return InkWell(
      onTap: onChanged == null ? null : () => _showPicker(context),
      child: InputDecorator(
        decoration: decoration,
        isEmpty: value == null,
        child: Text(value == null ? '' : labelBuilder(value as T)),
      ),
    );
  }

  Future<void> _showPicker(BuildContext context) async {
    var selected = value ?? values.first;
    final result = await showAdaptiveContentSheet<T>(
      context,
      builder: (context) => SizedBox(
        height: 300,
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: CupertinoButton(
                onPressed: () => Navigator.of(context).pop(selected),
                child: const Text('完成'),
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 44,
                scrollController: FixedExtentScrollController(
                  initialItem: values
                      .indexOf(selected)
                      .clamp(0, values.length - 1),
                ),
                onSelectedItemChanged: (index) => selected = values[index],
                children: [for (final item in values) Text(labelBuilder(item))],
              ),
            ),
          ],
        ),
      ),
    );
    if (result != null) onChanged?.call(result);
  }
}

Future<bool> showAdaptiveConfirmationDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = '确认',
  String cancelLabel = '取消',
  bool destructive = false,
}) async {
  if (usesCupertinoConventions(context)) {
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

PageRoute<T> adaptivePageRoute<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  RouteSettings? settings,
  bool fullscreenDialog = false,
}) {
  if (usesCupertinoConventions(context)) {
    return CupertinoPageRoute<T>(
      builder: builder,
      settings: settings,
      fullscreenDialog: fullscreenDialog,
    );
  }
  return MaterialPageRoute<T>(
    builder: builder,
    settings: settings,
    fullscreenDialog: fullscreenDialog,
  );
}

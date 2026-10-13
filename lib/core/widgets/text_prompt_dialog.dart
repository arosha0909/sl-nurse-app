import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

/// Single-field input dialog. It owns its controller, so the controller outlives
/// the dialog's closing animation (disposing it right after `showDialog` returns
/// would crash while the field is still on screen).
class TextPromptDialog extends StatefulWidget {
  const TextPromptDialog({
    super.key,
    required this.title,
    this.initial = '',
    this.hint,
    this.helper,
    this.maxLines = 1,
    this.keyboard = TextInputType.text,
    this.numeric = false,
    this.validate,
    this.confirmLabel = 'Save',
  });

  final String title;
  final String initial;
  final String? hint;
  final String? helper;
  final int maxLines;
  final TextInputType keyboard;

  /// Only digits and a decimal point.
  final bool numeric;
  final String? Function(String value)? validate;
  final String confirmLabel;

  /// Returns the trimmed text, or null when cancelled.
  static Future<String?> show(BuildContext context, TextPromptDialog dialog) =>
      showDialog<String>(context: context, builder: (_) => dialog);

  @override
  State<TextPromptDialog> createState() => _TextPromptDialogState();
}

class _TextPromptDialogState extends State<TextPromptDialog> {
  late final _controller = TextEditingController(text: widget.initial);
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    final problem = widget.validate?.call(value);
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: widget.maxLines,
        keyboardType: widget.keyboard,
        inputFormatters: widget.numeric
            ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
            : null,
        onSubmitted: widget.maxLines == 1 ? (_) => _submit() : null,
        decoration: InputDecoration(
          hintText: widget.hint,
          helperText: widget.helper,
          helperMaxLines: 2,
          errorText: _error,
          fillColor: AppColors.surface,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: Text(widget.confirmLabel)),
      ],
    );
  }
}

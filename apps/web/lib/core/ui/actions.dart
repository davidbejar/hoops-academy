import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';
import '../errors/app_error.dart';
import 'app_error_view.dart';

/// Runs a mutation, reports failures with a localised snack bar (never raw
/// server text) and returns whether it succeeded. [success] is shown on OK.
/// [errorText] lets a feature word specific failures (by error code); it
/// defaults to the generic per-kind message.
Future<bool> runAction(
  BuildContext context,
  Future<void> Function() action, {
  String? success,
  String Function(Object error, AppLocalizations l)? errorText,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final l = AppLocalizations.of(context);
  try {
    await action();
    if (success != null) {
      messenger?.showSnackBar(SnackBar(content: Text(success)));
    }
    return true;
  } on Object catch (e) {
    final text = errorText?.call(e, l) ?? AppError.of(e).message(l);
    messenger?.showSnackBar(SnackBar(content: Text(text)));
    return false;
  }
}

/// Yes/no dialog; true when confirmed.
Future<bool> confirmDialog(
  BuildContext context, {
  required String message,
  String? confirmLabel,
}) async {
  final l = AppLocalizations.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      content: Text(message),
      actions: [
        TextButton(
          key: const Key('dialog-cancel'),
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l.cancel),
        ),
        FilledButton(
          key: const Key('dialog-confirm'),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel ?? l.confirm),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Dialog with a note field. Returns the trimmed note (possibly empty), or
/// null when cancelled. With [required] an empty note blocks confirmation.
Future<String?> noteDialog(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  bool required = false,
  String? label,
}) {
  final l = AppLocalizations.of(context);
  return showDialog<String>(
    context: context,
    builder: (ctx) => _NoteDialog(
      title: title,
      confirmLabel: confirmLabel,
      required: required,
      label: label ?? (required ? l.noteRequired : l.noteOptional),
    ),
  );
}

class _NoteDialog extends StatefulWidget {
  const _NoteDialog({
    required this.title,
    required this.confirmLabel,
    required this.required,
    required this.label,
  });

  final String title;
  final String confirmLabel;
  final bool required;
  final String label;

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  final _controller = TextEditingController();
  final _form = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _form,
        child: TextFormField(
          key: const Key('note-field'),
          controller: _controller,
          decoration: InputDecoration(labelText: widget.label),
          maxLines: 3,
          validator: (v) => widget.required && (v ?? '').trim().isEmpty
              ? l.fieldRequired
              : null,
        ),
      ),
      actions: [
        TextButton(
          key: const Key('dialog-cancel'),
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        FilledButton(
          key: const Key('dialog-confirm'),
          onPressed: () {
            if (_form.currentState!.validate()) {
              Navigator.pop(context, _controller.text.trim());
            }
          },
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

/// Localised message for anything thrown by the data layer.
abstract final class AppErrorText {
  static String of(Object error, AppLocalizations l) =>
      AppError.of(error).message(l);
}

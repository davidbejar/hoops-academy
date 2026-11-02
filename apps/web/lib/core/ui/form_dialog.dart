import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';

/// Dialog around a validated form. [onSubmit] returns true on success (the
/// dialog then closes with `true`); on failure it stays open for correction.
class FormDialog extends StatefulWidget {
  const FormDialog({
    super.key,
    required this.title,
    required this.formKey,
    required this.children,
    required this.onSubmit,
    this.submitLabel,
    this.canSubmit = true,
    this.validateExtra,
    this.afterClose,
  });

  final String title;
  final GlobalKey<FormState> formKey;
  final List<Widget> children;
  final Future<bool> Function() onSubmit;
  final String? submitLabel;
  final bool canSubmit;

  /// Validation that lives outside form fields (role chips, date buttons).
  /// Runs together with the form validators; false blocks the submit.
  final bool Function()? validateExtra;

  /// Runs after a successful submit once the dialog has been popped, e.g. to show a result that must not stack
  /// under this dialog (a temporary password).
  final Future<void> Function()? afterClose;

  @override
  State<FormDialog> createState() => _FormDialogState();
}

class _FormDialogState extends State<FormDialog> {
  bool _busy = false;

  Future<void> _submit() async {
    final fieldsOk = widget.formKey.currentState!.validate();
    final extraOk = widget.validateExtra?.call() ?? true;
    if (!fieldsOk || !extraOk) return;
    setState(() => _busy = true);
    final ok = await widget.onSubmit();
    if (!mounted) return;
    if (ok) {
      final after = widget.afterClose;
      Navigator.of(context).pop(true);
      if (after != null) unawaited(after());
    } else {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // While the request runs the dialog must stay: its result (e.g. a temporary password) is shown from here.
    return PopScope(
      canPop: !_busy,
      child: AlertDialog(
        title: Text(widget.title),
        scrollable: true,
        content: Form(
          key: widget.formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: widget.children,
          ),
        ),
        actions: [
          TextButton(
            key: const Key('form-cancel'),
            onPressed: _busy ? null : () => Navigator.of(context).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            key: const Key('form-submit'),
            onPressed: _busy || !widget.canSubmit ? null : _submit,
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(widget.submitLabel ?? l.save),
          ),
        ],
      ),
    );
  }
}

/// Spacing between form fields.
const formGap = SizedBox(height: 12);

String? requiredValidator(AppLocalizations l, String? v) =>
    (v ?? '').trim().isEmpty ? l.fieldRequired : null;

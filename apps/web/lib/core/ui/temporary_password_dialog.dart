import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design/tokens.dart';
import '../../l10n/gen/app_localizations.dart';

/// Tells the creator of a login what happened (ADR-0024).
///
/// A login created by the call comes back with a server-generated [temporaryPassword]: it is shown once in
/// [showTemporaryPasswordDialog], then [done] (what the call did, e.g. "Administrator added") is confirmed in a snack
/// bar. Without one the person already had a login: a snack bar says that they sign in with their current password.
Future<void> announceLogin(
  BuildContext context, {
  required String person,
  required String? temporaryPassword,
  String? done,
  String? email,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final l = AppLocalizations.of(context);
  if (temporaryPassword == null) {
    final existing = l.tempPasswordExistingLogin;
    messenger?.showSnackBar(
      SnackBar(content: Text(done == null ? existing : '$done. $existing')),
    );
    return;
  }
  await showTemporaryPasswordDialog(
    context,
    person: person,
    email: email,
    password: temporaryPassword,
  );
  if (done != null) messenger?.showSnackBar(SnackBar(content: Text(done)));
}

/// Shows [password] once. Only the explicit "Done" closes it (no barrier tap, no back, no Escape), and the value
/// lives only in this dialog's widget: it is never logged, kept in a provider or written anywhere.
Future<void> showTemporaryPasswordDialog(
  BuildContext context, {
  required String person,
  required String password,
  String? email,
}) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (_) =>
      TemporaryPasswordDialog(person: person, email: email, password: password),
);

class TemporaryPasswordDialog extends StatefulWidget {
  const TemporaryPasswordDialog({
    super.key,
    required this.person,
    required this.password,
    this.email,
  });

  final String person;
  final String? email;
  final String password;

  @override
  State<TemporaryPasswordDialog> createState() =>
      _TemporaryPasswordDialogState();
}

class _TemporaryPasswordDialogState extends State<TemporaryPasswordDialog> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.password));
    if (mounted) setState(() => _copied = true);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      child: AlertDialog(
        key: const Key('temp-password-dialog'),
        title: Text(l.tempPasswordTitle),
        scrollable: true,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.tempPasswordFor(widget.person),
              style: theme.textTheme.titleSmall,
            ),
            if (widget.email != null)
              Text(
                l.tempPasswordLoginWith(widget.email!),
                style: theme.textTheme.bodyMedium,
              ),
            const SizedBox(height: HoopsSpace.md),
            Container(
              padding: const EdgeInsets.all(HoopsSpace.md),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(HoopsRadius.sm),
              ),
              child: SelectableText(
                widget.password,
                key: const Key('temp-password-value'),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontFamily: 'monospace',
                  fontFamilyFallback: const [
                    'Menlo',
                    'Consolas',
                    'Courier New',
                  ],
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: HoopsSpace.sm),
            OutlinedButton.icon(
              key: const Key('temp-password-copy'),
              onPressed: _copy,
              icon: Icon(_copied ? Icons.check : Icons.copy_outlined),
              label: Text(_copied ? l.tempPasswordCopied : l.tempPasswordCopy),
            ),
            const SizedBox(height: HoopsSpace.md),
            _Hint(icon: Icons.lock_outline, text: l.tempPasswordShareHint),
            _Hint(
              icon: Icons.visibility_off_outlined,
              text: l.tempPasswordShownOnce,
            ),
            _Hint(icon: Icons.login, text: l.tempPasswordFirstSignIn),
          ],
        ),
        actions: [
          FilledButton(
            key: const Key('temp-password-done'),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.tempPasswordDone),
          ),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: HoopsSpace.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: HoopsSpace.sm),
          Expanded(child: Text(text, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }
}

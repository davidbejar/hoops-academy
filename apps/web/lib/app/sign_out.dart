import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth/auth_providers.dart';
import '../core/connectivity/connectivity_providers.dart';
import '../core/http/request_context.dart';
import '../core/tenancy/tenant_selection.dart';
import '../features/match/application/match_providers.dart';
import '../l10n/gen/app_localizations.dart';

/// Signs the user out of this device. Everything local goes first (selected
/// academy, request context, offline match DB incl. unsynced events), so it
/// works offline; only then the identity provider session is ended, and that
/// is skipped while the browser reports no network (F-03, F-07).
Future<void> signOut(WidgetRef ref) async {
  final online = ref.read(onlineProvider).value ?? true;
  await ref.read(selectedTenantIdProvider.notifier).clear();
  ref.read(requestContextProvider).tenantId = null;
  try {
    await ref.read(matchStoreProvider).wipe();
  } on Object {
    // A broken local DB must not keep the user signed in.
  }
  await ref.read(authServiceProvider).logout(endSession: online);
}

/// Asks for confirmation when events were not synced yet, then [signOut]s.
Future<void> confirmAndSignOut(BuildContext context, WidgetRef ref) async {
  var unsynced = 0;
  try {
    unsynced = await ref.read(matchStoreProvider).unsyncedTotal();
  } on Object {
    // Unreadable store: nothing to warn about.
  }
  if (unsynced > 0) {
    if (!context.mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l = AppLocalizations.of(context);
        return AlertDialog(
          key: const Key('signout-warning'),
          title: Text(l.signOutUnsyncedTitle),
          content: Text(l.signOutUnsyncedBody(unsynced), key: const Key('signout-warning-body')),
          actions: [
            TextButton(
              key: const Key('signout-cancel'),
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l.cancel),
            ),
            FilledButton(
              key: const Key('signout-confirm'),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l.signOutAnyway),
            ),
          ],
        );
      },
    );
    if (ok != true) return;
  }
  await signOut(ref);
}

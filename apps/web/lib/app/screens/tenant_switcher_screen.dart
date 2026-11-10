import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/context_switcher.dart';
import '../../core/session/session.dart';
import '../../core/session/session_providers.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../core/ui/kit.dart';

/// Lists every context of the login (each academy from `/me`, plus
/// Application admin for a super admin) and remembers the choice. It is the
/// landing of a login with several contexts and none remembered (WP99).
class TenantSwitcherScreen extends ConsumerWidget {
  const TenantSwitcherScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final session = ref.watch(sessionProvider);
    final user = switch (session) {
      NeedsTenant(:final user) => user,
      Ready(:final user) => user,
      _ => null,
    };
    final activeId = ref.watch(activeContextIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.switchContext),
        automaticallyImplyLeading: activeId != null,
      ),
      body: SafeArea(
        child: ListView(
          key: const Key('tenant-list'),
          padding: EdgeInsets.symmetric(
            vertical: WidthClass.of(context).sectionGap,
          ),
          children: [
            ContentFrame(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PageHeader(
                    title: l.chooseContextTitle,
                    subtitle: l.chooseContextSubtitle,
                  ),
                  const SizedBox(height: HoopsSpace.lg),
                  ContextList(
                    contexts: user == null ? const [] : contextsOf(user),
                    activeId: activeId,
                    onSelect: (target) => enterContext(context, ref, target),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

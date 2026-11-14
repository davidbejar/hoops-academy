import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/tenant/presentation/tenant_avatar.dart';
import '../../l10n/gen/app_localizations.dart';
import '../session/session.dart';
import '../session/session_providers.dart';
import '../tenancy/tenant_selection.dart';
import '../ui/kit.dart';
import 'destination_labels.dart';

/// What the switcher and the shell chip show of a context.
extension AppContextLabel on AppContext {
  String title(AppLocalizations l) => switch (this) {
    AcademyContext(:final membership) => membership.tenantName,
    ApplicationAdminContext() => l.contextApplicationAdmin,
  };

  /// The role in that context ("Administrador, Entrenador", "Super admin").
  String role(AppLocalizations l) => switch (this) {
    AcademyContext(:final membership) =>
      membership.roles.map((r) => r.label(l)).join(', '),
    ApplicationAdminContext() => l.contextApplicationAdminRole,
  };
}

/// The id of the context the session works in, null while choosing.
final activeContextIdProvider = Provider<String?>((ref) {
  final session = ref.watch(sessionProvider);
  if (session is! Ready) return null;
  if (session.applicationAdmin) return platformContextId;
  return session.membership?.tenantId;
});

/// Remembers [target] (per browser) and opens its landing route: the menu and
/// the tenant header follow from the session.
Future<void> enterContext(
  BuildContext context,
  WidgetRef ref,
  AppContext target,
) async {
  final router = GoRouter.of(context);
  await ref.read(selectedTenantIdProvider.notifier).select(target.id);
  router.go('/');
}

/// Every context of the login with its name and role, the active one marked.
/// One widget for the sheet, the wide panel and the chooser screen.
class ContextList extends StatelessWidget {
  const ContextList({
    super.key,
    required this.contexts,
    required this.activeId,
    required this.onSelect,
  });

  final List<AppContext> contexts;
  final String? activeId;
  final ValueChanged<AppContext> onSelect;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HoopsTokens.colorsOf(context);
    return Column(
      key: const Key('context-list'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: HoopsSpace.gap,
      children: [
        for (final target in contexts)
          ListRow(
            key: Key('tenant-${target.id}'),
            leading: switch (target) {
              AcademyContext(:final membership) => InitialsAvatar(
                name: membership.tenantName,
              ),
              ApplicationAdminContext() => const IconTile(
                Icons.admin_panel_settings_outlined,
                size: HoopsSize.avatar,
              ),
            },
            title: target.title(l),
            subtitle: target.role(l),
            trailing: target.id == activeId
                ? Icon(Icons.check_circle, color: c.brand)
                : Icon(Icons.chevron_right, color: c.inkMuted),
            onTap: () => onSelect(target),
          ),
      ],
    );
  }
}

/// Opens the switcher: a sheet on phones, a panel beside the rail on wide
/// screens. Picking a context closes it and opens that context's landing.
Future<void> showContextSwitcher(BuildContext context, WidgetRef ref) {
  final user = switch (ref.read(sessionProvider)) {
    Ready(:final user) => user,
    NeedsTenant(:final user) => user,
    _ => null,
  };
  if (user == null) return Future.value();
  final contexts = contextsOf(user);
  final activeId = ref.read(activeContextIdProvider);
  final compact = WidthClass.of(context).isCompact;

  Widget content(BuildContext inner) => _SwitcherContent(
    contexts: contexts,
    activeId: activeId,
    onSelect: (target) {
      Navigator.of(inner).pop();
      enterContext(context, ref, target);
    },
  );

  return compact
      ? showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (inner) => SafeArea(child: content(inner)),
        )
      : showDialog<void>(
          context: context,
          builder: (inner) => Dialog(
            key: const Key('context-panel'),
            alignment: Alignment.topLeft,
            insetPadding: const EdgeInsets.all(HoopsSpace.md),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: content(inner),
            ),
          ),
        );
}

class _SwitcherContent extends StatelessWidget {
  const _SwitcherContent({
    required this.contexts,
    required this.activeId,
    required this.onSelect,
  });

  final List<AppContext> contexts;
  final String? activeId;
  final ValueChanged<AppContext> onSelect;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SingleChildScrollView(
      key: const Key('context-switcher'),
      padding: const EdgeInsets.fromLTRB(
        HoopsSpace.md,
        HoopsSpace.xs,
        HoopsSpace.md,
        HoopsSpace.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: HoopsSpace.gap),
            child: Semantics(
              header: true,
              child: Text(
                l.switchContext,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          ContextList(
            contexts: contexts,
            activeId: activeId,
            onSelect: onSelect,
          ),
        ],
      ),
    );
  }
}

/// The current context (avatar or mark + name) as a button that opens the
/// switcher; plain when the login has only one context.
class ContextChip extends ConsumerWidget {
  const ContextChip({super.key, required this.session});

  final Ready session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = HoopsTokens.colorsOf(context);
    final membership = session.membership;
    final canSwitch = contextsOf(session.user).length > 1;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: InkWell(
        key: const Key('tenant-chip'),
        borderRadius: BorderRadius.circular(HoopsRadius.md),
        onTap: canSwitch ? () => showContextSwitcher(context, ref) : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: HoopsSize.minTapTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: HoopsSpace.sm),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (membership != null) ...[
                  TenantAvatar(name: membership.tenantName, radius: 18),
                  const SizedBox(width: HoopsSpace.gap),
                ] else if (session.applicationAdmin) ...[
                  const IconTile(Icons.admin_panel_settings_outlined, size: 36),
                  const SizedBox(width: HoopsSpace.gap),
                ],
                Flexible(
                  child: Text(
                    membership?.tenantName ??
                        (session.applicationAdmin
                            ? l.contextApplicationAdmin
                            : l.appName),
                    overflow: TextOverflow.ellipsis,
                    style: HoopsType.brand(Theme.of(context).textTheme, c),
                  ),
                ),
                if (canSwitch) ...[
                  const SizedBox(width: HoopsSpace.xs),
                  Icon(Icons.expand_more, color: c.inkMuted),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The switcher entry at the top of the rail on wide screens.
class RailContextButton extends ConsumerWidget {
  const RailContextButton({super.key, required this.extended});

  final bool extended;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (session is! Ready || contextsOf(session.user).length < 2) {
      return const SizedBox.shrink();
    }
    final l = AppLocalizations.of(context);
    final c = HoopsTokens.colorsOf(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: HoopsSpace.md),
      child: Tooltip(
        message: l.switchContext,
        child: InkWell(
          key: const Key('rail-context'),
          borderRadius: BorderRadius.circular(HoopsRadius.md),
          onTap: () => showContextSwitcher(context, ref),
          child: SizedBox(
            width: extended ? 200 : 56,
            height: HoopsSize.minTapTarget,
            child: Row(
              mainAxisAlignment: extended
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                if (extended) const SizedBox(width: HoopsSpace.md),
                Icon(Icons.swap_horiz, color: c.inkMuted),
                if (extended) ...[
                  const SizedBox(width: HoopsSpace.sm),
                  Flexible(
                    child: Text(
                      l.switchContext,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

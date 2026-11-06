import 'package:flutter/material.dart';

import '../design/tokens.dart';

/// One entry of [showActionSheet].
@immutable
class SheetAction<T> {
  const SheetAction({
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final T value;
  final String? subtitle;

  /// Drawn in the danger colour (delete, void, remove).
  final bool destructive;
}

/// Bottom sheet listing [actions]; completes with the chosen value, or null
/// when dismissed. Phones get the actions near the thumb.
Future<T?> showActionSheet<T>(
  BuildContext context, {
  String? title,
  required List<SheetAction<T>> actions,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  builder: (_) => ActionSheetList<T>(title: title, actions: actions),
);

/// The content of [showActionSheet]; pops the route with the chosen value.
class ActionSheetList<T> extends StatelessWidget {
  const ActionSheetList({super.key, this.title, required this.actions});

  final String? title;
  final List<SheetAction<T>> actions;

  @override
  Widget build(BuildContext context) {
    final c = HoopsTokens.colorsOf(context);
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: HoopsSpace.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  HoopsSpace.lg,
                  0,
                  HoopsSpace.lg,
                  HoopsSpace.sm,
                ),
                child: Semantics(
                  header: true,
                  child: Text(title!, style: text.titleLarge),
                ),
              ),
            for (final a in actions)
              _ActionTile(
                key: Key('sheet-action-${a.value}'),
                action: a,
                color: a.destructive ? c.danger.foreground : c.ink,
                onTap: () => Navigator.of(context).pop(a.value),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    super.key,
    required this.action,
    required this.color,
    required this.onTap,
  });

  final SheetAction<Object?> action;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    minTileHeight: HoopsSize.minTapTarget + 8,
    contentPadding: const EdgeInsets.symmetric(horizontal: HoopsSpace.lg),
    shape: const RoundedRectangleBorder(),
    leading: Icon(action.icon, color: color),
    title: Text(
      action.label,
      style: Theme.of(context).textTheme.bodyLarge!
          .copyWith(color: color, fontWeight: FontWeight.w600),
    ),
    subtitle: action.subtitle == null ? null : Text(action.subtitle!),
    onTap: onTap,
  );
}

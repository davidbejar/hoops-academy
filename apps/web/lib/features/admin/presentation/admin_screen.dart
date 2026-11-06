import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/kit.dart';
import '../../../l10n/gen/app_localizations.dart';

/// Admin hub: entry points to every academy-level setting and queue.
/// Loaded through a deferred import (see `app/feature_modules.dart`).
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final entries = [
      (
        Icons.business_outlined,
        l.adminAcademyProfile,
        '/admin/profile',
        'admin-profile',
      ),
      (Icons.badge_outlined, l.adminMembers, '/admin/members', 'admin-members'),
      (Icons.event_outlined, l.adminSeasons, '/admin/seasons', 'admin-seasons'),
      (
        Icons.category_outlined,
        l.adminAgeCategories,
        '/admin/age-categories',
        'admin-categories',
      ),
      (
        Icons.how_to_reg_outlined,
        l.adminApprovals,
        '/players/requests',
        'admin-approvals',
      ),
      (
        Icons.report_problem_outlined,
        l.adminCases,
        '/teams/cases',
        'admin-cases',
      ),
      (Icons.history, l.adminActivity, '/admin/activity', 'admin-activity'),
    ];
    return PageBody(
      key: const Key('admin-hub'),
      header: PageHeader(title: l.adminTitle),
      children: [
        Column(
          spacing: HoopsSpace.gap,
          children: [
            for (final (icon, label, path, key) in entries)
              ListRow(
                key: Key(key),
                leading: _EntryIcon(icon),
                title: label,
                onTap: () => context.go(path),
              ),
          ],
        ),
      ],
    );
  }
}

class _EntryIcon extends StatelessWidget {
  const _EntryIcon(this.icon);
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = HoopsTokens.colorsOf(context).tone(HoopsTone.accent);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.container,
        borderRadius: BorderRadius.circular(HoopsRadius.sm),
      ),
      child: SizedBox.square(
        dimension: HoopsSize.iconTile - 4,
        child: Icon(icon, color: colors.onContainer),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../l10n/gen/app_localizations.dart';

/// Admin hub: entry points to every academy-level setting and queue.
/// Loaded through a deferred import (see `app/feature_modules.dart`).
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final entries = [
      (Icons.business_outlined, l.adminAcademyProfile, '/admin/profile', 'admin-profile'),
      (Icons.badge_outlined, l.adminMembers, '/admin/members', 'admin-members'),
      (Icons.event_outlined, l.adminSeasons, '/admin/seasons', 'admin-seasons'),
      (Icons.category_outlined, l.adminAgeCategories, '/admin/age-categories', 'admin-categories'),
      (Icons.how_to_reg_outlined, l.adminApprovals, '/players/requests', 'admin-approvals'),
      (Icons.report_problem_outlined, l.adminCases, '/teams/cases', 'admin-cases'),
    ];
    return ListView(
      key: const Key('admin-hub'),
      padding: const EdgeInsets.all(AppTokens.spaceMd),
      children: [
        Text(l.adminTitle, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppTokens.spaceMd),
        for (final (icon, label, path, key) in entries)
          Card(
            child: ListTile(
              key: Key(key),
              leading: Icon(icon),
              title: Text(label),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go(path),
            ),
          ),
      ],
    );
  }
}

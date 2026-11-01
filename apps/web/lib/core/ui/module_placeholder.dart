import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../l10n/gen/app_localizations.dart';
import '../navigation/destination_labels.dart';
import '../navigation/destinations.dart';

/// Stand-in body for feature modules that land in WP12–WP14. A feature
/// replaces its placeholder with real screens in its own `presentation/`.
class ModulePlaceholder extends StatelessWidget {
  const ModulePlaceholder({super.key, required this.destination});

  final AppDestination destination;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Center(
      key: Key('module-${destination.name}'),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spaceLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              destination.selectedIcon,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: AppTokens.spaceMd),
            Text(
              l.placeholderModule(destination.label(l)),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:material_ui/material_ui.dart';

import '../../l10n/gen/app_localizations.dart';
import '../navigation/destination_labels.dart';
import '../navigation/destinations.dart';
import 'empty_state.dart';

/// Stand-in body for feature modules that land in WP12–WP14. A feature
/// replaces its placeholder with real screens in its own `presentation/`.
class ModulePlaceholder extends StatelessWidget {
  const ModulePlaceholder({super.key, required this.destination});

  final AppDestination destination;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return EmptyState(
      key: Key('module-${destination.name}'),
      icon: destination.selectedIcon,
      title: l.placeholderModule(destination.label(l)),
    );
  }
}

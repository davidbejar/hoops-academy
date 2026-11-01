import 'package:flutter/widgets.dart';

import '../../../core/navigation/destinations.dart';
import '../../../core/ui/module_placeholder.dart';

/// Placeholder; the real screens arrive with the owning work package.
/// Loaded through a deferred import (see `app/router.dart`).
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const ModulePlaceholder(destination: AppDestination.admin);
}

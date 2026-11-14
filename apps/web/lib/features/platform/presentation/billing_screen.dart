import 'package:material_ui/material_ui.dart';

import '../../../core/ui/kit.dart';
import '../../../l10n/gen/app_localizations.dart';

/// Billing of the application admin: a placeholder until there is something
/// to bill (WP99; no backend call).
class BillingScreen extends StatelessWidget {
  const BillingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SubPage(
      title: l.appAdminBilling,
      parentPath: '/app-admin',
      child: EmptyState(
        key: const Key('billing-soon'),
        icon: Icons.receipt_long_outlined,
        title: l.billingSoonTitle,
        message: l.billingSoonBody,
      ),
    );
  }
}

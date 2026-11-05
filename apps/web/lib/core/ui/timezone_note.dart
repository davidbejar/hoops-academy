import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../features/tenant/application/tenant_providers.dart';
import '../../l10n/gen/app_localizations.dart';

/// "Times are shown in the academy zone", once per screen. Nothing while the
/// academy zone is unknown (the device zone is used then).
class TimezoneNote extends ConsumerWidget {
  const TimezoneNote({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = ref.watch(tenantZoneProvider).label;
    if (label == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.spaceMd),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          AppLocalizations.of(context).timesShownIn(label),
          key: const Key('timezone-note'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/tenant/application/tenant_providers.dart';
import '../session/session.dart';
import '../session/session_providers.dart';

/// The wall clock of the exports (file-name date). Overridden in tests.
final exportClockProvider = Provider<DateTime Function()>((_) => DateTime.now);

/// The active academy's slug for the file name; empty while unknown.
final academySlugProvider = Provider<String>((ref) {
  final session = ref.watch(sessionProvider);
  return session is Ready ? session.membership?.slug ?? '' : '';
});

/// Today's date in the academy's time zone (read at the moment of export).
DateTime exportDay(WidgetRef ref) =>
    ref.read(tenantZoneProvider).today(ref.read(exportClockProvider)());

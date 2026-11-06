import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/http/dio_provider.dart';
import '../../../core/session/session.dart';
import '../../../core/session/session_providers.dart';
import '../../../core/time/tenant_zone.dart';
import '../../admin/application/logo_revision.dart';
import '../data/tenant_repository.dart';
import '../domain/tenant_profile.dart';

final tenantRepositoryProvider = Provider<TenantRepository>(
  (ref) => ApiTenantRepository(ref.watch(dioProvider)),
);

/// Profile of the active academy (null while no tenant is active).
final tenantProfileProvider = FutureProvider<TenantProfile?>((ref) async {
  final tenantId = ref.watch(activeTenantIdProvider);
  if (tenantId == null) return null;
  return ref.watch(tenantRepositoryProvider).profile(tenantId);
});

/// The active academy's time zone, from the current membership in `/me`;
/// the device zone when there is none.
final tenantZoneProvider = Provider<TenantZone>((ref) {
  final session = ref.watch(sessionProvider);
  return TenantZone.of(session is Ready ? session.membership?.timezone : null);
});

/// Logo bytes of the active academy; null when it has none or loading fails
/// (the UI then shows initials).
final tenantLogoProvider = FutureProvider<Uint8List?>((ref) async {
  final tenantId = ref.watch(activeTenantIdProvider);
  if (tenantId == null) return null;
  // After the admin changed the logo (revision > 0) bypass any HTTP cache.
  final revalidate = ref.watch(logoRevisionProvider) > 0;
  try {
    return await ref
        .watch(tenantRepositoryProvider)
        .logo(tenantId, revalidate: revalidate);
  } on Object {
    return null;
  }
});

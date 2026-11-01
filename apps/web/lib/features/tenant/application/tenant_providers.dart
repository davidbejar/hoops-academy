import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/http/dio_provider.dart';
import '../../../core/session/session_providers.dart';
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

/// Logo bytes of the active academy; null when it has none or loading fails
/// (the UI then shows initials).
final tenantLogoProvider = FutureProvider<Uint8List?>((ref) async {
  final tenantId = ref.watch(activeTenantIdProvider);
  if (tenantId == null) return null;
  try {
    return await ref.watch(tenantRepositoryProvider).logo(tenantId);
  } on Object {
    return null;
  }
});

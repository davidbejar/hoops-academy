import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api.dart' as api;

/// Guardians added from a player (`POST /api/core/guardians`) and their logins (core 2.8.0, ADR-0024).
abstract class GuardiansRepository {
  /// A new PARENT member linked to [playerId]. With an [email] a login created by the call comes back with its
  /// temporary password, once; an e-mail that already signs in is linked and comes back without one.
  Future<api.GuardianLinkWithPassword> create({
    required String playerId,
    required String givenName,
    required String familyName,
    String? email,
  });

  /// A guardian's first login (or a new temporary password while pending); 409 `INVITATION_NOT_PENDING`.
  Future<api.MemberWithPassword> issueTemporaryPassword(String personId);
}

class ApiGuardiansRepository implements GuardiansRepository {
  ApiGuardiansRepository(api.HoopsCoreApi client, this._t)
    : _guardians = client.getGuardianLinksApi(),
      _members = client.getMembersApi();

  final api.GuardianLinksApi _guardians;
  final api.MembersApi _members;
  final String _t;

  @override
  Future<api.GuardianLinkWithPassword> create({
    required String playerId,
    required String givenName,
    required String familyName,
    String? email,
  }) async => (await _guardians.createGuardian(
    xTenantId: _t,
    createGuardianRequest: api.CreateGuardianRequest(
      (b) => b
        ..playerId = playerId
        ..givenName = givenName
        ..familyName = familyName
        ..email = email,
    ),
  )).data!;

  @override
  Future<api.MemberWithPassword> issueTemporaryPassword(
    String personId,
  ) async => (await _members.issueMemberTemporaryPassword(
    xTenantId: _t,
    personId: personId,
  )).data!;
}

final guardiansRepositoryProvider = Provider<GuardiansRepository>(
  (ref) => ApiGuardiansRepository(
    ref.watch(api.coreApiProvider),
    ref.watch(api.tenantIdProvider),
  ),
);

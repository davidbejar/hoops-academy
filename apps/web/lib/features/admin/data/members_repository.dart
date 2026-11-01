import '../../../core/api/api.dart' as api;

/// Members and guardian links (`/api/core/members`, `/guardian-links`).
abstract class MembersRepository {
  Future<List<api.Member>> list({String? query, api.TenantRole? role, bool? active});
  Future<api.Member> invite(api.InviteMemberRequest request);
  Future<api.Member> replaceRoles(String personId, Set<api.TenantRole> roles);
  Future<api.Member> deactivate(String personId);

  Future<List<api.GuardianLink>> guardianLinks({String? playerId, String? guardianPersonId});
  Future<api.GuardianLink> addGuardianLink({required String guardianPersonId, required String playerId});
  Future<void> removeGuardianLink(String linkId);
}

class ApiMembersRepository implements MembersRepository {
  ApiMembersRepository(api.HoopsCoreApi client, this._t)
    : _members = client.getMembersApi(),
      _links = client.getGuardianLinksApi();

  final api.MembersApi _members;
  final api.GuardianLinksApi _links;
  final String _t;

  @override
  Future<List<api.Member>> list({String? query, api.TenantRole? role, bool? active}) async =>
      (await _members.listMembers(
        xTenantId: _t,
        q: (query == null || query.trim().isEmpty) ? null : query.trim(),
        role: role,
        active: active,
        size: 100,
      )).data!.items.toList();

  @override
  Future<api.Member> invite(api.InviteMemberRequest request) async =>
      (await _members.inviteMember(xTenantId: _t, inviteMemberRequest: request)).data!;

  @override
  Future<api.Member> replaceRoles(String personId, Set<api.TenantRole> roles) async =>
      (await _members.replaceMemberRoles(
        xTenantId: _t,
        personId: personId,
        replaceMemberRolesRequest: api.ReplaceMemberRolesRequest(
          (b) => b.roles.replace(roles),
        ),
      )).data!;

  @override
  Future<api.Member> deactivate(String personId) async =>
      (await _members.deactivateMember(xTenantId: _t, personId: personId)).data!;

  @override
  Future<List<api.GuardianLink>> guardianLinks({String? playerId, String? guardianPersonId}) async =>
      (await _links.listGuardianLinks(
        xTenantId: _t,
        playerId: playerId,
        guardianPersonId: guardianPersonId,
        size: 100,
      )).data!.items.toList();

  @override
  Future<api.GuardianLink> addGuardianLink({required String guardianPersonId, required String playerId}) async =>
      (await _links.createGuardianLink(
        xTenantId: _t,
        createGuardianLinkRequest: api.CreateGuardianLinkRequest(
          (b) => b
            ..guardianPersonId = guardianPersonId
            ..playerId = playerId,
        ),
      )).data!;

  @override
  Future<void> removeGuardianLink(String linkId) async {
    await _links.deleteGuardianLink(xTenantId: _t, guardianLinkId: linkId);
  }
}

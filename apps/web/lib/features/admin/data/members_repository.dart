import '../../../core/api/api.dart' as api;
import '../../../core/api/clear_list.dart';

/// Members and guardian links (`/api/core/members`, `/guardian-links`).
abstract class MembersRepository {
  Future<List<api.Member>> list({
    String? query,
    api.TenantRole? role,
    bool? active,
  });

  /// A login created by the call comes back with its temporary password, once (ADR-0024).
  Future<api.MemberWithPassword> invite(api.InviteMemberRequest request);

  /// New temporary password for a pending member. 409 `INVITATION_NOT_PENDING` / `LOGIN_SHARED`.
  Future<api.MemberWithPassword> issueTemporaryPassword(String personId);

  Future<api.Member> replaceRoles(String personId, Set<api.TenantRole> roles);
  Future<api.Member> deactivate(String personId);

  /// Edits the personal data. A null [email], [phone], [birthDate] or [gender] empties the field (named in `clear`,
  /// ADR-0032). 409 `EMAIL_TAKEN` / `LOGIN_SHARED`, 422 `LOGIN_REQUIRES_EMAIL` (a member with a login keeps an e-mail).
  Future<api.Member> update(
    String personId, {
    required String givenName,
    required String familyName,
    String? email,
    String? phone,
    api.Date? birthDate,
    api.Gender? gender,
  });

  Future<List<api.GuardianLink>> guardianLinks({
    String? playerId,
    String? guardianPersonId,
  });
  Future<api.GuardianLink> addGuardianLink({
    required String guardianPersonId,
    required String playerId,
  });
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
  Future<List<api.Member>> list({
    String? query,
    api.TenantRole? role,
    bool? active,
  }) async => (await _members.listMembers(
    xTenantId: _t,
    q: (query == null || query.trim().isEmpty) ? null : query.trim(),
    role: role,
    active: active,
    size: 100,
  )).data!.items.toList();

  @override
  Future<api.MemberWithPassword> invite(
    api.InviteMemberRequest request,
  ) async => (await _members.inviteMember(
    xTenantId: _t,
    inviteMemberRequest: request,
  )).data!;

  @override
  Future<api.MemberWithPassword> issueTemporaryPassword(
    String personId,
  ) async => (await _members.issueMemberTemporaryPassword(
    xTenantId: _t,
    personId: personId,
  )).data!;

  @override
  Future<api.Member> replaceRoles(
    String personId,
    Set<api.TenantRole> roles,
  ) async => (await _members.replaceMemberRoles(
    xTenantId: _t,
    personId: personId,
    replaceMemberRolesRequest: api.ReplaceMemberRolesRequest(
      (b) => b.roles.replace(roles),
    ),
  )).data!;

  @override
  Future<api.Member> deactivate(String personId) async =>
      (await _members.deactivateMember(
        xTenantId: _t,
        personId: personId,
      )).data!;

  @override
  Future<api.Member> update(
    String personId, {
    required String givenName,
    required String familyName,
    String? email,
    String? phone,
    api.Date? birthDate,
    api.Gender? gender,
  }) async => (await _members.updateMember(
    xTenantId: _t,
    personId: personId,
    updateMemberRequest: api.UpdateMemberRequest(
      (b) => b
        ..givenName = givenName
        ..familyName = familyName
        ..email = email
        ..phone = phone
        ..birthDate = birthDate
        ..gender = gender
        ..clear = clearList({
          api.UpdateMemberRequestClearEnum.email: email,
          api.UpdateMemberRequestClearEnum.phone: phone,
          api.UpdateMemberRequestClearEnum.birthDate: birthDate,
          api.UpdateMemberRequestClearEnum.gender: gender,
        }),
    ),
  )).data!;

  @override
  Future<List<api.GuardianLink>> guardianLinks({
    String? playerId,
    String? guardianPersonId,
  }) async => (await _links.listGuardianLinks(
    xTenantId: _t,
    playerId: playerId,
    guardianPersonId: guardianPersonId,
    size: 100,
  )).data!.items.toList();

  @override
  Future<api.GuardianLink> addGuardianLink({
    required String guardianPersonId,
    required String playerId,
  }) async => (await _links.createGuardianLink(
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

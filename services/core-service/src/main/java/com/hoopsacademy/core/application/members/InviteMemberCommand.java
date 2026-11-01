package com.hoopsacademy.core.application.members;

import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.core.domain.membership.PersonalData;
import java.util.Set;

/** Invite a member; with {@code sendInvitation} a login is provisioned (requires an e-mail). */
public record InviteMemberCommand(PersonalData data, Set<TenantRole> roles, boolean sendInvitation) {}

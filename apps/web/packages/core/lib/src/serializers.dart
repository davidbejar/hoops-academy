//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_import

import 'package:one_of_serializer/any_of_serializer.dart';
import 'package:one_of_serializer/one_of_serializer.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';
import 'package:built_value/standard_json_plugin.dart';
import 'package:built_value/iso_8601_date_time_serializer.dart';
import 'package:hoops_core_api/src/date_serializer.dart';
import 'package:hoops_core_api/src/model/date.dart';

import 'package:hoops_core_api/src/model/add_tenant_admin_request.dart';
import 'package:hoops_core_api/src/model/age_category.dart';
import 'package:hoops_core_api/src/model/age_category_input.dart';
import 'package:hoops_core_api/src/model/age_rule.dart';
import 'package:hoops_core_api/src/model/approval_action.dart';
import 'package:hoops_core_api/src/model/approval_decision_request.dart';
import 'package:hoops_core_api/src/model/approval_payload.dart';
import 'package:hoops_core_api/src/model/approval_request.dart';
import 'package:hoops_core_api/src/model/approval_request_page.dart';
import 'package:hoops_core_api/src/model/approval_status.dart';
import 'package:hoops_core_api/src/model/assign_player_request.dart';
import 'package:hoops_core_api/src/model/authz_context.dart';
import 'package:hoops_core_api/src/model/authz_summary.dart';
import 'package:hoops_core_api/src/model/create_guardian_link_request.dart';
import 'package:hoops_core_api/src/model/create_player_request.dart';
import 'package:hoops_core_api/src/model/create_team_request.dart';
import 'package:hoops_core_api/src/model/create_tenant_request.dart';
import 'package:hoops_core_api/src/model/eligibility_case.dart';
import 'package:hoops_core_api/src/model/eligibility_case_page.dart';
import 'package:hoops_core_api/src/model/eligibility_case_resolution.dart';
import 'package:hoops_core_api/src/model/eligibility_case_status.dart';
import 'package:hoops_core_api/src/model/eligibility_check.dart';
import 'package:hoops_core_api/src/model/eligibility_reason.dart';
import 'package:hoops_core_api/src/model/eligibility_result.dart';
import 'package:hoops_core_api/src/model/eligible_team.dart';
import 'package:hoops_core_api/src/model/first_admin.dart';
import 'package:hoops_core_api/src/model/gender.dart';
import 'package:hoops_core_api/src/model/gender_policy.dart';
import 'package:hoops_core_api/src/model/guardian_link.dart';
import 'package:hoops_core_api/src/model/guardian_link_page.dart';
import 'package:hoops_core_api/src/model/invitation_status.dart';
import 'package:hoops_core_api/src/model/invite_member_request.dart';
import 'package:hoops_core_api/src/model/locale.dart';
import 'package:hoops_core_api/src/model/me.dart';
import 'package:hoops_core_api/src/model/member.dart';
import 'package:hoops_core_api/src/model/member_page.dart';
import 'package:hoops_core_api/src/model/membership.dart';
import 'package:hoops_core_api/src/model/orphan.dart';
import 'package:hoops_core_api/src/model/page_meta.dart';
import 'package:hoops_core_api/src/model/person_ref.dart';
import 'package:hoops_core_api/src/model/personal_data.dart';
import 'package:hoops_core_api/src/model/player.dart';
import 'package:hoops_core_api/src/model/player_batch_request.dart';
import 'package:hoops_core_api/src/model/player_batch_response.dart';
import 'package:hoops_core_api/src/model/player_brief.dart';
import 'package:hoops_core_api/src/model/player_command_result.dart';
import 'package:hoops_core_api/src/model/player_page.dart';
import 'package:hoops_core_api/src/model/player_ref.dart';
import 'package:hoops_core_api/src/model/player_status.dart';
import 'package:hoops_core_api/src/model/player_team_assignment.dart';
import 'package:hoops_core_api/src/model/problem.dart';
import 'package:hoops_core_api/src/model/problem_violation.dart';
import 'package:hoops_core_api/src/model/reject_approval_request.dart';
import 'package:hoops_core_api/src/model/replace_member_roles_request.dart';
import 'package:hoops_core_api/src/model/resolve_eligibility_case_request.dart';
import 'package:hoops_core_api/src/model/roster_player.dart';
import 'package:hoops_core_api/src/model/roster_staff.dart';
import 'package:hoops_core_api/src/model/season.dart';
import 'package:hoops_core_api/src/model/season_input.dart';
import 'package:hoops_core_api/src/model/season_rollover_request.dart';
import 'package:hoops_core_api/src/model/season_rollover_result.dart';
import 'package:hoops_core_api/src/model/staff_role.dart';
import 'package:hoops_core_api/src/model/team.dart';
import 'package:hoops_core_api/src/model/team_page.dart';
import 'package:hoops_core_api/src/model/team_player.dart';
import 'package:hoops_core_api/src/model/team_ref.dart';
import 'package:hoops_core_api/src/model/team_roster.dart';
import 'package:hoops_core_api/src/model/team_staff_assignment.dart';
import 'package:hoops_core_api/src/model/team_staff_member.dart';
import 'package:hoops_core_api/src/model/tenant.dart';
import 'package:hoops_core_api/src/model/tenant_admin.dart';
import 'package:hoops_core_api/src/model/tenant_admin_page.dart';
import 'package:hoops_core_api/src/model/tenant_lifecycle_request.dart';
import 'package:hoops_core_api/src/model/tenant_logo.dart';
import 'package:hoops_core_api/src/model/tenant_page.dart';
import 'package:hoops_core_api/src/model/tenant_profile.dart';
import 'package:hoops_core_api/src/model/tenant_role.dart';
import 'package:hoops_core_api/src/model/tenant_settings.dart';
import 'package:hoops_core_api/src/model/tenant_status.dart';
import 'package:hoops_core_api/src/model/tenant_summary.dart';
import 'package:hoops_core_api/src/model/tenant_usage.dart';
import 'package:hoops_core_api/src/model/tenant_usage_history.dart';
import 'package:hoops_core_api/src/model/tenant_usage_snapshot.dart';
import 'package:hoops_core_api/src/model/update_age_category_request.dart';
import 'package:hoops_core_api/src/model/update_me_request.dart';
import 'package:hoops_core_api/src/model/update_member_request.dart';
import 'package:hoops_core_api/src/model/update_season_request.dart';
import 'package:hoops_core_api/src/model/update_team_player_request.dart';
import 'package:hoops_core_api/src/model/update_team_request.dart';
import 'package:hoops_core_api/src/model/update_tenant_admin_request.dart';
import 'package:hoops_core_api/src/model/update_tenant_profile_request.dart';
import 'package:hoops_core_api/src/model/update_tenant_request.dart';
import 'package:hoops_core_api/src/model/usage_report.dart';
import 'package:hoops_core_api/src/model/withdraw_player_request.dart';

part 'serializers.g.dart';

@SerializersFor([
  AddTenantAdminRequest,
  AgeCategory,
  AgeCategoryInput,$AgeCategoryInput,
  AgeRule,
  ApprovalAction,
  ApprovalDecisionRequest,
  ApprovalPayload,
  ApprovalRequest,
  ApprovalRequestPage,
  ApprovalStatus,
  AssignPlayerRequest,
  AuthzContext,
  AuthzSummary,
  CreateGuardianLinkRequest,
  CreatePlayerRequest,
  CreateTeamRequest,
  CreateTenantRequest,
  EligibilityCase,
  EligibilityCasePage,
  EligibilityCaseResolution,
  EligibilityCaseStatus,
  EligibilityCheck,
  EligibilityReason,
  EligibilityResult,
  EligibleTeam,
  FirstAdmin,
  Gender,
  GenderPolicy,
  GuardianLink,
  GuardianLinkPage,
  InvitationStatus,
  InviteMemberRequest,
  Locale,
  Me,
  Member,
  MemberPage,
  Membership,
  Orphan,
  PageMeta,
  PersonRef,
  PersonalData,$PersonalData,
  Player,
  PlayerBatchRequest,
  PlayerBatchResponse,
  PlayerBrief,
  PlayerCommandResult,
  PlayerPage,
  PlayerRef,
  PlayerStatus,
  PlayerTeamAssignment,
  Problem,
  ProblemViolation,
  RejectApprovalRequest,
  ReplaceMemberRolesRequest,
  ResolveEligibilityCaseRequest,
  RosterPlayer,
  RosterStaff,
  Season,
  SeasonInput,$SeasonInput,
  SeasonRolloverRequest,
  SeasonRolloverResult,
  StaffRole,
  Team,
  TeamPage,
  TeamPlayer,
  TeamRef,
  TeamRoster,
  TeamStaffAssignment,
  TeamStaffMember,
  Tenant,
  TenantAdmin,
  TenantAdminPage,
  TenantLifecycleRequest,
  TenantLogo,
  TenantPage,
  TenantProfile,
  TenantRole,
  TenantSettings,
  TenantStatus,
  TenantSummary,
  TenantUsage,
  TenantUsageHistory,
  TenantUsageSnapshot,
  UpdateAgeCategoryRequest,
  UpdateMeRequest,
  UpdateMemberRequest,
  UpdateSeasonRequest,
  UpdateTeamPlayerRequest,
  UpdateTeamRequest,
  UpdateTenantAdminRequest,
  UpdateTenantProfileRequest,
  UpdateTenantRequest,
  UsageReport,
  WithdrawPlayerRequest,
])
Serializers serializers = (_$serializers.toBuilder()
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(Season)]),
        () => ListBuilder<Season>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(EligibilityReason)]),
        () => ListBuilder<EligibilityReason>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(TeamRef)]),
        () => ListBuilder<TeamRef>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(TeamPlayer)]),
        () => ListBuilder<TeamPlayer>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(Orphan)]),
        () => ListBuilder<Orphan>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(RosterPlayer)]),
        () => ListBuilder<RosterPlayer>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(RosterStaff)]),
        () => ListBuilder<RosterStaff>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(TeamStaffMember)]),
        () => ListBuilder<TeamStaffMember>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(EligibleTeam)]),
        () => ListBuilder<EligibleTeam>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(PlayerBrief)]),
        () => ListBuilder<PlayerBrief>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(GuardianLink)]),
        () => ListBuilder<GuardianLink>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(UsageReport)]),
        () => ListBuilder<UsageReport>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltMap, [FullType(String), FullType(int)]),
        () => MapBuilder<String, int>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(EligibilityCase)]),
        () => ListBuilder<EligibilityCase>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(TenantUsageSnapshot)]),
        () => ListBuilder<TenantUsageSnapshot>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(AgeCategory)]),
        () => ListBuilder<AgeCategory>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(TenantAdmin)]),
        () => ListBuilder<TenantAdmin>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(Membership)]),
        () => ListBuilder<Membership>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(ApprovalRequest)]),
        () => ListBuilder<ApprovalRequest>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltSet, [FullType(String)]),
        () => SetBuilder<String>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(PlayerTeamAssignment)]),
        () => ListBuilder<PlayerTeamAssignment>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(ProblemViolation)]),
        () => ListBuilder<ProblemViolation>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltSet, [FullType(TenantRole)]),
        () => SetBuilder<TenantRole>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(Team)]),
        () => ListBuilder<Team>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(Tenant)]),
        () => ListBuilder<Tenant>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(Member)]),
        () => ListBuilder<Member>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(Player)]),
        () => ListBuilder<Player>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(String)]),
        () => ListBuilder<String>(),
      )
      ..add(AgeCategoryInput.serializer)
      ..add(PersonalData.serializer)
      ..add(SeasonInput.serializer)
      ..add(const OneOfSerializer())
      ..add(const AnyOfSerializer())
      ..add(const DateSerializer())
      ..add(Iso8601DateTimeSerializer())
    ).build();

Serializers standardSerializers =
    (serializers.toBuilder()..addPlugin(StandardJsonPlugin())).build();

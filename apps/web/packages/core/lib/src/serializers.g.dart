// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'serializers.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializers _$serializers = (Serializers().toBuilder()
      ..add($AgeCategoryInput.serializer)
      ..add($ApprovalRequest.serializer)
      ..add($Member.serializer)
      ..add($PersonalData.serializer)
      ..add($SeasonInput.serializer)
      ..add($Tenant.serializer)
      ..add($TenantAdmin.serializer)
      ..add(AddTenantAdminRequest.serializer)
      ..add(AgeCategory.serializer)
      ..add(AgeRule.serializer)
      ..add(ApprovalAction.serializer)
      ..add(ApprovalDecisionRequest.serializer)
      ..add(ApprovalPayload.serializer)
      ..add(ApprovalRequestPage.serializer)
      ..add(ApprovalRequestWithPassword.serializer)
      ..add(ApprovalStatus.serializer)
      ..add(AssignPlayerRequest.serializer)
      ..add(AuthzContext.serializer)
      ..add(AuthzSummary.serializer)
      ..add(CreateGuardianLinkRequest.serializer)
      ..add(CreatePlayerRequest.serializer)
      ..add(CreateTeamRequest.serializer)
      ..add(CreateTenantRequest.serializer)
      ..add(EligibilityCase.serializer)
      ..add(EligibilityCasePage.serializer)
      ..add(EligibilityCaseResolution.serializer)
      ..add(EligibilityCaseStatus.serializer)
      ..add(EligibilityCheck.serializer)
      ..add(EligibilityReason.serializer)
      ..add(EligibilityResult.serializer)
      ..add(EligibleTeam.serializer)
      ..add(FirstAdmin.serializer)
      ..add(Gender.serializer)
      ..add(GenderPolicy.serializer)
      ..add(GuardianLink.serializer)
      ..add(GuardianLinkPage.serializer)
      ..add(InvitationStatus.serializer)
      ..add(InviteMemberRequest.serializer)
      ..add(Locale.serializer)
      ..add(Me.serializer)
      ..add(MemberPage.serializer)
      ..add(MemberWithPassword.serializer)
      ..add(Membership.serializer)
      ..add(Orphan.serializer)
      ..add(PageMeta.serializer)
      ..add(PersonRef.serializer)
      ..add(Player.serializer)
      ..add(PlayerBatchRequest.serializer)
      ..add(PlayerBatchResponse.serializer)
      ..add(PlayerBrief.serializer)
      ..add(PlayerCommandResult.serializer)
      ..add(PlayerPage.serializer)
      ..add(PlayerRef.serializer)
      ..add(PlayerStatus.serializer)
      ..add(PlayerTeamAssignment.serializer)
      ..add(Problem.serializer)
      ..add(ProblemViolation.serializer)
      ..add(RejectApprovalRequest.serializer)
      ..add(ReplaceMemberRolesRequest.serializer)
      ..add(ResolveEligibilityCaseRequest.serializer)
      ..add(RosterPlayer.serializer)
      ..add(RosterStaff.serializer)
      ..add(Season.serializer)
      ..add(SeasonRolloverRequest.serializer)
      ..add(SeasonRolloverResult.serializer)
      ..add(StaffRole.serializer)
      ..add(Team.serializer)
      ..add(TeamPage.serializer)
      ..add(TeamPlayer.serializer)
      ..add(TeamRef.serializer)
      ..add(TeamRoster.serializer)
      ..add(TeamStaffAssignment.serializer)
      ..add(TeamStaffMember.serializer)
      ..add(TenantAdminPage.serializer)
      ..add(TenantAdminWithPassword.serializer)
      ..add(TenantLifecycleRequest.serializer)
      ..add(TenantLogo.serializer)
      ..add(TenantLogoContentTypeEnum.serializer)
      ..add(TenantPage.serializer)
      ..add(TenantProfile.serializer)
      ..add(TenantRole.serializer)
      ..add(TenantSettings.serializer)
      ..add(TenantStatus.serializer)
      ..add(TenantSummary.serializer)
      ..add(TenantUsage.serializer)
      ..add(TenantUsageHistory.serializer)
      ..add(TenantUsageSnapshot.serializer)
      ..add(TenantUsageSnapshotUnavailableServicesEnum.serializer)
      ..add(TenantUsageUnavailableServicesEnum.serializer)
      ..add(TenantWithPassword.serializer)
      ..add(UpdateAgeCategoryRequest.serializer)
      ..add(UpdateMeRequest.serializer)
      ..add(UpdateMemberRequest.serializer)
      ..add(UpdateSeasonRequest.serializer)
      ..add(UpdateTeamPlayerRequest.serializer)
      ..add(UpdateTeamRequest.serializer)
      ..add(UpdateTenantAdminRequest.serializer)
      ..add(UpdateTenantProfileRequest.serializer)
      ..add(UpdateTenantRequest.serializer)
      ..add(UsageReport.serializer)
      ..add(UsageReportServiceEnum.serializer)
      ..add(WithdrawPlayerRequest.serializer)
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(ApprovalRequest)]),
          () => ListBuilder<ApprovalRequest>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(EligibilityCase)]),
          () => ListBuilder<EligibilityCase>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(EligibilityReason)]),
          () => ListBuilder<EligibilityReason>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(EligibilityReason)]),
          () => ListBuilder<EligibilityReason>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(GuardianLink)]),
          () => ListBuilder<GuardianLink>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(Member)]),
          () => ListBuilder<Member>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(Membership)]),
          () => ListBuilder<Membership>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(Player)]),
          () => ListBuilder<Player>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(PlayerBrief)]),
          () => ListBuilder<PlayerBrief>())
      ..addBuilderFactory(
          const FullType(
              BuiltList, const [const FullType(PlayerTeamAssignment)]),
          () => ListBuilder<PlayerTeamAssignment>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(ProblemViolation)]),
          () => ListBuilder<ProblemViolation>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(RosterPlayer)]),
          () => ListBuilder<RosterPlayer>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(RosterStaff)]),
          () => ListBuilder<RosterStaff>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(String)]),
          () => ListBuilder<String>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(String)]),
          () => ListBuilder<String>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(String)]),
          () => ListBuilder<String>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(Team)]),
          () => ListBuilder<Team>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(TeamRef)]),
          () => ListBuilder<TeamRef>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(Orphan)]),
          () => ListBuilder<Orphan>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(String)]),
          () => ListBuilder<String>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(Tenant)]),
          () => ListBuilder<Tenant>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(TenantAdmin)]),
          () => ListBuilder<TenantAdmin>())
      ..addBuilderFactory(
          const FullType(
              BuiltList, const [const FullType(TenantUsageSnapshot)]),
          () => ListBuilder<TenantUsageSnapshot>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(UsageReport)]),
          () => ListBuilder<UsageReport>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [
            const FullType(TenantUsageSnapshotUnavailableServicesEnum)
          ]),
          () => ListBuilder<TenantUsageSnapshotUnavailableServicesEnum>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(UsageReport)]),
          () => ListBuilder<UsageReport>())
      ..addBuilderFactory(
          const FullType(BuiltList,
              const [const FullType(TenantUsageUnavailableServicesEnum)]),
          () => ListBuilder<TenantUsageUnavailableServicesEnum>())
      ..addBuilderFactory(
          const FullType(
              BuiltMap, const [const FullType(String), const FullType(int)]),
          () => MapBuilder<String, int>())
      ..addBuilderFactory(
          const FullType(BuiltSet, const [const FullType(String)]),
          () => SetBuilder<String>())
      ..addBuilderFactory(
          const FullType(BuiltSet, const [const FullType(TenantRole)]),
          () => SetBuilder<TenantRole>())
      ..addBuilderFactory(
          const FullType(BuiltSet, const [const FullType(TenantRole)]),
          () => SetBuilder<TenantRole>())
      ..addBuilderFactory(
          const FullType(BuiltSet, const [const FullType(TenantRole)]),
          () => SetBuilder<TenantRole>())
      ..addBuilderFactory(
          const FullType(BuiltSet, const [const FullType(TenantRole)]),
          () => SetBuilder<TenantRole>())
      ..addBuilderFactory(
          const FullType(BuiltSet, const [const FullType(TenantRole)]),
          () => SetBuilder<TenantRole>())
      ..addBuilderFactory(
          const FullType(BuiltSet, const [const FullType(TenantRole)]),
          () => SetBuilder<TenantRole>())
      ..addBuilderFactory(
          const FullType(BuiltSet, const [const FullType(TenantRole)]),
          () => SetBuilder<TenantRole>())
      ..addBuilderFactory(
          const FullType(BuiltSet, const [const FullType(TenantRole)]),
          () => SetBuilder<TenantRole>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(String)]),
          () => ListBuilder<String>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(String)]),
          () => ListBuilder<String>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(String)]),
          () => ListBuilder<String>()))
    .build();

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

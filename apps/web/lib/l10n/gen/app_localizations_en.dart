// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Hoops Academy';

  @override
  String get loading => 'Loading…';

  @override
  String get retry => 'Retry';

  @override
  String get signIn => 'Sign in';

  @override
  String get signInSubtitle => 'Sign in with your academy account';

  @override
  String get signOut => 'Sign out';

  @override
  String signedInAs(String name) {
    return 'Signed in as $name';
  }

  @override
  String get offlineBanner => 'You are offline. Data may be out of date.';

  @override
  String get mockModeBanner => 'Demo mode: sample data, no server';

  @override
  String get navAdmin => 'Admin';

  @override
  String get navTeams => 'Teams';

  @override
  String get navMatches => 'Matches';

  @override
  String get navTraining => 'Training';

  @override
  String get navPlayers => 'Players';

  @override
  String get navMyPlayers => 'My players';

  @override
  String get navMe => 'Me';

  @override
  String get navPlatform => 'Platform';

  @override
  String placeholderModule(String module) {
    return '$module: coming soon';
  }

  @override
  String get profileTitle => 'Profile';

  @override
  String get language => 'Language';

  @override
  String get languageName_es => 'Español';

  @override
  String get languageName_en => 'English';

  @override
  String get languageName_id => 'Bahasa Indonesia';

  @override
  String get academy => 'Academy';

  @override
  String get switchAcademy => 'Switch academy';

  @override
  String get chooseAcademyTitle => 'Choose your academy';

  @override
  String get chooseAcademySubtitle =>
      'You belong to several academies. Which one do you want to work with?';

  @override
  String rolesInAcademy(String roles) {
    return 'Roles: $roles';
  }

  @override
  String get roleAdmin => 'Administrator';

  @override
  String get roleCoach => 'Coach';

  @override
  String get roleAssistantCoach => 'Assistant coach';

  @override
  String get roleParent => 'Parent';

  @override
  String get rolePlayer => 'Player';

  @override
  String get noAccessTitle => 'No access to any academy';

  @override
  String get noAccessBody =>
      'Your account does not belong to any academy yet. Ask an administrator to invite you.';

  @override
  String get profileLoadFailed => 'We could not load your profile';

  @override
  String get errorNetwork =>
      'Cannot reach the server. Check your connection and try again.';

  @override
  String get errorTimeout =>
      'The server is taking too long to respond. Try again.';

  @override
  String get errorUnauthorized =>
      'Your session has expired. Please sign in again.';

  @override
  String get errorForbidden => 'You are not allowed to do this.';

  @override
  String get errorNotFound => 'We could not find what you are looking for.';

  @override
  String get errorConflict => 'The data has changed. Refresh and try again.';

  @override
  String get errorValidation => 'Please check the data you entered.';

  @override
  String get errorServer => 'The server had a problem. Please try again later.';

  @override
  String get errorUnknown => 'An unexpected error occurred.';

  @override
  String errorReference(String traceId) {
    return 'Reference: $traceId';
  }

  @override
  String get emptyTitle => 'Nothing here yet';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get add => 'Add';

  @override
  String get create => 'Create';

  @override
  String get confirm => 'Confirm';

  @override
  String get close => 'Close';

  @override
  String get remove => 'Remove';

  @override
  String get search => 'Search';

  @override
  String get all => 'All';

  @override
  String get none => 'None';

  @override
  String get saved => 'Changes saved';

  @override
  String get fieldRequired => 'Required field';

  @override
  String get fieldInvalidNumber => 'Enter a valid number';

  @override
  String get fieldInvalidEmail => 'Enter a valid email';

  @override
  String get noResults => 'No results';

  @override
  String get noteOptional => 'Note (optional)';

  @override
  String get noteRequired => 'Note (required)';

  @override
  String get readOnlyHint => 'Read-only: you are not allowed to change this.';

  @override
  String get moreActions => 'More actions';

  @override
  String get adminTitle => 'Administration';

  @override
  String get adminAcademyProfile => 'Academy profile';

  @override
  String get adminMembers => 'Members';

  @override
  String get adminSeasons => 'Seasons';

  @override
  String get adminAgeCategories => 'Age categories';

  @override
  String get adminApprovals => 'Pending requests';

  @override
  String get adminCases => 'Eligibility cases';

  @override
  String get academyName => 'Academy name';

  @override
  String get academyTimezone => 'Time zone (e.g. Europe/Madrid)';

  @override
  String get academyAgeRule => 'Age rule';

  @override
  String get ageRuleBirthYear => 'By birth year';

  @override
  String get ageRuleBirthday => 'By birthday';

  @override
  String get academyMaxPlayUp => 'Maximum play-up levels';

  @override
  String get academyDefaultLocale => 'Default language';

  @override
  String get logoTitle => 'Logo';

  @override
  String get logoHint => 'PNG, JPEG or WebP, 512 KB at most';

  @override
  String get logoChoose => 'Choose image';

  @override
  String get logoUpload => 'Upload logo';

  @override
  String get logoRemove => 'Remove logo';

  @override
  String get logoRemoveConfirm => 'Remove the academy logo?';

  @override
  String get logoPreview => 'Preview';

  @override
  String get logoNone => 'No logo';

  @override
  String get logoUploaded => 'Logo updated';

  @override
  String get logoRemoved => 'Logo removed';

  @override
  String get logoErrorTooLarge => 'The image is larger than 512 KB.';

  @override
  String get logoErrorWrongType => 'Invalid format: use PNG, JPEG or WebP.';

  @override
  String get logoErrorEmpty => 'The file is empty.';

  @override
  String get membersSearchHint => 'Search by name or email';

  @override
  String get membersEmpty => 'No members yet';

  @override
  String get memberInvite => 'Invite';

  @override
  String get memberInviteTitle => 'Invite a member';

  @override
  String get memberGivenName => 'First name';

  @override
  String get memberFamilyName => 'Last name';

  @override
  String get memberEmail => 'Email';

  @override
  String get memberRoles => 'Roles';

  @override
  String get memberRolesRequired => 'Pick at least one role';

  @override
  String get memberInvited => 'Invitation sent';

  @override
  String get memberEditRoles => 'Edit roles';

  @override
  String get memberDeactivate => 'Deactivate';

  @override
  String memberDeactivateConfirm(String name) {
    return 'Deactivate $name? They will lose access to the academy.';
  }

  @override
  String get memberDeactivated => 'Member deactivated';

  @override
  String get memberInactive => 'Inactive';

  @override
  String get memberInvitationPending => 'Invitation pending';

  @override
  String get memberGuardianLinks => 'Linked players';

  @override
  String get memberGuardianNone => 'No linked players';

  @override
  String get memberGuardianAdd => 'Link player';

  @override
  String memberGuardianRemoveConfirm(String name) {
    return 'Remove the link to $name?';
  }

  @override
  String get memberGuardianOnlyParents =>
      'Links can only be edited for members with the Parent role.';

  @override
  String get seasonsEmpty => 'No seasons yet';

  @override
  String get seasonNew => 'New season';

  @override
  String get seasonEdit => 'Edit season';

  @override
  String get seasonName => 'Name';

  @override
  String get seasonStarts => 'Starts';

  @override
  String get seasonEnds => 'Ends';

  @override
  String get seasonReferenceYear => 'Reference year (birth-year rule)';

  @override
  String get seasonCurrent => 'Current';

  @override
  String get seasonDatesInvalid => 'The end date must be after the start date';

  @override
  String get seasonRollover => 'Roll over';

  @override
  String get rolloverTitle => 'Season rollover';

  @override
  String rolloverIntro(String name) {
    return 'The next season will be created from $name: teams are copied and players are re-checked.';
  }

  @override
  String get rolloverCloneStaff => 'Copy team staff';

  @override
  String get rolloverClonePlayers => 'Copy rosters';

  @override
  String get rolloverConfirm => 'Run rollover';

  @override
  String get rolloverDone => 'Rollover completed';

  @override
  String rolloverClonedTeams(String count) {
    return 'Teams copied: $count';
  }

  @override
  String get rolloverOrphansTitle => 'Players without a valid team';

  @override
  String get rolloverNoOrphans => 'All players remain eligible.';

  @override
  String rolloverOrphanLine(String player, String team) {
    return '$player (was: $team)';
  }

  @override
  String get rolloverGoToCases => 'Go to eligibility cases';

  @override
  String rolloverCasesOpened(String count) {
    return 'Cases opened: $count';
  }

  @override
  String get categoryNew => 'New category';

  @override
  String get categoryEdit => 'Edit category';

  @override
  String get categoriesEmpty => 'No categories yet';

  @override
  String get categoryCode => 'Code';

  @override
  String get categoryName => 'Name';

  @override
  String get categoryMaxAge => 'Maximum age (empty = no limit)';

  @override
  String get categoryRank => 'Order';

  @override
  String get categoryNoLimit => 'No age limit';

  @override
  String categoryUpTo(String age) {
    return 'Up to $age years';
  }

  @override
  String categoryDeleteConfirm(String name) {
    return 'Delete the category $name?';
  }

  @override
  String get teamsEmpty => 'No teams in this season';

  @override
  String get teamsNoSeason => 'Create a season first';

  @override
  String get teamsSeason => 'Season';

  @override
  String get teamNew => 'New team';

  @override
  String get teamEdit => 'Edit team';

  @override
  String get teamName => 'Name';

  @override
  String get teamAlias => 'Alias (optional)';

  @override
  String get teamCategory => 'Category';

  @override
  String get teamGenderPolicy => 'Gender policy';

  @override
  String get genderPolicyMale => 'Male';

  @override
  String get genderPolicyFemale => 'Female';

  @override
  String get genderPolicyMixed => 'Mixed';

  @override
  String teamPlayerCount(String count) {
    return '$count players';
  }

  @override
  String get teamStaff => 'Staff';

  @override
  String get teamStaffAdd => 'Add staff member';

  @override
  String get teamStaffNone => 'No staff';

  @override
  String teamStaffRemoveConfirm(String name) {
    return 'Remove $name from the team?';
  }

  @override
  String get teamStaffPick => 'Person';

  @override
  String get teamStaffRole => 'Function';

  @override
  String get teamRoster => 'Roster';

  @override
  String get teamRosterEmpty => 'The roster is empty';

  @override
  String get rosterAssign => 'Assign player';

  @override
  String get rosterSearchPlayer => 'Search player';

  @override
  String get rosterUnassign => 'Remove from roster';

  @override
  String rosterUnassignConfirm(String name) {
    return 'Remove $name from the roster?';
  }

  @override
  String get rosterJersey => 'Jersey number';

  @override
  String get rosterJerseyEdit => 'Change jersey number';

  @override
  String get rosterAssigned => 'Player assigned';

  @override
  String get rosterInvalid => 'No longer eligible';

  @override
  String get rosterEligibilityPending => 'Checking eligibility…';

  @override
  String get eligibilityEligible => 'Eligible';

  @override
  String eligibilityPlayUp(String levels) {
    return 'Plays up (+$levels)';
  }

  @override
  String get eligibilityIneligible => 'Not eligible';

  @override
  String playUpBadge(String levels) {
    return '+$levels';
  }

  @override
  String get reasonCategoryTooLow => 'Too old for this category';

  @override
  String get reasonPlayUpLimit => 'Exceeds the maximum play-up levels';

  @override
  String get reasonGenderPolicy => 'Does not meet the team gender policy';

  @override
  String get reasonMissingBirthDate => 'Birth date is missing';

  @override
  String get reasonMissingGender => 'Gender is missing';

  @override
  String get reasonPlayerNotActive => 'The player is not active';

  @override
  String get playersSearchHint => 'Search players';

  @override
  String get playersEmpty => 'No players match these filters';

  @override
  String get filterStatus => 'Status';

  @override
  String get filterTeam => 'Team';

  @override
  String get filterCategory => 'Category';

  @override
  String get filterClear => 'Clear filters';

  @override
  String get statusActive => 'Active';

  @override
  String get statusOrphan => 'Orphan';

  @override
  String get statusPendingApproval => 'Pending approval';

  @override
  String get statusWithdrawn => 'Withdrawn';

  @override
  String get playerNew => 'New player';

  @override
  String get playerNewRequest => 'Request new player';

  @override
  String get playerGivenName => 'First name';

  @override
  String get playerFamilyName => 'Last name';

  @override
  String get playerBirthDate => 'Birth date';

  @override
  String get playerBirthDateInvalid => 'Invalid birth date';

  @override
  String get playerGender => 'Gender';

  @override
  String get genderMale => 'Male';

  @override
  String get genderFemale => 'Female';

  @override
  String get playerEmail => 'Email (optional)';

  @override
  String get playerInitialTeam => 'Initial team (optional)';

  @override
  String get playerNote => 'Note for the administrator (optional)';

  @override
  String get playerCreated => 'Player created';

  @override
  String get playerRequestSent => 'Request sent to the administrator';

  @override
  String get playerBasics => 'Basic data';

  @override
  String get playerNaturalCategory => 'Natural category';

  @override
  String get playerGuardians => 'Guardians';

  @override
  String get playerNoGuardians => 'No linked guardians';

  @override
  String get playerTeams => 'Teams';

  @override
  String get playerNoTeams => 'No team';

  @override
  String get playerAssignToTeam => 'Assign to a team';

  @override
  String get playerNoEligibleTeams => 'No eligible teams this season';

  @override
  String get playerWithdraw => 'Withdraw';

  @override
  String playerWithdrawConfirm(String name) {
    return 'Withdraw $name?';
  }

  @override
  String get playerWithdrawReason => 'Reason (optional)';

  @override
  String get playerWithdrawn => 'Player withdrawn';

  @override
  String get playerWithdrawRequested => 'Withdrawal request sent';

  @override
  String get approvalsTitle => 'Requests';

  @override
  String get approvalsMine => 'My requests';

  @override
  String get approvalsEmpty => 'No requests';

  @override
  String get approvalActionAdd => 'Add player';

  @override
  String get approvalActionWithdraw => 'Withdraw player';

  @override
  String get approvalStatusPending => 'Pending';

  @override
  String get approvalStatusApproved => 'Approved';

  @override
  String get approvalStatusRejected => 'Rejected';

  @override
  String get approvalStatusCancelled => 'Cancelled';

  @override
  String approvalRequestedBy(String name) {
    return 'Requested by $name';
  }

  @override
  String get approvalApprove => 'Approve';

  @override
  String get approvalReject => 'Reject';

  @override
  String get approvalCancel => 'Cancel request';

  @override
  String get approvalCancelConfirm => 'Cancel this request?';

  @override
  String approvalDecisionNote(String note) {
    return 'Decision note: $note';
  }

  @override
  String get approvalApproved => 'Request approved';

  @override
  String get approvalRejected => 'Request rejected';

  @override
  String get approvalCancelled => 'Request cancelled';

  @override
  String get casesEmpty => 'No open cases';

  @override
  String caseTeam(String team) {
    return 'Invalidated team: $team';
  }

  @override
  String get caseReassign => 'Reassign';

  @override
  String caseReassignTitle(String player) {
    return 'Reassign $player';
  }

  @override
  String get caseRemoveFromTeam => 'Remove from team';

  @override
  String get caseDismiss => 'Dismiss case';

  @override
  String get caseResolved => 'Case resolved';

  @override
  String get casePickTeam => 'Pick the new team';

  @override
  String get back => 'Back';
}

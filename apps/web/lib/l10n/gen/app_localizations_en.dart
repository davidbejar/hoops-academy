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
  String get notMemberTitle => 'You are not a member of an academy yet';

  @override
  String notMemberBody(String email) {
    return 'You are not a member of an academy yet. Ask an academy administrator to add you with this e-mail: $email';
  }

  @override
  String get notMemberBodyNoEmail =>
      'You are not a member of an academy yet. Ask an academy administrator to add you with the e-mail you signed in with.';

  @override
  String timesShownIn(String zone) {
    return 'Times are shown in the academy\'s time zone: $zone';
  }

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
  String get statusRejected => 'Rejected';

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

  @override
  String get matchListEmpty => 'No matches yet';

  @override
  String get matchAllTeams => 'All teams';

  @override
  String get matchTeam => 'Team';

  @override
  String get matchStatusScheduled => 'Scheduled';

  @override
  String get matchStatusLive => 'Live';

  @override
  String get matchStatusFinished => 'Finished';

  @override
  String get matchStatusCancelled => 'Cancelled';

  @override
  String matchVs(String opponent) {
    return 'vs $opponent';
  }

  @override
  String get matchHome => 'Home';

  @override
  String get matchAway => 'Away';

  @override
  String get matchUs => 'Us';

  @override
  String get matchCachedData => 'Offline: data saved on this device';

  @override
  String get matchNew => 'New match';

  @override
  String get matchOpponent => 'Opponent';

  @override
  String get matchDate => 'Date';

  @override
  String get matchCreated => 'Match created';

  @override
  String get matchSetup => 'Match roster';

  @override
  String get matchSetupHint => 'Pick players, starters and jersey numbers';

  @override
  String get matchStarter => 'Starter';

  @override
  String get matchJersey => 'Jersey';

  @override
  String get matchSetupSaved => 'Roster saved';

  @override
  String get matchSetupNoPlayers => 'The team has no players';

  @override
  String get matchSetupNeedStarter => 'Mark at least one starter';

  @override
  String matchSetupSummary(int selected, int starters) {
    return '$selected selected · $starters starters';
  }

  @override
  String get matchSetupAction => 'Set up roster';

  @override
  String get matchNoRoster => 'This match has no roster yet';

  @override
  String get matchTabCourt => 'Court';

  @override
  String get matchTabLog => 'Plays';

  @override
  String get matchTabBox => 'Box score';

  @override
  String matchPeriodShort(int period) {
    return 'Q$period';
  }

  @override
  String matchOvertimeShort(int number) {
    return 'OT$number';
  }

  @override
  String get matchBeforeStart => 'Not started';

  @override
  String matchStartPeriod(String period) {
    return 'Start $period';
  }

  @override
  String matchEndPeriod(String period) {
    return 'End $period';
  }

  @override
  String get matchClockStart => 'Start the clock';

  @override
  String get matchClockPause => 'Stop the clock';

  @override
  String get matchClockMinus => 'Minus 10 seconds';

  @override
  String get matchClockPlus => 'Plus 10 seconds';

  @override
  String get matchOnCourt => 'On court';

  @override
  String get matchBench => 'Bench';

  @override
  String matchOpponentPoints(int points) {
    return 'Opp +$points';
  }

  @override
  String get matchTimeoutOwn => 'Timeout';

  @override
  String get matchTimeoutOpponent => 'Opponent timeout';

  @override
  String get matchUndo => 'Undo';

  @override
  String get matchUndone => 'Last play voided';

  @override
  String get matchNothingToUndo => 'Nothing to undo';

  @override
  String matchSubFor(String name) {
    return '$name comes in for…';
  }

  @override
  String matchStatsFor(String name) {
    return 'Stat for $name';
  }

  @override
  String matchRecorded(String action, String name) {
    return '$action · $name';
  }

  @override
  String get matchAction2ptMade => '2 PT ✓';

  @override
  String get matchAction2ptMissed => '2 PT ✗';

  @override
  String get matchAction3ptMade => '3 PT ✓';

  @override
  String get matchAction3ptMissed => '3 PT ✗';

  @override
  String get matchActionFtMade => 'FT ✓';

  @override
  String get matchActionFtMissed => 'FT ✗';

  @override
  String get matchActionAssist => 'Assist';

  @override
  String get matchActionOreb => 'Off. rebound';

  @override
  String get matchActionDreb => 'Def. rebound';

  @override
  String get matchActionSteal => 'Steal';

  @override
  String get matchActionBlock => 'Block';

  @override
  String get matchActionTurnover => 'Turnover';

  @override
  String get matchActionFoulPersonal => 'Personal foul';

  @override
  String get matchActionFoulTechnical => 'Technical foul';

  @override
  String get matchActionFoulUnsportsmanlike => 'Unsportsmanlike';

  @override
  String matchEvPeriodStart(String period) {
    return '$period starts';
  }

  @override
  String matchEvPeriodEnd(String period) {
    return '$period ends';
  }

  @override
  String matchEvSubIn(String name) {
    return '$name in';
  }

  @override
  String matchEvSubOut(String name) {
    return '$name out';
  }

  @override
  String matchEvVoid(String target) {
    return 'Voids: $target';
  }

  @override
  String get matchEvVoidUnknown => 'Voids a play';

  @override
  String matchEvNote(String text) {
    return 'Note: $text';
  }

  @override
  String get matchSyncPending => 'Pending';

  @override
  String get matchSyncSent => 'Sending';

  @override
  String get matchSyncDone => 'Synced';

  @override
  String matchSyncRejected(String reason) {
    return 'Rejected: $reason';
  }

  @override
  String get matchVoided => 'Voided';

  @override
  String matchRecordedBy(String name) {
    return 'by $name';
  }

  @override
  String get matchReasonSchema => 'invalid data';

  @override
  String get matchReasonNotAuthorized => 'not allowed';

  @override
  String get matchReasonCancelled => 'match cancelled';

  @override
  String get matchReasonSeqConflict => 'sequence conflict';

  @override
  String get matchReasonOther => 'rejected by the server';

  @override
  String get matchVoidEvent => 'Void';

  @override
  String get matchVoidConfirm => 'Void this play? A VOID event is recorded.';

  @override
  String get matchDiscard => 'Discard';

  @override
  String get matchDiscardConfirm =>
      'Discard this rejected play? It will not be sent again.';

  @override
  String matchUnsynced(int count) {
    return '$count unsynced';
  }

  @override
  String matchRejectedCount(int count) {
    return '$count rejected';
  }

  @override
  String get matchSyncPausedAuth => 'Sign in again to sync; your data is kept';

  @override
  String get matchSyncing => 'Syncing…';

  @override
  String get matchParentMode => 'Family mode: your players only';

  @override
  String get matchReadOnly => 'Read only';

  @override
  String get matchStart => 'Start match';

  @override
  String get matchFinish => 'Finish match';

  @override
  String get matchFinishConfirm =>
      'Finish the match? Corrections stay possible.';

  @override
  String get matchColMin => 'MIN';

  @override
  String get matchColPts => 'PTS';

  @override
  String get matchColReb => 'REB';

  @override
  String get matchColAst => 'AST';

  @override
  String get matchColStl => 'STL';

  @override
  String get matchColBlk => 'BLK';

  @override
  String get matchColTov => 'TOV';

  @override
  String get matchColPf => 'PF';

  @override
  String get matchColFg => 'FG';

  @override
  String get matchCol3p => '3P';

  @override
  String get matchColFt => 'FT';

  @override
  String get matchTotals => 'Team totals';

  @override
  String get matchPeriodScores => 'By period';

  @override
  String matchWarnings(int count) {
    return '$count consistency warnings (fix with Void)';
  }

  @override
  String get matchCopy => 'Copy result';

  @override
  String get matchCopied => 'Result copied';

  @override
  String matchShareLine(String name, int points, int rebounds, int assists) {
    return '$name: $points pts, $rebounds reb, $assists ast';
  }

  @override
  String get seasonStatsTitle => 'Season statistics';

  @override
  String seasonStatsGames(int played, int started) {
    return '$played games · $started started';
  }

  @override
  String get seasonStatsAverages => 'Per-game averages';

  @override
  String get seasonStatsTotals => 'Totals';

  @override
  String get seasonStatsMatches => 'Matches';

  @override
  String get seasonStatsEmpty => 'No matches this season';

  @override
  String get seasonStatsPoints => 'Points';

  @override
  String get seasonStatsRebounds => 'Rebounds';

  @override
  String get seasonStatsAssists => 'Assists';

  @override
  String get seasonStatsMinutes => 'Minutes';

  @override
  String get seasonStatsSeason => 'Season';

  @override
  String get trainingTitle => 'Training';

  @override
  String trainingWeekOf(String range) {
    return 'Week of $range';
  }

  @override
  String get trainingToday => 'Today';

  @override
  String get trainingPrevWeek => 'Previous week';

  @override
  String get trainingNextWeek => 'Next week';

  @override
  String get trainingAllTeams => 'All teams';

  @override
  String get trainingNoSessions => 'No training sessions this week';

  @override
  String get trainingNoSessionsDay => 'No sessions';

  @override
  String get trainingMenuPlans => 'Plans';

  @override
  String get trainingMenuSchedules => 'Schedules';

  @override
  String get trainingMenuAbsences => 'Absences';

  @override
  String get trainingMenuAssignments => 'Assignments';

  @override
  String get sessionStatusPlanned => 'Planned';

  @override
  String get sessionStatusDone => 'Done';

  @override
  String get sessionStatusCancelled => 'Cancelled';

  @override
  String get sessionDetailTitle => 'Training session';

  @override
  String sessionTimeRange(String end, String start) {
    return '$start – $end';
  }

  @override
  String get sessionLocation => 'Location';

  @override
  String get sessionNoLocation => 'No location';

  @override
  String get sessionPlan => 'Plan';

  @override
  String get sessionNoPlan => 'No plan attached';

  @override
  String get sessionEdit => 'Edit session';

  @override
  String get sessionUpdated => 'Session updated';

  @override
  String get sessionNotes => 'Notes';

  @override
  String sessionCancelReasonLine(String reason) {
    return 'Cancelled: $reason';
  }

  @override
  String get sessionNew => 'New session';

  @override
  String get sessionTeam => 'Team';

  @override
  String get sessionDate => 'Date';

  @override
  String get sessionStartTime => 'Start time';

  @override
  String get sessionDuration => 'Duration (min)';

  @override
  String sessionDurationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get sessionCancel => 'Cancel session';

  @override
  String get sessionCancelReason => 'Reason for cancelling';

  @override
  String get sessionCreated => 'Session created';

  @override
  String get sessionCancelled => 'Session cancelled';

  @override
  String get attendanceTitle => 'Attendance';

  @override
  String get attendancePresent => 'Present';

  @override
  String get attendanceLate => 'Late';

  @override
  String get attendanceAbsent => 'Absent';

  @override
  String get attendanceExcused => 'Excused';

  @override
  String get attendanceMinutesLate => 'Minutes late';

  @override
  String get attendanceExpectedAbsent => 'Planned absence';

  @override
  String get attendanceInjured => 'Injured';

  @override
  String get attendanceNotRecorded => 'Not recorded';

  @override
  String get attendanceSave => 'Save attendance';

  @override
  String get attendanceSaved => 'Attendance saved';

  @override
  String get attendanceEmpty => 'The team has no players';

  @override
  String get attendanceMinutesInvalid => 'Minutes between 1 and 180';

  @override
  String get scheduleTitle => 'Training schedules';

  @override
  String get scheduleNew => 'New schedule';

  @override
  String get scheduleEdit => 'Edit schedule';

  @override
  String get scheduleEmpty => 'No schedules yet';

  @override
  String get scheduleDay => 'Weekday';

  @override
  String get scheduleTime => 'Time (HH:MM)';

  @override
  String get scheduleTimeInvalid => 'Use the HH:MM format';

  @override
  String get scheduleValidFrom => 'Valid from';

  @override
  String get scheduleValidUntil => 'Valid until';

  @override
  String get scheduleNoEnd => 'No end date';

  @override
  String get scheduleDatesInvalid =>
      'The end date must not be before the start';

  @override
  String scheduleLine(String day, int minutes, String time) {
    return '$day $time · $minutes min';
  }

  @override
  String scheduleValidity(String from) {
    return 'From $from';
  }

  @override
  String scheduleValidityRange(String from, String to) {
    return '$from to $to';
  }

  @override
  String get scheduleDeleteConfirm =>
      'Delete this schedule? Future unchanged sessions will be removed.';

  @override
  String get dayMonday => 'Monday';

  @override
  String get dayTuesday => 'Tuesday';

  @override
  String get dayWednesday => 'Wednesday';

  @override
  String get dayThursday => 'Thursday';

  @override
  String get dayFriday => 'Friday';

  @override
  String get daySaturday => 'Saturday';

  @override
  String get daySunday => 'Sunday';

  @override
  String get absenceTitle => 'Planned absences';

  @override
  String get absenceNew => 'New absence';

  @override
  String get absencePlayer => 'Player';

  @override
  String get absenceFrom => 'From';

  @override
  String get absenceTo => 'To';

  @override
  String get absenceReason => 'Reason (optional)';

  @override
  String get absenceEmpty => 'No planned absences';

  @override
  String get absenceDatesInvalid => 'The end date cannot be before the start';

  @override
  String get absenceDeleteConfirm => 'Delete this absence?';

  @override
  String absenceRange(String from, String to) {
    return '$from → $to';
  }

  @override
  String get absenceSaved => 'Absence saved';

  @override
  String get planLibraryTitle => 'Training plans';

  @override
  String get planTemplates => 'Templates';

  @override
  String get planMine => 'Our plans';

  @override
  String get planSearchHint => 'Search plans';

  @override
  String get planEmptyTemplates => 'No templates';

  @override
  String get planEmptyMine => 'No plans yet. Create one or use a template.';

  @override
  String planSummary(int count, int minutes) {
    return '$count exercises · $minutes min';
  }

  @override
  String get planNew => 'New plan';

  @override
  String get planName => 'Plan name';

  @override
  String get planDescription => 'Description (optional)';

  @override
  String get planUse => 'Use template';

  @override
  String get planCopied => 'Template copied to your plans';

  @override
  String get planTemplateReadOnly => 'Read-only template: copy it to edit.';

  @override
  String get planItems => 'Exercises';

  @override
  String get planNoItems => 'This plan has no exercises yet';

  @override
  String get planItemAdd => 'Add exercise';

  @override
  String get planItemEdit => 'Edit exercise';

  @override
  String get planItemTitle => 'Title';

  @override
  String get planItemDuration => 'Duration (min)';

  @override
  String get planItemSets => 'Sets';

  @override
  String get planItemReps => 'Reps';

  @override
  String get planItemVideo => 'Video link (https)';

  @override
  String get planItemVideoInvalid => 'Must start with https://';

  @override
  String planItemSetsReps(int reps, int sets) {
    return '$sets × $reps';
  }

  @override
  String get planItemMoveUp => 'Move up';

  @override
  String get planItemMoveDown => 'Move down';

  @override
  String get planItemDeleteConfirm => 'Remove this exercise?';

  @override
  String get planDeleteConfirm => 'Delete this plan?';

  @override
  String get planAssign => 'Assign';

  @override
  String get planWatchVideo => 'Watch video';

  @override
  String get assignTitle => 'Assign plan';

  @override
  String get assignTarget => 'Assign to';

  @override
  String get assignToTeam => 'A team';

  @override
  String get assignToPlayer => 'A player';

  @override
  String get assignDue => 'Due date';

  @override
  String get assignDone => 'Plan assigned';

  @override
  String get assignmentsTitle => 'Assigned plans';

  @override
  String get assignmentsEmpty => 'No assigned plans';

  @override
  String assignmentDue(String date) {
    return 'Due $date';
  }

  @override
  String assignmentProgress(int done, int notDone, int partial) {
    return '$done done · $partial partial · $notDone not done';
  }

  @override
  String get assignmentDeleteConfirm =>
      'Remove this assignment and its completions?';

  @override
  String get assignmentProgressTitle => 'Progress';

  @override
  String assignmentTeamTarget(String name) {
    return 'Team: $name';
  }

  @override
  String get assignmentPlayerTarget => 'Player';

  @override
  String get completionDone => 'Done';

  @override
  String get completionPartial => 'Partial';

  @override
  String get completionNotDone => 'Not done';

  @override
  String get completionNone => 'Not marked';

  @override
  String get completionComment => 'Comment (optional)';

  @override
  String get completionMark => 'Mark';

  @override
  String get completionSaved => 'Marked';

  @override
  String get healthTitle => 'Health and fitness';

  @override
  String get healthInjuries => 'Injuries';

  @override
  String get healthGrowth => 'Growth';

  @override
  String get healthTests => 'Physical tests';

  @override
  String get injuryNew => 'Record injury';

  @override
  String get injuryBodyPart => 'Body part';

  @override
  String get injurySeverity => 'Severity';

  @override
  String get severityMinor => 'Minor';

  @override
  String get severityModerate => 'Moderate';

  @override
  String get severitySevere => 'Severe';

  @override
  String get injuryOccurredOn => 'Injury date';

  @override
  String get injuryExpectedReturn => 'Expected return';

  @override
  String get injuryDescription => 'Description (optional)';

  @override
  String get injuryStatusOpen => 'Open';

  @override
  String get injuryStatusRecovered => 'Recovered';

  @override
  String get injuryRecover => 'Mark recovered';

  @override
  String get injuryRecoveredOn => 'Return date';

  @override
  String get injuryUpdateReturn => 'Change expected return';

  @override
  String get injuryEmpty => 'No injuries recorded';

  @override
  String injuryReturnLine(String date) {
    return 'Expected return: $date';
  }

  @override
  String injuryRecoveredLine(String date) {
    return 'Recovered on $date';
  }

  @override
  String get injurySaved => 'Injury saved';

  @override
  String get availabilityAvailable => 'Available';

  @override
  String availabilityInjured(String bodyPart) {
    return 'Injured: $bodyPart';
  }

  @override
  String get growthHeight => 'Height (cm)';

  @override
  String get growthWeight => 'Weight (kg)';

  @override
  String get growthAdd => 'Add measurement';

  @override
  String get growthMeasuredOn => 'Measurement date';

  @override
  String get growthEmpty => 'No measurements yet';

  @override
  String get growthNeedOne => 'Enter height, weight or both';

  @override
  String get growthShowTable => 'Show table';

  @override
  String get growthHideTable => 'Hide table';

  @override
  String get growthDeleteConfirm => 'Delete this measurement?';

  @override
  String chartSummary(int count, String name, String value) {
    return 'Chart of $name: $count points, latest $value';
  }

  @override
  String get chartNoData => 'No data for the chart';

  @override
  String get chartDate => 'Date';

  @override
  String get chartValue => 'Value';

  @override
  String get testAdd => 'Record result';

  @override
  String get testType => 'Test';

  @override
  String get testValue => 'Value';

  @override
  String get testNotes => 'Notes (optional)';

  @override
  String get testMeasuredOn => 'Test date';

  @override
  String get bandPoor => 'Poor';

  @override
  String get bandBelowAverage => 'Below average';

  @override
  String get bandAverage => 'Average';

  @override
  String get bandAboveAverage => 'Above average';

  @override
  String get bandExcellent => 'Excellent';

  @override
  String testExpectedBand(String band) {
    return 'Expected band: $band';
  }

  @override
  String get testNoBand => 'No norm for this age and gender';

  @override
  String get testReferencePending => 'Reference pending';

  @override
  String testSavedBand(String band) {
    return 'Result saved. Band: $band';
  }

  @override
  String get testSavedNoBand => 'Result saved (no applicable norm)';

  @override
  String get testEmpty => 'No test results yet';

  @override
  String get testChartLegend => 'Expected bands';

  @override
  String testAtAge(int age) {
    return 'age $age';
  }

  @override
  String testResultLine(String unit, String value) {
    return '$value $unit';
  }

  @override
  String get testDeleteConfirm => 'Delete this result?';

  @override
  String get testTypesTitle => 'Test types';

  @override
  String get testTypeNew => 'New custom test';

  @override
  String get testTypeCode => 'Code';

  @override
  String get testTypeName => 'Name';

  @override
  String get testTypeUnit => 'Unit';

  @override
  String get testTypeHigher => 'Higher is better';

  @override
  String get testTypeGlobal => 'Global';

  @override
  String get testTypeCustom => 'Academy';

  @override
  String get testTypesEmpty => 'No test types';

  @override
  String get testTypeHigherYes => 'Higher is better';

  @override
  String get testTypeHigherNo => 'Lower is better';

  @override
  String get normsTitle => 'Reference norms';

  @override
  String get normsScopeEffective => 'Effective';

  @override
  String get normsScopeGlobal => 'Global';

  @override
  String get normsScopeTenant => 'Academy';

  @override
  String get normNew => 'New norm';

  @override
  String get normEdit => 'Edit norm';

  @override
  String get normGender => 'Gender';

  @override
  String get normMinAge => 'Minimum age';

  @override
  String get normMaxAge => 'Maximum age';

  @override
  String get normBand => 'Band';

  @override
  String get normMinValue => 'Minimum value';

  @override
  String get normMaxValue => 'Maximum value';

  @override
  String get normSource => 'Source';

  @override
  String normAges(int max, int min) {
    return 'ages $min–$max';
  }

  @override
  String normValues(String low, String high) {
    return '$low to $high';
  }

  @override
  String normValuesFrom(String low) {
    return 'from $low';
  }

  @override
  String normValuesUpTo(String high) {
    return 'up to $high';
  }

  @override
  String get normGlobalReadOnly => 'Global (read only)';

  @override
  String get normOverride => 'Academy override';

  @override
  String get normEmpty => 'No norms for this filter';

  @override
  String get normDeleteConfirm => 'Delete this norm?';

  @override
  String get normAgesInvalid => 'Maximum age must be at least the minimum';

  @override
  String get normAllTests => 'All tests';

  @override
  String get healthMenuTests => 'Test types';

  @override
  String get healthMenuNorms => 'Norms';

  @override
  String get meTitle => 'My sports profile';

  @override
  String get meSeasonStats => 'Season statistics';

  @override
  String get meUpcoming => 'Upcoming training';

  @override
  String get meNoUpcoming => 'No upcoming training';

  @override
  String get meTabTraining => 'Training';

  @override
  String get meTabPlans => 'Plans';

  @override
  String get meNoPlayer => 'Your account is not linked to a player yet';

  @override
  String get myPlayersTitle => 'My players';

  @override
  String get myPlayersEmpty => 'You have no linked players';

  @override
  String get profilePlatform => 'Platform console';

  @override
  String get mePlansEmpty => 'No assigned plans';

  @override
  String get platformTitle => 'Platform';

  @override
  String get platformSearchHint => 'Search by name or slug';

  @override
  String get platformEmpty => 'No academies match';

  @override
  String get platformNew => 'New academy';

  @override
  String get tenantName => 'Academy name';

  @override
  String get tenantSlug => 'Identifier (slug)';

  @override
  String get tenantSlugInvalid =>
      'Lowercase letters, numbers and hyphens (3-50)';

  @override
  String get tenantTimezone => 'Time zone';

  @override
  String get tenantLocale => 'Language';

  @override
  String get tenantAdminEmail => 'First admin email';

  @override
  String get tenantAdminGivenName => 'Admin first name';

  @override
  String get tenantAdminFamilyName => 'Admin last name';

  @override
  String get tenantStatusActive => 'Active';

  @override
  String get tenantStatusSuspended => 'Suspended';

  @override
  String get tenantStatusWithdrawn => 'Withdrawn';

  @override
  String get tenantCreated => 'Academy created';

  @override
  String get tenantSuspend => 'Suspend';

  @override
  String get tenantWithdraw => 'Withdraw';

  @override
  String get tenantReactivate => 'Reactivate';

  @override
  String get tenantReason => 'Reason';

  @override
  String get tenantSuspendTitle => 'Suspend the academy';

  @override
  String get tenantWithdrawTitle => 'Withdraw the academy';

  @override
  String get tenantWithdrawWarning =>
      'Withdrawing an academy starts its data retention period.';

  @override
  String get tenantUpdated => 'Status updated';

  @override
  String tenantCreatedOn(String date) {
    return 'Created $date';
  }

  @override
  String tenantRetainUntil(String date) {
    return 'Data retained until $date';
  }

  @override
  String get usageTitle => 'Usage';

  @override
  String usageUnavailable(String services) {
    return 'No data from: $services';
  }

  @override
  String usageLastActivity(String date) {
    return 'Last activity: $date';
  }

  @override
  String get usageTrendTitle => 'Usage trend';

  @override
  String get usageTrendEmpty => 'No usage snapshots yet';

  @override
  String get usageFailed => 'Usage could not be loaded';

  @override
  String get usageServiceCore => 'Core';

  @override
  String get usageServiceGame => 'Matches';

  @override
  String get usageServiceAthlete => 'Athletes';

  @override
  String get usageCounter_members => 'Members';

  @override
  String get usageCounter_players => 'Players';

  @override
  String get usageCounter_activePlayers => 'Active players';

  @override
  String get usageCounter_teams => 'Teams';

  @override
  String get usageCounter_seasons => 'Seasons';

  @override
  String get usageCounter_matches => 'Matches';

  @override
  String get usageCounter_liveMatches => 'Live matches';

  @override
  String get usageCounter_matchEvents => 'Match events';

  @override
  String get usageCounter_matchEventsLast30Days => 'Events (30 days)';

  @override
  String get usageCounter_trainingSessions => 'Training sessions';

  @override
  String get usageCounter_attendanceRecords => 'Attendance records';

  @override
  String get usageCounter_trainingPlans => 'Plans';

  @override
  String get usageCounter_physicalTestResults => 'Test results';

  @override
  String get usageCounter_injuries => 'Injuries';

  @override
  String get usageCounter_bodyMeasurements => 'Body measurements';

  @override
  String get signOutUnsyncedTitle => 'Events not synced yet';

  @override
  String signOutUnsyncedBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count match events are',
      one: '1 match event is',
    );
    return '$_temp0 not synced from this device. Signing out now discards them for good. Connect and wait for the sync, or sign out and discard them.';
  }

  @override
  String get signOutAnyway => 'Sign out and discard';

  @override
  String get updateAvailable => 'A new version is available';

  @override
  String get updateReload => 'Reload';

  @override
  String get adminsTitle => 'Administrators';

  @override
  String get adminsAdd => 'Add administrator';

  @override
  String get adminsEmpty => 'This academy has no active administrators';

  @override
  String get adminsLoadFailed => 'The administrators could not be loaded';

  @override
  String get adminInvitationAccepted => 'Invitation accepted';

  @override
  String adminOtherRoles(String roles) {
    return 'Also: $roles';
  }

  @override
  String get adminEdit => 'Edit administrator';

  @override
  String get adminRemove => 'Remove administrator';

  @override
  String get adminAddHint =>
      'If an active member already has this email, they become an administrator and keep their name. Otherwise their login is created and you will see a temporary password to give them; no email is sent.';

  @override
  String get adminAddSubmit => 'Add';

  @override
  String get adminEditEmailNote =>
      'The email is also the person\'s login: if you change it, they sign in with the new address and keep their password.';

  @override
  String adminRemoveConfirm(String name) {
    return 'Remove $name as administrator? This removes the Administrator role; other roles stay.';
  }

  @override
  String get adminRemoveSubmit => 'Remove';

  @override
  String get adminLastAdminNote =>
      'An academy needs at least one administrator. Add another administrator first.';

  @override
  String get adminAdded => 'Administrator added';

  @override
  String get adminUpdated => 'Administrator updated';

  @override
  String get adminRemoved => 'Administrator removed';

  @override
  String get adminsWithdrawn =>
      'This academy is withdrawn: its administrators can no longer be viewed or changed.';

  @override
  String get adminErrorEmailTaken =>
      'That email is already used by another person or account';

  @override
  String get adminErrorLoginAlreadyMember =>
      'That login already belongs to another member of this academy';

  @override
  String get adminErrorIdentityProvider =>
      'The sign-in service is unavailable. Try again in a few minutes.';

  @override
  String get adminErrorInvitationNotPending =>
      'The invitation is no longer pending';

  @override
  String get tempPasswordTitle => 'Temporary password';

  @override
  String tempPasswordFor(String person) {
    return 'Account of $person';
  }

  @override
  String tempPasswordLoginWith(String email) {
    return 'Sign-in email: $email';
  }

  @override
  String get tempPasswordShareHint =>
      'Give it to the person through a private channel. No email is sent.';

  @override
  String get tempPasswordShownOnce =>
      'Shown only now: it is not stored and cannot be viewed again. If it is lost, generate a new one while the person has not signed in yet.';

  @override
  String get tempPasswordFirstSignIn =>
      'At the first sign-in they use their email and this password, and must choose their own.';

  @override
  String get tempPasswordCopy => 'Copy password';

  @override
  String get tempPasswordCopied => 'Password copied';

  @override
  String get tempPasswordDone => 'Done';

  @override
  String get tempPasswordExistingLogin =>
      'They already had an account: they sign in with their current password.';

  @override
  String get tempPasswordIssue => 'Generate a new temporary password';

  @override
  String get tempPasswordExpired => 'Temporary password expired';

  @override
  String get memberAdded => 'Member added';

  @override
  String get memberInviteHint =>
      'No email is sent: when the login is created you will see a temporary password to give to the person.';

  @override
  String get memberErrorNotPending =>
      'This person has already signed in or the invitation is no longer pending';

  @override
  String get memberErrorLoginShared =>
      'This login is also used in another academy: only the platform administration can generate its password';

  @override
  String get playerEmailHint =>
      'With an email the player gets access: you will see a temporary password to give to them.';

  @override
  String get adminActivity => 'Activity';

  @override
  String get platformActivity => 'Academies\' activity';

  @override
  String get auditTitle => 'Activity';

  @override
  String get auditAnyTime => 'Any time';

  @override
  String get auditClearRange => 'Clear dates';

  @override
  String get auditAllActions => 'All actions';

  @override
  String auditSelectedActions(int count) {
    return '$count actions';
  }

  @override
  String get auditFilterTitle => 'Filter by action';

  @override
  String get auditApply => 'Apply';

  @override
  String get auditEmpty => 'No activity for this filter';

  @override
  String auditPageOf(int page, int pages) {
    return 'Page $page of $pages';
  }

  @override
  String get auditPreviousPage => 'Previous page';

  @override
  String get auditNextPage => 'Next page';

  @override
  String auditByActor(String actor) {
    return 'By $actor';
  }

  @override
  String get auditActorSystem => 'System';

  @override
  String get auditActorPlatform => 'Platform administration';

  @override
  String get auditActorMember => 'Academy member';

  @override
  String get auditTargetPerson => 'Person';

  @override
  String get auditTargetPlayer => 'Player';

  @override
  String get auditTargetTenant => 'Academy';

  @override
  String get auditTargetApprovalRequest => 'Request';

  @override
  String get auditTargetGuardianLink => 'Guardian link';

  @override
  String get auditActionAdminAdded => 'Administrator added';

  @override
  String get auditActionAdminRemoved => 'Administrator removed';

  @override
  String get auditActionAdminTemporaryPasswordIssued =>
      'Administrator temporary password issued';

  @override
  String get auditActionAdminUpdated => 'Administrator edited';

  @override
  String get auditActionApprovalCancelled => 'Request cancelled';

  @override
  String get auditActionGuardianLinkCreated => 'Guardian link created';

  @override
  String get auditActionGuardianLinkRemoved => 'Guardian link removed';

  @override
  String get auditActionMemberDeactivated => 'Member deactivated';

  @override
  String get auditActionMemberInvitationAccepted => 'First sign-in';

  @override
  String get auditActionMemberInvited => 'Member invited';

  @override
  String get auditActionMemberLoginEmailChanged => 'Sign-in e-mail changed';

  @override
  String get auditActionMemberRolesReplaced => 'Roles changed';

  @override
  String get auditActionMemberTemporaryPasswordExpired =>
      'Temporary password expired';

  @override
  String get auditActionMemberTemporaryPasswordIssued =>
      'Temporary password issued';

  @override
  String get auditActionMemberUpdated => 'Member edited';

  @override
  String get auditActionPlayerApproved => 'Player approved';

  @override
  String get auditActionPlayerRejected => 'Player rejected';

  @override
  String get auditActionPlayerRequested => 'Player requested';

  @override
  String get auditActionPlayerWithdrawn => 'Player withdrawn';

  @override
  String get auditActionTenantCreated => 'Academy created';

  @override
  String get auditActionTenantLogoRemoved => 'Logo removed';

  @override
  String get auditActionTenantLogoReplaced => 'Logo replaced';

  @override
  String get auditActionTenantMasterDataChanged =>
      'Academy master data changed';

  @override
  String get auditActionTenantProfileChanged => 'Academy profile changed';

  @override
  String get auditActionTenantReactivated => 'Academy reactivated';

  @override
  String get auditActionTenantSettingsChanged => 'Settings changed';

  @override
  String get auditActionTenantSuspended => 'Academy suspended';

  @override
  String get auditActionTenantWithdrawn => 'Academy withdrawn';
}

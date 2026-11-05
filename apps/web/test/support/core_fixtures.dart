import 'package:built_collection/built_collection.dart';
import 'package:hoops_app/core/api/api.dart' as api;

const catU12Id = 'cat-u12';
const catU14Id = 'cat-u14';
const seasonId = 'season-2026';
const pastSeasonId = 'season-2025';

api.AgeCategory category(String id, String code, int rank, {int? maxAge}) => api.AgeCategory(
  (b) => b
    ..id = id
    ..code = code
    ..name = code == 'U12' ? 'Mini' : 'Infantil'
    ..rank = rank
    ..maxAge = maxAge,
);

final u12 = category(catU12Id, 'U12', 1, maxAge: 12);
final u14 = category(catU14Id, 'U14', 2, maxAge: 14);

api.Season season(String id, String name, {bool current = false}) => api.Season(
  (b) => b
    ..id = id
    ..name = name
    ..startsOn = api.Date(2026, 9, 1)
    ..endsOn = api.Date(2027, 6, 30)
    ..referenceYear = 2026
    ..current = current,
);

api.Team team(
  String id,
  String name, {
  String? alias,
  api.AgeCategory? cat,
  api.GenderPolicy policy = api.GenderPolicy.MIXED,
  int players = 0,
  String sid = seasonId,
}) => api.Team(
  (b) => b
    ..id = id
    ..seasonId = sid
    ..name = name
    ..alias = alias
    ..ageCategory.replace(cat ?? u12)
    ..genderPolicy = policy
    ..playerCount = players,
);

api.PlayerRef playerRef(String id, String name) => api.PlayerRef((b) => b
  ..id = id
  ..displayName = name);
api.TeamRef teamRef(String id, String name) => api.TeamRef((b) => b
  ..id = id
  ..name = name);
api.PersonRef personRef(String id, String name) => api.PersonRef((b) => b
  ..personId = id
  ..displayName = name);

api.Player player(
  String id,
  String name, {
  api.PlayerStatus status = api.PlayerStatus.ACTIVE,
  api.AgeCategory? cat,
  List<api.PlayerTeamAssignment> teams = const [],
  api.Gender gender = api.Gender.MALE,
}) => api.Player(
  (b) => b
    ..id = id
    ..personId = 'person-$id'
    ..givenName = name.split(' ').first
    ..familyName = name.split(' ').last
    ..displayName = name
    ..birthDate = api.Date(2015, 3, 4)
    ..gender = gender
    ..status = status
    ..naturalCategory = cat?.toBuilder()
    ..teams.replace(teams)
    ..createdAt = DateTime.utc(2026, 1, 1),
);

api.PlayerTeamAssignment assignment(String teamId, String name, {String? jersey, int playUp = 0, bool valid = true}) =>
    api.PlayerTeamAssignment(
      (b) => b
        ..team.replace(teamRef(teamId, name))
        ..jerseyNumber = jersey
        ..playUpLevels = playUp
        ..valid = valid,
    );

api.TeamPlayer teamPlayer(String teamId, String pid, String name, {String? jersey, int playUp = 0, bool invalid = false}) =>
    api.TeamPlayer(
      (b) => b
        ..player.replace(playerRef(pid, name))
        ..teamId = teamId
        ..jerseyNumber = jersey
        ..joinedOn = api.Date(2026, 9, 1)
        ..playUpLevels = playUp
        ..invalidatedAt = invalid ? DateTime.utc(2026, 9, 2) : null
        ..playerStatus = api.PlayerStatus.ACTIVE,
    );

api.Member member(
  String id,
  String name, {
  Set<api.TenantRole> roles = const {api.TenantRole.COACH},
  bool active = true,
  String? email,
  api.InvitationStatus invitation = api.InvitationStatus.ACCEPTED,
  api.TemporaryPasswordStatus temporaryPassword = api.TemporaryPasswordStatus.NONE,
}) => api.Member(
  (b) => b
    ..personId = id
    ..givenName = name.split(' ').first
    ..familyName = name.split(' ').last
    ..displayName = name
    ..email = email ?? '${name.split(' ').first.toLowerCase()}@hoops-academy.com'
    ..roles = SetBuilder<api.TenantRole>(roles)
    ..active = active
    ..invitationStatus = invitation
    ..temporaryPasswordStatus = temporaryPassword
    ..createdAt = DateTime.utc(2026, 1, 1),
);

api.EligibilityCheck check(
  String teamId,
  String playerId,
  api.EligibilityResult result, {
  int playUp = 0,
  List<api.EligibilityReason> reasons = const [],
}) => api.EligibilityCheck(
  (b) => b
    ..playerId = playerId
    ..teamId = teamId
    ..asOf = api.Date(2026, 10, 1)
    ..result = result
    ..playUpLevels = playUp
    ..reasons.replace(reasons),
);

api.ApprovalRequest approval(
  String id, {
  api.ApprovalStatus status = api.ApprovalStatus.PENDING,
  api.ApprovalAction action = api.ApprovalAction.ADD_PLAYER,
  String playerName = 'Luca Mora',
  String by = 'person-me',
  String byName = 'Casey Coach',
  String? note,
}) => api.ApprovalRequest(
  (b) => b
    ..id = id
    ..action = action
    ..status = status
    ..player.replace(playerRef('p-$id', playerName))
    ..payload.replace(api.ApprovalPayload((p) => p.note = note))
    ..requestedBy.replace(personRef(by, byName))
    ..requestedAt = DateTime.utc(2026, 10, 1),
);

api.EligibilityCase eligibilityCase(String id, String pid, String pname, String tid, String tname) =>
    api.EligibilityCase(
      (b) => b
        ..id = id
        ..player.replace(playerRef(pid, pname))
        ..team.replace(teamRef(tid, tname))
        ..reason = api.EligibilityReason.CATEGORY_TOO_LOW
        ..status = api.EligibilityCaseStatus.OPEN
        ..openedAt = DateTime.utc(2026, 9, 1),
    );

api.TenantProfile profileFixture({bool hasLogo = false}) => api.TenantProfile(
  (b) => b
    ..id = 'tenant'
    ..slug = 'demo'
    ..name = 'Academia Demo'
    ..timezone = 'Europe/Madrid'
    ..defaultLocale = api.ApiLocale.es
    ..hasLogo = hasLogo,
);

api.TenantSettings settingsFixture() => api.TenantSettings(
  (b) => b
    ..ageRule = api.AgeRule.BIRTH_YEAR
    ..maxPlayUpLevels = 1,
);

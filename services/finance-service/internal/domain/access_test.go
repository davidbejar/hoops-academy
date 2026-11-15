package domain

import (
	"errors"
	"testing"
)

var (
	tenantA, _ = ParseTenantID("aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa")
	person     = PersonID(mustUUID("55555555-5555-4555-8555-555555555555"))
	playerID   = PlayerID(mustUUID("66666666-6666-4666-8666-666666666666"))
	otherTeam  = TeamID(mustUUID("77777777-7777-4777-8777-777777777777"))
)

func member(roles ...Role) Membership {
	return NewMembership("sub-1", person, tenantA, roles)
}

func TestRolesAreTheFiveTenantRoles(t *testing.T) {
	for _, text := range []string{"ADMIN", "COACH", "ASSISTANT_COACH", "PARENT", "PLAYER"} {
		if role, err := ParseRole(text); err != nil || string(role) != text {
			t.Errorf("%s: %v", text, err)
		}
	}
	if _, err := ParseRole("SUPER_ADMIN"); !errors.Is(err, ErrInvalid) {
		t.Error("unknown role accepted")
	}
}

// Decision 96 and docs/domain/authz-matrix.md, section Finance.
func TestOnlyAnAdminManagesFinance(t *testing.T) {
	for role, want := range map[Role]bool{Admin: true, Coach: false, AssistantCoach: false, Parent: false, Player: false} {
		if got := CanManageFinance(member(role)); got != want {
			t.Errorf("%s: %v", role, got)
		}
	}
	if !CanManageFinance(member(Coach, Admin)) {
		t.Error("roles are additive")
	}
	if CanManageFinance(member()) {
		t.Error("a member without roles")
	}
}

func TestACurrentCoachOfTheTeamReadsItsStatusAndAnAssistantNothing(t *testing.T) {
	coach := member(Coach).WithRelations(Relations{StaffTeams: []TeamID{teamID}})
	assistant := member(AssistantCoach).WithRelations(Relations{StaffTeams: []TeamID{teamID}})

	if !CanReadTeamStatus(coach, teamID) || CanReadTeamStatus(coach, otherTeam) {
		t.Error("coach")
	}
	if CanReadTeamStatus(assistant, teamID) {
		t.Error("an assistant coach has no finance access")
	}
	if !CanReadTeamStatus(member(Admin), otherTeam) {
		t.Error("admin")
	}
	if CanReadTeamStatus(member(Parent), teamID) {
		t.Error("parent")
	}
}

func TestAFamilyReadsTheDuesOfLinkedOrOwnPlayersOnly(t *testing.T) {
	parent := member(Parent).WithRelations(Relations{LinkedPlayers: []PlayerID{playerID}})
	self := member(Player).WithRelations(Relations{OwnPlayer: &playerID})
	other := PlayerID(mustUUID("88888888-8888-4888-8888-888888888888"))

	if !CanReadPlayerDues(parent, playerID) || CanReadPlayerDues(parent, other) {
		t.Error("parent")
	}
	if !CanReadPlayerDues(self, playerID) || CanReadPlayerDues(self, other) {
		t.Error("player")
	}
	if !CanReadPlayerDues(member(Admin), other) {
		t.Error("admin")
	}
	if CanReadPlayerDues(member(Coach).WithRelations(Relations{LinkedPlayers: []PlayerID{playerID}}), playerID) {
		t.Error("a link counts only with the PARENT role")
	}
	if CanReadPlayerDues(member(Parent).WithRelations(Relations{OwnPlayer: &playerID}), playerID) {
		t.Error("an own player counts only with the PLAYER role")
	}
}

func TestAMembershipKnowsItsTenantSubjectAndRoles(t *testing.T) {
	m := member(Parent, Admin, Parent)
	if m.Tenant() != tenantA || m.Subject() != "sub-1" || m.Person() != person {
		t.Errorf("got %+v", m)
	}
	if roles := m.RoleNames(); len(roles) != 2 || roles[0] != "ADMIN" || roles[1] != "PARENT" {
		t.Errorf("roles sorted and unique: %v", roles)
	}
	if !m.Has(Admin) || m.Has(Coach) {
		t.Error("Has")
	}
}

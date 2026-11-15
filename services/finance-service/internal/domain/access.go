package domain

import (
	"slices"
	"sort"
)

// Role is a tenant role (core.membership_role).
type Role string

// The tenant roles.
const (
	Admin          Role = "ADMIN"
	Coach          Role = "COACH"
	AssistantCoach Role = "ASSISTANT_COACH"
	Parent         Role = "PARENT"
	Player         Role = "PLAYER"
)

// ParseRole reads one of the five tenant roles.
func ParseRole(text string) (Role, error) {
	switch r := Role(text); r {
	case Admin, Coach, AssistantCoach, Parent, Player:
		return r, nil
	default:
		return "", invalid("role", "INVALID")
	}
}

// PlayerID identifies a player (core's player).
type PlayerID UUID

// String is the canonical text form.
func (id PlayerID) String() string { return UUID(id).String() }

// Relations are the caller's links the finance rules look at, from the roster replica (WP119 fills them; until
// then they are empty and only ADMIN reaches finance data).
type Relations struct {
	StaffTeams    []TeamID   // teams of current seasons the caller is staff of
	LinkedPlayers []PlayerID // players the caller is guardian of
	OwnPlayer     *PlayerID  // the caller's own player record
}

// Membership is what the authenticated caller may do in one academy: their roles and relations (the counterpart of
// common-quarkus' AuthzContext).
type Membership struct {
	subject   string
	person    PersonID
	tenant    TenantID
	roles     []Role
	relations Relations
}

// NewMembership is a member of tenant with roles (duplicates dropped).
func NewMembership(subject string, person PersonID, tenant TenantID, roles []Role) Membership {
	unique := slices.Clone(roles)
	sort.Slice(unique, func(i, j int) bool { return unique[i] < unique[j] })
	return Membership{subject: subject, person: person, tenant: tenant, roles: slices.Compact(unique)}
}

// WithRelations is the same membership with relations.
func (m Membership) WithRelations(relations Relations) Membership {
	m.relations = relations
	return m
}

// Subject is the caller's login (the token's sub).
func (m Membership) Subject() string { return m.subject }

// Person is the caller's person in this academy.
func (m Membership) Person() PersonID { return m.person }

// Tenant is the academy this membership is valid for.
func (m Membership) Tenant() TenantID { return m.tenant }

// Has reports a role.
func (m Membership) Has(role Role) bool { return slices.Contains(m.roles, role) }

// RoleNames are the roles, sorted.
func (m Membership) RoleNames() []string {
	names := make([]string, len(m.roles))
	for i, r := range m.roles {
		names[i] = string(r)
	}
	return names
}

// CanManageFinance reports ADMIN: settings, fee plans, dues, payments, expenses, balance and exports are ADMIN's
// (decision 96).
func CanManageFinance(m Membership) bool { return m.Has(Admin) }

// CanReadTeamStatus reports who may read which players of a team are up to date (status only, no amounts): ADMIN,
// or a COACH who is current staff of the team. ASSISTANT_COACH has no finance access (decision 96).
func CanReadTeamStatus(m Membership, team TeamID) bool {
	return m.Has(Admin) || m.Has(Coach) && slices.Contains(m.relations.StaffTeams, team)
}

// CanReadPlayerDues reports who may read a player's dues and payments: ADMIN, a PARENT linked to the player, the
// PLAYER themself.
func CanReadPlayerDues(m Membership, player PlayerID) bool {
	return m.Has(Admin) ||
		m.Has(Parent) && slices.Contains(m.relations.LinkedPlayers, player) ||
		m.Has(Player) && m.relations.OwnPlayer != nil && *m.relations.OwnPlayer == player
}

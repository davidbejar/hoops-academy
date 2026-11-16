package events

import (
	"bytes"
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"hoopsacademy.local/finance/internal/application"
	"hoopsacademy.local/finance/internal/testsupport/pgtest"
)

func contractFile(t *testing.T, name string) []byte {
	t.Helper()
	data, err := os.ReadFile(filepath.Join(pgtest.RepoRoot(), "libs", "contracts", "events", name))
	if err != nil {
		t.Fatal(err)
	}
	return data
}

func examples(t *testing.T, topic string) []json.RawMessage {
	t.Helper()
	var list []json.RawMessage
	if err := json.Unmarshal(contractFile(t, "examples/"+topic+".valid.json"), &list); err != nil {
		t.Fatal(err)
	}
	return list
}

func keyOf(t *testing.T, value []byte) []byte {
	t.Helper()
	var envelope struct{ TenantID, AggregateID string }
	_ = json.Unmarshal(value, &envelope)
	return []byte(envelope.TenantID + ":" + envelope.AggregateID)
}

func TestTheEmbeddedSchemasAreTheContracts(t *testing.T) {
	for _, topic := range Topics {
		embedded, err := schemaFiles.ReadFile("schemas/" + topic + ".schema.json")
		if err != nil {
			t.Fatal(err)
		}
		if !bytes.Equal(embedded, contractFile(t, topic+".schema.json")) {
			t.Errorf("%s: the copy differs from libs/contracts/events (cp it)", topic)
		}
	}
}

func TestEveryExampleOfTheContractsDecodes(t *testing.T) {
	decoder := NewDecoder()
	for _, topic := range Topics {
		for _, value := range examples(t, topic) {
			event, skip, err := decoder.Decode(topic, keyOf(t, value), value)
			if err != nil || skip || event.Topic != topic || event.Tenant.IsZero() {
				t.Errorf("%s %s: %+v %v %v", topic, value, event, skip, err)
			}
		}
	}
}

func TestAPersonEventKeepsLoginRolesAndActiveOnly(t *testing.T) {
	value := examples(t, "core.person")[0]
	event, _, err := NewDecoder().Decode("core.person", keyOf(t, value), value)
	if err != nil {
		t.Fatal(err)
	}
	if event.PersonData == nil || event.PersonData.Subject == nil || *event.PersonData.Subject == "" || !event.PersonData.Active ||
		strings.Join(event.PersonData.Roles, ",") != "ASSISTANT_COACH,COACH" || event.Type != "person.changed" {
		t.Errorf("person %+v", event.PersonData)
	}
}

func TestInvalidRecordsAreRefusedWithAReasonAndTombstonesSkipped(t *testing.T) {
	decoder := NewDecoder()
	person := examples(t, "core.person")[0]
	tenant := examples(t, "core.tenant")[0]
	var broken map[string]any
	_ = json.Unmarshal(person, &broken)
	broken["payload"].(map[string]any)["roles"] = []string{"OWNER"}
	brokenValue, _ := json.Marshal(broken)

	cases := map[string]struct {
		topic      string
		key, value []byte
		reason     string
	}{
		"key of another aggregate": {"core.person", []byte("x:y"), person, "key"},
		"schema":                   {"core.person", keyOf(t, brokenValue), brokenValue, "schema"},
		"not json":                 {"core.person", []byte("a:b"), []byte("{"), "schema"},
		"unknown topic":            {"core.unknown", keyOf(t, person), person, "topic"},
		"tenant of another topic":  {"core.person", keyOf(t, tenant), tenant, "schema"},
	}
	for name, c := range cases {
		_, _, err := decoder.Decode(c.topic, c.key, c.value)
		var invalid *Invalid
		if !asInvalid(err, &invalid) || invalid.Reason != c.reason {
			t.Errorf("%s: %v", name, err)
		}
	}
	if _, skip, err := decoder.Decode("core.person", []byte("a:b"), nil); !skip || err != nil {
		t.Errorf("tombstone: %v %v", skip, err)
	}
}

func asInvalid(err error, target **Invalid) bool {
	if invalid, ok := err.(*Invalid); ok { //nolint:errorlint // Decode returns it unwrapped
		*target = invalid
		return true
	}
	return false
}

// Privacy P-10: the finance replica keeps no birth date and no gender. The decoded event carries neither the fields
// nor their values; the player keeps its person, display name and status only.
func TestAPlayerEventDropsBirthDateAndGender(t *testing.T) {
	for _, value := range examples(t, "core.player") {
		event, _, err := NewDecoder().Decode("core.player", keyOf(t, value), value)
		if err != nil {
			t.Fatal(err)
		}
		var source struct {
			Payload struct{ BirthDate, Gender *string }
		}
		_ = json.Unmarshal(value, &source)
		decoded, _ := json.Marshal(event)
		text := strings.ToLower(string(decoded))
		for _, forbidden := range []string{"birth", "gender", "female", `"male"`} {
			if strings.Contains(text, forbidden) {
				t.Errorf("the decoded player holds %q: %s", forbidden, decoded)
			}
		}
		if source.Payload.BirthDate != nil && strings.Contains(string(decoded), *source.Payload.BirthDate) {
			t.Errorf("the decoded player holds the birth date: %s", decoded)
		}
		if event.Type == "player.changed" && (event.PlayerData == nil || event.PlayerData.DisplayName == "" ||
			event.PlayerData.Status == "" || event.PlayerData.Person.String() == "00000000-0000-0000-0000-000000000000") {
			t.Errorf("player %+v", event.PlayerData)
		}
	}
}

func TestTheRosterEventsKeepWhatTheFinanceRulesNeed(t *testing.T) {
	decoder := NewDecoder()
	decode := func(topic string) application.RosterEvent {
		value := examples(t, topic)[0]
		event, _, err := decoder.Decode(topic, keyOf(t, value), value)
		if err != nil {
			t.Fatal(err)
		}
		return event
	}

	team := decode("core.team").TeamData
	if team == nil || team.Season.String() != "4d5e6f70-8192-4a34-b5c6-d7e8f90a1b2c" ||
		team.SeasonStart.Format(time.DateOnly) != "2026-09-01" || team.SeasonEnd.Format(time.DateOnly) != "2027-06-30" ||
		team.AgeCategory.String() != "5e6f7081-92a3-4b45-86d7-e8f90a1b2c3d" {
		t.Errorf("team %+v", team)
	}
	assignment := decode("core.team-player").AssignmentData
	if assignment == nil || assignment.Team.String() != "3c4d5e6f-7081-4923-a4b5-c6d7e8f90a1b" ||
		assignment.Player.String() != "7e6d5c4b-3a29-4180-8f7e-6d5c4b3a2918" ||
		assignment.JoinedOn.Format(time.DateOnly) != "2026-09-15" || assignment.LeftOn != nil || assignment.Invalid != nil {
		t.Errorf("assignment %+v", assignment)
	}
	staff := decode("core.team-staff").StaffData
	if staff == nil || staff.Team.String() != "3c4d5e6f-7081-4923-a4b5-c6d7e8f90a1b" ||
		staff.Person.String() != "9f0e1d2c-3b4a-4596-8877-665544332211" || staff.Role != "COACH" {
		t.Errorf("staff %+v", staff)
	}
	link := decode("core.guardian-link").LinkData
	if link == nil || link.Guardian.String() != "b4c5d6e7-f809-41a2-b3c4-d5e6f7081920" ||
		link.Player.String() != "7e6d5c4b-3a29-4180-8f7e-6d5c4b3a2918" {
		t.Errorf("link %+v", link)
	}
	if person := decode("core.person").PersonData; person == nil || person.DisplayName == "" {
		t.Errorf("person %+v", person)
	}
	if len(Topics) != 7 {
		t.Errorf("topics %v", Topics)
	}
}

package events

import (
	"bytes"
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"

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

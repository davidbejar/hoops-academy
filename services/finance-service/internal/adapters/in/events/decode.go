// Package events consumes core's roster topics into finance-service's replica (ADR-0036, ADR-0037): each record is
// validated against its topic's JSON Schema (copies of libs/contracts/events, kept equal by a test) and its key,
// applied idempotently in a transaction bound to the event's tenant, or parked when invalid; offsets are committed
// after processing. WP118 consumes core.tenant and core.person (the tenant filter's membership); WP119 adds the
// topics of players, teams, assignments, staff and guardian links.
package events

import (
	"bytes"
	"embed"
	"encoding/json"
	"fmt"
	"time"

	"github.com/santhosh-tekuri/jsonschema/v6"

	"hoopsacademy.local/finance/internal/application"
	"hoopsacademy.local/finance/internal/domain"
)

// Topics are the topics this replica consumes.
var Topics = []string{"core.tenant", "core.person"}

//go:embed schemas/*.json
var schemaFiles embed.FS

// Invalid is a record that breaks the contract (parked, never applied); Reason is topic, schema or key.
type Invalid struct {
	Reason  string
	EventID string
}

func (e *Invalid) Error() string { return "invalid record: " + e.Reason }

// Decoder validates and decodes records.
type Decoder struct{ schemas map[string]*jsonschema.Schema }

// NewDecoder compiles the embedded schemas (a broken embedded file is a build error, so it panics).
func NewDecoder() *Decoder {
	compiler := jsonschema.NewCompiler()
	compiler.AssertFormat()
	schemas := map[string]*jsonschema.Schema{}
	for _, topic := range Topics {
		name := "schemas/" + topic + ".schema.json"
		data, err := schemaFiles.ReadFile(name)
		if err != nil {
			panic(err)
		}
		document, err := jsonschema.UnmarshalJSON(bytes.NewReader(data))
		if err != nil {
			panic(err)
		}
		if err := compiler.AddResource(name, document); err != nil {
			panic(err)
		}
		schemas[topic] = compiler.MustCompile(name)
	}
	return &Decoder{schemas: schemas}
}

type envelope struct {
	EventID     string          `json:"eventId"`
	Type        string          `json:"type"`
	TenantID    string          `json:"tenantId"`
	AggregateID string          `json:"aggregateId"`
	OccurredAt  time.Time       `json:"occurredAt"`
	Payload     json.RawMessage `json:"payload"`
}

// Decode reads one record. A null value is a tombstone (skip, nothing to apply). An *Invalid error is a contract
// violation to park.
func (d *Decoder) Decode(topic string, key, value []byte) (application.RosterEvent, bool, error) {
	if value == nil {
		return application.RosterEvent{}, true, nil
	}
	schema, known := d.schemas[topic]
	if !known {
		return application.RosterEvent{}, false, &Invalid{Reason: "topic"}
	}
	document, err := jsonschema.UnmarshalJSON(bytes.NewReader(value))
	if err != nil || schema.Validate(document) != nil {
		return application.RosterEvent{}, false, &Invalid{Reason: "schema", EventID: eventIDOf(value)}
	}
	var e envelope
	if err := json.Unmarshal(value, &e); err != nil {
		return application.RosterEvent{}, false, &Invalid{Reason: "schema"}
	}
	if string(key) != e.TenantID+":"+e.AggregateID || topic == "core.tenant" && e.AggregateID != e.TenantID {
		return application.RosterEvent{}, false, &Invalid{Reason: "key", EventID: e.EventID}
	}
	return decoded(topic, e)
}

func decoded(topic string, e envelope) (application.RosterEvent, bool, error) {
	id, errID := domain.ParseUUID(e.EventID)
	tenant, errTenant := domain.ParseTenantID(e.TenantID)
	aggregate, errAggregate := domain.ParseUUID(e.AggregateID)
	if errID != nil || errTenant != nil || errAggregate != nil {
		return application.RosterEvent{}, false, &Invalid{Reason: "schema", EventID: e.EventID}
	}
	event := application.RosterEvent{ID: id, Topic: topic, Type: e.Type, Tenant: tenant, Aggregate: aggregate,
		OccurredAt: e.OccurredAt.UTC()}
	var err error
	switch e.Type {
	case "tenant.changed":
		var p struct{ Status, Timezone string }
		err = json.Unmarshal(e.Payload, &p)
		event.TenantData = &application.TenantState{Status: p.Status, Timezone: p.Timezone}
	case "person.changed":
		var p struct {
			Subject *string
			Roles   []string
			Active  bool
		}
		err = json.Unmarshal(e.Payload, &p)
		event.PersonData = &application.PersonState{Subject: p.Subject, Roles: p.Roles, Active: p.Active}
	}
	if err != nil {
		return application.RosterEvent{}, false, fmt.Errorf("payload of %s: %w", e.Type, err)
	}
	return event, false, nil
}

// eventIDOf reads the event id of a record that failed validation, if it has one that looks like a UUID.
func eventIDOf(value []byte) string {
	var e struct{ EventID string }
	if json.Unmarshal(value, &e) != nil {
		return ""
	}
	if _, err := domain.ParseUUID(e.EventID); err != nil {
		return ""
	}
	return e.EventID
}

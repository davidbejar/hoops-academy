// Package events consumes core's roster topics into finance-service's replica (ADR-0036, ADR-0037): each record is
// validated against its topic's JSON Schema (copies of libs/contracts/events, kept equal by a test) and its key,
// applied idempotently in a transaction bound to the event's tenant, or parked when invalid; offsets are committed
// after processing. Topics lists the seven topics: academies and members (the tenant filter's membership), players,
// teams, assignments, staff and guardian links.
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
var Topics = []string{
	"core.tenant", "core.person", "core.player", "core.team", "core.team-player", "core.team-staff", "core.guardian-link",
}

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
	if read, ok := payloads[e.Type]; ok {
		if err := read(e.Payload, &event); err != nil {
			return application.RosterEvent{}, false, fmt.Errorf("payload of %s: %w", e.Type, err)
		}
	}
	return event, false, nil
}

// payloads decode the state of each `.changed` type into the event, keeping only what the replica stores: a player's
// birth date and gender are never read (P-10), nor jersey numbers or a staff entry's start; an academy keeps its slug and
// a team its name (the export file name and its team column, WP123).
var payloads = map[string]func(raw json.RawMessage, event *application.RosterEvent) error{
	"tenant.changed": func(raw json.RawMessage, event *application.RosterEvent) error {
		var p struct{ Status, Timezone, Slug string }
		err := unmarshal(raw, &p)
		event.TenantData = &application.TenantState{Status: p.Status, Timezone: p.Timezone, Slug: p.Slug}
		return err
	},
	"person.changed": func(raw json.RawMessage, event *application.RosterEvent) error {
		var p struct {
			DisplayName string
			Subject     *string
			Roles       []string
			Active      bool
		}
		err := unmarshal(raw, &p)
		event.PersonData = &application.PersonState{Subject: p.Subject, Roles: p.Roles, Active: p.Active,
			DisplayName: p.DisplayName}
		return err
	},
	"player.changed": func(raw json.RawMessage, event *application.RosterEvent) error {
		var p struct {
			PersonID            uuidText
			DisplayName, Status string
		}
		err := unmarshal(raw, &p)
		event.PlayerData = &application.PlayerState{Person: domain.PersonID(p.PersonID), DisplayName: p.DisplayName,
			Status: p.Status}
		return err
	},
	"team.changed": func(raw json.RawMessage, event *application.RosterEvent) error {
		var p struct {
			SeasonID                       uuidText
			SeasonStartDate, SeasonEndDate dateText
			AgeCategoryID                  uuidText
			Name                           string
		}
		err := unmarshal(raw, &p)
		event.TeamData = &application.TeamState{Season: domain.SeasonID(p.SeasonID),
			SeasonStart: time.Time(p.SeasonStartDate), SeasonEnd: time.Time(p.SeasonEndDate),
			AgeCategory: domain.AgeCategoryID(p.AgeCategoryID), Name: p.Name}
		return err
	},
	"team-player.changed": func(raw json.RawMessage, event *application.RosterEvent) error {
		var p struct {
			TeamID, PlayerID uuidText
			JoinedOn         dateText
			LeftOn           *dateText
			InvalidReason    *string
		}
		err := unmarshal(raw, &p)
		event.AssignmentData = &application.AssignmentState{Team: domain.TeamID(p.TeamID),
			Player: domain.PlayerID(p.PlayerID), JoinedOn: time.Time(p.JoinedOn), Invalid: p.InvalidReason}
		if p.LeftOn != nil {
			left := time.Time(*p.LeftOn)
			event.AssignmentData.LeftOn = &left
		}
		return err
	},
	"team-staff.changed": func(raw json.RawMessage, event *application.RosterEvent) error {
		var p struct {
			TeamID, PersonID uuidText
			Role             string
		}
		err := unmarshal(raw, &p)
		event.StaffData = &application.StaffState{Team: domain.TeamID(p.TeamID), Person: domain.PersonID(p.PersonID),
			Role: p.Role}
		return err
	},
	"guardian-link.changed": func(raw json.RawMessage, event *application.RosterEvent) error {
		var p struct{ GuardianPersonID, PlayerID uuidText }
		err := unmarshal(raw, &p)
		event.LinkData = &application.GuardianLinkState{Guardian: domain.PersonID(p.GuardianPersonID),
			Player: domain.PlayerID(p.PlayerID)}
		return err
	},
}

// uuidText reads a JSON string holding a UUID (the schema validated its form).
type uuidText domain.UUID

func (u *uuidText) UnmarshalJSON(data []byte) error {
	var text string
	if err := unmarshal(data, &text); err != nil {
		return err
	}
	id, err := domain.ParseUUID(text)
	*u = uuidText(id)
	return err
}

// dateText reads a JSON string holding a date (YYYY-MM-DD) as UTC midnight.
type dateText time.Time

func (d *dateText) UnmarshalJSON(data []byte) error {
	var text string
	if err := unmarshal(data, &text); err != nil {
		return err
	}
	day, err := time.Parse(time.DateOnly, text)
	if err != nil {
		return fmt.Errorf("date: %w", err)
	}
	*d = dateText(day)
	return nil
}

func unmarshal(data []byte, into any) error {
	if err := json.Unmarshal(data, into); err != nil {
		return fmt.Errorf("json: %w", err)
	}
	return nil
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

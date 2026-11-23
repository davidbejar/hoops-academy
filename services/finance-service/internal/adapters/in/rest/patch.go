package rest

import (
	"bytes"
	"encoding/json"

	"hoopsacademy.local/finance/internal/domain"
)

// jsonRaw keeps a property's raw value (a JSON null stays visible: absent or null = unchanged, ADR-0032).
type jsonRaw = json.RawMessage

var clearable = map[string]bool{"lastPeriod": true}

// planChanges reads an UpdateFeePlanRequest: at least one property (minProperties: 1), only the contract's
// properties, `clear` an array of unique clearable names.
func planChanges(body map[string]jsonRaw) (domain.FeePlanChanges, []violation) {
	var changes domain.FeePlanChanges
	var v []violation
	add := func(field, code string) { v = append(v, violation{field, code, messageOf(code)}) }
	if len(body) == 0 {
		add("body", "EMPTY_UPDATE")
	}
	for name, raw := range body {
		if bytes.Equal(bytes.TrimSpace(raw), []byte("null")) {
			continue
		}
		var err error
		switch name {
		case "name":
			err = json.Unmarshal(raw, &changes.Name)
		case "amountMinor":
			err = json.Unmarshal(raw, &changes.AmountMinor)
		case "firstPeriod":
			err = json.Unmarshal(raw, &changes.FirstPeriod)
		case "lastPeriod":
			err = json.Unmarshal(raw, &changes.LastPeriod)
		case "autoGenerate":
			err = json.Unmarshal(raw, &changes.AutoGenerate)
		case "clear":
			err = readClear(raw, &changes, add)
		default:
			add(safeField(name), "UNKNOWN_PROPERTY")
			continue
		}
		if err != nil {
			add(name, "INVALID_TYPE")
		}
	}
	return changes, v
}

func readClear(raw jsonRaw, changes *domain.FeePlanChanges, add func(field, code string)) error {
	var names []string
	if err := json.Unmarshal(raw, &names); err != nil {
		return err //nolint:wrapcheck // reported as INVALID_TYPE of clear
	}
	changes.ClearLastPeriod = readClearList(names, clearable, add)["lastPeriod"]
	return nil
}

// readClearList checks a `clear` list: each name clearable and named once (else INVALID); returns the names seen.
func readClearList(names []string, clearable map[string]bool, add func(field, code string)) map[string]bool {
	seen := map[string]bool{}
	for _, name := range names {
		if !clearable[name] || seen[name] {
			add("clear", "INVALID")
			continue
		}
		seen[name] = true
	}
	return seen
}

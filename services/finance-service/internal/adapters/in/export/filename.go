package export

import (
	"strings"
	"time"

	"golang.org/x/text/unicode/norm"
)

// maxPartLength bounds each part of a file name (ADR-0048).
const maxPartLength = 40

// FileName is hoops-<academy-slug>-<what>-<yyyyMMdd>.csv (ADR-0048): each part reduced to lower-case ASCII words
// joined by `-` (accents dropped, anything else a separator, at most 40 characters), an empty part left out; day is
// today in the academy's time zone.
func FileName(slug, what string, day time.Time) string {
	parts := []string{"hoops"}
	for _, part := range []string{slug, what, day.Format("20060102")} {
		if reduced := reduce(part); reduced != "" {
			parts = append(parts, reduced)
		}
	}
	return strings.Join(parts, "-") + ".csv"
}

// ContentDisposition is the attachment header of a file name (ASCII by construction, so no encoding is needed).
func ContentDisposition(name string) string { return `attachment; filename="` + name + `"` }

func reduce(part string) string {
	var words []string
	var word strings.Builder
	flush := func() {
		if word.Len() > 0 {
			words = append(words, word.String())
			word.Reset()
		}
	}
	for _, r := range norm.NFD.String(strings.ToLower(part)) {
		switch {
		case r >= 'a' && r <= 'z' || r >= '0' && r <= '9':
			word.WriteRune(r)
		case r >= 0x300 && r <= 0x36f: // a combining accent of a decomposed letter: dropped
		default:
			flush()
		}
	}
	flush()
	reduced := strings.Join(words, "-")
	if len(reduced) > maxPartLength {
		reduced = strings.TrimRight(reduced[:maxPartLength], "-")
	}
	return reduced
}

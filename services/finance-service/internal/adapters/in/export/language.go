package export

import (
	"strconv"
	"strings"
)

// Language is a language of the export's labels.
type Language int

// The languages of the app (es / en / id); English is the fallback.
const (
	English Language = iota
	Spanish
	Indonesian
)

func (l Language) String() string { return [...]string{"en", "es", "id"}[l] }

// maxRanges bounds how many entries of an Accept-Language header are read (the contract caps it at 200 characters).
const maxRanges = 20

// Negotiate picks the language of an Accept-Language header (RFC 9110) as core's exports do (ADR-0048): the
// supported language with the highest quality, the header's order on ties; q=0 refuses a language; `in` is read as
// Indonesian; an absent, `*`-only or unsupported header is English. An entry with a malformed quality is skipped.
func Negotiate(header string) Language {
	best, bestQuality := English, 0.0
	for i, entry := range strings.Split(header, ",") {
		if i == maxRanges {
			break
		}
		language, quality, ok := parseRange(entry)
		if ok && quality > bestQuality {
			best, bestQuality = language, quality
		}
	}
	return best
}

// parseRange reads one "tag[;q=value]" entry; ok is false for an unsupported tag or a malformed quality.
func parseRange(entry string) (Language, float64, bool) {
	tag, params, _ := strings.Cut(entry, ";")
	primary, _, _ := strings.Cut(strings.ToLower(strings.TrimSpace(tag)), "-")
	language, supported := map[string]Language{"en": English, "es": Spanish, "id": Indonesian, "in": Indonesian}[primary]
	if !supported {
		return English, 0, false
	}
	quality := 1.0
	if params = strings.TrimSpace(params); params != "" {
		name, value, found := strings.Cut(params, "=")
		parsed, err := strconv.ParseFloat(strings.TrimSpace(value), 64)
		if !found || strings.TrimSpace(strings.ToLower(name)) != "q" || err != nil || parsed < 0 || parsed > 1 {
			return English, 0, false
		}
		quality = parsed
	}
	return language, quality, true
}

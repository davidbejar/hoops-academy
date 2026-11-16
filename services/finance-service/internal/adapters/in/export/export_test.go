package export

import (
	"strings"
	"testing"
	"time"
)

func TestTheCsvIsUtf8WithBomCommasRfc4180QuotingAndCrlf(t *testing.T) {
	doc := NewDocument([]string{"Name", "Amount (minor units)", "Día"})
	doc.Row(Text("Pérez, Ana"), Number(4500), Text(`He said "hi"`))
	doc.Row(Text("line\nbreak"), Number(-3), Text(""))
	doc.Row(Text("plain"), Number(0), Text("cr\rinside"))

	want := "\uFEFF" + "Name,Amount (minor units),Día\r\n" +
		`"Pérez, Ana",4500,"He said ""hi"""` + "\r\n" +
		"\"line\nbreak\",-3,\r\n" +
		"plain,0,\"cr\rinside\"\r\n"
	if got := string(doc.Bytes()); got != want {
		t.Errorf("csv\n%q\nwant\n%q", got, want)
	}
	if doc.Rows() != 3 {
		t.Errorf("rows %d", doc.Rows())
	}
}

// ADR-0048: a text value starting with =, +, -, @, TAB or CR gets a leading ' (before quoting); numbers are exempt.
func TestTheFormulaGuardPrefixesDangerousTextButNotNumbers(t *testing.T) {
	doc := NewDocument([]string{"h"})
	for _, value := range []string{"=cmd|' /C calc'!A0", "+SUM(A1)", "-2", "@x", "\tx", "\rx", "a=b", "'quoted"} {
		doc.Row(Text(value))
	}
	doc.Row(Number(-7))
	rows := strings.Split(strings.TrimPrefix(string(doc.Bytes()), "\uFEFF"), "\r\n")
	want := []string{"h", `"'=cmd|' /C calc'!A0"`, "'+SUM(A1)", "'-2", "'@x", "'\tx", "\"'\rx\"", "a=b", "'quoted", "-7", ""}
	if len(rows) != len(want) {
		t.Fatalf("rows %q", rows)
	}
	for i := range want {
		if rows[i] != want[i] {
			t.Errorf("row %d: %q, want %q", i, rows[i], want[i])
		}
	}
	guarded := NewDocument([]string{"h"})
	guarded.Row(Text("=1,2"))
	if got := string(guarded.Bytes()); !strings.HasSuffix(got, "\r\n\"'=1,2\"\r\n") {
		t.Errorf("a guarded value with a separator is quoted with its ': %q", got)
	}
}

// The header's language: quality order, header order on ties, q=0 refused, `in` read as Indonesian, else English.
func TestTheLanguageIsNegotiatedFromAcceptLanguage(t *testing.T) {
	for header, want := range map[string]Language{
		"":                      English,
		"*":                     English,
		"fr-FR, de":             English,
		"es":                    Spanish,
		"es-ES,es;q=0.9":        Spanish,
		"id, en;q=0.8":          Indonesian,
		"in":                    Indonesian,
		"en;q=0.5, es;q=0.7":    Spanish,
		"es;q=0.7, id;q=0.7":    Spanish,
		"id;q=0.7, es;q=0.7":    Indonesian,
		"es;q=0, id":            Indonesian,
		"es;q=0":                English,
		"es;q=abc, id;q=0.1":    Indonesian,
		"fr;q=1, en-GB;q=0.2":   English,
		" ES ; q=0.9 ":          Spanish,
		"es;q=1.5":              English,
		strings.Repeat("x,", 9): English,
	} {
		if got := Negotiate(header); got != want {
			t.Errorf("%q: %v, want %v", header, got, want)
		}
	}
}

func TestTheLabelsExistInEveryLanguageForEveryColumnAndValue(t *testing.T) {
	for _, language := range []Language{English, Spanish, Indonesian} {
		labels := LabelsOf(language)
		for _, header := range [][]string{labels.DueHeader(), labels.ExpenseHeader()} {
			for i, h := range header {
				if h == "" {
					t.Errorf("%v: column %d has no label", language, i)
				}
			}
		}
		for _, value := range []string{"OPEN", "PAID", "WAIVED", "CASH", "BANK_TRANSFER", "CARD", "OTHER",
			"COURT_RENTAL", "SALARIES", "KIT", "TOURNAMENT_FEES", "TRAVEL"} {
			if labels.Value(value) == value || labels.Value(value) == "" {
				t.Errorf("%v: %s has no label", language, value)
			}
		}
		if labels.Value("UNKNOWN_VALUE") != "UNKNOWN_VALUE" {
			t.Errorf("%v: an unknown value is not kept as it is", language)
		}
	}
	if got := LabelsOf(Spanish).Value("PAID"); got != "Pagada" {
		t.Errorf("es PAID %q", got)
	}
	if got := LabelsOf(Indonesian).DueHeader()[0]; got != "Periode" {
		t.Errorf("id period %q", got)
	}
}

func TestTheFileNameIsAsciiWithTheAcademysSlugAndDay(t *testing.T) {
	day := time.Date(2026, 11, 16, 0, 0, 0, 0, time.UTC)
	for slug, want := range map[string]string{
		"hang-tuah":                 "hoops-hang-tuah-dues-20261116.csv",
		"Ñandú Básquet  Club":       "hoops-nandu-basquet-club-dues-20261116.csv",
		"":                          "hoops-dues-20261116.csv",
		"---":                       "hoops-dues-20261116.csv",
		strings.Repeat("abcde-", 10): "hoops-abcde-abcde-abcde-abcde-abcde-abcde-abcd-dues-20261116.csv",
		"a\"b;c\r\nd":               "hoops-a-b-c-d-dues-20261116.csv",
	} {
		if got := FileName(slug, "dues", day); got != want {
			t.Errorf("%q: %q, want %q", slug, got, want)
		}
	}
	if got := ContentDisposition(FileName("x", "expenses", day)); got != `attachment; filename="hoops-x-expenses-20261116.csv"` {
		t.Errorf("disposition %q", got)
	}
}

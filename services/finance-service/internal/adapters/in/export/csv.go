// Package export renders finance-service's CSV files by the spec of ADR-0048, shared with core's server-built exports
// and the web's: UTF-8 with BOM, `,` separator, RFC 4180 quoting, CRLF line ends, one header row, the formula-injection
// guard on text cells, header and enum labels in the caller's language (es / en / id), the ASCII file name
// hoops-<academy-slug>-<what>-<yyyyMMdd>.csv. Pure: no I/O, no request values in errors.
package export

import (
	"strconv"
	"strings"
)

const bom = "\uFEFF"

// Cell is one field of a row: text (guarded and quoted as needed) or a number (written as it is).
type Cell struct {
	value  string
	number bool
}

// Text is a text cell.
func Text(value string) Cell { return Cell{value: value} }

// Number is a numeric cell: exempt from the formula guard, so a negative number stays a number.
func Number(value int64) Cell { return Cell{value: strconv.FormatInt(value, 10), number: true} }

// Document is a CSV file being written: the header row, then the rows.
type Document struct {
	out  strings.Builder
	rows int
}

// NewDocument starts a file with its BOM and header row.
func NewDocument(header []string) *Document {
	d := &Document{}
	d.out.WriteString(bom)
	cells := make([]Cell, len(header))
	for i, h := range header {
		cells[i] = Text(h)
	}
	d.line(cells)
	return d
}

// Row appends one row.
func (d *Document) Row(cells ...Cell) {
	d.line(cells)
	d.rows++
}

// Rows counts the rows written after the header.
func (d *Document) Rows() int { return d.rows }

// Bytes is the file.
func (d *Document) Bytes() []byte { return []byte(d.out.String()) }

func (d *Document) line(cells []Cell) {
	for i, c := range cells {
		if i > 0 {
			d.out.WriteByte(',')
		}
		value := c.value
		if !c.number {
			value = quote(guard(value))
		}
		d.out.WriteString(value)
	}
	d.out.WriteString("\r\n")
}

// guard prefixes a text value that a spreadsheet would read as a formula (=, +, -, @, TAB, CR) with `'`.
func guard(value string) string {
	if value != "" && strings.ContainsRune("=+-@\t\r", rune(value[0])) {
		return "'" + value
	}
	return value
}

// quote applies RFC 4180: a field holding `,`, `"`, CR or LF is quoted and its quotes doubled.
func quote(value string) string {
	if !strings.ContainsAny(value, ",\"\r\n") {
		return value
	}
	return `"` + strings.ReplaceAll(value, `"`, `""`) + `"`
}

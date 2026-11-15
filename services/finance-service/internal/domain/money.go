package domain

import "regexp"

// Currency is an ISO 4217 currency an academy may keep its books in (decision 94: one per academy, no conversion).
type Currency struct {
	code   string
	digits int
}

var currencyCode = regexp.MustCompile(`^[A-Z]{3}$`)

// ParseCurrency reads an alphabetic ISO 4217 code. A code that is not three capital letters is invalid; a
// well-formed code that is not an active currency (withdrawn, a fund, a metal, a test code) is refused with 422
// UNKNOWN_CURRENCY.
func ParseCurrency(code string) (Currency, error) {
	if !currencyCode.MatchString(code) {
		return Currency{}, invalid("currency", "INVALID")
	}
	digits, ok := currencies[code]
	if !ok {
		return Currency{}, RuleViolation("UNKNOWN_CURRENCY", "not an active ISO 4217 currency")
	}
	return Currency{code: code, digits: digits}, nil
}

// Code is the alphabetic code, e.g. EUR.
func (c Currency) Code() string { return c.code }

// MinorDigits is the number of decimal places of the minor unit (EUR 2, JPY 0, BHD 3).
func (c Currency) MinorDigits() int { return c.digits }

// MaxAmountMinor caps every amount: 10^11 minor units (a billion euros, or 100 million dinars); larger values are
// typing mistakes, and the bound keeps sums of many amounts far from int64 overflow.
const MaxAmountMinor int64 = 100_000_000_000

// Amount is a positive amount in the minor unit of the academy's currency.
type Amount struct{ minor int64 }

// NewAmount accepts 1..MaxAmountMinor.
func NewAmount(minor int64) (Amount, error) {
	if minor < 1 || minor > MaxAmountMinor {
		return Amount{}, invalid("amountMinor", "OUT_OF_RANGE")
	}
	return Amount{minor: minor}, nil
}

// Minor is the amount in minor units.
func (a Amount) Minor() int64 { return a.minor }

// Settings are an academy's finance settings.
type Settings struct {
	Currency Currency
	Version  int
}

// ChangeCurrency sets the academy's currency (current is nil before the first choice). Once a due exists the
// currency is fixed (decision 94): another one is refused with 409 CURRENCY_LOCKED; the same one is no change.
func ChangeCurrency(current *Settings, currency Currency, duesExist bool) (Settings, error) {
	if current == nil {
		return Settings{Currency: currency}, nil
	}
	if current.Currency != currency && duesExist {
		return *current, Conflict("CURRENCY_LOCKED", "the currency is fixed once the first due exists")
	}
	changed := *current
	changed.Currency = currency
	return changed, nil
}

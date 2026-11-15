package domain

import (
	"errors"
	"testing"
)

func TestCurrenciesAreActiveISO4217CodesWithTheirMinorUnit(t *testing.T) {
	for code, digits := range map[string]int{"EUR": 2, "USD": 2, "IDR": 2, "JPY": 0, "KRW": 0, "BHD": 3, "MXN": 2} {
		currency, err := ParseCurrency(code)
		if err != nil {
			t.Fatalf("%s: %v", code, err)
		}
		if currency.Code() != code || currency.MinorDigits() != digits {
			t.Errorf("%s: got %s with %d digits, want %d", code, currency.Code(), currency.MinorDigits(), digits)
		}
	}
}

func TestMalformedCurrencyCodesAreInvalidAndUnknownOnesAreRefused(t *testing.T) {
	for _, code := range []string{"", "eur", "EU", "EURO", "E1R"} {
		if _, err := ParseCurrency(code); !errors.Is(err, ErrInvalid) {
			t.Errorf("%q: %v", code, err)
		}
	}
	// well-formed but not a currency one pays fees in: withdrawn, funds, metals, test codes
	for _, code := range []string{"ABC", "BGN", "HRK", "XAU", "XTS", "XXX", "CHE", "USN"} {
		var problem *Error
		if _, err := ParseCurrency(code); !errors.As(err, &problem) || problem.Code != "UNKNOWN_CURRENCY" ||
			problem.Kind != KindRule {
			t.Errorf("%q: %v", code, err)
		}
	}
}

func TestTheCurrencyListHasNoDuplicatesAndValidDigits(t *testing.T) {
	if len(currencies) < 150 {
		t.Errorf("only %d currencies", len(currencies))
	}
	for code, digits := range currencies {
		if len(code) != 3 || digits < 0 || digits > 3 {
			t.Errorf("%s: %d", code, digits)
		}
	}
}

func TestAmountsAreMinorUnitsWithinBounds(t *testing.T) {
	for _, minor := range []int64{1, 100, MaxAmountMinor} {
		amount, err := NewAmount(minor)
		if err != nil || amount.Minor() != minor {
			t.Errorf("%d: %v %v", minor, amount, err)
		}
	}
	for _, minor := range []int64{0, -1, MaxAmountMinor + 1} {
		if _, err := NewAmount(minor); !errors.Is(err, ErrInvalid) {
			t.Errorf("%d accepted: %v", minor, err)
		}
	}
}

func TestTheCurrencyIsFixedOnceTheFirstDueExists(t *testing.T) {
	eur, _ := ParseCurrency("EUR")
	idr, _ := ParseCurrency("IDR")

	if _, err := ChangeCurrency(nil, idr, false); err != nil {
		t.Errorf("first choice: %v", err)
	}
	current := &Settings{Currency: eur}
	changed, err := ChangeCurrency(current, idr, false)
	if err != nil || changed.Currency != idr {
		t.Errorf("change before any due: %v %v", changed, err)
	}
	if _, err := ChangeCurrency(current, eur, true); err != nil {
		t.Errorf("the same currency again is no change: %v", err)
	}
	var problem *Error
	if _, err := ChangeCurrency(current, idr, true); !errors.As(err, &problem) || problem.Code != "CURRENCY_LOCKED" ||
		problem.Kind != KindConflict {
		t.Errorf("change after the first due: %v", err)
	}
}

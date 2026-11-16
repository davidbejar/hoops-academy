package domain

import (
	"errors"
	"slices"
	"strings"
	"testing"
	"time"
)

var (
	dueID     = DueID(mustUUID("66666666-6666-4666-8666-666666666666"))
	paymentID = PaymentID(mustUUID("77777777-7777-4777-8777-777777777777"))
	adminID   = PersonID(mustUUID("99999999-9999-4999-8999-999999999999"))
	today     = time.Date(2026, 11, 16, 0, 0, 0, 0, time.UTC)
)

func openDue(t *testing.T) Due {
	t.Helper()
	plan, err := NewFeePlan(planID, monthlyInput(), created)
	if err != nil {
		t.Fatal(err)
	}
	window, err := plan.Window("2026-11", SeasonDates{Start: day2026(time.September, 1), End: time.Date(2027, 6, 30, 0, 0, 0, 0, time.UTC)})
	if err != nil {
		t.Fatal(err)
	}
	return NewDue(dueID, plan, window, Candidate{Player: playerID, Team: teamID, Name: "Pablo Player"}, created)
}

func requireError(t *testing.T, err error, kind Kind, code string) {
	t.Helper()
	var problem *Error
	if !errors.As(err, &problem) || problem.Kind != kind || problem.Code != code {
		t.Fatalf("expected kind %d code %s, got %v", kind, code, err)
	}
}

func TestANewDueIsOpenAtThePlansAmountForItsWindow(t *testing.T) {
	due := openDue(t)

	if due.ID != dueID || due.Plan != planID || due.Player != playerID || due.Team != teamID || due.Period != "2026-11" ||
		!due.Start.Equal(day2026(time.November, 1)) || !due.End.Equal(day2026(time.November, 30)) ||
		due.Amount.Minor() != 4500 || due.PlanAmount.Minor() != 4500 || due.Status != DueOpen || due.Reason != nil ||
		!due.CreatedAt.Equal(created) || !due.UpdatedAt.Equal(created) {
		t.Errorf("due %+v", due)
	}
}

func TestStatusesAndMethodsAreTheContractsEnums(t *testing.T) {
	for _, s := range []string{"OPEN", "PAID", "WAIVED"} {
		if got, err := ParseDueStatus(s); err != nil || string(got) != s {
			t.Errorf("status %s: %v %v", s, got, err)
		}
	}
	for _, m := range []string{"CASH", "BANK_TRANSFER", "CARD", "OTHER"} {
		if got, err := ParsePaymentMethod(m); err != nil || string(got) != m {
			t.Errorf("method %s: %v %v", m, got, err)
		}
	}
	if _, err := ParseDueStatus("open"); !errors.Is(err, ErrInvalid) {
		t.Errorf("status open: %v", err)
	}
	if _, err := ParsePaymentMethod("PAYPAL"); !errors.Is(err, ErrInvalid) {
		t.Errorf("method PAYPAL: %v", err)
	}
}

func TestAReasonIsTrimmedRequiredAndAtMost200Characters(t *testing.T) {
	if got, err := NewReason("reason", "  hardship  "); err != nil || got != "hardship" {
		t.Errorf("reason %q %v", got, err)
	}
	if got, err := NewReason("reason", strings.Repeat("ñ", 200)); err != nil || textLength(got) != 200 {
		t.Errorf("200 characters: %v", err)
	}
	if v := violationsOf(t, errOnly(NewReason("reason", "   "))); !slices.Equal(v, []Violation{{"reason", "REQUIRED"}}) {
		t.Errorf("blank: %v", v)
	}
	if v := violationsOf(t, errOnly(NewReason("voidReason", strings.Repeat("x", 201)))); !slices.Equal(v, []Violation{{"voidReason", "TOO_LONG"}}) {
		t.Errorf("too long: %v", v)
	}
}

func errOnly[T any](_ T, err error) error { return err }

func TestAnOpenDuesAmountChangesWithAReason(t *testing.T) {
	due := openDue(t)

	changed, err := due.ChangeAmount(3000, " sibling discount ", later)

	if err != nil || changed.Amount.Minor() != 3000 || changed.PlanAmount.Minor() != 4500 || changed.Status != DueOpen ||
		changed.Reason == nil || *changed.Reason != "sibling discount" || !changed.UpdatedAt.Equal(later) {
		t.Errorf("changed %+v %v", changed, err)
	}
	if v := violationsOf(t, errOnly(due.ChangeAmount(0, "", later))); !slices.Equal(v,
		[]Violation{{"amountMinor", "OUT_OF_RANGE"}, {"reason", "REQUIRED"}}) {
		t.Errorf("violations %v", v)
	}
}

func TestAnOpenDueIsWaivedForGood(t *testing.T) {
	due := openDue(t)

	waived, err := due.Waive("hardship", later)

	if err != nil || waived.Status != DueWaived || *waived.Reason != "hardship" || !waived.UpdatedAt.Equal(later) {
		t.Fatalf("waived %+v %v", waived, err)
	}
	requireError(t, errOnly(waived.Waive("again", later)), KindConflict, "DUE_NOT_OPEN")
	requireError(t, errOnly(waived.ChangeAmount(100, "later", later)), KindConflict, "DUE_NOT_OPEN")
	_, _, err = waived.Pay(paymentID, PaymentInput{PaidOn: today, Method: "CASH"}, adminID, today, later)
	requireError(t, err, KindConflict, "DUE_NOT_OPEN")
	if v := violationsOf(t, errOnly(due.Waive("", later))); !slices.Equal(v, []Violation{{"reason", "REQUIRED"}}) {
		t.Errorf("violations %v", v)
	}
}

func TestAPaymentSettlesTheWholeDue(t *testing.T) {
	due, _ := openDue(t).ChangeAmount(3000, "discount", later)
	note := " paid at the court "

	paid, payment, err := due.Pay(paymentID, PaymentInput{PaidOn: today, Method: "BANK_TRANSFER", Note: &note}, adminID,
		today, later)

	if err != nil || paid.Status != DuePaid || !paid.UpdatedAt.Equal(later) {
		t.Fatalf("paid %+v %v", paid, err)
	}
	if payment.ID != paymentID || payment.Due != dueID || payment.Amount.Minor() != 3000 || !payment.PaidOn.Equal(today) ||
		payment.Method != BankTransfer || *payment.Note != "paid at the court" || payment.RecordedBy != adminID ||
		!payment.RecordedAt.Equal(later) || payment.Voided() || payment.VoidReason != nil || payment.VoidedBy != nil {
		t.Errorf("payment %+v", payment)
	}
	_, _, err = paid.Pay(paymentID, PaymentInput{PaidOn: today, Method: "CASH"}, adminID, today, later)
	requireError(t, err, KindConflict, "DUE_NOT_OPEN")
}

func TestAPaymentIsRefusedForInvalidInputOrADayAfterToday(t *testing.T) {
	due := openDue(t)
	blank, long := "  ", strings.Repeat("n", 201)

	_, _, err := due.Pay(paymentID, PaymentInput{PaidOn: today, Method: "PAYPAL", Note: &blank}, adminID, today, later)
	if v := violationsOf(t, err); !slices.Equal(v, []Violation{{"method", "INVALID"}, {"note", "REQUIRED"}}) {
		t.Errorf("violations %v", v)
	}
	_, _, err = due.Pay(paymentID, PaymentInput{PaidOn: today, Method: "CASH", Note: &long}, adminID, today, later)
	if v := violationsOf(t, err); !slices.Equal(v, []Violation{{"note", "TOO_LONG"}}) {
		t.Errorf("violations %v", v)
	}
	_, _, err = due.Pay(paymentID, PaymentInput{PaidOn: today.AddDate(0, 0, 1), Method: "CASH"}, adminID, today, later)
	requireError(t, err, KindRule, "PAID_ON_IN_FUTURE")
	if _, p, err := due.Pay(paymentID, PaymentInput{PaidOn: today.AddDate(-1, 0, 0), Method: "CASH"}, adminID, today,
		later); err != nil || p.Note != nil {
		t.Errorf("a payment of last year without a note: %v", err)
	}
}

func TestAVoidedPaymentIsKeptAndItsDueReopened(t *testing.T) {
	paid, payment, _ := openDue(t).Pay(paymentID, PaymentInput{PaidOn: today, Method: "CASH"}, adminID, today, created)

	voided, err := payment.Void(" wrong family ", adminID, later)

	if err != nil || !voided.Voided() || !voided.VoidedAt.Equal(later) || *voided.VoidReason != "wrong family" ||
		*voided.VoidedBy != adminID || voided.Amount != payment.Amount {
		t.Fatalf("voided %+v %v", voided, err)
	}
	requireError(t, errOnly(voided.Void("again", adminID, later)), KindConflict, "PAYMENT_ALREADY_VOIDED")
	if v := violationsOf(t, errOnly(payment.Void("", adminID, later))); !slices.Equal(v, []Violation{{"reason", "REQUIRED"}}) {
		t.Errorf("violations %v", v)
	}
	reopened, err := paid.Reopen(later)
	if err != nil || reopened.Status != DueOpen || !reopened.UpdatedAt.Equal(later) {
		t.Errorf("reopened %+v %v", reopened, err)
	}
	requireError(t, errOnly(reopened.Reopen(later)), KindConflict, "DUE_NOT_PAID")
}

func TestDueAndPaymentIDsPrintCanonically(t *testing.T) {
	if dueID.String() != "66666666-6666-4666-8666-666666666666" || paymentID.String() != "77777777-7777-4777-8777-777777777777" ||
		playerID.String() != "66666666-6666-4666-8666-666666666666" {
		t.Error("ids")
	}
}

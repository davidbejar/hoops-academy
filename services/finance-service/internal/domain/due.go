package domain

import "time"

// DueID identifies a due.
type DueID UUID

// String is the canonical text form.
func (id DueID) String() string { return UUID(id).String() }

// PaymentID identifies a payment.
type PaymentID UUID

// String is the canonical text form.
func (id PaymentID) String() string { return UUID(id).String() }

// DueStatus is where a due stands (ADR-0056): OPEN until PAID by one payment or WAIVED by ADMIN.
type DueStatus string

// The statuses.
const (
	DueOpen   DueStatus = "OPEN"
	DuePaid   DueStatus = "PAID"
	DueWaived DueStatus = "WAIVED"
)

// ParseDueStatus reads OPEN, PAID or WAIVED.
func ParseDueStatus(text string) (DueStatus, error) {
	switch s := DueStatus(text); s {
	case DueOpen, DuePaid, DueWaived:
		return s, nil
	default:
		return "", invalid("status", "INVALID")
	}
}

// PaymentMethod is how a family paid (decision 95).
type PaymentMethod string

// The methods.
const (
	Cash         PaymentMethod = "CASH"
	BankTransfer PaymentMethod = "BANK_TRANSFER"
	Card         PaymentMethod = "CARD"
	OtherMethod  PaymentMethod = "OTHER"
)

// ParsePaymentMethod reads CASH, BANK_TRANSFER, CARD or OTHER.
func ParsePaymentMethod(text string) (PaymentMethod, error) {
	switch m := PaymentMethod(text); m {
	case Cash, BankTransfer, Card, OtherMethod:
		return m, nil
	default:
		return "", invalid("method", "INVALID")
	}
}

// MaxReasonLength bounds reasons and notes, in characters (P-12: short, no health or family details).
const MaxReasonLength = 200

// NewReason trims a reason or note of field: it must not be blank and has at most MaxReasonLength characters.
func NewReason(field, raw string) (string, error) {
	var v violations
	reason := checkReason(&v, field, raw)
	return reason, v.err()
}

func checkReason(v *violations, field, raw string) string {
	reason := cleanText(raw)
	switch {
	case reason == "":
		v.add(field, "REQUIRED")
	case textLength(reason) > MaxReasonLength:
		v.add(field, "TOO_LONG")
	}
	return reason
}

// Due is what one player owes under one plan for one period (decision 97). Immutable: plan, player, team, period
// and its dates; the amount changes only while OPEN, with a reason (the last one is kept, the audit trail has the
// history).
type Due struct {
	ID         DueID
	Plan       FeePlanID
	Player     PlayerID
	Team       TeamID // the team through which the player owed it
	Period     string // the period's key
	Start, End time.Time
	Amount     Amount
	PlanAmount Amount // the plan's amount at generation
	Status     DueStatus
	Reason     *string // of the last waiver or amount change
	CreatedAt  time.Time
	UpdatedAt  time.Time
	Version    int
}

// NewDue is the open due of candidate for the plan's window, at the plan's full amount (no proration).
func NewDue(id DueID, plan FeePlan, window DueWindow, candidate Candidate, now time.Time) Due {
	return Due{
		ID: id, Plan: plan.ID, Player: candidate.Player, Team: candidate.Team, Period: window.Period.Key(),
		Start: window.Start, End: window.End, Amount: plan.Amount, PlanAmount: plan.Amount, Status: DueOpen,
		CreatedAt: now, UpdatedAt: now,
	}
}

var errNotOpen = Conflict("DUE_NOT_OPEN", "only an open due can be changed, waived or paid")

// ChangeAmount sets another amount (1..MaxAmountMinor) on an OPEN due, with a reason.
func (d Due) ChangeAmount(amountMinor int64, rawReason string, now time.Time) (Due, error) {
	var v violations
	amount, err := NewAmount(amountMinor)
	if err != nil {
		v.add("amountMinor", "OUT_OF_RANGE")
	}
	reason := checkReason(&v, "reason", rawReason)
	if err := v.err(); err != nil {
		return d, err
	}
	if d.Status != DueOpen {
		return d, errNotOpen
	}
	d.Amount, d.Reason, d.UpdatedAt = amount, &reason, now
	return d, nil
}

// Waive releases an OPEN due for good, with a reason (choice of ADR-0056: a waived due is final).
func (d Due) Waive(rawReason string, now time.Time) (Due, error) {
	reason, err := NewReason("reason", rawReason)
	if err != nil {
		return d, err
	}
	if d.Status != DueOpen {
		return d, errNotOpen
	}
	d.Status, d.Reason, d.UpdatedAt = DueWaived, &reason, now
	return d, nil
}

// PaymentInput is a payment as ADMIN records it.
type PaymentInput struct {
	PaidOn time.Time // a date (UTC midnight)
	Method string
	Note   *string
}

// Payment settles a due in full (decision 95). A voided payment is kept with when, by whom and why.
type Payment struct {
	ID         PaymentID
	Due        DueID
	Amount     Amount
	PaidOn     time.Time
	Method     PaymentMethod
	Note       *string
	RecordedBy PersonID
	RecordedAt time.Time
	VoidedAt   *time.Time
	VoidReason *string
	VoidedBy   *PersonID
}

// Pay records the payment of the whole amount of an OPEN due; the payment day may not lie after today (the academy's
// date). It returns the PAID due and the payment.
func (d Due) Pay(id PaymentID, input PaymentInput, by PersonID, today, now time.Time) (Due, Payment, error) {
	var v violations
	method, err := ParsePaymentMethod(input.Method)
	if err != nil {
		v.add("method", "INVALID")
	}
	var note *string
	if input.Note != nil {
		text := checkReason(&v, "note", *input.Note)
		note = &text
	}
	if err := v.err(); err != nil {
		return d, Payment{}, err
	}
	if d.Status != DueOpen {
		return d, Payment{}, errNotOpen
	}
	if input.PaidOn.After(today) {
		return d, Payment{}, RuleViolation("PAID_ON_IN_FUTURE", "the payment day lies after today")
	}
	payment := Payment{ID: id, Due: d.ID, Amount: d.Amount, PaidOn: input.PaidOn, Method: method, Note: note,
		RecordedBy: by, RecordedAt: now}
	d.Status, d.UpdatedAt = DuePaid, now
	return d, payment, nil
}

// Voided reports a voided payment.
func (p Payment) Voided() bool { return p.VoidedAt != nil }

// Void marks a wrong payment voided, with a reason; it stays recorded.
func (p Payment) Void(rawReason string, by PersonID, now time.Time) (Payment, error) {
	reason, err := NewReason("reason", rawReason)
	if err != nil {
		return p, err
	}
	if p.Voided() {
		return p, Conflict("PAYMENT_ALREADY_VOIDED", "the payment is voided already")
	}
	p.VoidedAt, p.VoidReason, p.VoidedBy = &now, &reason, &by
	return p, nil
}

// Reopen makes a PAID due OPEN again once its payment was voided.
func (d Due) Reopen(now time.Time) (Due, error) {
	if d.Status != DuePaid {
		return d, Conflict("DUE_NOT_PAID", "only a paid due is opened again")
	}
	d.Status, d.UpdatedAt = DueOpen, now
	return d, nil
}

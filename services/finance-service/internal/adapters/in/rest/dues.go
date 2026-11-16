package rest

import (
	"net/http"
	"regexp"
	"time"

	"hoopsacademy.local/finance/internal/application"
	"hoopsacademy.local/finance/internal/domain"
)

const (
	dues     = "/api/finance/dues"
	payments = "/api/finance/payments"
)

func (h *handler) dueRoutes(mux *http.ServeMux) {
	mux.HandleFunc("POST "+plans+"/{id}/dues:generate", h.api(plans+"/{feePlanId}/dues:generate", h.withPlan(h.generateDues)))
	mux.HandleFunc("GET "+dues, h.api(dues, h.listDues))
	mux.HandleFunc("GET "+dues+"/{id}", h.api(dues+"/{dueId}", withID("dueId", h.getDue)))
	mux.HandleFunc("POST "+dues+"/{target}", h.customMethod(dues, "dueId", map[string]idHandler{
		"change-amount": h.changeDueAmount, "waive": h.waiveDue, "pay": h.payDue,
	}))
	mux.HandleFunc("POST "+payments+"/{target}", h.customMethod(payments, "paymentId", map[string]idHandler{
		"void": h.voidPayment,
	}))
	mux.HandleFunc("GET /api/finance/teams/{id}/due-status",
		h.api("/api/finance/teams/{teamId}/due-status", withID("teamId", h.teamDueStatus)))
	mux.HandleFunc("GET /api/finance/players/{id}/dues",
		h.api("/api/finance/players/{playerId}/dues", withID("playerId", h.playerDues)))
}

// --- answers

type personRefDTO struct {
	PersonID    string `json:"personId"`
	DisplayName string `json:"displayName"`
}

func personRefOf(ref application.PersonRef) personRefDTO {
	return personRefDTO{PersonID: ref.Person.String(), DisplayName: ref.Name}
}

type paymentDTO struct {
	ID          string        `json:"id"`
	DueID       string        `json:"dueId"`
	AmountMinor int64         `json:"amountMinor"`
	PaidOn      string        `json:"paidOn"`
	Method      string        `json:"method"`
	Note        *string       `json:"note"`
	RecordedBy  personRefDTO  `json:"recordedBy"`
	RecordedAt  string        `json:"recordedAt"`
	Voided      bool          `json:"voided"`
	VoidedAt    *string       `json:"voidedAt"`
	VoidReason  *string       `json:"voidReason"`
	VoidedBy    *personRefDTO `json:"voidedBy"`
}

func paymentOf(record application.PaymentRecord) paymentDTO {
	p := record.Payment
	dto := paymentDTO{
		ID: p.ID.String(), DueID: p.Due.String(), AmountMinor: p.Amount.Minor(), PaidOn: day(p.PaidOn),
		Method: string(p.Method), Note: p.Note, RecordedBy: personRefOf(record.RecordedBy),
		RecordedAt: instant(p.RecordedAt), Voided: p.Voided(), VoidReason: p.VoidReason,
	}
	if p.VoidedAt != nil {
		at := instant(*p.VoidedAt)
		dto.VoidedAt = &at
	}
	if record.VoidedBy != nil {
		by := personRefOf(*record.VoidedBy)
		dto.VoidedBy = &by
	}
	return dto
}

type dueDTO struct {
	ID              string      `json:"id"`
	FeePlanID       string      `json:"feePlanId"`
	FeePlanName     string      `json:"feePlanName"`
	PlayerID        string      `json:"playerId"`
	PlayerName      string      `json:"playerName"`
	TeamID          string      `json:"teamId"`
	Period          string      `json:"period"`
	PeriodStart     string      `json:"periodStart"`
	PeriodEnd       string      `json:"periodEnd"`
	AmountMinor     int64       `json:"amountMinor"`
	PlanAmountMinor int64       `json:"planAmountMinor"`
	Currency        string      `json:"currency"`
	Status          string      `json:"status"`
	Reason          *string     `json:"reason"`
	Payment         *paymentDTO `json:"payment"`
	CreatedAt       string      `json:"createdAt"`
	UpdatedAt       string      `json:"updatedAt"`
}

func dueOf(record application.DueRecord, currency domain.Currency) dueDTO {
	d := record.Due
	dto := dueDTO{
		ID: d.ID.String(), FeePlanID: d.Plan.String(), FeePlanName: record.PlanName, PlayerID: d.Player.String(),
		PlayerName: record.PlayerName, TeamID: d.Team.String(), Period: d.Period, PeriodStart: day(d.Start),
		PeriodEnd: day(d.End), AmountMinor: d.Amount.Minor(), PlanAmountMinor: d.PlanAmount.Minor(),
		Currency: currency.Code(), Status: string(d.Status), Reason: d.Reason, CreatedAt: instant(d.CreatedAt),
		UpdatedAt: instant(d.UpdatedAt),
	}
	if record.Payment != nil {
		payment := paymentOf(*record.Payment)
		dto.Payment = &payment
	}
	return dto
}

type dueDetailDTO struct {
	dueDTO
	Payments []paymentDTO `json:"payments"`
}

// playerDueDTO is a due as the family sees it: no reasons, notes or voided payments (decision 96, P-12).
type playerDueDTO struct {
	ID            string  `json:"id"`
	FeePlanName   string  `json:"feePlanName"`
	Period        string  `json:"period"`
	PeriodStart   string  `json:"periodStart"`
	PeriodEnd     string  `json:"periodEnd"`
	AmountMinor   int64   `json:"amountMinor"`
	Currency      string  `json:"currency"`
	Status        string  `json:"status"`
	PaidOn        *string `json:"paidOn"`
	PaymentMethod *string `json:"paymentMethod"`
}

func playerDueOf(record application.DueRecord, currency domain.Currency) playerDueDTO {
	d := record.Due
	dto := playerDueDTO{
		ID: d.ID.String(), FeePlanName: record.PlanName, Period: d.Period, PeriodStart: day(d.Start), PeriodEnd: day(d.End),
		AmountMinor: d.Amount.Minor(), Currency: currency.Code(), Status: string(d.Status),
	}
	if record.Payment != nil {
		paidOn, method := day(record.Payment.Payment.PaidOn), string(record.Payment.Payment.Method)
		dto.PaidOn, dto.PaymentMethod = &paidOn, &method
	}
	return dto
}

func day(t time.Time) string { return t.Format(time.DateOnly) }

// --- generation

type generatedDueDTO struct {
	DueID       *string `json:"dueId"`
	PlayerID    string  `json:"playerId"`
	PlayerName  string  `json:"playerName"`
	TeamID      string  `json:"teamId"`
	AmountMinor int64   `json:"amountMinor"`
}

func (h *handler) generateDues(w http.ResponseWriter, r *http.Request, caller domain.Membership, id domain.FeePlanID) {
	var body struct {
		Period  *string `json:"period"`
		Preview *bool   `json:"preview"`
	}
	if !decode(w, r, &body) {
		return
	}
	if body.Period == nil {
		writeProblem(w, r, validation, "VALIDATION_FAILED", "", []violation{{"period", "REQUIRED", messageOf("REQUIRED")}})
		return
	}
	preview := body.Preview != nil && *body.Preview
	generation, err := h.Finance.GenerateDues(r.Context(), caller, id, *body.Period, preview)
	if err != nil {
		h.writeError(w, r, err)
		return
	}
	created := make([]generatedDueDTO, len(generation.Created))
	for i, g := range generation.Created {
		created[i] = generatedDueDTO{PlayerID: g.Due.Player.String(), PlayerName: g.PlayerName, TeamID: g.Due.Team.String(),
			AmountMinor: g.Due.Amount.Minor()}
		if !preview {
			dueID := g.Due.ID.String()
			created[i].DueID = &dueID
		}
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"feePlanId": id.String(), "period": generation.Window.Period.Key(), "periodStart": day(generation.Window.Start),
		"periodEnd": day(generation.Window.End), "preview": preview, "created": len(created),
		"existing": generation.Existing, "dues": created,
	})
}

// --- reads

var periodKey = regexp.MustCompile(`^([0-9]{4}-(0[1-9]|1[0-2])|[0-9]{4}-Q[1-4]|SEASON)$`)

func (h *handler) listDues(w http.ResponseWriter, r *http.Request, caller domain.Membership) {
	q := newQuery(r)
	filter := application.DueFilter{
		Plan: typed[domain.FeePlanID](q.uuid("feePlanId")), Team: typed[domain.TeamID](q.uuid("teamId")),
		Player: typed[domain.PlayerID](q.uuid("playerId")), Season: typed[domain.SeasonID](q.uuid("seasonId")),
		From: q.date("from"), To: q.date("to"),
	}
	if period := q.values.Get("period"); period != "" {
		if !periodKey.MatchString(period) {
			q.invalid("period")
		}
		filter.Period = &period
	}
	if raw := q.values.Get("status"); raw != "" {
		if status, err := domain.ParseDueStatus(raw); err != nil {
			q.invalid("status")
		} else {
			filter.Status = &status
		}
	}
	page := q.page()
	if q.failed(w, r) {
		return
	}
	result, err := h.Finance.ListDues(r.Context(), caller, filter, page)
	if err != nil {
		h.writeError(w, withCaller(r, caller), err)
		return
	}
	items := make([]dueDTO, len(result.Items))
	for i, record := range result.Items {
		items[i] = dueOf(record, *result.Currency)
	}
	writeJSON(w, http.StatusOK, map[string]any{"items": items, "page": pageOf(page, result.Total)})
}

// typed converts an optional uuid to an id type.
func typed[T ~[16]byte](id *domain.UUID) *T {
	if id == nil {
		return nil
	}
	value := T(*id)
	return &value
}

func (h *handler) getDue(w http.ResponseWriter, r *http.Request, caller domain.Membership, id domain.UUID) {
	detail, err := h.Finance.Due(r.Context(), caller, domain.DueID(id))
	if err != nil {
		h.writeError(w, r, err)
		return
	}
	payments := make([]paymentDTO, len(detail.Payments))
	for i, p := range detail.Payments {
		payments[i] = paymentOf(p)
	}
	writeJSON(w, http.StatusOK, dueDetailDTO{dueDTO: dueOf(detail.DueRecord, detail.Currency), Payments: payments})
}

func (h *handler) teamDueStatus(w http.ResponseWriter, r *http.Request, caller domain.Membership, id domain.UUID) {
	statuses, err := h.Finance.TeamDueStatus(r.Context(), caller, domain.TeamID(id))
	if err != nil {
		h.writeError(w, r, err)
		return
	}
	type playerStatusDTO struct {
		PlayerID   string `json:"playerId"`
		PlayerName string `json:"playerName"`
		UpToDate   bool   `json:"upToDate"`
	}
	players := make([]playerStatusDTO, len(statuses))
	for i, s := range statuses {
		players[i] = playerStatusDTO{PlayerID: s.Player.String(), PlayerName: s.Name, UpToDate: s.UpToDate}
	}
	writeJSON(w, http.StatusOK, map[string]any{"teamId": domain.TeamID(id).String(), "players": players})
}

func (h *handler) playerDues(w http.ResponseWriter, r *http.Request, caller domain.Membership, id domain.UUID) {
	q := newQuery(r)
	page := q.page()
	if q.failed(w, r) {
		return
	}
	result, err := h.Finance.PlayerDues(r.Context(), caller, domain.PlayerID(id), page)
	if err != nil {
		h.writeError(w, r, err)
		return
	}
	items := make([]playerDueDTO, len(result.Items))
	for i, record := range result.Items {
		items[i] = playerDueOf(record, *result.Currency)
	}
	writeJSON(w, http.StatusOK, map[string]any{"items": items, "page": pageOf(page, result.Total)})
}

// --- writes

func (h *handler) answerDue(w http.ResponseWriter, r *http.Request, view application.DueView, err error) {
	if err != nil {
		h.writeError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, dueOf(view.DueRecord, view.Currency))
}

// reasonOf reads a ReasonRequest's reason (400 when absent).
func reasonOf(w http.ResponseWriter, r *http.Request) (string, bool) {
	var body struct {
		Reason *string `json:"reason"`
	}
	if !decode(w, r, &body) {
		return "", false
	}
	if body.Reason == nil {
		writeProblem(w, r, validation, "VALIDATION_FAILED", "", []violation{{"reason", "REQUIRED", messageOf("REQUIRED")}})
		return "", false
	}
	return *body.Reason, true
}

func (h *handler) changeDueAmount(w http.ResponseWriter, r *http.Request, caller domain.Membership, id domain.UUID) {
	var body struct {
		AmountMinor *int64  `json:"amountMinor"`
		Reason      *string `json:"reason"`
	}
	if !decode(w, r, &body) {
		return
	}
	if v := required(map[string]bool{"amountMinor": body.AmountMinor != nil, "reason": body.Reason != nil}); len(v) > 0 {
		writeProblem(w, r, validation, "VALIDATION_FAILED", "", v)
		return
	}
	view, err := h.Finance.ChangeDueAmount(r.Context(), caller, domain.DueID(id), *body.AmountMinor, *body.Reason)
	h.answerDue(w, r, view, err)
}

func (h *handler) waiveDue(w http.ResponseWriter, r *http.Request, caller domain.Membership, id domain.UUID) {
	if reason, ok := reasonOf(w, r); ok {
		view, err := h.Finance.WaiveDue(r.Context(), caller, domain.DueID(id), reason)
		h.answerDue(w, r, view, err)
	}
}

func (h *handler) payDue(w http.ResponseWriter, r *http.Request, caller domain.Membership, id domain.UUID) {
	var body struct {
		PaidOn *string `json:"paidOn"`
		Method *string `json:"method"`
		Note   *string `json:"note"`
	}
	if !decode(w, r, &body) {
		return
	}
	v := required(map[string]bool{"paidOn": body.PaidOn != nil, "method": body.Method != nil})
	var paidOn time.Time
	if body.PaidOn != nil {
		var err error
		if paidOn, err = time.Parse(time.DateOnly, *body.PaidOn); err != nil {
			v = append(v, violation{"paidOn", "INVALID", messageOf("INVALID")})
		}
	}
	if len(v) > 0 {
		writeProblem(w, r, validation, "VALIDATION_FAILED", "", v)
		return
	}
	view, err := h.Finance.PayDue(r.Context(), caller, domain.DueID(id),
		domain.PaymentInput{PaidOn: paidOn, Method: *body.Method, Note: body.Note})
	h.answerDue(w, r, view, err)
}

func (h *handler) voidPayment(w http.ResponseWriter, r *http.Request, caller domain.Membership, id domain.UUID) {
	if reason, ok := reasonOf(w, r); ok {
		view, err := h.Finance.VoidPayment(r.Context(), caller, domain.PaymentID(id), reason)
		h.answerDue(w, r, view, err)
	}
}

// required names the absent properties of present (field -> given), in the order of the contract's lists.
func required(present map[string]bool) []violation {
	var v []violation
	for _, field := range []string{"period", "amountMinor", "reason", "paidOn", "method"} {
		if given, asked := present[field]; asked && !given {
			v = append(v, violation{field, "REQUIRED", messageOf("REQUIRED")})
		}
	}
	return v
}

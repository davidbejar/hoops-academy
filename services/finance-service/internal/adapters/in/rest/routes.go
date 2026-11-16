package rest

import (
	"net/http"
	"strings"
	"time"

	"hoopsacademy.local/finance/internal/application"
	"hoopsacademy.local/finance/internal/domain"
)

const plans = "/api/finance/fee-plans"

func (h *handler) routes(mux *http.ServeMux) {
	mux.HandleFunc("GET /api/finance/settings", h.api("/api/finance/settings", h.getSettings))
	mux.HandleFunc("PUT /api/finance/settings", h.api("/api/finance/settings", h.putSettings))
	mux.HandleFunc("GET "+plans, h.api(plans, h.listPlans))
	mux.HandleFunc("POST "+plans, h.api(plans, h.createPlan))
	mux.HandleFunc("GET "+plans+"/{id}", h.api(plans+"/{feePlanId}", h.withPlan(h.getPlan)))
	mux.HandleFunc("PATCH "+plans+"/{id}", h.api(plans+"/{feePlanId}", h.withPlan(h.patchPlan)))
	mux.HandleFunc("DELETE "+plans+"/{id}", h.api(plans+"/{feePlanId}", h.withPlan(h.deletePlan)))
	// custom methods "<id>:archive" / "<id>:unarchive" are one path segment
	mux.HandleFunc("POST "+plans+"/{target}", h.customMethod(plans, "feePlanId", map[string]idHandler{
		"archive": asPlan(h.archivePlan), "unarchive": asPlan(h.unarchivePlan),
	}))
	h.dueRoutes(mux)
	h.notImplementedRoutes(mux)
}

type planHandler func(w http.ResponseWriter, r *http.Request, caller domain.Membership, id domain.FeePlanID)

// idHandler serves an operation on the resource of a uuid path parameter.
type idHandler func(w http.ResponseWriter, r *http.Request, caller domain.Membership, id domain.UUID)

func asPlan(serve planHandler) idHandler {
	return func(w http.ResponseWriter, r *http.Request, caller domain.Membership, id domain.UUID) {
		serve(w, r, caller, domain.FeePlanID(id))
	}
}

func (h *handler) withPlan(serve planHandler) memberHandler {
	return withID("feePlanId", asPlan(serve))
}

// withID reads the path parameter {id} (named param in the contract; 400 when not a uuid).
func withID(param string, serve idHandler) memberHandler {
	return func(w http.ResponseWriter, r *http.Request, caller domain.Membership) {
		if id, ok := pathID(w, r, r.PathValue("id"), param); ok {
			serve(w, withCaller(r, caller), caller, id)
		}
	}
}

// customMethod routes "<uuid>:<verb>" of a POST to the verb's handler; an unknown verb is 404.
func (h *handler) customMethod(base, param string, verbs map[string]idHandler) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		raw, verb, found := strings.Cut(r.PathValue("target"), ":")
		serve, known := verbs[verb]
		if !found || !known {
			writeProblem(w, r, notFound, "", "", nil)
			return
		}
		h.api(base+"/{"+param+"}:"+verb, func(w http.ResponseWriter, r *http.Request, caller domain.Membership) {
			if id, ok := pathID(w, r, raw, param); ok {
				serve(w, withCaller(r, caller), caller, id)
			}
		})(w, r)
	}
}

// --- settings

type settingsDTO struct {
	Currency       *string `json:"currency"`
	MinorDigits    *int    `json:"minorDigits"`
	CurrencyLocked bool    `json:"currencyLocked"`
}

func settingsOf(view application.SettingsView) settingsDTO {
	dto := settingsDTO{CurrencyLocked: view.Locked}
	if view.Currency != nil {
		code, digits := view.Currency.Code(), view.Currency.MinorDigits()
		dto.Currency, dto.MinorDigits = &code, &digits
	}
	return dto
}

func (h *handler) getSettings(w http.ResponseWriter, r *http.Request, caller domain.Membership) {
	view, err := h.Finance.Settings(r.Context(), caller)
	if err != nil {
		h.writeError(w, withCaller(r, caller), err)
		return
	}
	writeJSON(w, http.StatusOK, settingsOf(view))
}

func (h *handler) putSettings(w http.ResponseWriter, r *http.Request, caller domain.Membership) {
	var body struct {
		Currency *string `json:"currency"`
	}
	if !decode(w, r, &body) {
		return
	}
	if body.Currency == nil {
		writeProblem(w, r, validation, "VALIDATION_FAILED", "", []violation{{"currency", "REQUIRED", messageOf("REQUIRED")}})
		return
	}
	view, err := h.Finance.UpdateSettings(r.Context(), caller, *body.Currency)
	if err != nil {
		h.writeError(w, withCaller(r, caller), err)
		return
	}
	writeJSON(w, http.StatusOK, settingsOf(view))
}

// --- fee plans

type feePlanDTO struct {
	ID            string  `json:"id"`
	Name          string  `json:"name"`
	SeasonID      string  `json:"seasonId"`
	TeamID        *string `json:"teamId"`
	AgeCategoryID *string `json:"ageCategoryId"`
	AmountMinor   int64   `json:"amountMinor"`
	Currency      string  `json:"currency"`
	Cadence       string  `json:"cadence"`
	FirstPeriod   *string `json:"firstPeriod"`
	LastPeriod    *string `json:"lastPeriod"`
	AutoGenerate  bool    `json:"autoGenerate"`
	Archived      bool    `json:"archived"`
	HasDues       bool    `json:"hasDues"`
	CreatedAt     string  `json:"createdAt"`
	UpdatedAt     string  `json:"updatedAt"`
}

func feePlanOf(view application.FeePlanView) feePlanDTO {
	p := view.Plan
	dto := feePlanDTO{
		ID: p.ID.String(), Name: p.Name, SeasonID: p.Season.String(), AmountMinor: p.Amount.Minor(),
		Currency: view.Currency.Code(), Cadence: string(p.Cadence), AutoGenerate: p.AutoGenerate, Archived: p.Archived,
		HasDues: view.HasDues, CreatedAt: instant(p.CreatedAt), UpdatedAt: instant(p.UpdatedAt),
	}
	if p.Target.Team != nil {
		team := p.Target.Team.String()
		dto.TeamID = &team
	}
	if p.Target.AgeCategory != nil {
		category := p.Target.AgeCategory.String()
		dto.AgeCategoryID = &category
	}
	if p.First != nil {
		first := p.First.Key()
		dto.FirstPeriod = &first
	}
	if p.Last != nil {
		last := p.Last.Key()
		dto.LastPeriod = &last
	}
	return dto
}

func instant(t time.Time) string { return t.UTC().Format(time.RFC3339Nano) }

type pageDTO struct {
	Page          int   `json:"page"`
	Size          int   `json:"size"`
	TotalElements int64 `json:"totalElements"`
	TotalPages    int64 `json:"totalPages"`
}

func pageOf(page application.Page, total int64) pageDTO {
	size := int64(page.Size)
	return pageDTO{Page: page.Index, Size: page.Size, TotalElements: total, TotalPages: (total + size - 1) / size}
}

func (h *handler) listPlans(w http.ResponseWriter, r *http.Request, caller domain.Membership) {
	q := newQuery(r)
	filter := application.FeePlanFilter{IncludeArchived: q.boolean("includeArchived")}
	if id := q.uuid("seasonId"); id != nil {
		season := domain.SeasonID(*id)
		filter.Season = &season
	}
	if id := q.uuid("teamId"); id != nil {
		team := domain.TeamID(*id)
		filter.Team = &team
	}
	if id := q.uuid("ageCategoryId"); id != nil {
		category := domain.AgeCategoryID(*id)
		filter.AgeCategory = &category
	}
	page := q.page()
	if q.failed(w, r) {
		return
	}
	result, err := h.Finance.ListFeePlans(r.Context(), caller, filter, page)
	if err != nil {
		h.writeError(w, withCaller(r, caller), err)
		return
	}
	items := make([]feePlanDTO, len(result.Items))
	for i, view := range result.Items {
		items[i] = feePlanOf(view)
	}
	writeJSON(w, http.StatusOK, map[string]any{"items": items, "page": pageOf(page, result.Total)})
}

type createPlanBody struct {
	Name          *string `json:"name"`
	SeasonID      *string `json:"seasonId"`
	TeamID        *string `json:"teamId"`
	AgeCategoryID *string `json:"ageCategoryId"`
	AmountMinor   *int64  `json:"amountMinor"`
	Cadence       *string `json:"cadence"`
	FirstPeriod   *string `json:"firstPeriod"`
	LastPeriod    *string `json:"lastPeriod"`
	AutoGenerate  *bool   `json:"autoGenerate"`
}

func (h *handler) createPlan(w http.ResponseWriter, r *http.Request, caller domain.Membership) {
	var body createPlanBody
	if !decode(w, r, &body) {
		return
	}
	input, violations := body.input()
	if len(violations) > 0 {
		writeProblem(w, r, validation, "VALIDATION_FAILED", "", violations)
		return
	}
	view, err := h.Finance.CreateFeePlan(r.Context(), caller, application.FeePlanCommand{Input: input})
	if err != nil {
		h.writeError(w, withCaller(r, caller), err)
		return
	}
	w.Header().Set("Location", plans+"/"+view.Plan.ID.String())
	writeJSON(w, http.StatusCreated, feePlanOf(view))
}

// input checks what the domain cannot: presence and the uuid format of the ids.
func (b createPlanBody) input() (domain.FeePlanInput, []violation) {
	var v []violation
	required := func(field string, present bool) {
		if !present {
			v = append(v, violation{field, "REQUIRED", messageOf("REQUIRED")})
		}
	}
	required("name", b.Name != nil)
	required("seasonId", b.SeasonID != nil)
	required("amountMinor", b.AmountMinor != nil)
	required("cadence", b.Cadence != nil)
	optionalID := func(field string, raw *string) *domain.UUID {
		if raw == nil {
			return nil
		}
		id, err := domain.ParseUUID(*raw)
		if err != nil {
			v = append(v, violation{field, "INVALID", messageOf("INVALID")})
			return nil
		}
		return &id
	}
	season, team, category := optionalID("seasonId", b.SeasonID), optionalID("teamId", b.TeamID),
		optionalID("ageCategoryId", b.AgeCategoryID)
	if len(v) > 0 {
		return domain.FeePlanInput{}, v
	}
	input := domain.FeePlanInput{
		Name: *b.Name, Season: domain.SeasonID(*season), AmountMinor: *b.AmountMinor, Cadence: *b.Cadence,
		FirstPeriod: b.FirstPeriod, LastPeriod: b.LastPeriod, AutoGenerate: b.AutoGenerate == nil || *b.AutoGenerate,
	}
	if team != nil {
		id := domain.TeamID(*team)
		input.Team = &id
	}
	if category != nil {
		id := domain.AgeCategoryID(*category)
		input.AgeCategory = &id
	}
	return input, nil
}

func (h *handler) getPlan(w http.ResponseWriter, r *http.Request, caller domain.Membership, id domain.FeePlanID) {
	view, err := h.Finance.FeePlan(r.Context(), caller, id)
	h.answerPlan(w, r, view, err)
}

func (h *handler) answerPlan(w http.ResponseWriter, r *http.Request, view application.FeePlanView, err error) {
	if err != nil {
		h.writeError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, feePlanOf(view))
}

func (h *handler) patchPlan(w http.ResponseWriter, r *http.Request, caller domain.Membership, id domain.FeePlanID) {
	var body map[string]jsonRaw
	if !decode(w, r, &body) {
		return
	}
	changes, violations := planChanges(body)
	if len(violations) > 0 {
		writeProblem(w, r, validation, "VALIDATION_FAILED", "", violations)
		return
	}
	view, err := h.Finance.UpdateFeePlan(r.Context(), caller, id, changes)
	h.answerPlan(w, r, view, err)
}

func (h *handler) archivePlan(w http.ResponseWriter, r *http.Request, caller domain.Membership, id domain.FeePlanID) {
	view, err := h.Finance.ArchiveFeePlan(r.Context(), caller, id)
	h.answerPlan(w, r, view, err)
}

func (h *handler) unarchivePlan(w http.ResponseWriter, r *http.Request, caller domain.Membership, id domain.FeePlanID) {
	view, err := h.Finance.UnarchiveFeePlan(r.Context(), caller, id)
	h.answerPlan(w, r, view, err)
}

func (h *handler) deletePlan(w http.ResponseWriter, r *http.Request, caller domain.Membership, id domain.FeePlanID) {
	if err := h.Finance.DeleteFeePlan(r.Context(), caller, id); err != nil {
		h.writeError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

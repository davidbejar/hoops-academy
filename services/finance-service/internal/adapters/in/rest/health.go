package rest

import (
	"context"
	"net/http"
	"time"
)

type check struct {
	Name   string `json:"name"`
	Status string `json:"status"`
}

type healthDTO struct {
	Status string  `json:"status"`
	Checks []check `json:"checks"`
}

// health serves /q/health{,/live,/ready,/started} like SmallRye Health (the chart's probes) and /q/metrics. Never
// routed by the gateway; no tenant data.
func (h *handler) health(mux *http.ServeMux) {
	live := func(w http.ResponseWriter, _ *http.Request) {
		writeJSON(w, http.StatusOK, healthDTO{Status: "UP", Checks: []check{}})
	}
	ready := func(w http.ResponseWriter, r *http.Request) {
		checks := []check{{Name: "database", Status: "UP"}}
		if h.Ready != nil {
			ctx, cancel := context.WithTimeout(r.Context(), 2*time.Second)
			defer cancel()
			if err := h.Ready(ctx); err != nil {
				checks[0].Status = "DOWN"
				writeJSON(w, http.StatusServiceUnavailable, healthDTO{Status: "DOWN", Checks: checks})
				return
			}
		}
		writeJSON(w, http.StatusOK, healthDTO{Status: "UP", Checks: checks})
	}
	mux.HandleFunc("GET /q/health/live", live)
	mux.HandleFunc("GET /q/health/started", live)
	mux.HandleFunc("GET /q/health/ready", ready)
	mux.HandleFunc("GET /q/health", ready)
	mux.HandleFunc("GET /q/metrics", func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("Content-Type", "text/plain; version=0.0.4; charset=utf-8")
		h.Security.WriteMetrics(w)
		if h.Metrics != nil {
			h.Metrics(w)
		}
	})
}

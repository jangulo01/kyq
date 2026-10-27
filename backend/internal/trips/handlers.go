package trips

import (
	"errors"
	"net/http"
	"time"

	"github.com/google/uuid"

	"github.com/kyq/backend/internal/auth"
	"github.com/kyq/backend/internal/fares"
	"github.com/kyq/backend/internal/httpx"
	"github.com/kyq/backend/internal/store"
)

// Handlers serves /v1/fares/quote, /v1/trips/* and /v1/admin/fare-tables/*.
type Handlers struct{ Service *Service }

// Register mounts the routes. Party and role checks per action live in the Trip aggregate;
// non-participants get 404 (contracts/api.yaml).
func (h *Handlers) Register(mux *http.ServeMux, authMW func(http.Handler) http.Handler) {
	authed := func(f http.HandlerFunc) http.Handler { return authMW(f) }
	passenger := func(f http.HandlerFunc) http.Handler { return authMW(auth.RequireRole(auth.RolePassenger)(f)) }
	admin := func(f http.HandlerFunc) http.Handler { return authMW(auth.RequireRole(auth.RoleAdmin)(f)) }

	mux.Handle("PUT /v1/admin/fare-tables/{cityCode}", admin(h.putFareTable))
	mux.Handle("POST /v1/fares/quote", passenger(h.quote))
	mux.Handle("POST /v1/trips", passenger(h.request))
	mux.Handle("GET /v1/trips/active", authed(h.active))
	mux.Handle("GET /v1/trips/{tripId}", authed(h.get))

	act := func(op func(r *http.Request) (func(t *Trip, p Party, now time.Time) error, bool)) http.Handler {
		return authed(func(w http.ResponseWriter, r *http.Request) {
			fn, ok := op(r)
			if !ok {
				httpx.WriteError(w, http.StatusBadRequest, "invalid_body", "cuerpo inválido")
				return
			}
			h.act(w, r, fn)
		})
	}
	simple := func(fn func(t *Trip, p Party, now time.Time) error) http.Handler {
		return act(func(*http.Request) (func(*Trip, Party, time.Time) error, bool) { return fn, true })
	}

	mux.Handle("POST /v1/trips/{tripId}/accept", authed(h.accept))
	mux.Handle("POST /v1/trips/{tripId}/reject", simple((*Trip).Reject))
	mux.Handle("POST /v1/trips/{tripId}/negotiation", simple((*Trip).RequestNegotiation))
	mux.Handle("POST /v1/trips/{tripId}/negotiation/response", authed(h.negotiationResponse))
	mux.Handle("POST /v1/trips/{tripId}/proposals", authed(h.propose))
	mux.Handle("POST /v1/trips/{tripId}/proposals/{proposalId}/accept", authed(h.decide(true)))
	mux.Handle("POST /v1/trips/{tripId}/proposals/{proposalId}/reject", authed(h.decide(false)))
	mux.Handle("POST /v1/trips/{tripId}/arrive", simple((*Trip).Arrive))
	mux.Handle("POST /v1/trips/{tripId}/start", simple((*Trip).Start))
	mux.Handle("POST /v1/trips/{tripId}/complete", simple((*Trip).Complete))
	mux.Handle("POST /v1/trips/{tripId}/cancel", simple((*Trip).Cancel))
}

// ProposalView is contracts/api.yaml#FareProposal.
type ProposalView struct {
	ID          uuid.UUID      `json:"id"`
	ProposedBy  Party          `json:"proposed_by"`
	AmountMinor int64          `json:"amount_minor"`
	Status      ProposalStatus `json:"status"`
	ExpiresAt   time.Time      `json:"expires_at"`
}

// View is contracts/api.yaml#Trip.
type View struct {
	ID                      uuid.UUID     `json:"id"`
	Status                  Status        `json:"status"`
	PassengerID             uuid.UUID     `json:"passenger_id"`
	DriverID                uuid.UUID     `json:"driver_id"`
	Pickup                  Point         `json:"pickup"`
	Dropoff                 Point         `json:"dropoff"`
	DistanceM               int32         `json:"distance_m"`
	DurationS               int32         `json:"duration_s"`
	Currency                string        `json:"currency"`
	SuggestedFareMinor      int64         `json:"suggested_fare_minor"`
	AgreedFareMinor         *int64        `json:"agreed_fare_minor"`
	DriverPayoutMinor       *int64        `json:"driver_payout_minor"`
	PlatformCommissionMinor int64         `json:"platform_commission_minor"`
	OpenProposal            *ProposalView `json:"open_proposal"`
	OfferExpiresAt          *time.Time    `json:"offer_expires_at"`
	NegotiationExpiresAt    *time.Time    `json:"negotiation_expires_at"`
	CancelReason            *string       `json:"cancel_reason"`
}

func viewOf(t *Trip) View {
	v := View{
		ID: t.ID, Status: t.Status, PassengerID: t.PassengerID, DriverID: t.DriverID, Pickup: t.Pickup, Dropoff: t.Dropoff,
		DistanceM: t.DistanceM, DurationS: t.DurationS, Currency: t.Currency, SuggestedFareMinor: t.SuggestedFare,
		AgreedFareMinor: t.AgreedFare, DriverPayoutMinor: t.DriverPayout, PlatformCommissionMinor: 0,
		OfferExpiresAt: t.RespondBy, NegotiationExpiresAt: t.NegotiationExpiresAt, CancelReason: t.CancelReason,
	}
	if p := t.Proposal; p != nil {
		v.OpenProposal = &ProposalView{ID: p.ID, ProposedBy: p.ProposedBy, AmountMinor: p.Amount, Status: p.Status, ExpiresAt: p.ExpiresAt}
	}
	return v
}

func (h *Handlers) putFareTable(w http.ResponseWriter, r *http.Request) {
	var body fares.Table
	if !httpx.DecodeJSON(w, r, &body) {
		return
	}
	if body.RoundingMinor == 0 {
		body.RoundingMinor = 1
	}
	if err := body.Validate(); err != nil {
		httpx.WriteError(w, http.StatusBadRequest, "invalid_fare_table", err.Error())
		return
	}
	admin, _ := auth.FromContext(r.Context())
	err := h.Service.Store.UpsertFareTable(r.Context(), store.UpsertFareTableParams{
		CityCode: r.PathValue("cityCode"), Currency: body.Currency, BaseMinor: body.BaseMinor, PerKmMinor: body.PerKmMinor,
		PerMinuteMinor: body.PerMinuteMinor, MinimumMinor: body.MinimumMinor, RoundingMinor: body.RoundingMinor, UpdatedBy: admin.UserID,
	})
	if err != nil {
		httpx.InternalError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, body)
}

type routeBody struct {
	Pickup  *Point `json:"pickup"`
	Dropoff *Point `json:"dropoff"`
}

func (b routeBody) valid() bool {
	ok := func(p *Point) bool { return p != nil && p.Lat >= -90 && p.Lat <= 90 && p.Lng >= -180 && p.Lng <= 180 }
	return ok(b.Pickup) && ok(b.Dropoff)
}

func (h *Handlers) quote(w http.ResponseWriter, r *http.Request) {
	var body routeBody
	if !httpx.DecodeJSON(w, r, &body) {
		return
	}
	if !body.valid() {
		httpx.WriteError(w, http.StatusBadRequest, "invalid_route", "indica origen y destino válidos")
		return
	}
	table, route, fare, err := h.Service.Quote(r.Context(), *body.Pickup, *body.Dropoff)
	if err != nil {
		writeError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, map[string]any{
		"distance_m": route.DistanceM, "duration_s": route.DurationS, "suggested_fare_minor": fare, "currency": table.Currency,
	})
}

func (h *Handlers) request(w http.ResponseWriter, r *http.Request) {
	var body struct {
		routeBody
		DriverID uuid.UUID `json:"driver_id"`
	}
	if !httpx.DecodeJSON(w, r, &body) {
		return
	}
	if !body.valid() || body.DriverID == uuid.Nil {
		httpx.WriteError(w, http.StatusBadRequest, "invalid_route", "indica conductor, origen y destino válidos")
		return
	}
	p, _ := auth.FromContext(r.Context())
	trip, err := h.Service.Request(r.Context(), p.UserID, body.DriverID, *body.Pickup, *body.Dropoff)
	if err != nil {
		writeError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusCreated, viewOf(trip))
}

func (h *Handlers) active(w http.ResponseWriter, r *http.Request) {
	p, _ := auth.FromContext(r.Context())
	trip, err := h.Service.Active(r.Context(), p.UserID, p.Role == auth.RoleDriver)
	if errors.Is(err, ErrNotFound) {
		w.WriteHeader(http.StatusNoContent)
		return
	}
	if err != nil {
		writeError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, viewOf(trip))
}

func (h *Handlers) get(w http.ResponseWriter, r *http.Request) {
	id, ok := tripID(w, r)
	if !ok {
		return
	}
	p, _ := auth.FromContext(r.Context())
	trip, err := h.Service.Get(r.Context(), p.UserID, id)
	if err != nil {
		writeError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, viewOf(trip))
}

func (h *Handlers) act(w http.ResponseWriter, r *http.Request, op func(t *Trip, p Party, now time.Time) error) {
	id, ok := tripID(w, r)
	if !ok {
		return
	}
	p, _ := auth.FromContext(r.Context())
	trip, err := h.Service.Act(r.Context(), p.UserID, id, op)
	if err != nil {
		writeError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, viewOf(trip))
}

func (h *Handlers) accept(w http.ResponseWriter, r *http.Request) {
	var body struct {
		FareMinor *int64 `json:"fare_minor"`
	}
	if r.ContentLength != 0 && !httpx.DecodeJSON(w, r, &body) {
		return
	}
	h.act(w, r, func(t *Trip, p Party, now time.Time) error { return t.Accept(p, body.FareMinor, now) })
}

func (h *Handlers) negotiationResponse(w http.ResponseWriter, r *http.Request) {
	var body struct {
		Accept *bool `json:"accept"`
	}
	if !httpx.DecodeJSON(w, r, &body) {
		return
	}
	if body.Accept == nil {
		httpx.WriteError(w, http.StatusBadRequest, "invalid_body", "indica accept true o false")
		return
	}
	h.act(w, r, func(t *Trip, p Party, now time.Time) error { return t.RespondNegotiation(p, *body.Accept, now) })
}

func (h *Handlers) propose(w http.ResponseWriter, r *http.Request) {
	var body struct {
		AmountMinor int64 `json:"amount_minor"`
	}
	if !httpx.DecodeJSON(w, r, &body) {
		return
	}
	id, ok := tripID(w, r)
	if !ok {
		return
	}
	p, _ := auth.FromContext(r.Context())
	var proposal *Proposal
	_, err := h.Service.Act(r.Context(), p.UserID, id, func(t *Trip, party Party, now time.Time) error {
		var err error
		proposal, err = t.Propose(party, body.AmountMinor, now)
		return err
	})
	if err != nil {
		writeError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusCreated, ProposalView{
		ID: proposal.ID, ProposedBy: proposal.ProposedBy, AmountMinor: proposal.Amount, Status: proposal.Status, ExpiresAt: proposal.ExpiresAt,
	})
}

func (h *Handlers) decide(accept bool) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		proposalID, err := uuid.Parse(r.PathValue("proposalId"))
		if err != nil {
			httpx.WriteError(w, http.StatusConflict, "no_open_proposal", "esa propuesta ya no está abierta")
			return
		}
		h.act(w, r, func(t *Trip, p Party, now time.Time) error { return t.DecideProposal(p, proposalID, accept, now) })
	}
}

func tripID(w http.ResponseWriter, r *http.Request) (uuid.UUID, bool) {
	id, err := uuid.Parse(r.PathValue("tripId"))
	if err != nil {
		httpx.WriteError(w, http.StatusNotFound, "not_found", "viaje no encontrado")
		return uuid.Nil, false
	}
	return id, true
}

func writeError(w http.ResponseWriter, r *http.Request, err error) {
	type mapping struct {
		status        int
		code, message string
	}
	known := map[error]mapping{
		ErrNotFound:          {http.StatusNotFound, "not_found", "viaje no encontrado"},
		ErrForbidden:         {http.StatusForbidden, "forbidden", "tu papel en el viaje no permite esta acción"},
		ErrInvalidTransition: {http.StatusConflict, "invalid_transition", "el viaje ya cambió de estado"},
		ErrExpired:           {http.StatusConflict, "expired", "se agotó el tiempo para responder"},
		ErrNoOpenProposal:    {http.StatusConflict, "no_open_proposal", "esa propuesta ya no está abierta"},
		ErrInvalidAmount:     {http.StatusBadRequest, "invalid_amount", "la tarifa debe ser mayor que cero"},
		ErrNotAffiliated:     {http.StatusConflict, "not_affiliated", "ese conductor no está en tu lista"},
		ErrDriverNotFree:     {http.StatusConflict, "driver_not_free", "tu conductor ya no está libre"},
		ErrPassengerHasTrip:  {http.StatusConflict, "passenger_has_active_trip", "ya tienes un viaje en curso"},
		ErrCityNotConfigured: {http.StatusServiceUnavailable, "city_not_configured", "la ciudad aún no tiene tarifas"},
		ErrNoRoute:           {http.StatusUnprocessableEntity, "no_route", "no encontramos una ruta por carretera"},
	}
	for target, m := range known {
		if errors.Is(err, target) {
			httpx.WriteError(w, m.status, m.code, m.message)
			return
		}
	}
	httpx.InternalError(w, r, err)
}

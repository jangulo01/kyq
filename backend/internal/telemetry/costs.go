package telemetry

import (
	"context"
	"errors"
	"math"
	"net/http"
	"regexp"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"

	"github.com/kyq/backend/internal/auth"
	"github.com/kyq/backend/internal/httpx"
	"github.com/kyq/backend/internal/store"
)

// Cost concepts (cost_rates.concept). Unit costs are in millionths of the minor unit because
// one realtime event costs a fraction of a cent.
const (
	ConceptVoiceMinute   = "voice_minute"
	ConceptRealtimeEvent = "realtime_event"
	ConceptRouteRequest  = "route_request"
	ConceptFixedMonthly  = "fixed_monthly"
)

// Concepts in display order.
var Concepts = []string{ConceptVoiceMinute, ConceptRealtimeEvent, ConceptRouteRequest, ConceptFixedMonthly}

// Rate is a unit cost in force from EffectiveFrom (a calendar day).
type Rate struct {
	Concept       string    `json:"concept"`
	Currency      string    `json:"currency"`
	UnitCostMicro int64     `json:"unit_cost_micro"`
	EffectiveFrom time.Time `json:"-"`
}

// DayUsage is what one driver used on one day (driver_usage_daily).
type DayUsage struct {
	Day          time.Time
	VoiceSeconds int64
	Events       int64
	Routes       int64
}

// CostItem is the cost of one concept in a month.
type CostItem struct {
	Concept   string  `json:"concept"`
	Usage     float64 `json:"usage"` // minutos, eventos o peticiones; 1 para el fijo
	CostMinor float64 `json:"cost_minor"`
}

// Breakdown is what a driver cost in a month against what they paid (RN-KYQ-004,
// contracts: CostBreakdown).
type Breakdown struct {
	Month          string     `json:"month"`
	Currency       string     `json:"currency"`
	PaidMinor      int64      `json:"paid_minor"`
	Items          []CostItem `json:"items"`
	TotalCostMinor float64    `json:"total_cost_minor"`
	MarginMinor    float64    `json:"margin_minor"`
}

// rateAt returns the unit cost of concept in force on day: the latest rate whose
// EffectiveFrom is on or before day; 0 when none.
func rateAt(rates []Rate, concept, currency string, day time.Time) int64 {
	var best *Rate
	for i := range rates {
		r := &rates[i]
		if r.Concept != concept || r.Currency != currency || r.EffectiveFrom.After(day) {
			continue
		}
		if best == nil || r.EffectiveFrom.After(best.EffectiveFrom) {
			best = r
		}
	}
	if best == nil {
		return 0
	}
	return best.UnitCostMicro
}

func round2(x float64) float64 { return math.Round(x*100) / 100 }

// ComputeCosts prices a month of usage (RN-KYQ-004): each day's usage at the rate in force that
// day, plus the fixed monthly cost in force at the end of the period (asOf for the current
// month). Margin = paid − cost.
func ComputeCosts(month time.Time, currency string, rates []Rate, days []DayUsage, paidMinor int64, asOf time.Time) Breakdown {
	monthStart := time.Date(month.Year(), month.Month(), 1, 0, 0, 0, 0, time.UTC)
	last := monthStart.AddDate(0, 1, -1)
	if asOf.Before(last) {
		last = time.Date(asOf.Year(), asOf.Month(), asOf.Day(), 0, 0, 0, 0, time.UTC)
	}
	var voiceMin, events, routes, voiceCost, eventCost, routeCost float64
	for _, d := range days {
		v := float64(d.VoiceSeconds) / 60
		voiceMin += v
		events += float64(d.Events)
		routes += float64(d.Routes)
		voiceCost += v * float64(rateAt(rates, ConceptVoiceMinute, currency, d.Day))
		eventCost += float64(d.Events) * float64(rateAt(rates, ConceptRealtimeEvent, currency, d.Day))
		routeCost += float64(d.Routes) * float64(rateAt(rates, ConceptRouteRequest, currency, d.Day))
	}
	fixed := float64(rateAt(rates, ConceptFixedMonthly, currency, last))
	items := []CostItem{
		{Concept: ConceptVoiceMinute, Usage: round2(voiceMin), CostMinor: round2(voiceCost / 1e6)},
		{Concept: ConceptRealtimeEvent, Usage: events, CostMinor: round2(eventCost / 1e6)},
		{Concept: ConceptRouteRequest, Usage: routes, CostMinor: round2(routeCost / 1e6)},
		{Concept: ConceptFixedMonthly, Usage: 1, CostMinor: round2(fixed / 1e6)},
	}
	var total float64
	for _, it := range items {
		total += it.CostMinor
	}
	total = round2(total)
	return Breakdown{
		Month: monthStart.Format("2006-01"), Currency: currency, PaidMinor: paidMinor, Items: items,
		TotalCostMinor: total, MarginMinor: round2(float64(paidMinor) - total),
	}
}

// CostHandlers serves the cost transparency routes (FR-024..FR-026).
type CostHandlers struct {
	Store    *store.Store
	CityCode string
	Now      func() time.Time
}

func (h *CostHandlers) now() time.Time {
	if h.Now != nil {
		return h.Now()
	}
	return time.Now()
}

// Register mounts the routes behind authMW and the role checks.
func (h *CostHandlers) Register(mux *http.ServeMux, authMW func(http.Handler) http.Handler) {
	driver := func(f http.HandlerFunc) http.Handler { return authMW(auth.RequireRole(auth.RoleDriver)(f)) }
	admin := func(f http.HandlerFunc) http.Handler { return authMW(auth.RequireRole(auth.RoleAdmin)(f)) }
	mux.Handle("GET /v1/driver/costs", driver(h.driverCosts))
	mux.Handle("GET /v1/admin/cost-rates", admin(h.listRates))
	mux.Handle("PUT /v1/admin/cost-rates", admin(h.putRate))
	mux.Handle("GET /v1/admin/costs", admin(h.adminCosts))
}

var monthPattern = regexp.MustCompile(`^[0-9]{4}-(0[1-9]|1[0-2])$`)

func (h *CostHandlers) month(w http.ResponseWriter, r *http.Request, required bool) (time.Time, bool) {
	v := r.URL.Query().Get("month")
	if v == "" && !required {
		n := h.now().UTC()
		return time.Date(n.Year(), n.Month(), 1, 0, 0, 0, 0, time.UTC), true
	}
	if !monthPattern.MatchString(v) {
		httpx.WriteError(w, http.StatusBadRequest, "invalid_month", "month en formato AAAA-MM")
		return time.Time{}, false
	}
	t, _ := time.Parse("2006-01", v)
	return t, true
}

// currency is the currency of the city's subscription price; COP when none is set.
func (h *CostHandlers) currency(ctx context.Context) (string, error) {
	p, err := h.Store.GetCurrentPrice(ctx, store.GetCurrentPriceParams{CityCode: h.CityCode, EffectiveFrom: h.now()})
	if store.IsNotFound(err) {
		return "COP", nil
	}
	return p.Currency, err
}

func (h *CostHandlers) rates(ctx context.Context) ([]Rate, error) {
	rows, err := h.Store.ListCostRates(ctx)
	if err != nil {
		return nil, err
	}
	out := make([]Rate, len(rows))
	for i, r := range rows {
		out[i] = Rate{Concept: string(r.Concept), Currency: r.Currency, UnitCostMicro: r.UnitCostMicro, EffectiveFrom: r.EffectiveFrom}
	}
	return out, nil
}

// breakdowns computes the month for one driver (driverID valid) or for all.
func (h *CostHandlers) breakdowns(ctx context.Context, month time.Time, driverID uuid.NullUUID) (map[uuid.UUID]Breakdown, string, error) {
	currency, err := h.currency(ctx)
	if err != nil {
		return nil, "", err
	}
	rates, err := h.rates(ctx)
	if err != nil {
		return nil, "", err
	}
	end := month.AddDate(0, 1, 0)
	usage, err := h.Store.ListDailyUsage(ctx, store.ListDailyUsageParams{FromDay: month, ToDay: end, DriverID: driverID})
	if err != nil {
		return nil, "", err
	}
	paid, err := h.Store.SumApprovedPayments(ctx, store.SumApprovedPaymentsParams{
		FromTs: pgtype.Timestamptz{Time: month, Valid: true}, ToTs: pgtype.Timestamptz{Time: end, Valid: true}, DriverID: driverID,
	})
	if err != nil {
		return nil, "", err
	}
	days := map[uuid.UUID][]DayUsage{}
	for _, u := range usage {
		days[u.DriverID] = append(days[u.DriverID], DayUsage{Day: u.Day, VoiceSeconds: u.VoiceParticipantSeconds, Events: u.RealtimeEvents, Routes: u.RouteRequests})
	}
	paidBy := map[uuid.UUID]int64{}
	for _, p := range paid {
		if p.Currency == currency {
			paidBy[p.DriverID] += p.PaidMinor
		}
	}
	out := map[uuid.UUID]Breakdown{}
	ids := map[uuid.UUID]bool{}
	for id := range days {
		ids[id] = true
	}
	for id := range paidBy {
		ids[id] = true
	}
	if driverID.Valid {
		ids[driverID.UUID] = true
	}
	now := h.now()
	for id := range ids {
		out[id] = ComputeCosts(month, currency, rates, days[id], paidBy[id], now)
	}
	return out, currency, nil
}

func (h *CostHandlers) driverCosts(w http.ResponseWriter, r *http.Request) {
	month, ok := h.month(w, r, false)
	if !ok {
		return
	}
	p, _ := auth.FromContext(r.Context())
	all, _, err := h.breakdowns(r.Context(), month, uuid.NullUUID{UUID: p.UserID, Valid: true})
	if err != nil {
		httpx.InternalError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, all[p.UserID])
}

// DriverCost is one row of GET /v1/admin/costs.
type DriverCost struct {
	DriverID    uuid.UUID `json:"driver_id"`
	DisplayName string    `json:"display_name"`
	Breakdown
	// Margen negativo: el costo medido supera lo pagado (se destaca en el panel).
	NegativeMargin bool `json:"negative_margin"`
}

func (h *CostHandlers) adminCosts(w http.ResponseWriter, r *http.Request) {
	month, ok := h.month(w, r, true)
	if !ok {
		return
	}
	all, currency, err := h.breakdowns(r.Context(), month, uuid.NullUUID{})
	if err != nil {
		httpx.InternalError(w, r, err)
		return
	}
	names, err := h.Store.ListDriverNames(r.Context())
	if err != nil {
		httpx.InternalError(w, r, err)
		return
	}
	rates, err := h.rates(r.Context())
	if err != nil {
		httpx.InternalError(w, r, err)
		return
	}
	out := make([]DriverCost, 0, len(names))
	for _, n := range names {
		b, ok := all[n.DriverID]
		if !ok {
			b = ComputeCosts(month, currency, rates, nil, 0, h.now())
		}
		out = append(out, DriverCost{DriverID: n.DriverID, DisplayName: n.DisplayName, Breakdown: b, NegativeMargin: b.MarginMinor < 0})
	}
	httpx.WriteJSON(w, http.StatusOK, out)
}

// RateView is a stored rate.
type RateView struct {
	Concept       string `json:"concept"`
	Currency      string `json:"currency"`
	UnitCostMicro int64  `json:"unit_cost_micro"`
	EffectiveFrom string `json:"effective_from"`
}

func (h *CostHandlers) listRates(w http.ResponseWriter, r *http.Request) {
	rates, err := h.rates(r.Context())
	if err != nil {
		httpx.InternalError(w, r, err)
		return
	}
	out := make([]RateView, len(rates))
	for i, rt := range rates {
		out[i] = RateView{Concept: rt.Concept, Currency: rt.Currency, UnitCostMicro: rt.UnitCostMicro, EffectiveFrom: rt.EffectiveFrom.Format(time.DateOnly)}
	}
	httpx.WriteJSON(w, http.StatusOK, out)
}

var errInvalidRate = errors.New("invalid rate")

func (h *CostHandlers) putRate(w http.ResponseWriter, r *http.Request) {
	var body struct {
		Concept       string `json:"concept"`
		Currency      string `json:"currency"`
		UnitCostMicro *int64 `json:"unit_cost_micro"`
		EffectiveFrom string `json:"effective_from"`
	}
	if !httpx.DecodeJSON(w, r, &body) {
		return
	}
	body.Currency = strings.ToUpper(strings.TrimSpace(body.Currency))
	from, err := time.Parse(time.DateOnly, body.EffectiveFrom)
	known := false
	for _, c := range Concepts {
		known = known || c == body.Concept
	}
	if err != nil || !known || len(body.Currency) != 3 || body.UnitCostMicro == nil || *body.UnitCostMicro < 0 {
		httpx.WriteError(w, http.StatusBadRequest, "invalid_rate", errInvalidRate.Error()+": concepto conocido, moneda de 3 letras, costo ≥ 0 y fecha AAAA-MM-DD")
		return
	}
	admin, _ := auth.FromContext(r.Context())
	if err := h.Store.UpsertCostRate(r.Context(), store.UpsertCostRateParams{
		Concept: store.CostConcept(body.Concept), Currency: body.Currency, UnitCostMicro: *body.UnitCostMicro,
		EffectiveFrom: from, CreatedBy: uuid.NullUUID{UUID: admin.UserID, Valid: true},
	}); err != nil {
		httpx.InternalError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, RateView{Concept: body.Concept, Currency: body.Currency, UnitCostMicro: *body.UnitCostMicro, EffectiveFrom: body.EffectiveFrom})
}

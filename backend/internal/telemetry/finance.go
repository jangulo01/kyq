package telemetry

import (
	"context"
	"net/http"
	"strconv"
	"time"

	"github.com/google/uuid"

	"github.com/kyq/backend/internal/httpx"
)

// Finanzas (007, US2): el agregado mensual de suscripciones frente a infraestructura se calcula
// con los mismos desgloses por conductor de 002 (FR-008), no con otra fórmula.

// ConceptCost is the cost of one concept in a month, summed over drivers.
type ConceptCost struct {
	Concept   string  `json:"concept"`
	CostMinor float64 `json:"cost_minor"`
}

// FinanceMonth is one month of GET /v1/admin/finance (contracts: FinanceMonth).
type FinanceMonth struct {
	Month                       string        `json:"month"`
	RevenueMinor                int64         `json:"revenue_minor"`
	InfraCostMinor              float64       `json:"infra_cost_minor"`
	MarginMinor                 float64       `json:"margin_minor"`
	MarginPct                   *float64      `json:"margin_pct"`
	Drivers                     int           `json:"drivers"`
	ActiveDrivers               int           `json:"active_drivers"`
	PayingDrivers               int           `json:"paying_drivers"`
	NegativeMarginDrivers       int           `json:"negative_margin_drivers"`
	CostPerActiveDriverMinor    *float64      `json:"cost_per_active_driver_minor"`
	RevenuePerPayingDriverMinor *float64      `json:"revenue_per_paying_driver_minor"`
	CostByConcept               []ConceptCost `json:"cost_by_concept"`
	RatesMissing                bool          `json:"rates_missing"`
}

// FinanceTotals sums the months of the report.
type FinanceTotals struct {
	RevenueMinor   int64    `json:"revenue_minor"`
	InfraCostMinor float64  `json:"infra_cost_minor"`
	MarginMinor    float64  `json:"margin_minor"`
	MarginPct      *float64 `json:"margin_pct"`
}

// FinanceReport is GET /v1/admin/finance (contracts: FinanceReport).
type FinanceReport struct {
	Currency string         `json:"currency"`
	Months   []FinanceMonth `json:"months"`
	Totals   FinanceTotals  `json:"totals"`
}

// DriverMonth is what one driver contributes to a month: its 002 breakdown and whether it was
// active (measured usage or a payment in the month).
type DriverMonth struct {
	Breakdown Breakdown
	Active    bool
}

func ratio(num, den float64) *float64 {
	if den == 0 {
		return nil
	}
	v := round2(num / den)
	return &v
}

// SummarizeMonth adds up the per-driver breakdowns of one month. ratesMissing reports whether no
// cost rate was in force.
func SummarizeMonth(month string, drivers []DriverMonth, ratesMissing bool) FinanceMonth {
	m := FinanceMonth{Month: month, Drivers: len(drivers), RatesMissing: ratesMissing, CostByConcept: []ConceptCost{}}
	byConcept := map[string]float64{}
	for _, d := range drivers {
		b := d.Breakdown
		m.RevenueMinor += b.PaidMinor
		m.InfraCostMinor += b.TotalCostMinor
		if d.Active {
			m.ActiveDrivers++
		}
		if b.PaidMinor > 0 {
			m.PayingDrivers++
		}
		if b.MarginMinor < 0 {
			m.NegativeMarginDrivers++
		}
		for _, it := range b.Items {
			byConcept[it.Concept] += it.CostMinor
		}
	}
	for _, c := range Concepts {
		m.CostByConcept = append(m.CostByConcept, ConceptCost{Concept: c, CostMinor: round2(byConcept[c])})
	}
	m.InfraCostMinor = round2(m.InfraCostMinor)
	m.MarginMinor = round2(float64(m.RevenueMinor) - m.InfraCostMinor)
	if pct := ratio(m.MarginMinor*100, float64(m.RevenueMinor)); pct != nil {
		m.MarginPct = pct
	}
	m.CostPerActiveDriverMinor = ratio(m.InfraCostMinor, float64(m.ActiveDrivers))
	m.RevenuePerPayingDriverMinor = ratio(float64(m.RevenueMinor), float64(m.PayingDrivers))
	return m
}

// SummarizeTotals adds up the months.
func SummarizeTotals(months []FinanceMonth) FinanceTotals {
	var t FinanceTotals
	for _, m := range months {
		t.RevenueMinor += m.RevenueMinor
		t.InfraCostMinor += m.InfraCostMinor
	}
	t.InfraCostMinor = round2(t.InfraCostMinor)
	t.MarginMinor = round2(float64(t.RevenueMinor) - t.InfraCostMinor)
	t.MarginPct = ratio(t.MarginMinor*100, float64(t.RevenueMinor))
	return t
}

// monthDrivers returns the 002 breakdown of every driver that existed at the end of month
// (drivers created later did not exist yet, research R5), with its activity.
func (h *CostHandlers) monthDrivers(ctx context.Context, month time.Time) ([]DriverMonth, []uuid.UUID, map[uuid.UUID]string, string, error) {
	all, currency, err := h.breakdowns(ctx, month, uuid.NullUUID{})
	if err != nil {
		return nil, nil, nil, "", err
	}
	rows, err := h.Store.ListDriversCreatedBefore(ctx, month.AddDate(0, 1, 0))
	if err != nil {
		return nil, nil, nil, "", err
	}
	rates, err := h.rates(ctx)
	if err != nil {
		return nil, nil, nil, "", err
	}
	out := make([]DriverMonth, 0, len(rows))
	ids := make([]uuid.UUID, 0, len(rows))
	names := map[uuid.UUID]string{}
	for _, row := range rows {
		b, active := all[row.DriverID]
		if !active {
			b = ComputeCosts(month, currency, rates, nil, 0, h.now())
		}
		out = append(out, DriverMonth{Breakdown: b, Active: active})
		ids = append(ids, row.DriverID)
		names[row.DriverID] = row.DisplayName
	}
	return out, ids, names, currency, nil
}

// ratesMissing reports whether no cost rate of currency was in force at any point of month.
func ratesMissing(rates []Rate, currency string, month time.Time) bool {
	end := month.AddDate(0, 1, 0)
	for _, r := range rates {
		if r.Currency == currency && r.EffectiveFrom.Before(end) {
			return false
		}
	}
	return true
}

const maxFinanceMonths = 24

func (h *CostHandlers) finance(w http.ResponseWriter, r *http.Request) {
	to, ok := h.optionalMonth(w, r, "to")
	if !ok {
		return
	}
	months := 6
	if v := r.URL.Query().Get("months"); v != "" {
		n, err := strconv.Atoi(v)
		if err != nil || n < 1 || n > maxFinanceMonths {
			httpx.WriteError(w, http.StatusBadRequest, "invalid_months", "months debe ser un entero de 1 a 24")
			return
		}
		months = n
	}
	rates, err := h.rates(r.Context())
	if err != nil {
		httpx.InternalError(w, r, err)
		return
	}
	report := FinanceReport{Months: make([]FinanceMonth, 0, months)}
	for i := months - 1; i >= 0; i-- {
		month := to.AddDate(0, -i, 0)
		drivers, _, _, currency, err := h.monthDrivers(r.Context(), month)
		if err != nil {
			httpx.InternalError(w, r, err)
			return
		}
		report.Currency = currency
		report.Months = append(report.Months, SummarizeMonth(month.Format("2006-01"), drivers, ratesMissing(rates, currency, month)))
	}
	report.Totals = SummarizeTotals(report.Months)
	httpx.WriteJSON(w, http.StatusOK, report)
}

// optionalMonth reads a month query parameter (AAAA-MM); the current month when absent.
func (h *CostHandlers) optionalMonth(w http.ResponseWriter, r *http.Request, name string) (time.Time, bool) {
	v := r.URL.Query().Get(name)
	if v == "" {
		n := h.now().UTC()
		return time.Date(n.Year(), n.Month(), 1, 0, 0, 0, 0, time.UTC), true
	}
	if !monthPattern.MatchString(v) {
		httpx.WriteError(w, http.StatusBadRequest, "invalid_month", name+" en formato AAAA-MM")
		return time.Time{}, false
	}
	t, _ := time.Parse("2006-01", v)
	return t, true
}

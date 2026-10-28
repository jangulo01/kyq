// Package crm implements the loyalty analytics and user moderation of the admin panel (spec
// 007, US3 and US4).
package crm

import (
	"context"
	"math"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"

	"github.com/kyq/backend/internal/store"
)

// SC008Target is the goal of SC-008 of spec 001: 80 % of affiliations get a trip request within
// their first 30 days.
const SC008Target = 0.8

// SC008Window is the time a passenger has to request a trip after affiliating.
const SC008Window = 30 * 24 * time.Hour

// InactiveAfter marks a chosen driver as inactive when it completed no trip in this period.
const InactiveAfter = 30 * 24 * time.Hour

// Week is one row of the weekly affiliation series (contracts: CrmWeek).
type Week struct {
	WeekStart string `json:"week_start"`
	Created   int    `json:"created"`
	Removed   int    `json:"removed"`
	ActiveEnd int    `json:"active_end"`
}

// Affiliations summarizes affiliation growth and churn in the period.
type Affiliations struct {
	ActiveNow     int      `json:"active_now"`
	ActiveAtStart int      `json:"active_at_start"`
	Created       int      `json:"created"`
	Removed       int      `json:"removed"`
	Net           int      `json:"net"`
	ChurnRate     *float64 `json:"churn_rate"`
	Weekly        []Week   `json:"weekly"`
}

// Repeat summarizes repeat trips per passenger–driver pair.
type Repeat struct {
	Pairs           int      `json:"pairs"`
	RepeatPairs     int      `json:"repeat_pairs"`
	RepeatRate      *float64 `json:"repeat_rate"`
	CompletedTrips  int      `json:"completed_trips"`
	AvgTripsPerPair *float64 `json:"avg_trips_per_pair"`
}

// SC008 is the indicator of spec 001 (contracts: CrmReport.sc008).
type SC008 struct {
	Matured        int      `json:"matured"`
	WithRequest30d int      `json:"with_request_30d"`
	Rate           *float64 `json:"rate"`
	Target         float64  `json:"target"`
	Met            *bool    `json:"met"`
	Pending        int      `json:"pending"`
}

// ChurnedDriver is a driver that lost affiliations in the period.
type ChurnedDriver struct {
	DriverID    uuid.UUID `json:"driver_id"`
	DisplayName string    `json:"display_name"`
	Removed     int64     `json:"removed"`
	ActiveNow   int64     `json:"active_now"`
}

// InactiveDriver is a chosen driver (with active affiliations) without recent completed trips.
type InactiveDriver struct {
	DriverID           uuid.UUID  `json:"driver_id"`
	DisplayName        string     `json:"display_name"`
	ActiveAffiliations int64      `json:"active_affiliations"`
	LastCompletedAt    *time.Time `json:"last_completed_at"`
}

// Report is GET /v1/admin/crm (contracts: CrmReport).
type Report struct {
	From                  string           `json:"from"`
	To                    string           `json:"to"`
	Affiliations          Affiliations     `json:"affiliations"`
	Repeat                Repeat           `json:"repeat"`
	SC008                 SC008            `json:"sc008"`
	ChurnedDrivers        []ChurnedDriver  `json:"churned_drivers"`
	InactiveChosenDrivers []InactiveDriver `json:"inactive_chosen_drivers"`
}

// AffiliationSpan is when an affiliation was created and, if so, removed.
type AffiliationSpan struct {
	CreatedAt time.Time
	RemovedAt *time.Time
}

func (a AffiliationSpan) activeAt(t time.Time) bool {
	return !a.CreatedAt.After(t) && (a.RemovedAt == nil || a.RemovedAt.After(t))
}

func rate(num, den int) *float64 {
	if den == 0 {
		return nil
	}
	v := math.Round(float64(num)/float64(den)*10000) / 10000
	return &v
}

// weekStart returns the Monday 00:00 UTC of the week of t.
func weekStart(t time.Time) time.Time {
	d := time.Date(t.Year(), t.Month(), t.Day(), 0, 0, 0, 0, time.UTC)
	offset := (int(d.Weekday()) + 6) % 7
	return d.AddDate(0, 0, -offset)
}

// SummarizeAffiliations computes growth, churn and the weekly series for [from, to) (to is the
// day after the last day of the period) as of now.
func SummarizeAffiliations(spans []AffiliationSpan, from, to, now time.Time) Affiliations {
	out := Affiliations{Weekly: []Week{}}
	for _, a := range spans {
		if a.activeAt(now) {
			out.ActiveNow++
		}
		if a.activeAt(from.Add(-time.Nanosecond)) {
			out.ActiveAtStart++
		}
		if !a.CreatedAt.Before(from) && a.CreatedAt.Before(to) {
			out.Created++
		}
		if a.RemovedAt != nil && !a.RemovedAt.Before(from) && a.RemovedAt.Before(to) {
			out.Removed++
		}
	}
	out.Net = out.Created - out.Removed
	out.ChurnRate = rate(out.Removed, out.ActiveAtStart+out.Created)
	for ws := weekStart(from); ws.Before(to); ws = ws.AddDate(0, 0, 7) {
		we := ws.AddDate(0, 0, 7)
		w := Week{WeekStart: ws.Format(time.DateOnly)}
		for _, a := range spans {
			if !a.CreatedAt.Before(ws) && a.CreatedAt.Before(we) {
				w.Created++
			}
			if a.RemovedAt != nil && !a.RemovedAt.Before(ws) && a.RemovedAt.Before(we) {
				w.Removed++
			}
			if a.activeAt(we.Add(-time.Nanosecond)) {
				w.ActiveEnd++
			}
		}
		out.Weekly = append(out.Weekly, w)
	}
	return out
}

// SummarizeRepeat computes the repeat indicators from the completed trips of each pair.
func SummarizeRepeat(tripsPerPair []int64) Repeat {
	out := Repeat{Pairs: len(tripsPerPair)}
	for _, n := range tripsPerPair {
		out.CompletedTrips += int(n)
		if n >= 2 {
			out.RepeatPairs++
		}
	}
	out.RepeatRate = rate(out.RepeatPairs, out.Pairs)
	if out.Pairs > 0 {
		v := math.Round(float64(out.CompletedTrips)/float64(out.Pairs)*100) / 100
		out.AvgTripsPerPair = &v
	}
	return out
}

// AffiliationRequest is an affiliation of the period and whether its passenger requested a trip
// to that driver in the following 30 days.
type AffiliationRequest struct {
	CreatedAt time.Time
	Requested bool
}

// SummarizeSC008 counts only matured affiliations (30 days elapsed by now); the others are
// pending.
func SummarizeSC008(rows []AffiliationRequest, now time.Time) SC008 {
	out := SC008{Target: SC008Target}
	for _, r := range rows {
		if r.CreatedAt.Add(SC008Window).After(now) {
			out.Pending++
			continue
		}
		out.Matured++
		if r.Requested {
			out.WithRequest30d++
		}
	}
	out.Rate = rate(out.WithRequest30d, out.Matured)
	if out.Rate != nil {
		met := *out.Rate >= SC008Target
		out.Met = &met
	}
	return out
}

func ts(t time.Time) pgtype.Timestamptz { return pgtype.Timestamptz{Time: t, Valid: true} }

// BuildReport reads affiliations and trips and computes the report for the days [from, to]
// (both included) as of now.
func BuildReport(ctx context.Context, q *store.Queries, from, to, now time.Time) (Report, error) {
	end := to.AddDate(0, 0, 1)
	timeline, err := q.ListAffiliationTimeline(ctx, maxTime(end, now))
	if err != nil {
		return Report{}, err
	}
	spans := make([]AffiliationSpan, len(timeline))
	for i, row := range timeline {
		spans[i] = AffiliationSpan{CreatedAt: row.CreatedAt}
		if row.RemovedAt.Valid {
			removed := row.RemovedAt.Time
			spans[i].RemovedAt = &removed
		}
	}
	pairs, err := q.CompletedTripsByPair(ctx, store.CompletedTripsByPairParams{FromTs: ts(from), ToTs: ts(end)})
	if err != nil {
		return Report{}, err
	}
	perPair := make([]int64, len(pairs))
	for i, p := range pairs {
		perPair[i] = p.Trips
	}
	requests, err := q.AffiliationsWithFirstRequest(ctx, store.AffiliationsWithFirstRequestParams{FromTs: from, ToTs: end})
	if err != nil {
		return Report{}, err
	}
	reqs := make([]AffiliationRequest, len(requests))
	for i, r := range requests {
		reqs[i] = AffiliationRequest{CreatedAt: r.CreatedAt, Requested: r.Requested}
	}
	churned, err := q.TopDriversByRemovals(ctx, store.TopDriversByRemovalsParams{FromTs: ts(from), ToTs: ts(end)})
	if err != nil {
		return Report{}, err
	}
	inactive, err := q.InactiveChosenDrivers(ctx, now.Add(-InactiveAfter))
	if err != nil {
		return Report{}, err
	}

	report := Report{
		From: from.Format(time.DateOnly), To: to.Format(time.DateOnly),
		Affiliations:          SummarizeAffiliations(spans, from, end, now),
		Repeat:                SummarizeRepeat(perPair),
		SC008:                 SummarizeSC008(reqs, now),
		ChurnedDrivers:        make([]ChurnedDriver, len(churned)),
		InactiveChosenDrivers: make([]InactiveDriver, len(inactive)),
	}
	for i, c := range churned {
		report.ChurnedDrivers[i] = ChurnedDriver{DriverID: c.DriverID, DisplayName: c.DisplayName, Removed: c.Removed, ActiveNow: c.ActiveNow}
	}
	for i, d := range inactive {
		v := InactiveDriver{DriverID: d.DriverID, DisplayName: d.DisplayName, ActiveAffiliations: d.ActiveAffiliations}
		if d.LastCompletedAt.After(time.Unix(0, 0)) {
			last := d.LastCompletedAt
			v.LastCompletedAt = &last
		}
		report.InactiveChosenDrivers[i] = v
	}
	return report, nil
}

func maxTime(a, b time.Time) time.Time {
	if a.After(b) {
		return a
	}
	return b
}

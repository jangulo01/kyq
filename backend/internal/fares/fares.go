// Package fares computes the suggested fare from the city fare table and the route (FR-010,
// FR-010b, RN-KYQ-013).
package fares

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"net/url"
	"strings"
	"time"
)

// Table is a city fare table. Amounts are in minor units of Currency.
type Table struct {
	CityCode       string `json:"-"`
	Currency       string `json:"currency"`
	BaseMinor      int64  `json:"base_minor"`
	PerKmMinor     int64  `json:"per_km_minor"`
	PerMinuteMinor int64  `json:"per_minute_minor"`
	MinimumMinor   int64  `json:"minimum_minor"`
	// RoundingMinor is the usual cash unit; the fare is rounded half up to a multiple of it.
	RoundingMinor int64 `json:"rounding_minor"`
}

// Validate checks the table invariants.
func (t Table) Validate() error {
	switch {
	case len(t.Currency) != 3:
		return errors.New("currency must be an ISO 4217 code")
	case t.BaseMinor < 0 || t.PerKmMinor < 0 || t.PerMinuteMinor < 0 || t.MinimumMinor < 0:
		return errors.New("amounts must be zero or positive")
	case t.RoundingMinor < 1:
		return errors.New("rounding_minor must be at least 1")
	}
	return nil
}

// Suggest returns max(minimum, base + per_km × km + per_minute × min), rounded.
func (t Table) Suggest(distanceM, durationS int32) int64 {
	raw := t.BaseMinor + t.PerKmMinor*int64(distanceM)/1000 + t.PerMinuteMinor*int64(durationS)/60
	raw = max(raw, t.MinimumMinor)
	r := t.RoundingMinor
	if r <= 1 {
		return raw
	}
	return (raw + r/2) / r * r
}

// Route is a road route estimate.
type Route struct {
	DistanceM int32
	DurationS int32
}

// RouteEstimator estimates driving routes.
type RouteEstimator interface {
	Route(ctx context.Context, fromLat, fromLng, toLat, toLng float64) (Route, error)
}

// ErrNoRoute means the router found no road route between the points.
var ErrNoRoute = errors.New("no route between points")

// OSRM queries an OSRM server (/route/v1/driving).
type OSRM struct {
	BaseURL string
	HTTP    *http.Client
}

func (o OSRM) Route(ctx context.Context, fromLat, fromLng, toLat, toLng float64) (Route, error) {
	coords := fmt.Sprintf("%f,%f;%f,%f", fromLng, fromLat, toLng, toLat)
	endpoint := strings.TrimRight(o.BaseURL, "/") + "/route/v1/driving/" + url.PathEscape(coords) + "?overview=false"
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, endpoint, nil)
	if err != nil {
		return Route{}, err
	}
	client := o.HTTP
	if client == nil {
		client = &http.Client{Timeout: 5 * time.Second}
	}
	resp, err := client.Do(req)
	if err != nil {
		return Route{}, fmt.Errorf("osrm: %w", err)
	}
	defer resp.Body.Close()
	var body struct {
		Code   string `json:"code"`
		Routes []struct {
			Distance float64 `json:"distance"`
			Duration float64 `json:"duration"`
		} `json:"routes"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&body); err != nil {
		return Route{}, fmt.Errorf("osrm: decode: %w", err)
	}
	if body.Code == "NoRoute" || (body.Code == "Ok" && len(body.Routes) == 0) {
		return Route{}, ErrNoRoute
	}
	if body.Code != "Ok" {
		return Route{}, fmt.Errorf("osrm: code %q", body.Code)
	}
	return Route{DistanceM: int32(body.Routes[0].Distance + 0.5), DurationS: int32(body.Routes[0].Duration + 0.5)}, nil
}

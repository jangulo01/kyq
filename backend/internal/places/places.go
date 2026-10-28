// Package places is the address search of spec 010 (US5): a proxy to a self-hosted Photon
// geocoder (OpenStreetMap) limited to the box of the configured city, with a short cache.
package places

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"sync"
	"time"
	"unicode/utf8"
)

// Parámetros de la búsqueda (FR-014, research R5).
const (
	MinQuery = 3
	MaxQuery = 120
	Limit    = 8
	CacheTTL = 10 * time.Minute
	Timeout  = 3 * time.Second
	maxCache = 2000
)

var (
	// ErrQueryTooShort: al menos 3 caracteres.
	ErrQueryTooShort = errors.New("query too short")
	// ErrUnavailable: sin geocodificador configurado o sin respuesta.
	ErrUnavailable = errors.New("places unavailable")
)

// BBox is the box of the city: results outside are dropped.
type BBox struct{ MinLng, MinLat, MaxLng, MaxLat float64 }

// Bogota is the default city box.
var Bogota = BBox{MinLng: -74.25, MinLat: 4.45, MaxLng: -73.98, MaxLat: 4.85}

// ParseBBox reads "minLng,minLat,maxLng,maxLat"; empty returns Bogota.
func ParseBBox(raw string) (BBox, error) {
	if strings.TrimSpace(raw) == "" {
		return Bogota, nil
	}
	parts := strings.Split(raw, ",")
	if len(parts) != 4 {
		return BBox{}, fmt.Errorf("KYQ_CITY_BBOX: se esperan 4 números, minLng,minLat,maxLng,maxLat")
	}
	var v [4]float64
	for i, p := range parts {
		f, err := strconv.ParseFloat(strings.TrimSpace(p), 64)
		if err != nil {
			return BBox{}, fmt.Errorf("KYQ_CITY_BBOX: %q no es un número", p)
		}
		v[i] = f
	}
	b := BBox{MinLng: v[0], MinLat: v[1], MaxLng: v[2], MaxLat: v[3]}
	if b.MinLng >= b.MaxLng || b.MinLat >= b.MaxLat {
		return BBox{}, fmt.Errorf("KYQ_CITY_BBOX: los mínimos deben ser menores que los máximos")
	}
	return b, nil
}

// Contains reports whether the point is inside the box.
func (b BBox) Contains(lat, lng float64) bool {
	return lat >= b.MinLat && lat <= b.MaxLat && lng >= b.MinLng && lng <= b.MaxLng
}

// Place is one suggestion (contracts: Place).
type Place struct {
	Label  string  `json:"label"`
	Detail string  `json:"detail"`
	Lat    float64 `json:"lat"`
	Lng    float64 `json:"lng"`
}

type cached struct {
	at     time.Time
	places []Place
}

// Service searches places.
type Service struct {
	URL  string // Photon, p. ej. http://photon:2322; vacío, sin buscador
	BBox BBox
	HTTP *http.Client
	Now  func() time.Time

	mu    sync.Mutex
	cache map[string]cached
}

func (s *Service) now() time.Time {
	if s.Now != nil {
		return s.Now()
	}
	return time.Now()
}

// Search returns up to 8 suggestions of the city for q.
func (s *Service) Search(ctx context.Context, q string) ([]Place, error) {
	q = strings.Join(strings.Fields(q), " ")
	if n := utf8.RuneCountInString(q); n < MinQuery {
		return nil, ErrQueryTooShort
	} else if n > MaxQuery {
		q = string([]rune(q)[:MaxQuery])
	}
	if s.URL == "" {
		return nil, ErrUnavailable
	}
	key := strings.ToLower(q)
	now := s.now()
	s.mu.Lock()
	if c, ok := s.cache[key]; ok && now.Sub(c.at) < CacheTTL {
		s.mu.Unlock()
		return c.places, nil
	}
	s.mu.Unlock()

	places, err := s.photon(ctx, q)
	if err != nil {
		return nil, fmt.Errorf("%w: %v", ErrUnavailable, err)
	}
	s.mu.Lock()
	if s.cache == nil || len(s.cache) >= maxCache {
		s.cache = map[string]cached{}
	}
	s.cache[key] = cached{at: now, places: places}
	s.mu.Unlock()
	return places, nil
}

type photonResponse struct {
	Features []struct {
		Geometry struct {
			Coordinates []float64 `json:"coordinates"`
		} `json:"geometry"`
		Properties map[string]any `json:"properties"`
	} `json:"features"`
}

func (s *Service) photon(ctx context.Context, q string) ([]Place, error) {
	ctx, cancel := context.WithTimeout(ctx, Timeout)
	defer cancel()
	b := s.BBox
	params := url.Values{
		"q": {q}, "limit": {strconv.Itoa(Limit * 2)}, "lang": {"es"},
		"bbox": {fmt.Sprintf("%g,%g,%g,%g", b.MinLng, b.MinLat, b.MaxLng, b.MaxLat)},
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, strings.TrimRight(s.URL, "/")+"/api?"+params.Encode(), nil)
	if err != nil {
		return nil, err
	}
	client := s.HTTP
	if client == nil {
		client = http.DefaultClient
	}
	res, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer res.Body.Close()
	if res.StatusCode != http.StatusOK {
		return nil, errors.New(res.Status)
	}
	var body photonResponse
	if err := json.NewDecoder(res.Body).Decode(&body); err != nil {
		return nil, err
	}
	out := []Place{}
	seen := map[string]bool{}
	for _, f := range body.Features {
		if len(f.Geometry.Coordinates) < 2 {
			continue
		}
		lng, lat := f.Geometry.Coordinates[0], f.Geometry.Coordinates[1]
		if !b.Contains(lat, lng) {
			continue
		}
		label, detail := describe(f.Properties)
		if label == "" || seen[label+detail] {
			continue
		}
		seen[label+detail] = true
		out = append(out, Place{Label: label, Detail: detail, Lat: lat, Lng: lng})
		if len(out) == Limit {
			break
		}
	}
	return out, nil
}

// describe builds "name" or "street housenumber" and "district, city" from Photon properties.
func describe(p map[string]any) (string, string) {
	str := func(k string) string {
		v, _ := p[k].(string)
		return strings.TrimSpace(v)
	}
	label := str("name")
	street := strings.TrimSpace(str("street") + " " + str("housenumber"))
	if label == "" {
		label = street
		street = ""
	}
	var parts []string
	for _, v := range []string{street, str("district"), str("locality"), str("city")} {
		if v != "" && v != label && !contains(parts, v) {
			parts = append(parts, v)
		}
	}
	return label, strings.Join(parts, ", ")
}

func contains(xs []string, v string) bool {
	for _, x := range xs {
		if x == v {
			return true
		}
	}
	return false
}

package domains

import (
	"context"
	"errors"
	"net/http"
	"net/url"
	"slices"
	"strings"
	"sync"
	"time"

	"github.com/google/uuid"

	"github.com/kyq/backend/internal/store"
)

// ProbeTimeout is the limit of the check of each domain.
const ProbeTimeout = 3 * time.Second

var (
	// ErrInvalidURL: la API debe ser http(s)://host sin ruta y el tiempo real ws(s)://….
	ErrInvalidURL = errors.New("invalid domain url")
	// ErrDuplicate: ese dominio de API ya está en la lista.
	ErrDuplicate = errors.New("duplicate domain")
	// ErrLastActive: la lista no puede quedar sin dominios activos (FR-019).
	ErrLastActive = errors.New("last active domain")
	// ErrNotFound: el dominio no existe.
	ErrNotFound = errors.New("domain not found")
	// ErrInvalidOrder: el orden debe nombrar cada dominio una vez.
	ErrInvalidOrder = errors.New("invalid order")
	// ErrNotConfigured: sin KYQ_DOMAINS_SIGNING_KEY no se publica la lista.
	ErrNotConfigured = errors.New("domain signing not configured")
)

// Probe checks a domain and returns its latency.
type Probe func(ctx context.Context, apiURL string) (time.Duration, error)

// HTTPProbe calls GET {apiURL}/healthz.
func HTTPProbe(client *http.Client) Probe {
	return func(ctx context.Context, apiURL string) (time.Duration, error) {
		start := time.Now()
		req, err := http.NewRequestWithContext(ctx, http.MethodGet, apiURL+"/healthz", nil)
		if err != nil {
			return 0, err
		}
		res, err := client.Do(req)
		if err != nil {
			return 0, err
		}
		_ = res.Body.Close()
		if res.StatusCode != http.StatusOK {
			return 0, errors.New(res.Status)
		}
		return time.Since(start), nil
	}
}

// Domain is contracts: MirrorDomain.
type Domain struct {
	ID          uuid.UUID `json:"id"`
	APIURL      string    `json:"api_url"`
	RealtimeURL string    `json:"realtime_url"`
	Position    int       `json:"position"`
	Active      bool      `json:"active"`
	// Status: ok, down o unchecked (sin comprobación).
	Status    string `json:"status"`
	LatencyMs *int64 `json:"latency_ms"`
}

// Listing is GET /v1/admin/domains.
type Listing struct {
	Version           int64    `json:"version"`
	SigningConfigured bool     `json:"signing_configured"`
	PublicKey         *string  `json:"public_key"`
	Domains           []Domain `json:"domains"`
}

// Service manages the mirror domains.
type Service struct {
	Store  *store.Store
	Signer *Signer // nil: sin firma configurada
	Probe  Probe   // nil: sin comprobación
	Now    func() time.Time
}

func (s *Service) now() time.Time {
	if s.Now != nil {
		return s.Now()
	}
	return time.Now()
}

func normalize(apiURL, realtimeURL string) (string, string, error) {
	apiURL, realtimeURL = strings.TrimRight(strings.TrimSpace(apiURL), "/"), strings.TrimSpace(realtimeURL)
	a, err := url.Parse(apiURL)
	if err != nil || (a.Scheme != "https" && a.Scheme != "http") || a.Host == "" || a.Path != "" || a.RawQuery != "" {
		return "", "", ErrInvalidURL
	}
	r, err := url.Parse(realtimeURL)
	if err != nil || (r.Scheme != "wss" && r.Scheme != "ws") || r.Host == "" {
		return "", "", ErrInvalidURL
	}
	return apiURL, realtimeURL, nil
}

// List returns the domains with their current status, checked in parallel (FR-019).
func (s *Service) List(ctx context.Context) (Listing, error) {
	rows, err := s.Store.ListMirrorDomains(ctx)
	if err != nil {
		return Listing{}, err
	}
	v, err := s.Store.GetMirrorDomainsVersion(ctx)
	if err != nil {
		return Listing{}, err
	}
	out := Listing{Version: v.Version, SigningConfigured: s.Signer != nil, Domains: make([]Domain, len(rows))}
	if s.Signer != nil {
		k := s.Signer.PublicKey()
		out.PublicKey = &k
	}
	var wg sync.WaitGroup
	for i, r := range rows {
		out.Domains[i] = Domain{ID: r.ID, APIURL: r.ApiUrl, RealtimeURL: r.RealtimeUrl, Position: int(r.Position), Active: r.Active, Status: "unchecked"}
		if s.Probe == nil {
			continue
		}
		wg.Add(1)
		go func(d *Domain) {
			defer wg.Done()
			pctx, cancel := context.WithTimeout(ctx, ProbeTimeout)
			defer cancel()
			latency, err := s.Probe(pctx, d.APIURL)
			if err != nil {
				d.Status = "down"
				return
			}
			ms := latency.Milliseconds()
			d.Status, d.LatencyMs = "ok", &ms
		}(&out.Domains[i])
	}
	wg.Wait()
	return out, nil
}

// mutate runs fn with the version row locked and bumps the version (research R7).
func (s *Service) mutate(ctx context.Context, fn func(q *store.Queries) error) error {
	return s.Store.WithTx(ctx, func(q *store.Queries) error {
		if _, err := q.LockMirrorDomainsVersion(ctx); err != nil {
			return err
		}
		if err := fn(q); err != nil {
			return err
		}
		_, err := q.BumpMirrorDomainsVersion(ctx, s.now())
		return err
	})
}

// Create adds a domain at the end of the list.
func (s *Service) Create(ctx context.Context, apiURL, realtimeURL string, active bool) (Domain, error) {
	apiURL, realtimeURL, err := normalize(apiURL, realtimeURL)
	if err != nil {
		return Domain{}, err
	}
	var row store.MirrorDomain
	err = s.mutate(ctx, func(q *store.Queries) error {
		var err error
		row, err = q.InsertMirrorDomain(ctx, store.InsertMirrorDomainParams{
			ID: uuid.New(), ApiUrl: apiURL, RealtimeUrl: realtimeURL, Active: active, CreatedAt: s.now(),
		})
		if store.IsUniqueViolation(err) {
			return ErrDuplicate
		}
		return err
	})
	if err != nil {
		return Domain{}, err
	}
	return Domain{ID: row.ID, APIURL: row.ApiUrl, RealtimeURL: row.RealtimeUrl, Position: int(row.Position), Active: row.Active, Status: "unchecked"}, nil
}

// Update changes a domain; deactivating the last active one is rejected.
func (s *Service) Update(ctx context.Context, id uuid.UUID, apiURL, realtimeURL string, active bool) (Domain, error) {
	apiURL, realtimeURL, err := normalize(apiURL, realtimeURL)
	if err != nil {
		return Domain{}, err
	}
	var row store.MirrorDomain
	err = s.mutate(ctx, func(q *store.Queries) error {
		cur, err := q.GetMirrorDomain(ctx, id)
		if store.IsNotFound(err) {
			return ErrNotFound
		}
		if err != nil {
			return err
		}
		if cur.Active && !active {
			if err := lastActiveGuard(ctx, q); err != nil {
				return err
			}
		}
		row, err = q.UpdateMirrorDomain(ctx, store.UpdateMirrorDomainParams{
			ID: id, ApiUrl: apiURL, RealtimeUrl: realtimeURL, Active: active, UpdatedAt: s.now(),
		})
		if store.IsUniqueViolation(err) {
			return ErrDuplicate
		}
		return err
	})
	if err != nil {
		return Domain{}, err
	}
	return Domain{ID: row.ID, APIURL: row.ApiUrl, RealtimeURL: row.RealtimeUrl, Position: int(row.Position), Active: row.Active, Status: "unchecked"}, nil
}

// Delete removes a domain; removing the last active one is rejected.
func (s *Service) Delete(ctx context.Context, id uuid.UUID) error {
	return s.mutate(ctx, func(q *store.Queries) error {
		cur, err := q.GetMirrorDomain(ctx, id)
		if store.IsNotFound(err) {
			return ErrNotFound
		}
		if err != nil {
			return err
		}
		if cur.Active {
			if err := lastActiveGuard(ctx, q); err != nil {
				return err
			}
		}
		_, err = q.DeleteMirrorDomain(ctx, id)
		return err
	})
}

func lastActiveGuard(ctx context.Context, q *store.Queries) error {
	n, err := q.CountActiveMirrorDomains(ctx)
	if err != nil {
		return err
	}
	if n <= 1 {
		return ErrLastActive
	}
	return nil
}

// Reorder sets the order of the list; ids must name every domain once.
func (s *Service) Reorder(ctx context.Context, ids []uuid.UUID) error {
	return s.mutate(ctx, func(q *store.Queries) error {
		rows, err := q.ListMirrorDomains(ctx)
		if err != nil {
			return err
		}
		have := make([]uuid.UUID, len(rows))
		for i, r := range rows {
			have[i] = r.ID
		}
		want := slices.Clone(ids)
		cmp := func(a, b uuid.UUID) int { return strings.Compare(a.String(), b.String()) }
		slices.SortFunc(have, cmp)
		slices.SortFunc(want, cmp)
		if !slices.Equal(have, want) {
			return ErrInvalidOrder
		}
		for i, id := range ids {
			if err := q.SetMirrorDomainPosition(ctx, store.SetMirrorDomainPositionParams{ID: id, Position: int32(i + 1), UpdatedAt: s.now()}); err != nil {
				return err
			}
		}
		return nil
	})
}

// SignedList returns the active domains in order, signed (FR-020).
func (s *Service) SignedList(ctx context.Context) (Signed, error) {
	if s.Signer == nil {
		return Signed{}, ErrNotConfigured
	}
	rows, err := s.Store.ListMirrorDomains(ctx)
	if err != nil {
		return Signed{}, err
	}
	v, err := s.Store.GetMirrorDomainsVersion(ctx)
	if err != nil {
		return Signed{}, err
	}
	p := Payload{Version: v.Version, IssuedAt: v.UpdatedAt.UTC(), Domains: []Entry{}}
	for _, r := range rows {
		if r.Active {
			p.Domains = append(p.Domains, Entry{APIURL: r.ApiUrl, RealtimeURL: r.RealtimeUrl})
		}
	}
	return s.Signer.Sign(p)
}

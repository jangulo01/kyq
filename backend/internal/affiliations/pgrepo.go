package affiliations

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"

	"github.com/kyq/backend/internal/store"
)

// PgRepo implements Repo on PostgreSQL.
type PgRepo struct{ q *store.Queries }

// NewPgRepo returns a repository using q.
func NewPgRepo(q *store.Queries) *PgRepo { return &PgRepo{q: q} }

func optionalTime(t pgtype.Timestamptz) *time.Time {
	if !t.Valid {
		return nil
	}
	v := t.Time
	return &v
}

func (r *PgRepo) DriverByQRToken(ctx context.Context, token string) (ChosenDriver, error) {
	row, err := r.q.GetChosenDriverByQRToken(ctx, token)
	if store.IsNotFound(err) {
		return ChosenDriver{}, ErrDriverNotFound
	}
	if err != nil {
		return ChosenDriver{}, err
	}
	return ChosenDriver{
		DriverID: row.DriverID, DisplayName: row.DisplayName, VehicleDescription: row.VehicleDescription,
		Presence: string(row.Presence), BusyUntilEstimate: optionalTime(row.BusyUntilEstimate),
	}, nil
}

func (r *PgRepo) State(ctx context.Context, p, d uuid.UUID) (AffiliationState, error) {
	row, err := r.q.GetAffiliation(ctx, store.GetAffiliationParams{PassengerID: p, DriverID: d})
	if store.IsNotFound(err) {
		return StateNone, nil
	}
	if err != nil {
		return StateNone, err
	}
	if row.RemovedAt.Valid {
		return StateRemoved, nil
	}
	return StateActive, nil
}

func (r *PgRepo) Insert(ctx context.Context, p, d uuid.UUID) error {
	return r.q.InsertAffiliation(ctx, store.InsertAffiliationParams{PassengerID: p, DriverID: d})
}

func (r *PgRepo) Reactivate(ctx context.Context, p, d uuid.UUID) error {
	return r.q.ReactivateAffiliation(ctx, store.ReactivateAffiliationParams{PassengerID: p, DriverID: d})
}

func (r *PgRepo) Remove(ctx context.Context, p, d uuid.UUID) (bool, error) {
	n, err := r.q.RemoveAffiliation(ctx, store.RemoveAffiliationParams{PassengerID: p, DriverID: d})
	return n == 1, err
}

func (r *PgRepo) ChosenDrivers(ctx context.Context, p uuid.UUID) ([]ChosenDriver, error) {
	rows, err := r.q.ListChosenDrivers(ctx, p)
	if err != nil {
		return nil, err
	}
	out := make([]ChosenDriver, len(rows))
	for i, row := range rows {
		out[i] = ChosenDriver{
			DriverID: row.DriverID, DisplayName: row.DisplayName, VehicleDescription: row.VehicleDescription,
			Presence: string(row.Presence), BusyUntilEstimate: optionalTime(row.BusyUntilEstimate),
		}
		if row.CooperativeID.Valid && row.CooperativeName.Valid {
			out[i].Cooperative = &CooperativeRef{ID: row.CooperativeID.UUID, Name: row.CooperativeName.String}
		}
	}
	return out, nil
}

func (r *PgRepo) Clients(ctx context.Context, d uuid.UUID) ([]Client, error) {
	rows, err := r.q.ListDriverClients(ctx, d)
	if err != nil {
		return nil, err
	}
	out := make([]Client, len(rows))
	for i, row := range rows {
		out[i] = Client{PassengerID: row.PassengerID, DisplayName: row.DisplayName, AffiliatedAt: row.AffiliatedAt}
	}
	return out, nil
}

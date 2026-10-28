package drivers

import (
	"context"
	"time"

	"github.com/google/uuid"

	"github.com/kyq/backend/internal/store"
)

// Eligibility implements affiliations.Eligibility with the same rule as going ONLINE, without the
// trip-in-progress exception (RN-KYQ-002, RN-KYQ-003, RN-KYQ-016).
type Eligibility struct {
	Store *store.Store
	Now   func() time.Time
}

func (e Eligibility) CanWork(ctx context.Context, driverID uuid.UUID) (bool, error) {
	profile, err := e.Store.GetDriverProfile(ctx, driverID)
	if err != nil {
		return false, err
	}
	docs, err := e.Store.ListDocumentsForDrivers(ctx, []uuid.UUID{driverID})
	if err != nil {
		return false, err
	}
	var paidUntil time.Time
	if profile.PaidUntil.Valid {
		paidUntil = profile.PaidUntil.Time
	}
	now := time.Now()
	if e.Now != nil {
		now = e.Now()
	}
	return EvaluateOnline(paidUntil, GateDocuments(docs), false, now) == BlockNone, nil
}

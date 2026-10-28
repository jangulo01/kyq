package drivers

import (
	"time"

	"github.com/jackc/pgx/v5/pgtype"

	"github.com/kyq/backend/internal/store"
)

// GateDocuments converts the approved documents of a driver into gate input.
func GateDocuments(rows []store.ListDocumentsForDriversRow) []Document {
	out := make([]Document, len(rows))
	for i, r := range rows {
		out[i] = Document{Type: string(r.DocType), ExpiresAt: DateOrZero(r.ExpiresAt), ExemptUntil: DateOrZero(r.ExemptUntil), Approved: true}
	}
	return out
}

// DateOrZero returns the date or the zero time when it is NULL.
func DateOrZero(d pgtype.Date) time.Time {
	if !d.Valid {
		return time.Time{}
	}
	return d.Time
}

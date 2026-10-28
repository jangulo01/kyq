package kyc

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"

	"github.com/kyq/backend/internal/drivers"
	"github.com/kyq/backend/internal/notify"
	"github.com/kyq/backend/internal/store"
)

// OptionalDate distinguishes an absent JSON field (keep the value) from null (clear it).
type OptionalDate struct {
	Set   bool
	Valid bool
	Time  time.Time
}

// UnmarshalJSON accepts null or "YYYY-MM-DD".
func (o *OptionalDate) UnmarshalJSON(b []byte) error {
	o.Set = true
	if bytes.Equal(b, []byte("null")) {
		return nil
	}
	var s string
	if err := json.Unmarshal(b, &s); err != nil {
		return err
	}
	t, err := time.Parse(time.DateOnly, s)
	if err != nil {
		return fmt.Errorf("fecha AAAA-MM-DD: %w", err)
	}
	o.Valid, o.Time = true, t
	return nil
}

func (o OptionalDate) apply(current pgtype.Date) pgtype.Date {
	if !o.Set {
		return current
	}
	return pgtype.Date{Time: o.Time, Valid: o.Valid}
}

// Review is the body of POST /v1/admin/kyc/documents/{id}/review. On approval the admin may
// correct the number and the dates (FR-009).
type Review struct {
	Decision    string       `json:"decision"`
	Reason      string       `json:"reason"`
	Number      *string      `json:"number"`
	ExpiresAt   OptionalDate `json:"expires_at"`
	ExemptUntil OptionalDate `json:"exempt_until"`
}

// ReviewDocument approves or rejects a submitted document and notifies the driver. Approving
// supersedes the previously approved document of the same type, which stayed in force while
// this one was in review (FR-007). Reviewer and time are stored (FR-012).
func (s *Service) ReviewDocument(ctx context.Context, adminID, docID uuid.UUID, in Review) (Document, error) {
	in.Reason = strings.TrimSpace(in.Reason)
	switch in.Decision {
	case "approve", "reject":
	default:
		return Document{}, ErrInvalidDecision
	}
	if in.Decision == "reject" && (in.Reason == "" || utf8.RuneCountInString(in.Reason) > 200) {
		return Document{}, ErrReasonRequired
	}
	now := s.now()
	today := drivers.Today(now)
	reviewedAt := pgtype.Timestamptz{Time: now, Valid: true}
	reviewer := uuid.NullUUID{UUID: adminID, Valid: true}
	var row store.DriverDocument
	var notice *store.Notice
	err := s.Store.WithTx(ctx, func(q *store.Queries) error {
		var err error
		row, err = q.GetDocumentForUpdate(ctx, docID)
		if store.IsNotFound(err) {
			return ErrNotFound
		}
		if err != nil {
			return err
		}
		if row.Status != store.DocumentStatusSubmitted {
			return ErrNotSubmitted
		}
		label := drivers.DocumentLabel(string(row.DocType))
		if in.Decision == "reject" {
			if err := q.RejectDocument(ctx, store.RejectDocumentParams{
				ID: docID, RejectReason: text(in.Reason), ReviewedBy: reviewer, ReviewedAt: reviewedAt,
			}); err != nil {
				return err
			}
			row.Status, row.RejectReason, row.ReviewedBy, row.ReviewedAt = store.DocumentStatusRejected, text(in.Reason), reviewer, reviewedAt
			rejections, err := q.CountRejectedDocuments(ctx, store.CountRejectedDocumentsParams{DriverID: row.DriverID, DocType: row.DocType})
			if err != nil {
				return err
			}
			body := label + " rechazado: " + in.Reason + ". Vuelve a enviarlo desde Documentos."
			if rejections >= supportAfterRejections {
				body += " Si necesitas ayuda, escribe a soporte de Kyq."
			}
			notice, err = notify.Create(ctx, q, row.DriverID, now, notify.Notice{
				Kind: "doc_rejected", DedupKey: "doc_rejected:" + docID.String(), Title: label + " rechazado", Body: body,
			})
			return err
		}

		number := row.Number
		if in.Number != nil {
			number = strings.TrimSpace(*in.Number)
			if !numberPattern.MatchString(number) {
				return ErrInvalidNumber
			}
		}
		expires := in.ExpiresAt.apply(row.ExpiresAt)
		exempt := in.ExemptUntil.apply(row.ExemptUntil)
		if exempt.Valid && row.DocType != store.DriverDocTypeTechnicalInspection {
			return ErrExemptNotAllowed
		}
		if drivers.DocumentExpires(string(row.DocType)) && !expires.Valid && !exempt.Valid {
			return ErrExpiresRequired
		}
		if err := q.SupersedeApprovedDocument(ctx, store.SupersedeApprovedDocumentParams{DriverID: row.DriverID, DocType: row.DocType}); err != nil {
			return err
		}
		if err := q.ApproveDocument(ctx, store.ApproveDocumentParams{
			ID: docID, Number: number, ExpiresAt: expires, ExemptUntil: exempt, ReviewedBy: reviewer, ReviewedAt: reviewedAt,
		}); err != nil {
			return err
		}
		row.Status, row.Number, row.ExpiresAt, row.ExemptUntil = store.DocumentStatusApproved, number, expires, exempt
		row.ReviewedBy, row.ReviewedAt, row.RejectReason = reviewer, reviewedAt, pgtype.Text{}

		approved, err := q.ListDocumentsForDrivers(ctx, []uuid.UUID{row.DriverID})
		if err != nil {
			return err
		}
		body := "Un administrador aprobó tu " + strings.ToLower(label[:1]) + label[1:] + "."
		if len(drivers.DocumentProblems(drivers.GateDocuments(approved), now)) == 0 {
			body += " Tus documentos están al día."
		}
		notice, err = notify.Create(ctx, q, row.DriverID, now, notify.Notice{
			Kind: "doc_approved", DedupKey: "doc_approved:" + docID.String(), Title: label + " aprobado", Body: body,
		})
		return err
	})
	if err != nil {
		return Document{}, err
	}
	s.Notify.Announce(ctx, notice)
	d := toDocument(row, today)
	return d, s.photosFor(ctx, []*Document{&d})
}

// QueueEntry is one driver waiting for review (FR-008), oldest first.
type QueueEntry struct {
	DriverID          uuid.UUID `json:"driver_id"`
	DisplayName       string    `json:"display_name"`
	VehiclePlate      string    `json:"vehicle_plate"`
	PendingDocuments  int64     `json:"pending_documents"`
	OldestSubmittedAt time.Time `json:"oldest_submitted_at"`
}

// Queue lists drivers with documents in review, oldest submission first.
func (s *Service) Queue(ctx context.Context) ([]QueueEntry, error) {
	rows, err := s.Store.ListKYCQueue(ctx)
	if err != nil {
		return nil, err
	}
	out := make([]QueueEntry, len(rows))
	for i, r := range rows {
		out[i] = QueueEntry{
			DriverID: r.DriverID, DisplayName: r.DisplayName, VehiclePlate: r.VehiclePlate,
			PendingDocuments: r.PendingDocuments, OldestSubmittedAt: r.OldestSubmittedAt,
		}
	}
	return out, nil
}

// DriverFile is the admin view of a driver's documents with signed photo URLs (5 min).
type DriverFile struct {
	DriverID         uuid.UUID                 `json:"driver_id"`
	DisplayName      string                    `json:"display_name"`
	PhoneE164        string                    `json:"phone_e164"`
	Status           string                    `json:"status"`
	Vehicle          *Vehicle                  `json:"vehicle"`
	Documents        []Slot                    `json:"documents"`
	BlockedDocuments []drivers.DocumentProblem `json:"blocked_documents"`
}

// File returns the KYC file of driverID for admins.
func (s *Service) File(ctx context.Context, driverID uuid.UUID) (DriverFile, error) {
	d, err := s.Store.GetDriverForKYC(ctx, driverID)
	if store.IsNotFound(err) {
		return DriverFile{}, ErrNotFound
	}
	if err != nil {
		return DriverFile{}, err
	}
	rows, err := s.Store.ListDriverDocuments(ctx, driverID)
	if err != nil {
		return DriverFile{}, err
	}
	now := s.now()
	slots, gate, err := s.file(ctx, rows, now)
	if err != nil {
		return DriverFile{}, err
	}
	vehicle, complete := vehicleFrom(d.VehiclePlate, d.VehicleBrand, d.VehicleModel, d.VehicleColor, d.VehicleYear)
	problems := drivers.DocumentProblems(gate, now)
	out := DriverFile{
		DriverID: d.UserID, DisplayName: d.DisplayName, PhoneE164: d.PhoneE164,
		Status: onboardingStatus(complete, slots, problems), Vehicle: vehicle, Documents: slots,
		BlockedDocuments: problems,
	}
	if out.BlockedDocuments == nil {
		out.BlockedDocuments = []drivers.DocumentProblem{}
	}
	return out, nil
}

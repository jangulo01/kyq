// Package kyc implements driver self onboarding: vehicle data, document submissions with photos
// in a private bucket, the admin review queue and expiry notices (spec 002, RN-KYQ-016).
package kyc

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"regexp"
	"slices"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"

	"github.com/kyq/backend/internal/drivers"
	"github.com/kyq/backend/internal/notify"
	"github.com/kyq/backend/internal/storage"
	"github.com/kyq/backend/internal/store"
)

// Photo limits (research R4): the app compresses to ≤ 1 MB; the server accepts up to 2 MB.
const (
	PhotoContentType = "image/jpeg"
	MaxPhotoBytes    = 2 << 20
	UploadURLTTL     = 10 * time.Minute
	ReadURLTTL       = 5 * time.Minute
	// Rechazos del mismo tipo a partir de los cuales se sugiere contactar a soporte.
	supportAfterRejections = 3
)

var (
	ErrNotFound         = errors.New("not found")
	ErrInvalidVehicle   = errors.New("invalid vehicle")
	ErrVehicleRequired  = errors.New("vehicle required")
	ErrInvalidDocType   = errors.New("invalid document type")
	ErrInvalidNumber    = errors.New("invalid document number")
	ErrExpiresRequired  = errors.New("expiry date required")
	ErrAlreadyExpired   = errors.New("document already expired")
	ErrInvalidSides     = errors.New("invalid photo sides")
	ErrDocumentInReview = errors.New("document in review")
	ErrNotUploading     = errors.New("document not uploading")
	ErrPhotosMissing    = errors.New("photos missing")
	ErrPhotoInvalid     = errors.New("photo invalid")
	ErrNotSubmitted     = errors.New("document not submitted")
	ErrReasonRequired   = errors.New("reject reason required")
	ErrInvalidDecision  = errors.New("invalid decision")
	ErrExemptNotAllowed = errors.New("exempt_until only for technical inspection")
)

var (
	platePattern  = regexp.MustCompile(`^[A-Z]{3}[0-9]{2}[0-9A-Z]$`)
	numberPattern = regexp.MustCompile(`^[0-9A-Za-z][0-9A-Za-z .\-]{0,39}$`)
)

// Onboarding states (data-model.md: drivers.onboarding_status).
const (
	StatusProfileIncomplete = "profile_incomplete"
	StatusDocumentsPending  = "documents_pending"
	StatusInReview          = "in_review"
	StatusDocumentsOK       = "documents_ok"
)

// Service holds the KYC use cases.
type Service struct {
	Store   *store.Store
	Objects storage.Objects
	Notify  *notify.Service
	Now     func() time.Time
	Logger  *slog.Logger
}

func (s *Service) now() time.Time {
	if s.Now != nil {
		return s.Now()
	}
	return time.Now()
}

func (s *Service) logger() *slog.Logger {
	if s.Logger != nil {
		return s.Logger
	}
	return slog.Default()
}

// Vehicle is the driver's vehicle (FR-002).
type Vehicle struct {
	Plate string `json:"plate"`
	Brand string `json:"brand"`
	Model string `json:"model"`
	Color string `json:"color"`
	Year  int    `json:"year"`
}

func (v *Vehicle) normalize() {
	v.Plate = strings.ToUpper(strings.Join(strings.Fields(v.Plate), ""))
	v.Brand = strings.TrimSpace(v.Brand)
	v.Model = strings.TrimSpace(v.Model)
	v.Color = strings.TrimSpace(v.Color)
}

func (v Vehicle) validate(now time.Time) error {
	textOK := func(s string, max int) bool { n := utf8.RuneCountInString(s); return n >= 1 && n <= max }
	switch {
	case !platePattern.MatchString(v.Plate):
		return fmt.Errorf("%w: placa con formato ABC123 o ABC12D", ErrInvalidVehicle)
	case !textOK(v.Brand, 40) || !textOK(v.Model, 40) || !textOK(v.Color, 30):
		return fmt.Errorf("%w: indica marca, modelo y color", ErrInvalidVehicle)
	case v.Year < 1990 || v.Year > now.Year()+1:
		return fmt.Errorf("%w: año entre 1990 y %d", ErrInvalidVehicle, now.Year()+1)
	}
	return nil
}

// Description is what passengers see of the vehicle (vehicle_description of 001).
func (v Vehicle) Description() string { return v.Brand + " " + v.Model + " " + v.Color }

// SetVehicle stores the vehicle of driverID.
func (s *Service) SetVehicle(ctx context.Context, driverID uuid.UUID, v Vehicle) (Vehicle, error) {
	v.normalize()
	if err := v.validate(s.now()); err != nil {
		return Vehicle{}, err
	}
	err := s.Store.SetDriverVehicle(ctx, store.SetDriverVehicleParams{
		UserID: driverID, VehiclePlate: v.Plate,
		VehicleBrand: text(v.Brand), VehicleModel: text(v.Model), VehicleColor: text(v.Color),
		VehicleYear: pgtype.Int2{Int16: int16(v.Year), Valid: true}, VehicleDescription: v.Description(),
	})
	return v, err
}

func vehicleFrom(plate string, brand, model, color pgtype.Text, year pgtype.Int2) (*Vehicle, bool) {
	if plate == "" && !brand.Valid {
		return nil, false
	}
	v := &Vehicle{Plate: plate, Brand: brand.String, Model: model.String, Color: color.String, Year: int(year.Int16)}
	complete := plate != "" && brand.Valid && model.Valid && color.Valid && year.Valid
	return v, complete
}

// Photo is a signed URL to read one side of a document (5 min).
type Photo struct {
	Side string `json:"side"`
	URL  string `json:"url"`
}

// Document is the JSON of a document submission (contracts: Document). Number is shown only to
// the driver and to admins (FR-011).
type Document struct {
	ID           uuid.UUID  `json:"id"`
	DocType      string     `json:"doc_type"`
	Number       string     `json:"number"`
	ExpiresAt    *string    `json:"expires_at"`
	ExemptUntil  *string    `json:"exempt_until"`
	Status       string     `json:"status"`
	Expired      bool       `json:"expired"`
	Legacy       bool       `json:"legacy"`
	RejectReason *string    `json:"reject_reason"`
	SubmittedAt  *time.Time `json:"submitted_at"`
	ReviewedAt   *time.Time `json:"reviewed_at"`
	Photos       []Photo    `json:"photos"`
}

func dateString(d pgtype.Date) *string {
	if !d.Valid {
		return nil
	}
	s := d.Time.Format(time.DateOnly)
	return &s
}

func timePtr(t pgtype.Timestamptz) *time.Time {
	if !t.Valid {
		return nil
	}
	v := t.Time
	return &v
}

func gateDoc(d store.DriverDocument) drivers.Document {
	return drivers.Document{
		Type: string(d.DocType), ExpiresAt: drivers.DateOrZero(d.ExpiresAt), ExemptUntil: drivers.DateOrZero(d.ExemptUntil),
		Approved: d.Status == store.DocumentStatusApproved,
	}
}

func toDocument(d store.DriverDocument, today time.Time) Document {
	out := Document{
		ID: d.ID, DocType: string(d.DocType), Number: d.Number, ExpiresAt: dateString(d.ExpiresAt),
		ExemptUntil: dateString(d.ExemptUntil), Status: string(d.Status), Legacy: d.Legacy,
		SubmittedAt: timePtr(d.SubmittedAt), ReviewedAt: timePtr(d.ReviewedAt), Photos: []Photo{},
	}
	if d.RejectReason.Valid {
		r := d.RejectReason.String
		out.RejectReason = &r
	}
	if d.Status == store.DocumentStatusApproved {
		out.Expired = !gateDoc(d).InForce(today)
	}
	return out
}

// photosFor adds signed read URLs of the uploaded photos of docs.
func (s *Service) photosFor(ctx context.Context, docs []*Document) error {
	if len(docs) == 0 {
		return nil
	}
	ids := make([]uuid.UUID, len(docs))
	byID := map[uuid.UUID]*Document{}
	for i, d := range docs {
		ids[i] = d.ID
		byID[d.ID] = d
	}
	rows, err := s.Store.ListDocumentPhotos(ctx, ids)
	if err != nil {
		return err
	}
	for _, p := range rows {
		if !p.UploadedAt.Valid {
			continue
		}
		u, err := s.Objects.PresignGet(ctx, p.ObjectKey, ReadURLTTL)
		if err != nil {
			return err
		}
		d := byID[p.DocumentID]
		d.Photos = append(d.Photos, Photo{Side: string(p.Side), URL: u})
	}
	return nil
}

// Slot is the state of one mandatory document type: Current is the approved one (in force or
// expired), Latest the newest submission when it is not Current (uploading, in review or
// rejected).
type Slot struct {
	DocType       string    `json:"doc_type"`
	Label         string    `json:"label"`
	Current       *Document `json:"current"`
	Latest        *Document `json:"latest"`
	RejectedCount int       `json:"rejected_count"`
	// Tras 3 rechazos del mismo documento se sugiere contactar a soporte.
	SuggestSupport bool `json:"suggest_support"`
}

// Onboarding is the body of GET /v1/driver/onboarding.
type Onboarding struct {
	Status             string                    `json:"status"`
	Vehicle            *Vehicle                  `json:"vehicle"`
	Documents          []Slot                    `json:"documents"`
	BlockedDocuments   []drivers.DocumentProblem `json:"blocked_documents"`
	SubscriptionStatus string                    `json:"subscription_status"`
	PaidUntil          *time.Time                `json:"paid_until"`
	CanGoOnline        bool                      `json:"can_go_online"`
}

// file builds the slots of a driver from all its documents.
func (s *Service) file(ctx context.Context, rows []store.DriverDocument, now time.Time) ([]Slot, []drivers.Document, error) {
	today := drivers.Today(now)
	slots := make([]Slot, len(drivers.MandatoryDocuments))
	index := map[string]int{}
	for i, t := range drivers.MandatoryDocuments {
		slots[i] = Slot{DocType: t, Label: drivers.DocumentLabel(t)}
		index[t] = i
	}
	var gate []drivers.Document
	var withPhotos []*Document
	// rows viene del más reciente al más antiguo.
	for _, r := range rows {
		slot := &slots[index[string(r.DocType)]]
		switch r.Status {
		case store.DocumentStatusApproved:
			d := toDocument(r, today)
			slot.Current = &d
			withPhotos = append(withPhotos, slot.Current)
			gate = append(gate, gateDoc(r))
		case store.DocumentStatusRejected, store.DocumentStatusUploading, store.DocumentStatusSubmitted:
			if slot.Current != nil {
				continue // más antiguo que el aprobado vigente
			}
			if r.Status == store.DocumentStatusRejected {
				slot.RejectedCount++
			}
			if slot.Latest == nil {
				d := toDocument(r, today)
				slot.Latest = &d
				withPhotos = append(withPhotos, slot.Latest)
			}
		}
	}
	for i := range slots {
		slots[i].SuggestSupport = slots[i].RejectedCount >= supportAfterRejections
	}
	return slots, gate, s.photosFor(ctx, withPhotos)
}

// onboardingStatus derives the onboarding state: documents in force win over an incomplete
// vehicle so drivers registered in 001 keep working.
func onboardingStatus(vehicleComplete bool, slots []Slot, problems []drivers.DocumentProblem) string {
	if len(problems) == 0 {
		return StatusDocumentsOK
	}
	if !vehicleComplete {
		return StatusProfileIncomplete
	}
	for _, p := range problems {
		slot := slots[slices.Index(drivers.MandatoryDocuments, p.Type)]
		if slot.Latest == nil || slot.Latest.Status != string(store.DocumentStatusSubmitted) {
			return StatusDocumentsPending
		}
	}
	return StatusInReview
}

// Onboarding returns the onboarding state of driverID.
func (s *Service) Onboarding(ctx context.Context, driverID uuid.UUID) (Onboarding, error) {
	profile, err := s.Store.GetDriverOnboardingProfile(ctx, driverID)
	if store.IsNotFound(err) {
		return Onboarding{}, ErrNotFound
	}
	if err != nil {
		return Onboarding{}, err
	}
	rows, err := s.Store.ListDriverDocuments(ctx, driverID)
	if err != nil {
		return Onboarding{}, err
	}
	now := s.now()
	slots, gate, err := s.file(ctx, rows, now)
	if err != nil {
		return Onboarding{}, err
	}
	vehicle, complete := vehicleFrom(profile.VehiclePlate, profile.VehicleBrand, profile.VehicleModel, profile.VehicleColor, profile.VehicleYear)
	problems := drivers.DocumentProblems(gate, now)
	out := Onboarding{
		Status: onboardingStatus(complete, slots, problems), Vehicle: vehicle, Documents: slots,
		BlockedDocuments: problems,
	}
	if out.BlockedDocuments == nil {
		out.BlockedDocuments = []drivers.DocumentProblem{}
	}
	var paidUntil time.Time
	if profile.PaidUntil.Valid {
		paidUntil = profile.PaidUntil.Time
		out.PaidUntil = &paidUntil
	}
	out.SubscriptionStatus = drivers.BillingStatus(out.PaidUntil, now)
	out.CanGoOnline = drivers.EvaluateOnline(paidUntil, gate, false, now) == drivers.BlockNone
	return out, nil
}

// NewDocument is the body of POST /v1/driver/documents.
type NewDocument struct {
	DocType   string     `json:"doc_type"`
	Number    string     `json:"number"`
	ExpiresAt *string    `json:"expires_at"`
	Sides     []string   `json:"sides"`
	expires   *time.Time `json:"-"`
}

// Upload is a signed URL to PUT one photo (image/jpeg, ≤ 2 MB, 10 min).
type Upload struct {
	Side string `json:"side"`
	URL  string `json:"url"`
}

func (n *NewDocument) validate(today time.Time) error {
	n.Number = strings.TrimSpace(n.Number)
	if !slices.Contains(drivers.MandatoryDocuments, n.DocType) {
		return ErrInvalidDocType
	}
	if !numberPattern.MatchString(n.Number) {
		return ErrInvalidNumber
	}
	if n.ExpiresAt != nil && *n.ExpiresAt != "" {
		t, err := time.Parse(time.DateOnly, *n.ExpiresAt)
		if err != nil {
			return ErrExpiresRequired
		}
		if !today.Before(t) {
			return ErrAlreadyExpired
		}
		if drivers.DocumentExpires(n.DocType) {
			n.expires = &t
		}
	}
	if drivers.DocumentExpires(n.DocType) && n.expires == nil {
		return ErrExpiresRequired
	}
	if len(n.Sides) == 0 || len(n.Sides) > 2 || !slices.Contains(n.Sides, "front") {
		return ErrInvalidSides
	}
	for i, side := range n.Sides {
		if (side != "front" && side != "back") || slices.Index(n.Sides, side) != i {
			return ErrInvalidSides
		}
	}
	return nil
}

// ObjectKey is the private key of a photo; it carries no personal data.
func ObjectKey(driverID, docID uuid.UUID, side string) string {
	return "kyc/" + driverID.String() + "/" + docID.String() + "/" + side + ".jpg"
}

// CreateDocument starts a submission in `uploading` and returns one signed upload URL per side.
// A previous unfinished upload of the same type is discarded; one in review blocks a new one.
func (s *Service) CreateDocument(ctx context.Context, driverID uuid.UUID, in NewDocument) (Document, []Upload, error) {
	now := s.now()
	if err := in.validate(drivers.Today(now)); err != nil {
		return Document{}, nil, err
	}
	profile, err := s.Store.GetDriverOnboardingProfile(ctx, driverID)
	if store.IsNotFound(err) {
		return Document{}, nil, ErrNotFound
	}
	if err != nil {
		return Document{}, nil, err
	}
	if _, complete := vehicleFrom(profile.VehiclePlate, profile.VehicleBrand, profile.VehicleModel, profile.VehicleColor, profile.VehicleYear); !complete {
		return Document{}, nil, ErrVehicleRequired
	}
	id, err := uuid.NewV7()
	if err != nil {
		return Document{}, nil, err
	}
	var discarded []string
	var row store.DriverDocument
	err = s.Store.WithTx(ctx, func(q *store.Queries) error {
		if _, err := q.LockDriver(ctx, driverID); err != nil {
			return err
		}
		prev, err := q.GetInFlightDocument(ctx, store.GetInFlightDocumentParams{DriverID: driverID, DocType: store.DriverDocType(in.DocType)})
		switch {
		case err == nil && prev.Status == store.DocumentStatusSubmitted:
			return ErrDocumentInReview
		case err == nil:
			photos, err := q.ListDocumentPhotos(ctx, []uuid.UUID{prev.ID})
			if err != nil {
				return err
			}
			for _, p := range photos {
				discarded = append(discarded, p.ObjectKey)
			}
			if err := q.DeleteDocument(ctx, prev.ID); err != nil {
				return err
			}
		case !store.IsNotFound(err):
			return err
		}
		params := store.InsertDocumentParams{
			ID: id, DriverID: driverID, DocType: store.DriverDocType(in.DocType), Number: in.Number,
			Status: store.DocumentStatusUploading,
		}
		if in.expires != nil {
			params.ExpiresAt = pgtype.Date{Time: *in.expires, Valid: true}
		}
		row, err = q.InsertDocument(ctx, params)
		if err != nil {
			return err
		}
		for _, side := range in.Sides {
			if err := q.InsertDocumentPhoto(ctx, store.InsertDocumentPhotoParams{
				DocumentID: id, Side: store.DocumentSide(side), ObjectKey: ObjectKey(driverID, id, side),
			}); err != nil {
				return err
			}
		}
		return nil
	})
	if err != nil {
		return Document{}, nil, err
	}
	for _, key := range discarded {
		if err := s.Objects.Remove(ctx, key); err != nil {
			s.logger().WarnContext(ctx, "remove discarded kyc photo", "err", err)
		}
	}
	uploads := make([]Upload, len(in.Sides))
	for i, side := range in.Sides {
		u, err := s.Objects.PresignPut(ctx, ObjectKey(driverID, id, side), PhotoContentType, UploadURLTTL)
		if err != nil {
			return Document{}, nil, err
		}
		uploads[i] = Upload{Side: side, URL: u}
	}
	return toDocument(row, drivers.Today(now)), uploads, nil
}

// Submit checks that every photo was uploaded (JPEG, ≤ 2 MB) and moves the document to
// `submitted`: it enters the review queue.
func (s *Service) Submit(ctx context.Context, driverID, docID uuid.UUID) (Document, error) {
	photos, err := s.Store.ListDocumentPhotos(ctx, []uuid.UUID{docID})
	if err != nil {
		return Document{}, err
	}
	for _, p := range photos {
		info, err := s.Objects.Stat(ctx, p.ObjectKey)
		if errors.Is(err, storage.ErrNotFound) {
			return Document{}, ErrPhotosMissing
		}
		if err != nil {
			return Document{}, err
		}
		if info.Size > MaxPhotoBytes || info.Size == 0 || !strings.HasPrefix(info.ContentType, PhotoContentType) {
			if err := s.Objects.Remove(ctx, p.ObjectKey); err != nil {
				s.logger().WarnContext(ctx, "remove invalid kyc photo", "err", err)
			}
			return Document{}, ErrPhotoInvalid
		}
	}
	now := s.now()
	var row store.DriverDocument
	err = s.Store.WithTx(ctx, func(q *store.Queries) error {
		var err error
		row, err = q.GetDocumentForUpdate(ctx, docID)
		if store.IsNotFound(err) || (err == nil && row.DriverID != driverID) {
			return ErrNotFound
		}
		if err != nil {
			return err
		}
		if row.Status != store.DocumentStatusUploading {
			return ErrNotUploading
		}
		if len(photos) == 0 {
			return ErrPhotosMissing
		}
		for _, p := range photos {
			if err := q.MarkPhotoUploaded(ctx, store.MarkPhotoUploadedParams{
				DocumentID: docID, Side: p.Side, UploadedAt: pgtype.Timestamptz{Time: now, Valid: true},
			}); err != nil {
				return err
			}
		}
		if err := q.SubmitDocument(ctx, store.SubmitDocumentParams{ID: docID, SubmittedAt: pgtype.Timestamptz{Time: now, Valid: true}}); err != nil {
			return err
		}
		row.Status = store.DocumentStatusSubmitted
		row.SubmittedAt = pgtype.Timestamptz{Time: now, Valid: true}
		return nil
	})
	if err != nil {
		return Document{}, err
	}
	d := toDocument(row, drivers.Today(now))
	return d, s.photosFor(ctx, []*Document{&d})
}

func text(s string) pgtype.Text { return pgtype.Text{String: s, Valid: true} }

// Package admin implements the minimal administration endpoints (FR-004).
package admin

import (
	"context"
	"crypto/rand"
	"encoding/base64"
	"errors"
	"net/http"
	"regexp"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/kyq/backend/internal/auth"
	"github.com/kyq/backend/internal/drivers"
	"github.com/kyq/backend/internal/httpx"
	"github.com/kyq/backend/internal/store"
)

var phoneE164 = regexp.MustCompile(`^\+[1-9][0-9]{6,14}$`)

// Handlers serves /v1/admin/*. Every route requires the admin role.
type Handlers struct {
	Store *store.Store
	Now   func() time.Time
}

// Register mounts the routes on mux behind authMW and the admin role check.
func (h *Handlers) Register(mux *http.ServeMux, authMW func(http.Handler) http.Handler) {
	guard := func(f http.HandlerFunc) http.Handler { return authMW(auth.RequireRole(auth.RoleAdmin)(f)) }
	mux.Handle("GET /v1/admin/drivers", guard(h.listDrivers))
	mux.Handle("POST /v1/admin/drivers", guard(h.createDriver))
	mux.Handle("PUT /v1/admin/drivers/{driverId}/subscription", guard(h.putSubscription))
	mux.Handle("PUT /v1/admin/drivers/{driverId}/documents/{docType}", guard(h.putDocument))
}

func (h *Handlers) now() time.Time {
	if h.Now != nil {
		return h.Now()
	}
	return time.Now()
}

// DriverDocument is the admin view of a document.
type DriverDocument struct {
	DocType   string `json:"doc_type"`
	ExpiresAt string `json:"expires_at"`
	Approved  bool   `json:"approved"`
}

// DriverSummary is one row of GET /v1/admin/drivers.
type DriverSummary struct {
	DriverID           uuid.UUID        `json:"driver_id"`
	PhoneE164          string           `json:"phone_e164"`
	DisplayName        string           `json:"display_name"`
	QRToken            string           `json:"qr_token"`
	VehiclePlate       string           `json:"vehicle_plate"`
	VehicleDescription string           `json:"vehicle_description"`
	Presence           string           `json:"presence"`
	PaidUntil          *time.Time       `json:"paid_until"`
	SubscriptionStatus string           `json:"subscription_status"`
	CanGoOnline        bool             `json:"can_go_online"`
	BlockReason        *string          `json:"block_reason"`
	Documents          []DriverDocument `json:"documents"`
}

func (h *Handlers) listDrivers(w http.ResponseWriter, r *http.Request) {
	out, err := ListDrivers(r.Context(), h.Store.Queries, h.now())
	if err != nil {
		httpx.InternalError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, out)
}

// ListDrivers returns every driver with subscription, documents and ONLINE eligibility.
func ListDrivers(ctx context.Context, q *store.Queries, now time.Time) ([]DriverSummary, error) {
	rows, err := q.ListDriversForAdmin(ctx)
	if err != nil {
		return nil, err
	}
	ids := make([]uuid.UUID, len(rows))
	for i, row := range rows {
		ids[i] = row.ID
	}
	docRows, err := q.ListDocumentsForDrivers(ctx, ids)
	if err != nil {
		return nil, err
	}
	docs := map[uuid.UUID][]store.ListDocumentsForDriversRow{}
	for _, d := range docRows {
		docs[d.DriverID] = append(docs[d.DriverID], d)
	}

	out := make([]DriverSummary, 0, len(rows))
	for _, row := range rows {
		var paidUntil time.Time
		s := DriverSummary{
			DriverID: row.ID, PhoneE164: row.PhoneE164, DisplayName: row.DisplayName,
			QRToken: row.QrToken, VehiclePlate: row.VehiclePlate,
			VehicleDescription: row.VehicleDescription, Presence: string(row.Presence),
			Documents: []DriverDocument{},
		}
		if row.PaidUntil.Valid {
			paidUntil = row.PaidUntil.Time
			s.PaidUntil = &paidUntil
		}
		gateDocs := make([]drivers.Document, 0, len(docs[row.ID]))
		for _, d := range docs[row.ID] {
			s.Documents = append(s.Documents, DriverDocument{
				DocType: string(d.DocType), ExpiresAt: d.ExpiresAt.Format(time.DateOnly), Approved: d.Approved,
			})
			gateDocs = append(gateDocs, drivers.Document{Type: string(d.DocType), ExpiresAt: d.ExpiresAt, Approved: d.Approved})
		}
		s.SubscriptionStatus = string(drivers.SubscriptionStatusAt(paidUntil, now))
		// La lista de admin no conoce viajes en curso; se evalúa como si no hubiera.
		if reason := drivers.EvaluateOnline(paidUntil, gateDocs, false, now); reason == drivers.BlockNone {
			s.CanGoOnline = true
		} else {
			str := string(reason)
			s.BlockReason = &str
		}
		out = append(out, s)
	}
	return out, nil
}

func (h *Handlers) createDriver(w http.ResponseWriter, r *http.Request) {
	var body struct {
		Phone              string `json:"phone_e164"`
		DisplayName        string `json:"display_name"`
		VehiclePlate       string `json:"vehicle_plate"`
		VehicleDescription string `json:"vehicle_description"`
	}
	if !httpx.DecodeJSON(w, r, &body) {
		return
	}
	body.DisplayName = strings.TrimSpace(body.DisplayName)
	body.VehiclePlate = strings.ToUpper(strings.TrimSpace(body.VehiclePlate))
	body.VehicleDescription = strings.TrimSpace(body.VehicleDescription)
	switch {
	case !phoneE164.MatchString(body.Phone):
		httpx.WriteError(w, http.StatusBadRequest, "invalid_phone", "el teléfono debe estar en formato E.164")
		return
	case utf8.RuneCountInString(body.DisplayName) < 2 || utf8.RuneCountInString(body.DisplayName) > 60:
		httpx.WriteError(w, http.StatusBadRequest, "invalid_display_name", "el nombre debe tener de 2 a 60 caracteres")
		return
	case body.VehiclePlate == "" || body.VehicleDescription == "":
		httpx.WriteError(w, http.StatusBadRequest, "invalid_vehicle", "indica placa y descripción del vehículo")
		return
	}

	id, err := uuid.NewV7()
	if err != nil {
		httpx.InternalError(w, r, err)
		return
	}
	qr, err := newQRToken()
	if err != nil {
		httpx.InternalError(w, r, err)
		return
	}
	errPhoneInUse := errors.New("phone in use")
	err = h.Store.WithTx(r.Context(), func(q *store.Queries) error {
		if _, err := q.GetUserByPhone(r.Context(), body.Phone); err == nil {
			return errPhoneInUse
		} else if !store.IsNotFound(err) {
			return err
		}
		if _, err := q.CreateUser(r.Context(), store.CreateUserParams{
			ID: id, PhoneE164: body.Phone, Role: store.UserRoleDriver, DisplayName: body.DisplayName,
		}); err != nil {
			return err
		}
		return q.CreateDriver(r.Context(), store.CreateDriverParams{
			UserID: id, QrToken: qr, VehiclePlate: body.VehiclePlate, VehicleDescription: body.VehicleDescription,
		})
	})
	if errors.Is(err, errPhoneInUse) {
		httpx.WriteError(w, http.StatusConflict, "phone_in_use", "ese teléfono ya tiene una cuenta")
		return
	}
	if err != nil {
		httpx.InternalError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusCreated, map[string]any{"driver_id": id, "qr_token": qr})
}

func (h *Handlers) putSubscription(w http.ResponseWriter, r *http.Request) {
	driverID, ok := h.driverID(w, r)
	if !ok {
		return
	}
	var body struct {
		PaidUntil time.Time `json:"paid_until"`
	}
	if !httpx.DecodeJSON(w, r, &body) {
		return
	}
	if body.PaidUntil.IsZero() {
		httpx.WriteError(w, http.StatusBadRequest, "invalid_paid_until", "indica paid_until en RFC 3339")
		return
	}
	admin, _ := auth.FromContext(r.Context())
	err := h.Store.UpsertSubscription(r.Context(), store.UpsertSubscriptionParams{
		DriverID: driverID, PaidUntil: body.PaidUntil, UpdatedBy: admin.UserID,
	})
	if err != nil {
		httpx.InternalError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, map[string]any{
		"driver_id":           driverID,
		"paid_until":          body.PaidUntil,
		"subscription_status": drivers.SubscriptionStatusAt(body.PaidUntil, h.now()),
	})
}

func (h *Handlers) putDocument(w http.ResponseWriter, r *http.Request) {
	driverID, ok := h.driverID(w, r)
	if !ok {
		return
	}
	docType := r.PathValue("docType")
	switch docType {
	case drivers.DocLicense, drivers.DocMandatoryInsurance, drivers.DocVehicleRegistration:
	default:
		httpx.WriteError(w, http.StatusBadRequest, "invalid_doc_type", "tipo de documento desconocido")
		return
	}
	var body struct {
		ExpiresAt string `json:"expires_at"`
		Approved  bool   `json:"approved"`
	}
	if !httpx.DecodeJSON(w, r, &body) {
		return
	}
	expires, err := time.Parse(time.DateOnly, body.ExpiresAt)
	if err != nil {
		httpx.WriteError(w, http.StatusBadRequest, "invalid_expires_at", "expires_at debe ser AAAA-MM-DD")
		return
	}
	id, err := uuid.NewV7()
	if err != nil {
		httpx.InternalError(w, r, err)
		return
	}
	params := store.UpsertDriverDocumentParams{
		ID: id, DriverID: driverID, DocType: store.DriverDocType(docType), ExpiresAt: expires,
	}
	if body.Approved {
		admin, _ := auth.FromContext(r.Context())
		params.ApprovedBy = uuid.NullUUID{UUID: admin.UserID, Valid: true}
		params.ApprovedAt = pgtype.Timestamptz{Time: h.now(), Valid: true}
	}
	if err := h.Store.UpsertDriverDocument(r.Context(), params); err != nil {
		httpx.InternalError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, DriverDocument{DocType: docType, ExpiresAt: body.ExpiresAt, Approved: body.Approved})
}

func (h *Handlers) driverID(w http.ResponseWriter, r *http.Request) (uuid.UUID, bool) {
	id, err := uuid.Parse(r.PathValue("driverId"))
	if err != nil {
		httpx.WriteError(w, http.StatusNotFound, "not_found", "conductor no encontrado")
		return uuid.Nil, false
	}
	exists, err := h.Store.DriverExists(r.Context(), id)
	if err != nil {
		httpx.InternalError(w, r, err)
		return uuid.Nil, false
	}
	if !exists {
		httpx.WriteError(w, http.StatusNotFound, "not_found", "conductor no encontrado")
		return uuid.Nil, false
	}
	return id, true
}

// newQRToken returns 128 random bits, URL-safe (FR-005).
func newQRToken() (string, error) {
	var b [16]byte
	if _, err := rand.Read(b[:]); err != nil {
		return "", err
	}
	return base64.RawURLEncoding.EncodeToString(b[:]), nil
}

package safety

import (
	"bytes"
	"errors"
	"html/template"
	"net/http"
	"time"

	"github.com/google/uuid"

	"github.com/kyq/backend/internal/auth"
	"github.com/kyq/backend/internal/httpx"
	"github.com/kyq/backend/web/share"
)

// Handlers serves the SOS routes of the apps, the console (/v1/ops/*), the shared trip (public)
// and the safety profile (/v1/me/*).
type Handlers struct {
	Service *Service
	// MapStyleURL is the MapLibre style of the shared trip page; empty: the tiles service on
	// port 8081 of the same host.
	MapStyleURL string
}

var sharePage = template.Must(template.New("share").Parse(share.Page))

// Register mounts the routes on mux behind authMW, except the public shared trip.
func (h *Handlers) Register(mux *http.ServeMux, authMW func(http.Handler) http.Handler) {
	party := func(f http.HandlerFunc) http.Handler {
		return authMW(auth.RequireRole(auth.RolePassenger, auth.RoleDriver)(f))
	}
	ops := func(f http.HandlerFunc) http.Handler { return authMW(auth.RequireRole(auth.RoleAdmin)(f)) }

	mux.Handle("POST /v1/trips/{tripId}/sos", party(h.raise))
	mux.Handle("GET /v1/sos/active", party(h.active))
	mux.Handle("POST /v1/sos/{alertId}/locations", party(h.locations))
	mux.Handle("POST /v1/sos/{alertId}/cancel", party(h.cancel))
	mux.Handle("GET /v1/sos/{alertId}/token", party(h.token))

	mux.Handle("POST /v1/trips/{tripId}/share", party(h.share))
	mux.HandleFunc("GET /v1/share/{token}", h.shared)
	mux.HandleFunc("GET /s/{token}", h.sharedPage)

	mux.Handle("GET /v1/me/emergency-contacts", party(h.contacts))
	mux.Handle("PUT /v1/me/emergency-contacts", party(h.putContacts))
	mux.Handle("GET /v1/me/safety-pin", party(h.pin))
	mux.Handle("PUT /v1/me/safety-pin", party(h.putPIN))

	mux.Handle("GET /v1/ops/sos", ops(h.list))
	mux.Handle("GET /v1/ops/sos/{alertId}", ops(h.detail))
	mux.Handle("POST /v1/ops/sos/{alertId}/claim", ops(h.claim))
	mux.Handle("POST /v1/ops/sos/{alertId}/release", ops(h.release))
	mux.Handle("POST /v1/ops/sos/{alertId}/notes", ops(h.note))
	mux.Handle("POST /v1/ops/sos/{alertId}/close", ops(h.close))
	mux.Handle("POST /v1/ops/sos/{alertId}/token", ops(h.operatorToken))
	mux.Handle("GET /v1/ops/duty", ops(h.duty))
	mux.Handle("PUT /v1/ops/duty", ops(h.putDuty))
}

func caller(r *http.Request) uuid.UUID {
	p, _ := auth.FromContext(r.Context())
	return p.UserID
}

func pathID(w http.ResponseWriter, r *http.Request, name, notFound string) (uuid.UUID, bool) {
	id, err := uuid.Parse(r.PathValue(name))
	if err != nil {
		httpx.WriteError(w, http.StatusNotFound, "not_found", notFound)
		return uuid.Nil, false
	}
	return id, true
}

func (h *Handlers) raise(w http.ResponseWriter, r *http.Request) {
	tripID, ok := pathID(w, r, "tripId", "viaje no encontrado")
	if !ok {
		return
	}
	var body struct {
		Location *Point `json:"location"`
	}
	if r.ContentLength != 0 && !httpx.DecodeJSON(w, r, &body) {
		return
	}
	out, created, err := h.Service.Raise(r.Context(), caller(r), tripID, body.Location)
	if err != nil {
		writeError(w, r, err)
		return
	}
	status := http.StatusOK
	if created {
		status = http.StatusCreated
	}
	httpx.WriteJSON(w, status, out)
}

func (h *Handlers) active(w http.ResponseWriter, r *http.Request) {
	alert, err := h.Service.Active(r.Context(), caller(r))
	if err != nil {
		writeError(w, r, err)
		return
	}
	if alert == nil {
		w.WriteHeader(http.StatusNoContent)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, alert)
}

func (h *Handlers) locations(w http.ResponseWriter, r *http.Request) {
	alertID, ok := pathID(w, r, "alertId", "alerta no encontrada")
	if !ok {
		return
	}
	var body struct {
		Points []Point `json:"points"`
	}
	if !httpx.DecodeJSON(w, r, &body) {
		return
	}
	out, err := h.Service.Locations(r.Context(), caller(r), alertID, body.Points)
	if err != nil {
		writeError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, out)
}

func (h *Handlers) cancel(w http.ResponseWriter, r *http.Request) {
	alertID, ok := pathID(w, r, "alertId", "alerta no encontrada")
	if !ok {
		return
	}
	var body struct {
		PIN string `json:"pin"`
	}
	if !httpx.DecodeJSON(w, r, &body) {
		return
	}
	if err := h.Service.Cancel(r.Context(), caller(r), alertID, body.PIN); err != nil {
		writeError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handlers) token(w http.ResponseWriter, r *http.Request) {
	alertID, ok := pathID(w, r, "alertId", "alerta no encontrada")
	if !ok {
		return
	}
	creds, err := h.Service.Token(r.Context(), caller(r), alertID)
	if err != nil {
		writeError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, creds)
}

func (h *Handlers) share(w http.ResponseWriter, r *http.Request) {
	tripID, ok := pathID(w, r, "tripId", "viaje no encontrado")
	if !ok {
		return
	}
	link, err := h.Service.Share(r.Context(), caller(r), tripID)
	if err != nil {
		writeError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, link)
}

// publicHeaders keep a shared trip out of caches, search engines and referrers.
func publicHeaders(w http.ResponseWriter) {
	w.Header().Set("Cache-Control", "no-store")
	w.Header().Set("Referrer-Policy", "no-referrer")
	w.Header().Set("X-Robots-Tag", "noindex, nofollow")
	w.Header().Set("X-Content-Type-Options", "nosniff")
}

func (h *Handlers) shared(w http.ResponseWriter, r *http.Request) {
	publicHeaders(w)
	trip, err := h.Service.Shared(r.Context(), r.PathValue("token"))
	if err != nil {
		writeError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, trip)
}

func (h *Handlers) sharedPage(w http.ResponseWriter, r *http.Request) {
	publicHeaders(w)
	var buf bytes.Buffer
	if err := sharePage.Execute(&buf, struct{ StyleURL string }{h.MapStyleURL}); err != nil {
		httpx.InternalError(w, r, err)
		return
	}
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	w.Header().Set("Content-Security-Policy", "default-src 'self'; script-src 'self' 'unsafe-inline' https://unpkg.com; "+
		"style-src 'self' 'unsafe-inline' https://unpkg.com; img-src * data: blob:; connect-src *; worker-src blob:; "+
		"child-src blob:; frame-ancestors 'none'")
	_, _ = w.Write(buf.Bytes())
}

func (h *Handlers) contacts(w http.ResponseWriter, r *http.Request) {
	contacts, err := h.Service.Contacts(r.Context(), caller(r))
	if err != nil {
		writeError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, map[string]any{"contacts": contacts})
}

func (h *Handlers) putContacts(w http.ResponseWriter, r *http.Request) {
	var body struct {
		Contacts []Contact `json:"contacts"`
	}
	if !httpx.DecodeJSON(w, r, &body) {
		return
	}
	contacts, err := h.Service.SetContacts(r.Context(), caller(r), body.Contacts)
	if err != nil {
		writeError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, map[string]any{"contacts": contacts})
}

func (h *Handlers) pin(w http.ResponseWriter, r *http.Request) {
	has, err := h.Service.HasPIN(r.Context(), caller(r))
	if err != nil {
		writeError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, map[string]bool{"has_pin": has})
}

func (h *Handlers) putPIN(w http.ResponseWriter, r *http.Request) {
	var body struct {
		PIN        string  `json:"pin"`
		CurrentPIN *string `json:"current_pin"`
	}
	if !httpx.DecodeJSON(w, r, &body) {
		return
	}
	if err := h.Service.SetPIN(r.Context(), caller(r), body.PIN, body.CurrentPIN); err != nil {
		writeError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handlers) list(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	var (
		out []AlertSummary
		err error
	)
	switch q.Get("view") {
	case "", "open":
		out, err = h.Service.ListOpen(r.Context(), caller(r))
	case "history":
		now := h.Service.now()
		f := HistoryFilter{From: now.AddDate(0, 0, -30), To: now.Add(time.Minute), Outcome: q.Get("outcome")}
		if v := q.Get("from"); v != "" {
			if f.From, err = time.Parse(time.DateOnly, v); err != nil {
				httpx.WriteError(w, http.StatusBadRequest, "invalid_filter", "from debe ser AAAA-MM-DD")
				return
			}
		}
		if v := q.Get("to"); v != "" {
			to, err := time.Parse(time.DateOnly, v)
			if err != nil {
				httpx.WriteError(w, http.StatusBadRequest, "invalid_filter", "to debe ser AAAA-MM-DD")
				return
			}
			f.To = to.AddDate(0, 0, 1) // incluye el día indicado
		}
		out, err = h.Service.ListHistory(r.Context(), caller(r), f)
	default:
		httpx.WriteError(w, http.StatusBadRequest, "invalid_filter", "view debe ser open o history")
		return
	}
	if err != nil {
		writeError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, out)
}

func (h *Handlers) detail(w http.ResponseWriter, r *http.Request) {
	alertID, ok := pathID(w, r, "alertId", "alerta no encontrada")
	if !ok {
		return
	}
	d, err := h.Service.Detail(r.Context(), caller(r), alertID)
	if err != nil {
		writeError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, d)
}

func (h *Handlers) claim(w http.ResponseWriter, r *http.Request) {
	alertID, ok := pathID(w, r, "alertId", "alerta no encontrada")
	if !ok {
		return
	}
	out, err := h.Service.Claim(r.Context(), caller(r), alertID)
	if err != nil {
		writeError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, out)
}

func (h *Handlers) release(w http.ResponseWriter, r *http.Request) {
	alertID, ok := pathID(w, r, "alertId", "alerta no encontrada")
	if !ok {
		return
	}
	if err := h.Service.Release(r.Context(), caller(r), alertID); err != nil {
		writeError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handlers) note(w http.ResponseWriter, r *http.Request) {
	alertID, ok := pathID(w, r, "alertId", "alerta no encontrada")
	if !ok {
		return
	}
	var body struct {
		Body string `json:"body"`
	}
	if !httpx.DecodeJSON(w, r, &body) {
		return
	}
	n, err := h.Service.AddNote(r.Context(), caller(r), alertID, body.Body)
	if err != nil {
		writeError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusCreated, n)
}

func (h *Handlers) close(w http.ResponseWriter, r *http.Request) {
	alertID, ok := pathID(w, r, "alertId", "alerta no encontrada")
	if !ok {
		return
	}
	var body struct {
		Outcome string `json:"outcome"`
	}
	if !httpx.DecodeJSON(w, r, &body) {
		return
	}
	if err := h.Service.Close(r.Context(), caller(r), alertID, body.Outcome); err != nil {
		writeError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handlers) operatorToken(w http.ResponseWriter, r *http.Request) {
	alertID, ok := pathID(w, r, "alertId", "alerta no encontrada")
	if !ok {
		return
	}
	creds, err := h.Service.OperatorToken(r.Context(), caller(r), alertID)
	if err != nil {
		writeError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, creds)
}

func (h *Handlers) duty(w http.ResponseWriter, r *http.Request) {
	on, err := h.Service.Duty(r.Context(), caller(r))
	if err != nil {
		writeError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, map[string]bool{"on_duty": on})
}

func (h *Handlers) putDuty(w http.ResponseWriter, r *http.Request) {
	var body struct {
		OnDuty *bool `json:"on_duty"`
	}
	if !httpx.DecodeJSON(w, r, &body) {
		return
	}
	if body.OnDuty == nil {
		httpx.WriteError(w, http.StatusBadRequest, "invalid_body", "indica on_duty")
		return
	}
	if err := h.Service.SetDuty(r.Context(), caller(r), *body.OnDuty); err != nil {
		writeError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, map[string]bool{"on_duty": *body.OnDuty})
}

func writeError(w http.ResponseWriter, r *http.Request, err error) {
	type mapped struct {
		status        int
		code, message string
	}
	table := []struct {
		err error
		m   mapped
	}{
		{ErrNotFound, mapped{http.StatusNotFound, "not_found", "no encontrado"}},
		{ErrUnavailable, mapped{http.StatusConflict, "sos_unavailable", "el SOS solo está disponible durante un viaje; si estás en peligro llama al 123"}},
		{ErrClosed, mapped{http.StatusGone, "sos_closed", "la alerta ya está cerrada"}},
		{ErrInvalidLocation, mapped{http.StatusBadRequest, "invalid_location", "ubicación inválida (1 a 5 puntos con coordenadas válidas)"}},
		{ErrNoPIN, mapped{http.StatusForbidden, "no_pin", "no tienes PIN de seguridad: la alerta sigue abierta hasta que el operador la cierre"}},
		{ErrInvalidPIN, mapped{http.StatusForbidden, "invalid_pin", "PIN incorrecto: la alerta sigue abierta"}},
		{ErrPINLocked, mapped{http.StatusLocked, "pin_locked", "demasiados intentos: la alerta sigue abierta hasta que el operador la cierre"}},
		{ErrVoiceUnavailable, mapped{http.StatusServiceUnavailable, "sos_voice_unavailable", "el servidor de voz no responde, inténtalo de nuevo"}},
		{ErrShareUnavailable, mapped{http.StatusConflict, "share_unavailable", "solo se comparte un viaje aceptado y sin terminar"}},
		{ErrShareExpired, mapped{http.StatusGone, "share_expired", "viaje finalizado"}},
		{ErrTooManyContacts, mapped{http.StatusBadRequest, "too_many_contacts", "máximo 3 contactos de emergencia"}},
		{ErrInvalidContact, mapped{http.StatusBadRequest, "invalid_contact", "cada contacto necesita nombre (2 a 60 caracteres) y teléfono en formato E.164"}},
		{ErrInvalidPINFormat, mapped{http.StatusBadRequest, "invalid_pin_format", "el PIN debe tener 4 dígitos"}},
		{ErrWrongCurrentPIN, mapped{http.StatusForbidden, "wrong_current_pin", "el PIN actual no coincide"}},
		{ErrPINDuringSOS, mapped{http.StatusConflict, "sos_active", "no puedes cambiar el PIN con una alerta abierta"}},
		{ErrNotOperator, mapped{http.StatusForbidden, "not_emergency_operator", "necesitas el permiso de operador de emergencias"}},
		{ErrClaimed, mapped{http.StatusConflict, "sos_claimed", "otro operador atiende esta alerta"}},
		{ErrNotClaimant, mapped{http.StatusConflict, "sos_not_claimed", "toma la alerta antes de hacer esto"}},
		{ErrInvalidOutcome, mapped{http.StatusBadRequest, "invalid_outcome", "indica el desenlace: false_alarm, resolved, escalated_authorities o no_response"}},
		{ErrInvalidNote, mapped{http.StatusBadRequest, "invalid_note", "la nota debe tener de 1 a 2000 caracteres"}},
		{ErrInvalidFilter, mapped{http.StatusBadRequest, "invalid_filter", "filtro inválido"}},
	}
	for _, e := range table {
		if errors.Is(err, e.err) {
			httpx.WriteError(w, e.m.status, e.m.code, e.m.message)
			return
		}
	}
	httpx.InternalError(w, r, err)
}

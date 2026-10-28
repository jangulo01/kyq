package radio

import (
	"errors"
	"io"
	"net/http"
	"strconv"

	"github.com/google/uuid"

	"github.com/kyq/backend/internal/auth"
	"github.com/kyq/backend/internal/httpx"
)

// Handlers serves /v1/radio/* (drivers and passengers), the public invitation views and /r/{code}.
type Handlers struct{ Service *Service }

// Register mounts the routes behind authMW; drivers and passengers share them (the service
// decides per role).
func (h *Handlers) Register(mux *http.ServeMux, authMW func(http.Handler) http.Handler) {
	user := func(f http.HandlerFunc) http.Handler {
		return authMW(auth.RequireRole(auth.RoleDriver, auth.RolePassenger)(f))
	}
	driver := func(f http.HandlerFunc) http.Handler { return authMW(auth.RequireRole(auth.RoleDriver)(f)) }
	admin := func(f http.HandlerFunc) http.Handler { return authMW(auth.RequireRole(auth.RoleAdmin)(f)) }
	mux.Handle("GET /v1/radio/me", user(h.me))
	mux.Handle("PUT /v1/radio/me", user(h.updateMe))
	mux.Handle("POST /v1/radio/me/consent", user(h.consent))
	mux.Handle("POST /v1/radio/me/heartbeat", user(h.heartbeat))
	mux.Handle("GET /v1/radio/me/quiet-hours", user(h.quietHours))
	mux.Handle("PUT /v1/radio/me/quiet-hours", user(h.setQuietHours))
	mux.Handle("GET /v1/radio/conversations", user(h.list))
	mux.Handle("GET /v1/radio/conversations/{conversationId}", user(h.detail))
	mux.Handle("DELETE /v1/radio/conversations/{conversationId}", user(h.delete))
	mux.Handle("PUT /v1/radio/conversations/{conversationId}/listening", user(h.listening))
	mux.Handle("POST /v1/radio/conversations/{conversationId}/ptt/token", user(h.token))
	mux.Handle("POST /v1/radio/conversations/{conversationId}/ptt/floor", user(h.takeFloor))
	mux.Handle("DELETE /v1/radio/conversations/{conversationId}/ptt/floor", user(h.releaseFloor))
	mux.Handle("GET /v1/radio/conversations/{conversationId}/messages", user(h.history))
	mux.Handle("POST /v1/radio/conversations/{conversationId}/messages", user(h.send))
	mux.Handle("POST /v1/radio/conversations/{conversationId}/photos", user(h.reservePhoto))
	mux.Handle("POST /v1/radio/conversations/{conversationId}/emergency", user(h.emergency))
	mux.Handle("POST /v1/radio/messages/{messageId}/photo-uploaded", user(h.photoUploaded))
	mux.Handle("GET /v1/radio/messages/{messageId}/media", user(h.media))
	mux.Handle("PUT /v1/radio/messages/{messageId}/receipt", user(h.receipt))
	mux.Handle("POST /v1/radio/contacts/invites", driver(h.inviteContact))
	mux.Handle("POST /v1/radio/channels", driver(h.createChannel))
	mux.Handle("PATCH /v1/radio/channels/{conversationId}", driver(h.updateChannel))
	mux.Handle("POST /v1/radio/channels/{conversationId}/invite", driver(h.channelInvite))
	mux.Handle("PUT /v1/radio/channels/{conversationId}/members/{userId}", driver(h.moderate))
	mux.Handle("POST /v1/radio/channels/{conversationId}/leave", user(h.leave))
	mux.Handle("POST /v1/radio/invites/{code}/accept", user(h.accept))
	mux.Handle("GET /v1/admin/radio/settings", admin(h.adminSettings))
	mux.Handle("PUT /v1/admin/radio/settings", admin(h.updateSettings))
	mux.Handle("GET /v1/admin/radio/bulk-uploads", admin(h.bulkUploads))
	mux.Handle("POST /v1/admin/radio/bulk-uploads", admin(h.uploadBulk))
	mux.Handle("GET /v1/admin/radio/bulk-uploads/{bulkId}", admin(h.bulkDetail))
	mux.Handle("POST /v1/admin/radio/bulk-uploads/{bulkId}/send", admin(h.sendBulk))
	mux.Handle("PUT /v1/radio/clients", driver(h.setClients))
	mux.Handle("PUT /v1/radio/clients/{passengerId}", driver(h.setClient))
	// Públicas: vista de la invitación, página del enlace y baja de SMS (sin datos personales).
	mux.HandleFunc("GET /v1/radio/invites/{code}", h.preview)
	mux.HandleFunc("GET /r/{code}", h.page)
	mux.HandleFunc("GET /r/{code}/baja", h.optOutPage)
	mux.HandleFunc("POST /r/{code}/baja", h.optOut)
}

func principal(r *http.Request) uuid.UUID {
	p, _ := auth.FromContext(r.Context())
	return p.UserID
}

func pathID(w http.ResponseWriter, r *http.Request, name string) (uuid.UUID, bool) {
	id, err := uuid.Parse(r.PathValue(name))
	if err != nil {
		httpx.WriteError(w, http.StatusNotFound, "not_found", "no encontrado")
		return uuid.Nil, false
	}
	return id, true
}

func (h *Handlers) me(w http.ResponseWriter, r *http.Request) {
	out, err := h.Service.Me(r.Context(), principal(r))
	respond(w, r, http.StatusOK, out, err)
}

func (h *Handlers) updateMe(w http.ResponseWriter, r *http.Request) {
	var in MeUpdate
	if !httpx.DecodeJSON(w, r, &in) {
		return
	}
	out, err := h.Service.UpdateMe(r.Context(), principal(r), in)
	respond(w, r, http.StatusOK, out, err)
}

func (h *Handlers) consent(w http.ResponseWriter, r *http.Request) {
	respond(w, r, http.StatusNoContent, nil, h.Service.Consent(r.Context(), principal(r)))
}

func (h *Handlers) heartbeat(w http.ResponseWriter, r *http.Request) {
	respond(w, r, http.StatusNoContent, nil, h.Service.Heartbeat(r.Context(), principal(r)))
}

func (h *Handlers) quietHours(w http.ResponseWriter, r *http.Request) {
	out, err := h.Service.GetQuietHours(r.Context(), principal(r))
	respond(w, r, http.StatusOK, out, err)
}

func (h *Handlers) setQuietHours(w http.ResponseWriter, r *http.Request) {
	var in []QuietHoursRule
	if !httpx.DecodeJSON(w, r, &in) {
		return
	}
	respond(w, r, http.StatusNoContent, nil, h.Service.SetQuietHours(r.Context(), principal(r), in))
}

func (h *Handlers) list(w http.ResponseWriter, r *http.Request) {
	out, err := h.Service.List(r.Context(), principal(r))
	respond(w, r, http.StatusOK, out, err)
}

func (h *Handlers) detail(w http.ResponseWriter, r *http.Request) {
	id, ok := pathID(w, r, "conversationId")
	if !ok {
		return
	}
	out, err := h.Service.Detail(r.Context(), principal(r), id)
	respond(w, r, http.StatusOK, out, err)
}

func (h *Handlers) delete(w http.ResponseWriter, r *http.Request) {
	id, ok := pathID(w, r, "conversationId")
	if !ok {
		return
	}
	respond(w, r, http.StatusNoContent, nil, h.Service.Delete(r.Context(), principal(r), id))
}

func (h *Handlers) listening(w http.ResponseWriter, r *http.Request) {
	id, ok := pathID(w, r, "conversationId")
	if !ok {
		return
	}
	var in struct {
		Listening *bool `json:"listening"`
	}
	if !httpx.DecodeJSON(w, r, &in) {
		return
	}
	if in.Listening == nil {
		httpx.WriteError(w, http.StatusBadRequest, "invalid_radio_request", "indica listening")
		return
	}
	respond(w, r, http.StatusNoContent, nil, h.Service.SetListening(r.Context(), principal(r), id, *in.Listening))
}

func (h *Handlers) token(w http.ResponseWriter, r *http.Request) {
	id, ok := pathID(w, r, "conversationId")
	if !ok {
		return
	}
	out, err := h.Service.Token(r.Context(), principal(r), id)
	respond(w, r, http.StatusOK, out, err)
}

func (h *Handlers) takeFloor(w http.ResponseWriter, r *http.Request) {
	id, ok := pathID(w, r, "conversationId")
	if !ok {
		return
	}
	out, err := h.Service.TakeFloor(r.Context(), principal(r), id)
	respond(w, r, http.StatusOK, out, err)
}

func (h *Handlers) releaseFloor(w http.ResponseWriter, r *http.Request) {
	id, ok := pathID(w, r, "conversationId")
	if !ok {
		return
	}
	respond(w, r, http.StatusNoContent, nil, h.Service.ReleaseFloor(r.Context(), principal(r), id))
}

func (h *Handlers) history(w http.ResponseWriter, r *http.Request) {
	id, ok := pathID(w, r, "conversationId")
	if !ok {
		return
	}
	var before *uuid.UUID
	if v := r.URL.Query().Get("before"); v != "" {
		b, err := uuid.Parse(v)
		if err != nil {
			httpx.WriteError(w, http.StatusBadRequest, "invalid_radio_request", "before inválido")
			return
		}
		before = &b
	}
	limit := 50
	if v := r.URL.Query().Get("limit"); v != "" {
		n, err := strconv.Atoi(v)
		if err != nil || n < 1 || n > HistoryLimit {
			httpx.WriteError(w, http.StatusBadRequest, "invalid_radio_request", "limit entre 1 y 100")
			return
		}
		limit = n
	}
	out, err := h.Service.History(r.Context(), principal(r), id, before, limit)
	respond(w, r, http.StatusOK, out, err)
}

func (h *Handlers) send(w http.ResponseWriter, r *http.Request) {
	id, ok := pathID(w, r, "conversationId")
	if !ok {
		return
	}
	var in SendInput
	if !httpx.DecodeJSON(w, r, &in) {
		return
	}
	out, err := h.Service.Send(r.Context(), principal(r), id, in)
	respond(w, r, http.StatusCreated, out, err)
}

func (h *Handlers) media(w http.ResponseWriter, r *http.Request) {
	id, ok := pathID(w, r, "messageId")
	if !ok {
		return
	}
	url, err := h.Service.MediaURL(r.Context(), principal(r), id)
	respond(w, r, http.StatusOK, map[string]string{"url": url}, err)
}

func (h *Handlers) receipt(w http.ResponseWriter, r *http.Request) {
	id, ok := pathID(w, r, "messageId")
	if !ok {
		return
	}
	var in ReceiptInput
	if !httpx.DecodeJSON(w, r, &in) {
		return
	}
	respond(w, r, http.StatusNoContent, nil, h.Service.Receipt(r.Context(), principal(r), id, in))
}

func (h *Handlers) inviteContact(w http.ResponseWriter, r *http.Request) {
	var in ContactInviteInput
	if !httpx.DecodeJSON(w, r, &in) {
		return
	}
	out, err := h.Service.InviteContact(r.Context(), principal(r), in)
	if err == nil && out == nil {
		// Con teléfono: 202 siempre, exista o no la cuenta (FR-002).
		w.WriteHeader(http.StatusAccepted)
		return
	}
	respond(w, r, http.StatusCreated, out, err)
}

func (h *Handlers) createChannel(w http.ResponseWriter, r *http.Request) {
	var in ChannelInput
	if !httpx.DecodeJSON(w, r, &in) {
		return
	}
	out, err := h.Service.CreateChannel(r.Context(), principal(r), in)
	respond(w, r, http.StatusCreated, out, err)
}

func (h *Handlers) updateChannel(w http.ResponseWriter, r *http.Request) {
	id, ok := pathID(w, r, "conversationId")
	if !ok {
		return
	}
	var raw map[string]any
	var in ChannelInput
	if !httpx.DecodeJSON(w, r, &raw) {
		return
	}
	if v, ok := raw["name"].(string); ok {
		in.Name = &v
	}
	if v, ok := raw["description"].(string); ok {
		in.Description = &v
	}
	if v, ok := raw["join_mode"].(string); ok {
		in.JoinMode = &v
	}
	if v, ok := raw["passenger_role_max"]; ok {
		in.SetPassengerRole = true
		if s, ok := v.(string); ok {
			in.PassengerRoleMax = &s
		}
	}
	out, err := h.Service.UpdateChannel(r.Context(), principal(r), id, in)
	respond(w, r, http.StatusOK, out, err)
}

func (h *Handlers) channelInvite(w http.ResponseWriter, r *http.Request) {
	id, ok := pathID(w, r, "conversationId")
	if !ok {
		return
	}
	out, err := h.Service.ChannelInvite(r.Context(), principal(r), id)
	respond(w, r, http.StatusCreated, out, err)
}

func (h *Handlers) moderate(w http.ResponseWriter, r *http.Request) {
	id, ok := pathID(w, r, "conversationId")
	if !ok {
		return
	}
	target, ok := pathID(w, r, "userId")
	if !ok {
		return
	}
	var in ModerateInput
	if !httpx.DecodeJSON(w, r, &in) {
		return
	}
	respond(w, r, http.StatusNoContent, nil, h.Service.Moderate(r.Context(), principal(r), id, target, in))
}

func (h *Handlers) leave(w http.ResponseWriter, r *http.Request) {
	id, ok := pathID(w, r, "conversationId")
	if !ok {
		return
	}
	respond(w, r, http.StatusNoContent, nil, h.Service.Leave(r.Context(), principal(r), id))
}

func (h *Handlers) adminSettings(w http.ResponseWriter, r *http.Request) {
	out, err := h.Service.AdminSettings(r.Context())
	respond(w, r, http.StatusOK, out, err)
}

func (h *Handlers) updateSettings(w http.ResponseWriter, r *http.Request) {
	var in SettingsInput
	if !httpx.DecodeJSON(w, r, &in) {
		return
	}
	out, err := h.Service.UpdateSettings(r.Context(), principal(r), in)
	respond(w, r, http.StatusOK, out, err)
}

func (h *Handlers) bulkUploads(w http.ResponseWriter, r *http.Request) {
	out, err := h.Service.BulkUploads(r.Context())
	respond(w, r, http.StatusOK, out, err)
}

// maxBulkBytes caps the CSV body: 2 000 filas caben con holgura.
const maxBulkBytes = 1 << 20

func (h *Handlers) uploadBulk(w http.ResponseWriter, r *http.Request) {
	data, err := io.ReadAll(http.MaxBytesReader(w, r.Body, maxBulkBytes))
	if err != nil {
		writeError(w, r, ErrBulkTooLarge)
		return
	}
	out, err := h.Service.UploadBulk(r.Context(), principal(r), r.URL.Query().Get("file_name"), data)
	respond(w, r, http.StatusCreated, out, err)
}

func (h *Handlers) bulkDetail(w http.ResponseWriter, r *http.Request) {
	id, ok := pathID(w, r, "bulkId")
	if !ok {
		return
	}
	out, err := h.Service.BulkDetail(r.Context(), id)
	respond(w, r, http.StatusOK, out, err)
}

func (h *Handlers) sendBulk(w http.ResponseWriter, r *http.Request) {
	id, ok := pathID(w, r, "bulkId")
	if !ok {
		return
	}
	var in struct {
		OnlyFailed bool `json:"only_failed"`
	}
	if r.ContentLength != 0 && !httpx.DecodeJSON(w, r, &in) {
		return
	}
	respond(w, r, http.StatusAccepted, nil, h.Service.SendBulk(r.Context(), id, in.OnlyFailed))
}

func (h *Handlers) emergency(w http.ResponseWriter, r *http.Request) {
	id, ok := pathID(w, r, "conversationId")
	if !ok {
		return
	}
	var in struct {
		Lat *float64 `json:"lat"`
		Lng *float64 `json:"lng"`
	}
	if !httpx.DecodeJSON(w, r, &in) {
		return
	}
	if (in.Lat == nil) != (in.Lng == nil) {
		writeError(w, r, ErrInvalid)
		return
	}
	out, err := h.Service.Emergency(r.Context(), principal(r), id, in.Lat, in.Lng)
	respond(w, r, http.StatusCreated, out, err)
}

func (h *Handlers) reservePhoto(w http.ResponseWriter, r *http.Request) {
	id, ok := pathID(w, r, "conversationId")
	if !ok {
		return
	}
	out, err := h.Service.ReservePhoto(r.Context(), principal(r), id)
	respond(w, r, http.StatusCreated, out, err)
}

func (h *Handlers) photoUploaded(w http.ResponseWriter, r *http.Request) {
	id, ok := pathID(w, r, "messageId")
	if !ok {
		return
	}
	respond(w, r, http.StatusNoContent, nil, h.Service.PhotoUploaded(r.Context(), principal(r), id))
}

func (h *Handlers) setClients(w http.ResponseWriter, r *http.Request) {
	var in struct {
		Enabled *bool `json:"enabled"`
	}
	if !httpx.DecodeJSON(w, r, &in) {
		return
	}
	if in.Enabled == nil {
		writeError(w, r, ErrInvalid)
		return
	}
	respond(w, r, http.StatusNoContent, nil, h.Service.SetClients(r.Context(), principal(r), *in.Enabled))
}

func (h *Handlers) setClient(w http.ResponseWriter, r *http.Request) {
	id, ok := pathID(w, r, "passengerId")
	if !ok {
		return
	}
	var in ClientUpdate
	if !httpx.DecodeJSON(w, r, &in) {
		return
	}
	respond(w, r, http.StatusNoContent, nil, h.Service.SetClient(r.Context(), principal(r), id, in))
}

func (h *Handlers) accept(w http.ResponseWriter, r *http.Request) {
	out, err := h.Service.Accept(r.Context(), principal(r), r.PathValue("code"))
	status := http.StatusOK
	if out.Pending {
		status = http.StatusAccepted
	}
	respond(w, r, status, out.Conversation, err)
}

func (h *Handlers) preview(w http.ResponseWriter, r *http.Request) {
	out, err := h.Service.Preview(r.Context(), r.PathValue("code"))
	respond(w, r, http.StatusOK, out, err)
}

func respond(w http.ResponseWriter, r *http.Request, status int, out any, err error) {
	if err != nil {
		writeError(w, r, err)
		return
	}
	if status == http.StatusNoContent || out == nil {
		w.WriteHeader(status)
		return
	}
	httpx.WriteJSON(w, status, out)
}

func writeError(w http.ResponseWriter, r *http.Request, err error) {
	var busy *FloorBusyError
	if errors.As(err, &busy) {
		httpx.WriteJSON(w, http.StatusConflict, map[string]string{
			"code": "floor_busy", "message": busy.HolderName + " está hablando", "holder_name": busy.HolderName,
		})
		return
	}
	known := []struct {
		target        error
		status        int
		code, message string
	}{
		{ErrAccessDenied, http.StatusForbidden, "radio_access_denied", "no tienes acceso a Radio"},
		{ErrListenOnly, http.StatusForbidden, "radio_listen_only", "aquí solo puedes escuchar"},
		{ErrConsentRequired, http.StatusForbidden, "radio_consent_required", "acepta el aviso de registro de Radio"},
		{ErrNotFound, http.StatusNotFound, "not_found", "no encontrado"},
		{ErrInvalid, http.StatusBadRequest, "invalid_radio_request", "solicitud de Radio inválida"},
		{ErrMuted, http.StatusForbidden, "member_muted", "un moderador te silenció en este canal"},
		{ErrBlocked, http.StatusForbidden, "blocked", "no puedes enviar mensajes en esta conversación"},
		{ErrSuspended, http.StatusForbidden, "conversation_suspended", "esta conversación está suspendida"},
		{ErrNotOwner, http.StatusForbidden, "not_owner", "solo el dueño del canal puede hacerlo"},
		{ErrNotModerator, http.StatusForbidden, "not_moderator", "solo el dueño o un moderador puede hacerlo"},
		{ErrCooperative, http.StatusForbidden, "cooperative_channel", "el canal de la cooperativa lo administra la cooperativa"},
		{ErrNameTaken, http.StatusConflict, "channel_name_taken", "ya existe un canal con ese nombre"},
		{ErrChannelLimit, http.StatusConflict, "channel_limit", "ya tienes 10 canales"},
		{ErrChannelFull, http.StatusConflict, "channel_full", "el canal está lleno"},
		{ErrListeningLimit, http.StatusConflict, "listening_limit", "ya escuchas 10 conversaciones; apaga alguna"},
		{ErrSavedLimit, http.StatusConflict, "saved_limit", "ya tienes 200 mensajes guardados"},
		{ErrRateLimited, http.StatusTooManyRequests, "rate_limited", "espera un momento antes de enviar otro mensaje"},
		{ErrInviteExpired, http.StatusGone, "invite_expired", "la invitación venció o ya se usó"},
		{ErrInviteWrongApp, http.StatusConflict, "invite_wrong_app", "esta invitación es para la otra app de Kyq"},
		{ErrPassengersClosed, http.StatusForbidden, "passengers_not_allowed", "este canal no admite pasajeros"},
		{ErrNoMedia, http.StatusNotFound, "no_media", "este mensaje no tiene audio ni foto"},
		{ErrPhotoInvalid, http.StatusConflict, "photo_invalid", "la foto debe ser JPEG de máximo 2 MB; vuelve a enviarla"},
		{ErrBulkTooLarge, http.StatusRequestEntityTooLarge, "bulk_too_large", "el archivo tiene más de 2 000 filas"},
		{ErrBulkState, http.StatusConflict, "bulk_state", "esa carga ya se está enviando o no tiene filas por enviar"},
		{ErrUnavailable, http.StatusServiceUnavailable, "voice_unavailable", "el servidor de voz no responde; inténtalo de nuevo"},
	}
	for _, k := range known {
		if errors.Is(err, k.target) {
			httpx.WriteError(w, k.status, k.code, k.message)
			return
		}
	}
	httpx.InternalError(w, r, err)
}

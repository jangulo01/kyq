package realtime

import (
	"errors"
	"net/http"

	"github.com/kyq/backend/internal/auth"
	"github.com/kyq/backend/internal/httpx"
)

// Handlers exposes the token endpoints. Routes require auth.RequireAuth.
type Handlers struct {
	Tokens     Tokens
	Authorizer Authorizer
}

// Register mounts the routes on mux wrapped by authMW.
func (h *Handlers) Register(mux *http.ServeMux, authMW func(http.Handler) http.Handler) {
	mux.Handle("POST /v1/realtime/token", authMW(http.HandlerFunc(h.connection)))
	mux.Handle("POST /v1/realtime/subscription-token", authMW(http.HandlerFunc(h.subscription)))
}

type tokenResponse struct {
	Token string `json:"token"`
}

func (h *Handlers) connection(w http.ResponseWriter, r *http.Request) {
	p, _ := auth.FromContext(r.Context())
	token, err := h.Tokens.Connection(p.UserID)
	if err != nil {
		httpx.InternalError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, tokenResponse{Token: token})
}

func (h *Handlers) subscription(w http.ResponseWriter, r *http.Request) {
	var body struct {
		Channel string `json:"channel"`
	}
	if !httpx.DecodeJSON(w, r, &body) {
		return
	}
	p, _ := auth.FromContext(r.Context())
	if err := h.Authorizer.Authorize(r.Context(), p.UserID, body.Channel); err != nil {
		if errors.Is(err, ErrForbiddenChannel) {
			httpx.WriteError(w, http.StatusForbidden, "forbidden_channel", "no puedes suscribirte a este canal")
			return
		}
		httpx.InternalError(w, r, err)
		return
	}
	token, err := h.Tokens.Subscription(p.UserID, body.Channel)
	if err != nil {
		httpx.InternalError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, tokenResponse{Token: token})
}

package auth

import (
	"context"
	"errors"
	"net"
	"net/http"
	"strings"

	"github.com/kyq/backend/internal/httpx"
)

// Handlers exposes the /v1/auth endpoints.
type Handlers struct{ svc *Service }

// NewHandlers wraps the service.
func NewHandlers(svc *Service) *Handlers { return &Handlers{svc: svc} }

// Register mounts the routes on mux.
func (h *Handlers) Register(mux *http.ServeMux) {
	mux.HandleFunc("POST /v1/auth/otp/request", h.requestOTP)
	mux.HandleFunc("POST /v1/auth/otp/verify", h.verifyOTP)
	mux.HandleFunc("POST /v1/auth/refresh", h.refresh)
}

func (h *Handlers) requestOTP(w http.ResponseWriter, r *http.Request) {
	var body struct {
		Phone string `json:"phone_e164"`
	}
	if !httpx.DecodeJSON(w, r, &body) {
		return
	}
	if err := h.svc.RequestOTP(r.Context(), body.Phone, clientIP(r)); err != nil {
		writeAuthError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handlers) verifyOTP(w http.ResponseWriter, r *http.Request) {
	var body struct {
		Phone       string `json:"phone_e164"`
		Code        string `json:"code"`
		DisplayName string `json:"display_name"`
		Role        string `json:"role"`
	}
	if !httpx.DecodeJSON(w, r, &body) {
		return
	}
	tokens, err := h.svc.VerifyOTP(r.Context(), body.Phone, body.Code, body.DisplayName, body.Role)
	if err != nil {
		writeAuthError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, tokens)
}

func (h *Handlers) refresh(w http.ResponseWriter, r *http.Request) {
	var body struct {
		RefreshToken string `json:"refresh_token"`
	}
	if !httpx.DecodeJSON(w, r, &body) {
		return
	}
	tokens, err := h.svc.Refresh(r.Context(), body.RefreshToken)
	if err != nil {
		writeAuthError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, tokens)
}

func writeAuthError(w http.ResponseWriter, r *http.Request, err error) {
	switch {
	case errors.Is(err, ErrInvalidPhone):
		httpx.WriteError(w, http.StatusBadRequest, "invalid_phone", "el teléfono debe estar en formato E.164")
	case errors.Is(err, ErrCountryNotServed):
		httpx.WriteError(w, http.StatusBadRequest, "country_not_served", "Kyq aún no opera en el país de ese teléfono")
	case errors.Is(err, ErrDisplayNameRequired):
		httpx.WriteError(w, http.StatusBadRequest, "display_name_required", "indica un nombre de 2 a 60 caracteres")
	case errors.Is(err, ErrInvalidRole):
		httpx.WriteError(w, http.StatusBadRequest, "invalid_role", "role debe ser passenger o driver")
	case errors.Is(err, ErrPhoneHasOtherRole):
		httpx.WriteError(w, http.StatusConflict, "phone_has_other_role",
			"ese teléfono ya tiene una cuenta con otro rol; usa otro número")
	case errors.Is(err, ErrAccountSuspended):
		httpx.WriteError(w, http.StatusForbidden, "account_suspended",
			"tu cuenta está suspendida; comunícate con el soporte de Kyq")
	case errors.Is(err, ErrRateLimited):
		httpx.WriteError(w, http.StatusTooManyRequests, "rate_limited", "demasiados códigos solicitados; espera una hora")
	case errors.Is(err, ErrInvalidCode):
		httpx.WriteError(w, http.StatusUnauthorized, "invalid_code", "código incorrecto o caducado")
	case errors.Is(err, ErrInvalidRefreshToken):
		httpx.WriteError(w, http.StatusUnauthorized, "invalid_refresh_token", "sesión caducada; vuelve a iniciar sesión")
	default:
		httpx.InternalError(w, r, err)
	}
}

// clientIP returns the caller IP from the connection. Behind a reverse proxy, configure it to
// overwrite RemoteAddr (or extend this to a trusted header) so the per-IP limit stays meaningful.
func clientIP(r *http.Request) string {
	host, _, err := net.SplitHostPort(r.RemoteAddr)
	if err != nil {
		return r.RemoteAddr
	}
	return host
}

type principalKey struct{}

// RequireAuth rejects requests without a valid bearer access token and stores the principal.
func RequireAuth(tokens *TokenIssuer) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			raw, ok := strings.CutPrefix(r.Header.Get("Authorization"), "Bearer ")
			if !ok || raw == "" {
				httpx.WriteError(w, http.StatusUnauthorized, "unauthorized", "falta el token de acceso")
				return
			}
			p, err := tokens.ParseAccess(raw)
			if err != nil {
				httpx.WriteError(w, http.StatusUnauthorized, "unauthorized", "token de acceso inválido o caducado")
				return
			}
			next.ServeHTTP(w, r.WithContext(WithPrincipal(r.Context(), p)))
		})
	}
}

// RequireRole rejects authenticated callers whose role is not listed. Use after RequireAuth.
func RequireRole(roles ...string) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			p, ok := FromContext(r.Context())
			if !ok {
				httpx.WriteError(w, http.StatusUnauthorized, "unauthorized", "falta el token de acceso")
				return
			}
			for _, role := range roles {
				if p.Role == role {
					next.ServeHTTP(w, r)
					return
				}
			}
			httpx.WriteError(w, http.StatusForbidden, "forbidden", "tu rol no permite esta acción")
		})
	}
}

// WithPrincipal stores p in ctx.
func WithPrincipal(ctx context.Context, p Principal) context.Context {
	return context.WithValue(ctx, principalKey{}, p)
}

// FromContext returns the authenticated principal.
func FromContext(ctx context.Context) (Principal, bool) {
	p, ok := ctx.Value(principalKey{}).(Principal)
	return p, ok
}

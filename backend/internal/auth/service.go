// Package auth implements phone OTP login, access tokens and refresh token rotation.
package auth

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"net/netip"
	"regexp"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/google/uuid"
)

var (
	ErrInvalidPhone        = errors.New("invalid phone")
	ErrRateLimited         = errors.New("too many otp requests")
	ErrCountryNotServed    = errors.New("phone country not served")
	ErrInvalidCode         = errors.New("invalid otp code")
	ErrDisplayNameRequired = errors.New("display name required")
	ErrInvalidRefreshToken = errors.New("invalid refresh token")
	ErrNotFound            = errors.New("not found")
	ErrPhoneHasOtherRole   = errors.New("phone has another role")
	ErrInvalidRole         = errors.New("invalid role")
	// ErrAccountSuspended: un administrador suspendió la cuenta (007, FR-016).
	ErrAccountSuspended = errors.New("account suspended")
)

// Límites de envío de OTP por hora contra el bombeo de SMS (números rotados desde un mismo
// origen o en masa). Ajustar cuando haya volumen real.
const (
	otpRequestsPerPhoneHour = 5
	otpRequestsPerIPHour    = 20
	// Umbral de alerta, no de bloqueo: bloquear a todos permitiría a un atacante dejar sin
	// login a todo el país.
	otpRequestsGlobalAlertPerHour = 500
	// Techo duro solo para teléfonos sin cuenta: limita el coste de un bombeo masivo sin
	// impedir nunca el login de los usuarios existentes.
	otpNewPhonesGlobalCapPerHour = 3000
	// Segundo nivel IPv6: un proveedor suele asignar una /48; rotar /64 dentro de ella no
	// debe esquivar el límite.
	otpRequestsPerIPv6_48Hour = 60
)

// DefaultOTPCountryPrefixes son los mercados atendidos: solo se envían SMS a estos prefijos.
var DefaultOTPCountryPrefixes = []string{"+57", "+51"}

var phoneE164 = regexp.MustCompile(`^\+[1-9][0-9]{6,14}$`)

// User is the authentication view of a user.
type User struct {
	ID          uuid.UUID
	Phone       string
	Role        string
	DisplayName string
	// Suspended: sin login ni renovación de sesión (007).
	Suspended bool
}

// RefreshToken is a stored refresh token.
type RefreshToken struct {
	ID        uuid.UUID
	UserID    uuid.UUID
	Hash      []byte
	ExpiresAt time.Time
	Rotated   bool
}

// Repo persists users and refresh tokens. Lookups return ErrNotFound when nothing matches.
type Repo interface {
	GetUserByPhone(ctx context.Context, phone string) (User, error)
	GetUserByID(ctx context.Context, id uuid.UUID) (User, error)
	CreateUser(ctx context.Context, u User) (User, error)
	// CreateDriver creates the user with the driver role and its driver profile (no vehicle yet,
	// new QR) in one transaction.
	CreateDriver(ctx context.Context, u User) (User, error)
	InsertRefreshToken(ctx context.Context, t RefreshToken) error
	GetRefreshToken(ctx context.Context, hash []byte) (RefreshToken, error)
	// MarkRotated returns false when the token was already rotated.
	MarkRotated(ctx context.Context, id uuid.UUID) (bool, error)
	RevokeAll(ctx context.Context, userID uuid.UUID) error
}

// Tokens is the session returned after login or refresh.
type Tokens struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
	Role         string `json:"role"`
	// Scope is ScopeSupport for the support-only session of a suspended user (009).
	Scope string `json:"scope,omitempty"`
	// RadioInvitesApplied: conversaciones de Radio a las que llevó una invitación enviada a este
	// teléfono, aplicada al verificar el OTP (011, R9).
	RadioInvitesApplied []uuid.UUID `json:"radio_invites_applied,omitempty"`
}

// InviteApplier accepts the Radio invitations sent to a phone when its owner verifies it (011).
// Package radio implements it; a failure never blocks the login.
type InviteApplier interface {
	ApplyPhoneInvites(ctx context.Context, userID uuid.UUID, phone string) ([]uuid.UUID, error)
}

// SuspendedError is ErrAccountSuspended carrying the support-only session of the user (009,
// FR-011): the apps keep 007's "account suspended" answer and can still reach support.
type SuspendedError struct{ Support Tokens }

func (e *SuspendedError) Error() string        { return ErrAccountSuspended.Error() }
func (e *SuspendedError) Is(target error) bool { return target == ErrAccountSuspended }

// Service implements the authentication use cases.
type Service struct {
	repo          Repo
	otp           OTPSender
	tokens        *TokenIssuer
	limiter       *rateLimiter
	ipLimiter     *rateLimiter
	ip48Limiter   *rateLimiter
	globalLimiter *rateLimiter
	newPhoneCap   *rateLimiter
	prefixes      []string
	now           func() time.Time
	// Invites aplica las invitaciones de Radio pendientes del teléfono; nil no hace nada.
	Invites InviteApplier
}

// NewService builds the service. now may be nil.
func NewService(repo Repo, otp OTPSender, tokens *TokenIssuer, now func() time.Time) *Service {
	if now == nil {
		now = time.Now
	}
	return &Service{
		repo:          repo,
		otp:           otp,
		tokens:        tokens,
		limiter:       newRateLimiter(otpRequestsPerPhoneHour, time.Hour),
		ipLimiter:     newRateLimiter(otpRequestsPerIPHour, time.Hour),
		ip48Limiter:   newRateLimiter(otpRequestsPerIPv6_48Hour, time.Hour),
		globalLimiter: newRateLimiter(otpRequestsGlobalAlertPerHour, time.Hour),
		newPhoneCap:   newRateLimiter(otpNewPhonesGlobalCapPerHour, time.Hour),
		prefixes:      DefaultOTPCountryPrefixes,
		now:           now,
	}
}

// WithCountryPrefixes restricts OTP delivery to phones starting with one of prefixes.
func (s *Service) WithCountryPrefixes(prefixes []string) *Service {
	s.prefixes = prefixes
	return s
}

// RequestOTP sends a code to phone. Limits per hour: 20 per client IP (IPv6 by /64, plus 60 per
// /48) and 5 per phone; at most 3000 to phones without an account, and an alert above 500 in
// total. Only phones of served countries receive SMS.
func (s *Service) RequestOTP(ctx context.Context, phone, clientIP string) error {
	if !phoneE164.MatchString(phone) {
		return ErrInvalidPhone
	}
	if !s.servedCountry(phone) {
		return ErrCountryNotServed
	}
	now := s.now()
	// Primero la IP: así una IP bloqueada no gasta el cupo del teléfono de la víctima.
	if !s.ipLimiter.allow(ipKey(clientIP), now) || !s.ip48Limiter.allow(ip48Key(clientIP), now) ||
		!s.limiter.allow(phone, now) {
		return ErrRateLimited
	}
	if _, err := s.repo.GetUserByPhone(ctx, phone); errors.Is(err, ErrNotFound) {
		if !s.newPhoneCap.allow("new", now) {
			slog.ErrorContext(ctx, "otp: techo de SMS a teléfonos nuevos alcanzado; registros pausados",
				"cap_per_hour", otpNewPhonesGlobalCapPerHour)
			return ErrRateLimited
		}
	} else if err != nil {
		return fmt.Errorf("lookup phone: %w", err)
	}
	if !s.globalLimiter.allow("all", now) {
		slog.WarnContext(ctx, "otp: volumen global de SMS por encima del umbral; revisar posible bombeo",
			"threshold_per_hour", otpRequestsGlobalAlertPerHour)
	}
	return s.otp.Send(ctx, phone)
}

func (s *Service) servedCountry(phone string) bool {
	for _, p := range s.prefixes {
		if strings.HasPrefix(phone, p) {
			return true
		}
	}
	return false
}

// VerifyOTP checks the code and returns a session. New phones register as passengers and must
// send a display name; admins are created by an administrator. role is "" (keep the existing
// role; passenger for new phones), "passenger" or "driver": a driver signs up with "driver"
// (FR-001), and a phone that already has another role gets ErrPhoneHasOtherRole (FR-003).
func (s *Service) VerifyOTP(ctx context.Context, phone, code, displayName, role string) (Tokens, error) {
	if !phoneE164.MatchString(phone) {
		return Tokens{}, ErrInvalidPhone
	}
	if role != "" && role != RolePassenger && role != RoleDriver {
		return Tokens{}, ErrInvalidRole
	}
	ok, err := s.otp.Check(ctx, phone, code)
	if err != nil {
		return Tokens{}, fmt.Errorf("check otp: %w", err)
	}
	if !ok {
		return Tokens{}, ErrInvalidCode
	}
	user, err := s.repo.GetUserByPhone(ctx, phone)
	if errors.Is(err, ErrNotFound) {
		name := strings.TrimSpace(displayName)
		if n := utf8.RuneCountInString(name); n < 2 || n > 60 {
			return Tokens{}, ErrDisplayNameRequired
		}
		id, err := uuid.NewV7()
		if err != nil {
			return Tokens{}, err
		}
		u := User{ID: id, Phone: phone, Role: RolePassenger, DisplayName: name}
		if role == RoleDriver {
			u.Role = RoleDriver
			user, err = s.repo.CreateDriver(ctx, u)
		} else {
			user, err = s.repo.CreateUser(ctx, u)
		}
		if err != nil {
			return Tokens{}, fmt.Errorf("create user: %w", err)
		}
	} else if err != nil {
		return Tokens{}, fmt.Errorf("get user: %w", err)
	} else if role != "" && user.Role != role {
		return Tokens{}, ErrPhoneHasOtherRole
	} else if user.Suspended {
		return s.suspended(ctx, user)
	}
	tokens, err := s.issue(ctx, user)
	if err != nil || s.Invites == nil {
		return tokens, err
	}
	if applied, err := s.Invites.ApplyPhoneInvites(ctx, user.ID, user.Phone); err == nil && len(applied) > 0 {
		tokens.RadioInvitesApplied = applied
	}
	return tokens, nil
}

// Refresh rotates a refresh token. Reusing a rotated token revokes every session of the user.
func (s *Service) Refresh(ctx context.Context, raw string) (Tokens, error) {
	stored, err := s.repo.GetRefreshToken(ctx, hashRefreshToken(raw))
	if errors.Is(err, ErrNotFound) {
		return Tokens{}, ErrInvalidRefreshToken
	}
	if err != nil {
		return Tokens{}, fmt.Errorf("get refresh token: %w", err)
	}
	if stored.Rotated {
		if err := s.repo.RevokeAll(ctx, stored.UserID); err != nil {
			return Tokens{}, fmt.Errorf("revoke sessions: %w", err)
		}
		return Tokens{}, ErrInvalidRefreshToken
	}
	if !s.now().Before(stored.ExpiresAt) {
		return Tokens{}, ErrInvalidRefreshToken
	}
	rotated, err := s.repo.MarkRotated(ctx, stored.ID)
	if err != nil {
		return Tokens{}, fmt.Errorf("rotate refresh token: %w", err)
	}
	if !rotated {
		return Tokens{}, ErrInvalidRefreshToken
	}
	user, err := s.repo.GetUserByID(ctx, stored.UserID)
	if err != nil {
		return Tokens{}, fmt.Errorf("get user: %w", err)
	}
	if user.Suspended {
		return s.suspended(ctx, user)
	}
	return s.issue(ctx, user)
}

// suspended answers ErrAccountSuspended with a support-only session (009, research R4).
func (s *Service) suspended(ctx context.Context, user User) (Tokens, error) {
	support, err := s.issue(ctx, user)
	if err != nil {
		return Tokens{}, err
	}
	return Tokens{}, &SuspendedError{Support: support}
}

func (s *Service) issue(ctx context.Context, user User) (Tokens, error) {
	scope := ""
	if user.Suspended {
		scope = ScopeSupport
	}
	access, err := s.tokens.IssueAccess(Principal{UserID: user.ID, Role: user.Role, Scope: scope})
	if err != nil {
		return Tokens{}, fmt.Errorf("issue access token: %w", err)
	}
	raw, hash, err := newRefreshToken()
	if err != nil {
		return Tokens{}, err
	}
	id, err := uuid.NewV7()
	if err != nil {
		return Tokens{}, err
	}
	err = s.repo.InsertRefreshToken(ctx, RefreshToken{
		ID: id, UserID: user.ID, Hash: hash, ExpiresAt: s.now().Add(refreshTTL),
	})
	if err != nil {
		return Tokens{}, fmt.Errorf("store refresh token: %w", err)
	}
	return Tokens{AccessToken: access, RefreshToken: raw, Role: user.Role, Scope: scope}, nil
}

// ip48Key groups IPv6 clients by /48 for the coarser limiter; IPv4 keys are unchanged.
func ip48Key(ip string) string {
	addr, err := netip.ParseAddr(ip)
	if err != nil || addr.Is4() || addr.Is4In6() {
		return ip
	}
	prefix, err := addr.Prefix(48)
	if err != nil {
		return ip
	}
	return prefix.String()
}

// ipKey groups IPv6 clients by /64, the usual allocation to one customer.
func ipKey(ip string) string {
	addr, err := netip.ParseAddr(ip)
	if err != nil || addr.Is4() || addr.Is4In6() {
		return ip
	}
	prefix, err := addr.Prefix(64)
	if err != nil {
		return ip
	}
	return prefix.String()
}

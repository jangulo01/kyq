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
)

// Límites de envío de OTP por hora contra el bombeo de SMS (números rotados desde un mismo
// origen o en masa). Ajustar cuando haya volumen real.
const (
	otpRequestsPerPhoneHour = 5
	otpRequestsPerIPHour    = 20
	// Umbral de alerta, no de bloqueo: bloquear a todos permitiría a un atacante dejar sin
	// login a todo el país.
	otpRequestsGlobalAlertPerHour = 500
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
}

// Service implements the authentication use cases.
type Service struct {
	repo          Repo
	otp           OTPSender
	tokens        *TokenIssuer
	limiter       *rateLimiter
	ipLimiter     *rateLimiter
	globalLimiter *rateLimiter
	prefixes      []string
	now           func() time.Time
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
		globalLimiter: newRateLimiter(otpRequestsGlobalAlertPerHour, time.Hour),
		prefixes:      DefaultOTPCountryPrefixes,
		now:           now,
	}
}

// WithCountryPrefixes restricts OTP delivery to phones starting with one of prefixes.
func (s *Service) WithCountryPrefixes(prefixes []string) *Service {
	s.prefixes = prefixes
	return s
}

// RequestOTP sends a code to phone. Limits per hour: 20 per client IP (IPv6 by /64) and 5 per
// phone; above 500 in total it logs an alert. Only phones of served countries receive SMS.
func (s *Service) RequestOTP(ctx context.Context, phone, clientIP string) error {
	if !phoneE164.MatchString(phone) {
		return ErrInvalidPhone
	}
	if !s.servedCountry(phone) {
		return ErrCountryNotServed
	}
	now := s.now()
	// Primero la IP: así una IP bloqueada no gasta el cupo del teléfono de la víctima.
	if !s.ipLimiter.allow(ipKey(clientIP), now) || !s.limiter.allow(phone, now) {
		return ErrRateLimited
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
// send a display name; drivers and admins are created by an administrator.
func (s *Service) VerifyOTP(ctx context.Context, phone, code, displayName string) (Tokens, error) {
	if !phoneE164.MatchString(phone) {
		return Tokens{}, ErrInvalidPhone
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
		user, err = s.repo.CreateUser(ctx, User{ID: id, Phone: phone, Role: RolePassenger, DisplayName: name})
		if err != nil {
			return Tokens{}, fmt.Errorf("create user: %w", err)
		}
	} else if err != nil {
		return Tokens{}, fmt.Errorf("get user: %w", err)
	}
	return s.issue(ctx, user)
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
	return s.issue(ctx, user)
}

func (s *Service) issue(ctx context.Context, user User) (Tokens, error) {
	access, err := s.tokens.IssueAccess(Principal{UserID: user.ID, Role: user.Role})
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
	return Tokens{AccessToken: access, RefreshToken: raw, Role: user.Role}, nil
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

package auth

import (
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"errors"
	"fmt"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
)

// Role values match users.role.
const (
	RolePassenger = "passenger"
	RoleDriver    = "driver"
	RoleAdmin     = "admin"
)

const (
	accessTTL  = 15 * time.Minute
	refreshTTL = 30 * 24 * time.Hour
	issuer     = "kyq"
)

// ScopeSupport limits a session to the support routes: it is what a suspended user gets (009,
// FR-011).
const ScopeSupport = "support"

// Principal is the authenticated caller.
type Principal struct {
	UserID uuid.UUID
	Role   string
	// Scope is empty for a full session or ScopeSupport.
	Scope string
}

type accessClaims struct {
	Role  string `json:"role"`
	Scope string `json:"scp,omitempty"`
	jwt.RegisteredClaims
}

// TokenIssuer signs and verifies access tokens (HS256).
type TokenIssuer struct {
	secret []byte
	now    func() time.Time
}

// NewTokenIssuer returns an issuer using secret, which must be at least 32 bytes.
func NewTokenIssuer(secret []byte, now func() time.Time) *TokenIssuer {
	if now == nil {
		now = time.Now
	}
	return &TokenIssuer{secret: secret, now: now}
}

// IssueAccess returns a signed access token valid for 15 minutes.
func (t *TokenIssuer) IssueAccess(p Principal) (string, error) {
	now := t.now()
	claims := accessClaims{
		Role:  p.Role,
		Scope: p.Scope,
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   p.UserID.String(),
			Issuer:    issuer,
			IssuedAt:  jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(now.Add(accessTTL)),
		},
	}
	return jwt.NewWithClaims(jwt.SigningMethodHS256, claims).SignedString(t.secret)
}

// ParseAccess verifies an access token and returns its principal.
func (t *TokenIssuer) ParseAccess(token string) (Principal, error) {
	var claims accessClaims
	_, err := jwt.ParseWithClaims(token, &claims, func(*jwt.Token) (any, error) { return t.secret, nil },
		jwt.WithValidMethods([]string{jwt.SigningMethodHS256.Alg()}),
		jwt.WithIssuer(issuer),
		jwt.WithTimeFunc(t.now),
		jwt.WithExpirationRequired(),
	)
	if err != nil {
		return Principal{}, fmt.Errorf("parse access token: %w", err)
	}
	id, err := uuid.Parse(claims.Subject)
	if err != nil {
		return Principal{}, errors.New("access token subject is not a uuid")
	}
	switch claims.Role {
	case RolePassenger, RoleDriver, RoleAdmin:
	default:
		return Principal{}, errors.New("access token has unknown role")
	}
	switch claims.Scope {
	case "", ScopeSupport:
	default:
		return Principal{}, errors.New("access token has unknown scope")
	}
	return Principal{UserID: id, Role: claims.Role, Scope: claims.Scope}, nil
}

// newRefreshToken returns a random opaque token and the hash stored in the database.
func newRefreshToken() (raw string, hash []byte, err error) {
	var b [32]byte
	if _, err := rand.Read(b[:]); err != nil {
		return "", nil, err
	}
	raw = base64.RawURLEncoding.EncodeToString(b[:])
	return raw, hashRefreshToken(raw), nil
}

func hashRefreshToken(raw string) []byte {
	sum := sha256.Sum256([]byte(raw))
	return sum[:]
}

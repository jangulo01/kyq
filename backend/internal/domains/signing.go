// Package domains implements the mirror domains of the API and the realtime service (spec 009,
// US5): the admin keeps the list and the apps get it signed with Ed25519, so a list that Kyq did
// not sign never moves an app to another domain (SC-006).
package domains

import (
	"crypto/ed25519"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"time"
)

// Entry is one active domain in the signed list.
type Entry struct {
	APIURL      string `json:"api_url"`
	RealtimeURL string `json:"realtime_url"`
}

// Payload is the signed content (research R7).
type Payload struct {
	Version  int64     `json:"version"`
	IssuedAt time.Time `json:"issued_at"`
	Domains  []Entry   `json:"domains"`
}

// Signed is GET /v1/domains: the payload exactly as signed and its Ed25519 signature.
type Signed struct {
	Payload   string `json:"payload"`
	Signature string `json:"signature"`
}

// ErrBadSignature means the list was not signed by Kyq.
var ErrBadSignature = errors.New("invalid domain list signature")

// Signer holds the private key of the backend.
type Signer struct{ key ed25519.PrivateKey }

// NewSigner reads a base64 Ed25519 seed of 32 bytes (KYQ_DOMAINS_SIGNING_KEY).
func NewSigner(seedB64 string) (*Signer, error) {
	seed, err := base64.StdEncoding.DecodeString(seedB64)
	if err != nil || len(seed) != ed25519.SeedSize {
		return nil, fmt.Errorf("domains signing key: expected base64 of %d bytes", ed25519.SeedSize)
	}
	return &Signer{key: ed25519.NewKeyFromSeed(seed)}, nil
}

// PublicKey is the base64 public key the apps carry (KYQ_DOMAINS_PUBLIC_KEY).
func (s *Signer) PublicKey() string {
	return base64.StdEncoding.EncodeToString(s.key.Public().(ed25519.PublicKey))
}

// Sign serializes p and signs its bytes.
func (s *Signer) Sign(p Payload) (Signed, error) {
	if p.Domains == nil {
		p.Domains = []Entry{}
	}
	raw, err := json.Marshal(p)
	if err != nil {
		return Signed{}, err
	}
	return Signed{Payload: string(raw), Signature: base64.StdEncoding.EncodeToString(ed25519.Sign(s.key, raw))}, nil
}

// Verify checks the signature with a base64 public key and returns the payload.
func Verify(publicKeyB64 string, signed Signed) (Payload, error) {
	pub, err := base64.StdEncoding.DecodeString(publicKeyB64)
	if err != nil || len(pub) != ed25519.PublicKeySize {
		return Payload{}, ErrBadSignature
	}
	sig, err := base64.StdEncoding.DecodeString(signed.Signature)
	if err != nil || !ed25519.Verify(ed25519.PublicKey(pub), []byte(signed.Payload), sig) {
		return Payload{}, ErrBadSignature
	}
	var p Payload
	if err := json.Unmarshal([]byte(signed.Payload), &p); err != nil {
		return Payload{}, ErrBadSignature
	}
	return p, nil
}

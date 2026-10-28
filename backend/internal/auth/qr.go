package auth

import (
	"crypto/rand"
	"encoding/base64"
)

// NewQRToken returns 128 random bits, URL-safe: the driver's affiliation QR (FR-005 de 001).
func NewQRToken() (string, error) {
	var b [16]byte
	if _, err := rand.Read(b[:]); err != nil {
		return "", err
	}
	return base64.RawURLEncoding.EncodeToString(b[:]), nil
}

// Package httpx holds the JSON request and response helpers shared by every module.
package httpx

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"net/http"
)

// MaxBodyBytes caps every JSON request body.
const MaxBodyBytes = 1 << 20

// Error is the body of every error response (contracts/api.yaml#/components/schemas/Error).
type Error struct {
	Code    string `json:"code"`
	Message string `json:"message"`
}

// WriteJSON writes v as JSON with the given status.
func WriteJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	if err := json.NewEncoder(w).Encode(v); err != nil {
		slog.Error("write json response", "err", err)
	}
}

// WriteError writes an Error body.
func WriteError(w http.ResponseWriter, status int, code, message string) {
	WriteJSON(w, status, Error{Code: code, Message: message})
}

// InternalError logs err and writes a generic 500 without leaking details.
func InternalError(w http.ResponseWriter, r *http.Request, err error) {
	slog.ErrorContext(r.Context(), "internal error", "path", r.URL.Path, "err", err)
	WriteError(w, http.StatusInternalServerError, "internal", "error interno")
}

// DecodeJSON decodes the request body into dst, rejecting unknown fields and trailing data.
// On failure it writes a 400 response and returns false.
func DecodeJSON(w http.ResponseWriter, r *http.Request, dst any) bool {
	dec := json.NewDecoder(http.MaxBytesReader(w, r.Body, MaxBodyBytes))
	dec.DisallowUnknownFields()
	if err := dec.Decode(dst); err != nil {
		WriteError(w, http.StatusBadRequest, "invalid_body", describe(err))
		return false
	}
	if err := dec.Decode(&struct{}{}); !errors.Is(err, io.EOF) {
		WriteError(w, http.StatusBadRequest, "invalid_body", "el cuerpo debe contener un solo objeto JSON")
		return false
	}
	return true
}

func describe(err error) string {
	var maxErr *http.MaxBytesError
	if errors.As(err, &maxErr) {
		return fmt.Sprintf("el cuerpo supera %d bytes", maxErr.Limit)
	}
	return "JSON inválido: " + err.Error()
}

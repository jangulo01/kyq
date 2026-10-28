// Package billing charges the monthly driver subscription with Bold payment links and keeps
// subscriptions.paid_until (spec 002, research R1–R3, RN-KYQ-001/002/003).
package billing

import (
	"bytes"
	"context"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"math"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"time"
)

var (
	// ErrBoldUnavailable means Bold is disabled, unreachable or refused the request.
	ErrBoldUnavailable = errors.New("bold unavailable")
	// ErrLinkNotFound means Bold does not know the payment link.
	ErrLinkNotFound = errors.New("bold link not found")
)

// Bold link statuses (GET /online/link/v1/{id}).
const (
	LinkActive     = "ACTIVE"
	LinkProcessing = "PROCESSING"
	LinkPaid       = "PAID"
	LinkRejected   = "REJECTED"
	LinkCancelled  = "CANCELLED"
	LinkExpired    = "EXPIRED"
)

// LinkRequest creates a payment link with a closed amount.
type LinkRequest struct {
	Reference   string // id del pago en Kyq
	Description string
	Currency    string
	AmountMinor int64
	ExpiresAt   time.Time
}

// Link is a created payment link: ID is LNK_..., URL the hosted checkout.
type Link struct {
	ID  string
	URL string
}

// LinkStatus is the state of a link as Bold reports it.
type LinkStatus struct {
	ID            string
	Status        string
	Reference     string
	Currency      string
	TotalMinor    int64
	PaymentMethod string
	TransactionID string
}

// BoldAPI is the part of the Bold API Kyq uses; tests replace it with an httptest server.
type BoldAPI interface {
	CreateLink(ctx context.Context, r LinkRequest) (Link, error)
	GetLink(ctx context.Context, linkID string) (LinkStatus, error)
}

// BoldClient calls the Bold "API Link de pagos" with the identity key.
type BoldClient struct {
	BaseURL     string // https://integrations.api.bold.co
	IdentityKey string
	HTTP        *http.Client
}

func (c *BoldClient) client() *http.Client {
	if c.HTTP != nil {
		return c.HTTP
	}
	return &http.Client{Timeout: 10 * time.Second}
}

// boldErrors is the error list Bold returns, e.g. [{"errors": "...", "code": "PL_000"}].
type boldErrors []struct {
	Errors string `json:"errors"`
	Code   string `json:"code"`
}

func (e boldErrors) String() string {
	parts := make([]string, len(e))
	for i, x := range e {
		parts[i] = x.Code + " " + x.Errors
	}
	return strings.Join(parts, "; ")
}

func (c *BoldClient) do(ctx context.Context, method, path string, body any, out any) (int, error) {
	var reader io.Reader
	if body != nil {
		raw, err := json.Marshal(body)
		if err != nil {
			return 0, err
		}
		reader = bytes.NewReader(raw)
	}
	req, err := http.NewRequestWithContext(ctx, method, strings.TrimRight(c.BaseURL, "/")+path, reader)
	if err != nil {
		return 0, err
	}
	req.Header.Set("Authorization", "x-api-key "+c.IdentityKey)
	if body != nil {
		req.Header.Set("Content-Type", "application/json")
	}
	resp, err := c.client().Do(req)
	if err != nil {
		return 0, fmt.Errorf("%w: %v", ErrBoldUnavailable, err)
	}
	defer resp.Body.Close()
	raw, err := io.ReadAll(io.LimitReader(resp.Body, 1<<20))
	if err != nil {
		return resp.StatusCode, fmt.Errorf("%w: read body: %v", ErrBoldUnavailable, err)
	}
	if out != nil && len(raw) > 0 {
		if err := json.Unmarshal(raw, out); err != nil && resp.StatusCode < 300 {
			return resp.StatusCode, fmt.Errorf("%w: decode: %v", ErrBoldUnavailable, err)
		}
	}
	return resp.StatusCode, nil
}

// CreateLink creates a CLOSE link. Bold expects expiration_date in nanoseconds since the epoch
// (verified against the sandbox: milliseconds are rejected as a past date).
func (c *BoldClient) CreateLink(ctx context.Context, r LinkRequest) (Link, error) {
	body := map[string]any{
		"amount_type":     "CLOSE",
		"amount":          map[string]any{"currency": r.Currency, "total_amount": MajorAmount(r.AmountMinor)},
		"reference":       r.Reference,
		"description":     r.Description,
		"expiration_date": r.ExpiresAt.UnixNano(),
	}
	var out struct {
		Payload struct {
			PaymentLink string `json:"payment_link"`
			URL         string `json:"url"`
		} `json:"payload"`
		Errors boldErrors `json:"errors"`
	}
	status, err := c.do(ctx, http.MethodPost, "/online/link/v1", body, &out)
	if err != nil {
		return Link{}, err
	}
	if status != http.StatusOK && status != http.StatusCreated || out.Payload.PaymentLink == "" {
		return Link{}, fmt.Errorf("%w: create link: status %d %s", ErrBoldUnavailable, status, out.Errors)
	}
	return Link{ID: out.Payload.PaymentLink, URL: out.Payload.URL}, nil
}

// linkBody is the link status. The sandbox answers it flat; it is also accepted wrapped in
// "payload" like the other link endpoints.
type linkBody struct {
	ID            string      `json:"id"`
	Status        string      `json:"status"`
	Reference     string      `json:"reference"`
	Currency      string      `json:"currency"`
	Total         json.Number `json:"total"`
	PaymentMethod *string     `json:"payment_method"`
	TransactionID *string     `json:"transaction_id"`
}

// GetLink reads the status of a link.
func (c *BoldClient) GetLink(ctx context.Context, linkID string) (LinkStatus, error) {
	var out struct {
		linkBody
		Payload *linkBody  `json:"payload"`
		Errors  boldErrors `json:"errors"`
	}
	status, err := c.do(ctx, http.MethodGet, "/online/link/v1/"+url.PathEscape(linkID), nil, &out)
	if err != nil {
		return LinkStatus{}, err
	}
	if status == http.StatusNotFound {
		return LinkStatus{}, ErrLinkNotFound
	}
	b := out.linkBody
	if b.Status == "" && out.Payload != nil {
		b = *out.Payload
	}
	if status != http.StatusOK || b.Status == "" {
		return LinkStatus{}, fmt.Errorf("%w: get link: status %d %s", ErrBoldUnavailable, status, out.Errors)
	}
	total, err := MinorAmount(b.Total)
	if err != nil {
		return LinkStatus{}, fmt.Errorf("%w: total %q", ErrBoldUnavailable, b.Total)
	}
	ls := LinkStatus{ID: b.ID, Status: b.Status, Reference: b.Reference, Currency: b.Currency, TotalMinor: total}
	if b.PaymentMethod != nil {
		ls.PaymentMethod = *b.PaymentMethod
	}
	if b.TransactionID != nil {
		ls.TransactionID = *b.TransactionID
	}
	return ls, nil
}

// MajorAmount converts minor units (centavos) to the amount Bold expects, e.g. 5000000 → 50000.
func MajorAmount(minor int64) json.Number {
	if minor%100 == 0 {
		return json.Number(strconv.FormatInt(minor/100, 10))
	}
	return json.Number(strconv.FormatFloat(float64(minor)/100, 'f', 2, 64))
}

// MinorAmount converts an amount from Bold to minor units. Empty is zero.
func MinorAmount(n json.Number) (int64, error) {
	if n == "" {
		return 0, nil
	}
	f, err := strconv.ParseFloat(string(n), 64)
	if err != nil {
		return 0, err
	}
	return int64(math.Round(f * 100)), nil
}

// VerifySignature checks the x-bold-signature header of a webhook: the hex HMAC-SHA256 of the
// base64 of the raw body with the secret key (an empty key in the sandbox), compared in
// constant time.
func VerifySignature(secret string, body []byte, signature string) bool {
	got, err := hex.DecodeString(strings.TrimSpace(signature))
	if err != nil || len(got) == 0 {
		return false
	}
	mac := hmac.New(sha256.New, []byte(secret))
	mac.Write([]byte(base64.StdEncoding.EncodeToString(body)))
	return hmac.Equal(got, mac.Sum(nil))
}

// Sign returns the signature Bold would send for body; tests use it.
func Sign(secret string, body []byte) string {
	mac := hmac.New(sha256.New, []byte(secret))
	mac.Write([]byte(base64.StdEncoding.EncodeToString(body)))
	return hex.EncodeToString(mac.Sum(nil))
}

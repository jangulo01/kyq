package auth

import (
	"context"
	"crypto/subtle"
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"strings"
	"time"
)

// OTPSender delivers one-time codes and checks them.
type OTPSender interface {
	Send(ctx context.Context, phone string) error
	Check(ctx context.Context, phone, code string) (bool, error)
}

// DevOTP accepts a fixed code for every phone and sends nothing. Development only.
type DevOTP struct{ Code string }

func (DevOTP) Send(context.Context, string) error { return nil }

func (d DevOTP) Check(_ context.Context, _ string, code string) (bool, error) {
	return subtle.ConstantTimeCompare([]byte(code), []byte(d.Code)) == 1, nil
}

// TwilioVerify sends and checks codes with the Twilio Verify API.
type TwilioVerify struct {
	AccountSID string
	AuthToken  string
	ServiceSID string
	BaseURL    string // defaults to https://verify.twilio.com
	Client     *http.Client
}

func (t TwilioVerify) Send(ctx context.Context, phone string) error {
	_, err := t.post(ctx, "Verifications", url.Values{"To": {phone}, "Channel": {"sms"}})
	return err
}

func (t TwilioVerify) Check(ctx context.Context, phone, code string) (bool, error) {
	status, err := t.post(ctx, "VerificationCheck", url.Values{"To": {phone}, "Code": {code}})
	if err != nil {
		return false, err
	}
	return status == "approved", nil
}

func (t TwilioVerify) post(ctx context.Context, resource string, form url.Values) (string, error) {
	base := t.BaseURL
	if base == "" {
		base = "https://verify.twilio.com"
	}
	client := t.Client
	if client == nil {
		client = &http.Client{Timeout: 10 * time.Second}
	}
	endpoint := fmt.Sprintf("%s/v2/Services/%s/%s", base, url.PathEscape(t.ServiceSID), resource)
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, endpoint, strings.NewReader(form.Encode()))
	if err != nil {
		return "", err
	}
	req.SetBasicAuth(t.AccountSID, t.AuthToken)
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	resp, err := client.Do(req)
	if err != nil {
		return "", fmt.Errorf("twilio %s: %w", resource, err)
	}
	defer resp.Body.Close()
	// Twilio answers 404 when a check has no pending verification: treat as a wrong code.
	if resource == "VerificationCheck" && resp.StatusCode == http.StatusNotFound {
		return "not_found", nil
	}
	if resp.StatusCode >= 300 {
		return "", fmt.Errorf("twilio %s: status %d", resource, resp.StatusCode)
	}
	var body struct {
		Status string `json:"status"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&body); err != nil {
		return "", fmt.Errorf("twilio %s: decode: %w", resource, err)
	}
	return body.Status, nil
}

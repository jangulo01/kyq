package notify

import (
	"context"
	"fmt"
	"log/slog"
	"net/http"
	"net/url"
	"strings"
	"time"

	"github.com/jackc/pgx/v5/pgtype"
)

// SMSSender delivers a text message to a phone in E.164.
type SMSSender interface {
	SendSMS(ctx context.Context, phone, body string) error
}

// LogSMS only logs that an SMS would be sent (development). It never logs the phone or the text.
type LogSMS struct{ Logger *slog.Logger }

func (l LogSMS) SendSMS(ctx context.Context, _, body string) error {
	logger := l.Logger
	if logger == nil {
		logger = slog.Default()
	}
	logger.InfoContext(ctx, "sms (desarrollo): no se envía", "chars", len(body))
	return nil
}

// TwilioSMS sends with the Twilio Messages API. From is a phone number or a Messaging Service
// SID (MG...).
type TwilioSMS struct {
	AccountSID string
	AuthToken  string
	From       string
	HTTP       *http.Client
}

func (t TwilioSMS) SendSMS(ctx context.Context, phone, body string) error {
	form := url.Values{"To": {phone}, "Body": {body}}
	if strings.HasPrefix(t.From, "MG") {
		form.Set("MessagingServiceSid", t.From)
	} else {
		form.Set("From", t.From)
	}
	endpoint := "https://api.twilio.com/2010-04-01/Accounts/" + url.PathEscape(t.AccountSID) + "/Messages.json"
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, endpoint, strings.NewReader(form.Encode()))
	if err != nil {
		return err
	}
	req.SetBasicAuth(t.AccountSID, t.AuthToken)
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	client := t.HTTP
	if client == nil {
		client = &http.Client{Timeout: 10 * time.Second}
	}
	resp, err := client.Do(req)
	if err != nil {
		return fmt.Errorf("twilio sms: %w", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusCreated && resp.StatusCode != http.StatusOK {
		return fmt.Errorf("twilio sms: status %d", resp.StatusCode)
	}
	return nil
}

func timestamptz(t time.Time) pgtype.Timestamptz { return pgtype.Timestamptz{Time: t, Valid: true} }

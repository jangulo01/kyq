// Package realtime publishes events to Centrifugo and issues its connection and subscription
// tokens. Channels and events: specs/001-chosen-driver-trip-ptt/contracts/realtime.md.
package realtime

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"strings"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
)

const tokenTTL = time.Hour

// Event is the envelope of every published message.
type Event struct {
	Type       string    `json:"type"`
	OccurredAt time.Time `json:"occurred_at"`
	Data       any       `json:"data"`
}

// Publisher sends events to channels.
type Publisher interface {
	Publish(ctx context.Context, channel string, ev Event) error
}

// Client talks to the Centrifugo HTTP API.
type Client struct {
	APIURL string // e.g. http://localhost:8000/api
	APIKey string
	HTTP   *http.Client
}

// Publish sends ev to channel.
func (c *Client) Publish(ctx context.Context, channel string, ev Event) error {
	body, err := json.Marshal(map[string]any{"channel": channel, "data": ev})
	if err != nil {
		return err
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, strings.TrimRight(c.APIURL, "/")+"/publish", bytes.NewReader(body))
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-API-Key", c.APIKey)
	client := c.HTTP
	if client == nil {
		client = &http.Client{Timeout: 5 * time.Second}
	}
	resp, err := client.Do(req)
	if err != nil {
		return fmt.Errorf("centrifugo publish: %w", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("centrifugo publish: status %d", resp.StatusCode)
	}
	var out struct {
		Error *struct {
			Code    int    `json:"code"`
			Message string `json:"message"`
		} `json:"error"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&out); err != nil {
		return fmt.Errorf("centrifugo publish: decode: %w", err)
	}
	if out.Error != nil {
		return fmt.Errorf("centrifugo publish: %d %s", out.Error.Code, out.Error.Message)
	}
	return nil
}

// Tokens signs Centrifugo connection and subscription tokens (HS256).
type Tokens struct {
	Secret []byte
	Now    func() time.Time
}

func (t Tokens) now() time.Time {
	if t.Now != nil {
		return t.Now()
	}
	return time.Now()
}

// Connection returns a connection token for userID.
func (t Tokens) Connection(userID uuid.UUID) (string, error) {
	now := t.now()
	return jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.RegisteredClaims{
		Subject:   userID.String(),
		IssuedAt:  jwt.NewNumericDate(now),
		ExpiresAt: jwt.NewNumericDate(now.Add(tokenTTL)),
	}).SignedString(t.Secret)
}

type subscriptionClaims struct {
	Channel string `json:"channel"`
	jwt.RegisteredClaims
}

// Subscription returns a token that lets userID subscribe to channel.
func (t Tokens) Subscription(userID uuid.UUID, channel string) (string, error) {
	now := t.now()
	return jwt.NewWithClaims(jwt.SigningMethodHS256, subscriptionClaims{
		Channel: channel,
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   userID.String(),
			IssuedAt:  jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(now.Add(tokenTTL)),
		},
	}).SignedString(t.Secret)
}

// ErrForbiddenChannel means the caller may not subscribe to the channel.
var ErrForbiddenChannel = errors.New("forbidden channel")

// AffiliationChecker reports whether a passenger has a driver as chosen driver.
type AffiliationChecker interface {
	IsAffiliated(ctx context.Context, passengerID, driverID uuid.UUID) (bool, error)
}

// TripParticipantChecker reports whether a user is the passenger or driver of a trip.
type TripParticipantChecker interface {
	IsParticipant(ctx context.Context, tripID, userID uuid.UUID) (bool, error)
}

// OperatorChecker reports whether a user is an administrator with the emergency operator
// permission (003, FR-012).
type OperatorChecker interface {
	IsEmergencyOperator(ctx context.Context, userID uuid.UUID) (bool, error)
}

// OpsSOSChannel is the emergency console queue: sos.created, sos.claimed, sos.released,
// sos.closed, sos.cancel_attempt and sos.escalated (003, research R3).
const OpsSOSChannel = "ops:sos"

// Authorizer decides which channels a user may subscribe to. Nil checkers deny their channels.
type Authorizer struct {
	Affiliations AffiliationChecker
	Trips        TripParticipantChecker
	Operators    OperatorChecker
}

// Authorize returns nil when userID may subscribe to channel.
func (a Authorizer) Authorize(ctx context.Context, userID uuid.UUID, channel string) error {
	prefix, rawID, ok := strings.Cut(channel, ":")
	if !ok {
		return ErrForbiddenChannel
	}
	if channel == OpsSOSChannel {
		return a.operator(ctx, userID)
	}
	id, err := uuid.Parse(rawID)
	if err != nil {
		return ErrForbiddenChannel
	}
	allowed := false
	switch prefix {
	case "user":
		allowed = id == userID
	case "driver_presence":
		if id == userID {
			allowed = true
		} else if a.Affiliations != nil {
			allowed, err = a.Affiliations.IsAffiliated(ctx, userID, id)
		}
	case "trip":
		if a.Trips != nil {
			allowed, err = a.Trips.IsParticipant(ctx, id, userID)
		}
	case "sos":
		// Ubicación en vivo de una alerta: solo operadores; ni la persona ni la otra parte del
		// viaje (FR-006).
		return a.operator(ctx, userID)
	}
	if err != nil {
		return fmt.Errorf("authorize channel: %w", err)
	}
	if !allowed {
		return ErrForbiddenChannel
	}
	return nil
}

func (a Authorizer) operator(ctx context.Context, userID uuid.UUID) error {
	if a.Operators == nil {
		return ErrForbiddenChannel
	}
	ok, err := a.Operators.IsEmergencyOperator(ctx, userID)
	if err != nil {
		return fmt.Errorf("authorize channel: %w", err)
	}
	if !ok {
		return ErrForbiddenChannel
	}
	return nil
}

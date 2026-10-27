package ptt

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

// Rooms creates and deletes LiveKit rooms.
type Rooms interface {
	CreateRoom(ctx context.Context, name string) error
	DeleteRoom(ctx context.Context, name string) error
}

// LiveKit signs access tokens and calls the RoomService Twirp API. A small client instead of
// the server SDK: two calls and one JWT are all the MVP needs.
type LiveKit struct {
	APIURL    string // e.g. http://livekit:7880
	APIKey    string
	APISecret string
	HTTP      *http.Client
}

// APIURLFrom turns the client WebSocket URL into the HTTP URL of the same server.
func APIURLFrom(wsURL string) string {
	switch {
	case strings.HasPrefix(wsURL, "wss://"):
		return "https://" + strings.TrimPrefix(wsURL, "wss://")
	case strings.HasPrefix(wsURL, "ws://"):
		return "http://" + strings.TrimPrefix(wsURL, "ws://")
	}
	return wsURL
}

type videoGrant struct {
	Room              string   `json:"room,omitempty"`
	RoomJoin          bool     `json:"roomJoin,omitempty"`
	RoomCreate        bool     `json:"roomCreate,omitempty"`
	CanPublish        *bool    `json:"canPublish,omitempty"`
	CanSubscribe      *bool    `json:"canSubscribe,omitempty"`
	CanPublishData    *bool    `json:"canPublishData,omitempty"`
	CanPublishSources []string `json:"canPublishSources,omitempty"`
}

type claims struct {
	jwt.RegisteredClaims
	Name  string     `json:"name,omitempty"`
	Video videoGrant `json:"video"`
}

// ParticipantToken lets identity join room and publish only microphone audio and data
// messages (FR-016) until now+ttl.
func (l LiveKit) ParticipantToken(identity, name, room string, now time.Time, ttl time.Duration) (string, error) {
	yes := true
	return l.sign(claims{
		RegisteredClaims: jwt.RegisteredClaims{Subject: identity},
		Name:             name,
		Video: videoGrant{
			Room: room, RoomJoin: true, CanPublish: &yes, CanSubscribe: &yes, CanPublishData: &yes,
			CanPublishSources: []string{"microphone"},
		},
	}, now, ttl)
}

func (l LiveKit) sign(c claims, now time.Time, ttl time.Duration) (string, error) {
	c.Issuer = l.APIKey
	c.NotBefore = jwt.NewNumericDate(now)
	c.ExpiresAt = jwt.NewNumericDate(now.Add(ttl))
	return jwt.NewWithClaims(jwt.SigningMethodHS256, c).SignedString([]byte(l.APISecret))
}

// CreateRoom is idempotent: LiveKit returns the existing room when the name is taken.
func (l LiveKit) CreateRoom(ctx context.Context, name string) error {
	return l.call(ctx, "CreateRoom", map[string]any{"name": name, "max_participants": 2, "empty_timeout": 300})
}

// DeleteRoom disconnects everyone in the room.
func (l LiveKit) DeleteRoom(ctx context.Context, name string) error {
	return l.call(ctx, "DeleteRoom", map[string]any{"room": name})
}

func (l LiveKit) call(ctx context.Context, method string, body any) error {
	token, err := l.sign(claims{Video: videoGrant{RoomCreate: true}}, time.Now(), time.Minute)
	if err != nil {
		return err
	}
	payload, err := json.Marshal(body)
	if err != nil {
		return err
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodPost,
		strings.TrimRight(l.APIURL, "/")+"/twirp/livekit.RoomService/"+method, bytes.NewReader(payload))
	if err != nil {
		return err
	}
	req.Header.Set("Authorization", "Bearer "+token)
	req.Header.Set("Content-Type", "application/json")
	client := l.HTTP
	if client == nil {
		client = &http.Client{Timeout: 5 * time.Second}
	}
	resp, err := client.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("livekit %s: status %d", method, resp.StatusCode)
	}
	return nil
}

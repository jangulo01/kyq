package ptt

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
)

// Rooms manages LiveKit rooms and who may publish audio in them.
type Rooms interface {
	CreateRoom(ctx context.Context, name string) error
	// DeleteRoom succeeds when the room no longer exists.
	DeleteRoom(ctx context.Context, name string) error
	// SetCanPublish succeeds when the participant is not in the room: it gets the default
	// (no publishing) from its token when it joins.
	SetCanPublish(ctx context.Context, room, identity string, canPublish bool) error
}

// errNotFound is a Twirp not_found answer (room or participant gone).
var errNotFound = errors.New("livekit: not found")

// errPrecondition is a Twirp failed_precondition answer (e.g. an egress already finished).
var errPrecondition = errors.New("livekit: failed precondition")

// LiveKit signs access tokens and calls the RoomService Twirp API. A small client instead of
// the server SDK: three calls and one JWT are all the MVP needs.
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
	RoomAdmin         bool     `json:"roomAdmin,omitempty"`
	CanPublish        *bool    `json:"canPublish,omitempty"`
	CanSubscribe      *bool    `json:"canSubscribe,omitempty"`
	CanPublishData    *bool    `json:"canPublishData,omitempty"`
	CanPublishSources []string `json:"canPublishSources,omitempty"`
	RoomRecord        bool     `json:"roomRecord,omitempty"`
}

type claims struct {
	jwt.RegisteredClaims
	Name  string     `json:"name,omitempty"`
	Video videoGrant `json:"video"`
}

// ParticipantToken lets identity join room, listen and send data messages until now+ttl.
// Publishing audio is off: the server grants it only to the floor holder (FR-017), so a
// modified app cannot talk over the other party.
func (l LiveKit) ParticipantToken(identity, name, room string, now time.Time, ttl time.Duration) (string, error) {
	yes, no := true, false
	return l.sign(claims{
		RegisteredClaims: jwt.RegisteredClaims{Subject: identity},
		Name:             name,
		Video: videoGrant{
			Room: room, RoomJoin: true, CanPublish: &no, CanSubscribe: &yes, CanPublishData: &yes,
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
	return l.call(ctx, "CreateRoom", videoGrant{RoomCreate: true}, map[string]any{"name": name, "max_participants": 2, "empty_timeout": 300})
}

// DeleteRoom disconnects everyone in the room.
func (l LiveKit) DeleteRoom(ctx context.Context, name string) error {
	if err := l.call(ctx, "DeleteRoom", videoGrant{RoomCreate: true}, map[string]any{"room": name}); !errors.Is(err, errNotFound) {
		return err
	}
	return nil
}

// SetCanPublish grants or revokes microphone publishing; revoking unpublishes the track.
func (l LiveKit) SetCanPublish(ctx context.Context, room, identity string, canPublish bool) error {
	err := l.call(ctx, "UpdateParticipant", videoGrant{Room: room, RoomAdmin: true}, map[string]any{
		"room": room, "identity": identity,
		"permission": map[string]any{
			"can_subscribe": true, "can_publish": canPublish, "can_publish_data": true,
			"can_publish_sources": []string{"MICROPHONE"},
		},
	})
	if errors.Is(err, errNotFound) {
		return nil
	}
	return err
}

func (l LiveKit) call(ctx context.Context, method string, grant videoGrant, body any) error {
	return l.twirp(ctx, "livekit.RoomService", method, grant, body, nil)
}

// twirp calls service/method with body and decodes the answer into out (nil: discarded).
func (l LiveKit) twirp(ctx context.Context, service, method string, grant videoGrant, body, out any) error {
	token, err := l.sign(claims{Video: grant}, time.Now(), time.Minute)
	if err != nil {
		return err
	}
	payload, err := json.Marshal(body)
	if err != nil {
		return err
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodPost,
		strings.TrimRight(l.APIURL, "/")+"/twirp/"+service+"/"+method, bytes.NewReader(payload))
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
	switch resp.StatusCode {
	case http.StatusOK:
		if out == nil {
			return nil
		}
		if err := json.NewDecoder(resp.Body).Decode(out); err != nil {
			return fmt.Errorf("livekit %s: decode: %w", method, err)
		}
		return nil
	case http.StatusNotFound:
		return errNotFound
	case http.StatusPreconditionFailed:
		return errPrecondition
	}
	return fmt.Errorf("livekit %s: status %d", method, resp.StatusCode)
}

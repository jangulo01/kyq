package ptt

import (
	"context"
	"errors"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

// Salas SOS (003, research R1): la persona en riesgo publica micrófono desde que entra, los
// operadores entran solo a escuchar y la API concede hablar a quien toma la alerta con
// SetCanPublish, con el mismo criterio fail-closed del turno PTT.

// SOSRoomMaxParticipants admite a la persona, varios operadores escuchando y el grabador.
const SOSRoomMaxParticipants = 10

// sosEmptyTimeout mantiene la sala aunque la persona pierda la conexión un rato: la API la
// borra al cerrar la alerta.
const sosEmptyTimeout = 2 * 60 * 60

// CreateSOSRoom creates the room of an alert; idempotent like CreateRoom.
func (l LiveKit) CreateSOSRoom(ctx context.Context, name string) error {
	return l.call(ctx, "CreateRoom", videoGrant{RoomCreate: true}, map[string]any{
		"name": name, "max_participants": SOSRoomMaxParticipants, "empty_timeout": sosEmptyTimeout,
	})
}

// SOSToken lets the person who raised the alert talk from the start: in an emergency there is
// no turn, the microphone stays open (research R1).
func (l LiveKit) SOSToken(identity, name, room string, now time.Time, ttl time.Duration) (string, error) {
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

// OperatorToken lets an operator join and listen. Talking needs the claim: the API grants it
// with SetCanPublish and takes it back on release, so a token never carries the right to talk.
func (l LiveKit) OperatorToken(identity, name, room string, now time.Time, ttl time.Duration) (string, error) {
	yes, no := true, false
	return l.sign(claims{
		RegisteredClaims: jwt.RegisteredClaims{Subject: identity},
		Name:             name,
		Video: videoGrant{
			Room: room, RoomJoin: true, CanPublish: &no, CanSubscribe: &yes, CanPublishData: &no,
			CanPublishSources: []string{"microphone"},
		},
	}, now, ttl)
}

// StartAudioEgress records the room's mixed audio as OGG/Opus to filepath in the default bucket
// of the egress service (infra/egress.yaml, bucket kyq-sos). It returns the egress id.
func (l LiveKit) StartAudioEgress(ctx context.Context, room, filepath string) (string, error) {
	var out struct {
		EgressID string `json:"egress_id"`
	}
	err := l.twirp(ctx, "livekit.Egress", "StartRoomCompositeEgress", videoGrant{Room: room, RoomRecord: true}, map[string]any{
		"room_name":  room,
		"audio_only": true,
		"file_outputs": []map[string]any{
			{"file_type": "OGG", "filepath": filepath},
		},
	}, &out)
	if err != nil {
		return "", err
	}
	if out.EgressID == "" {
		return "", errors.New("livekit StartRoomCompositeEgress: empty egress_id")
	}
	return out.EgressID, nil
}

// StopEgress ends a recording; an egress that no longer exists counts as stopped.
func (l LiveKit) StopEgress(ctx context.Context, egressID string) error {
	err := l.twirp(ctx, "livekit.Egress", "StopEgress", videoGrant{RoomRecord: true}, map[string]any{"egress_id": egressID}, nil)
	// Twirp responde failed_precondition (412) si la grabación ya terminó.
	if errors.Is(err, errNotFound) || errors.Is(err, errPrecondition) {
		return nil
	}
	return err
}

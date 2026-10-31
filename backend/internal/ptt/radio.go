package ptt

import "context"

// Salas de Radio Kyq (011, research R1 y R3): persistentes por conversación y, con registro, con
// egress automático por pista: LiveKit graba cada publicación de micrófono como un archivo
// OGG/Opus en el bucket de Radio, sin que la API inicie nada por mensaje.

// radioEmptyTimeout mantiene la sala mientras nadie la usa; se vuelve a crear al pedir token.
const radioEmptyTimeout = 10 * 60

// RadioS3 is where the track egress writes radio messages (bucket kyq-radio). The egress service
// reaches the same internal endpoint as the API.
type RadioS3 struct {
	Endpoint  string // p. ej. http://minio:9000
	Region    string
	AccessKey string
	SecretKey string
	Bucket    string
}

// RadioRooms creates Radio rooms on top of LiveKit and implements radio.Rooms.
type RadioRooms struct {
	LiveKit
	S3 RadioS3
}

// RadioFilepath is the object path template of each recorded message: one file per track, under
// the room (no personal data).
const RadioFilepath = "radio/{room_name}/{track_id}"

// CreateRadioRoom is idempotent like CreateRoom. With record, every microphone track is
// recorded by itself (AutoTrackEgress).
func (r RadioRooms) CreateRadioRoom(ctx context.Context, name string, maxParticipants int, record bool) error {
	body := map[string]any{"name": name, "max_participants": maxParticipants, "empty_timeout": radioEmptyTimeout}
	if record {
		body["egress"] = map[string]any{
			"tracks": map[string]any{
				"filepath":         RadioFilepath,
				"disable_manifest": true,
				"s3": map[string]any{
					"access_key": r.S3.AccessKey, "secret": r.S3.SecretKey, "region": r.S3.Region,
					"endpoint": r.S3.Endpoint, "bucket": r.S3.Bucket, "force_path_style": true,
				},
			},
		}
	}
	return r.call(ctx, "CreateRoom", videoGrant{RoomCreate: true}, body)
}

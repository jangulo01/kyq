-- +goose Up
-- Canal de voz 1 a 1 por viaje (RN-KYQ-009, RN-KYQ-014). La voz no se almacena (FR-021).
CREATE TABLE ptt_channels (
    trip_id          uuid PRIMARY KEY REFERENCES trips (id),
    room_name        text NOT NULL UNIQUE,
    opened_at        timestamptz NOT NULL,
    closes_at        timestamptz,
    closed_at        timestamptz,
    floor_holder_id  uuid REFERENCES users (id),
    floor_expires_at timestamptz
);

CREATE INDEX ptt_channels_due ON ptt_channels (closes_at) WHERE closed_at IS NULL AND closes_at IS NOT NULL;

-- +goose Down
DROP TABLE ptt_channels;

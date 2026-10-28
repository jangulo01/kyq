-- +goose Up
-- Pre-consulta de voz de clientes frecuentes (RN-KYQ-010, specs/005-ptt-extras). Como el canal
-- del viaje, la voz no se almacena: solo los datos de cada consulta, que se borran a los 30 días.
ALTER TABLE drivers ADD COLUMN accepts_preconsults boolean NOT NULL DEFAULT false;
ALTER TABLE affiliations ADD COLUMN preconsults_blocked boolean NOT NULL DEFAULT false;

CREATE TABLE ptt_preconsults (
    id               uuid PRIMARY KEY,
    passenger_id     uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    driver_id        uuid NOT NULL REFERENCES drivers (user_id) ON DELETE CASCADE,
    room_name        text NOT NULL UNIQUE,
    opened_at        timestamptz NOT NULL,
    join_deadline    timestamptz NOT NULL,
    closes_at        timestamptz NOT NULL,
    joined_at        timestamptz,
    answered_at      timestamptz,
    closed_at        timestamptz,
    close_reason     text CHECK (close_reason IN (
        'ended_by_passenger', 'ended_by_driver', 'disabled', 'missed', 'driver_unavailable', 'expired'
    )),
    floor_holder_id  uuid REFERENCES users (id),
    floor_expires_at timestamptz,
    CHECK (passenger_id <> driver_id),
    CHECK (closed_at IS NULL OR close_reason IS NOT NULL)
);

-- Una consulta abierta por conductor y por pasajero (FR-007).
CREATE UNIQUE INDEX ptt_preconsults_open_driver ON ptt_preconsults (driver_id) WHERE closed_at IS NULL;
CREATE UNIQUE INDEX ptt_preconsults_open_passenger ON ptt_preconsults (passenger_id) WHERE closed_at IS NULL;
CREATE INDEX ptt_preconsults_passenger_recent ON ptt_preconsults (passenger_id, opened_at);
CREATE INDEX ptt_preconsults_driver_recent ON ptt_preconsults (driver_id, opened_at);
CREATE INDEX ptt_preconsults_closed ON ptt_preconsults (closed_at) WHERE closed_at IS NOT NULL;

-- +goose Down
DROP TABLE ptt_preconsults;
ALTER TABLE affiliations DROP COLUMN preconsults_blocked;
ALTER TABLE drivers DROP COLUMN accepts_preconsults;

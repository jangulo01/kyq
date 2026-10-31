-- +goose Up
-- 010: agenda de reservas, notas del conductor sobre sus clientes y llegada automática.

CREATE TYPE reservation_status AS ENUM ('pending', 'confirmed', 'rejected', 'cancelled', 'expired', 'fulfilled', 'missed');

CREATE TABLE reservations (
    id                        uuid PRIMARY KEY,
    passenger_id              uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    driver_id                 uuid NOT NULL REFERENCES drivers (user_id) ON DELETE CASCADE,
    pickup_lat                double precision NOT NULL,
    pickup_lng                double precision NOT NULL,
    dropoff_lat               double precision NOT NULL,
    dropoff_lng               double precision NOT NULL,
    pickup_label              text CHECK (pickup_label IS NULL OR char_length(pickup_label) <= 200),
    dropoff_label             text CHECK (dropoff_label IS NULL OR char_length(dropoff_label) <= 200),
    scheduled_at              timestamptz NOT NULL,
    distance_m                integer NOT NULL CHECK (distance_m >= 0),
    duration_s                integer NOT NULL CHECK (duration_s >= 0),
    currency                  char(3) NOT NULL,
    -- Tarifa reservada: la sugerida al reservar, con la preferencial de 008 si aplicaba.
    fare_minor                bigint NOT NULL CHECK (fare_minor > 0),
    list_fare_minor           bigint NOT NULL CHECK (list_fare_minor > 0),
    preferential_discount_pct smallint NOT NULL DEFAULT 0 CHECK (preferential_discount_pct BETWEEN 0 AND 30),
    status                    reservation_status NOT NULL DEFAULT 'pending',
    cancelled_by              uuid REFERENCES users (id) ON DELETE SET NULL,
    reminded_at               timestamptz,
    trip_id                   uuid REFERENCES trips (id) ON DELETE SET NULL,
    created_at                timestamptz NOT NULL,
    updated_at                timestamptz NOT NULL
);

CREATE INDEX reservations_passenger_idx ON reservations (passenger_id, scheduled_at);
CREATE INDEX reservations_driver_idx ON reservations (driver_id, scheduled_at);
CREATE INDEX reservations_due_idx ON reservations (status, scheduled_at) WHERE status IN ('pending', 'confirmed');

-- Notas privadas del conductor sobre sus clientes: nunca llegan al pasajero (FR-008).
CREATE TABLE client_notes (
    driver_id    uuid NOT NULL REFERENCES drivers (user_id) ON DELETE CASCADE,
    passenger_id uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    body         text NOT NULL CHECK (char_length(btrim(body)) BETWEEN 1 AND 500),
    updated_at   timestamptz NOT NULL,
    PRIMARY KEY (driver_id, passenger_id)
);

-- Llegada automática: inicio de la racha de ubicaciones precisas a < 60 m de la recogida.
ALTER TABLE trips ADD COLUMN near_pickup_since timestamptz;

-- +goose Down
ALTER TABLE trips DROP COLUMN near_pickup_since;
DROP TABLE client_notes;
DROP TABLE reservations;
DROP TYPE reservation_status;

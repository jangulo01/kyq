-- +goose Up
ALTER TABLE drivers
    ADD COLUMN last_lat double precision,
    ADD COLUMN last_lng double precision,
    ADD COLUMN busy_estimate_updated_at timestamptz;

CREATE TABLE fare_tables (
    city_code        text PRIMARY KEY,
    currency         char(3) NOT NULL,
    base_minor       bigint NOT NULL CHECK (base_minor >= 0),
    per_km_minor     bigint NOT NULL CHECK (per_km_minor >= 0),
    per_minute_minor bigint NOT NULL CHECK (per_minute_minor >= 0),
    minimum_minor    bigint NOT NULL CHECK (minimum_minor >= 0),
    rounding_minor   bigint NOT NULL DEFAULT 1 CHECK (rounding_minor >= 1),
    updated_by       uuid NOT NULL REFERENCES users (id),
    updated_at       timestamptz NOT NULL DEFAULT now()
);

CREATE TYPE trip_status AS ENUM (
    'REQUESTED', 'FARE_PENDING', 'NEGOTIATION_PENDING', 'NEGOTIATING',
    'ACCEPTED', 'ARRIVED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'
);

CREATE TYPE trip_cancel_reason AS ENUM (
    'passenger', 'driver', 'offer_expired', 'offer_rejected', 'fare_rejected', 'negotiation_failed'
);

CREATE TABLE trips (
    id                        uuid PRIMARY KEY,
    passenger_id              uuid NOT NULL REFERENCES users (id),
    driver_id                 uuid NOT NULL REFERENCES drivers (user_id),
    city_code                 text NOT NULL REFERENCES fare_tables (city_code),
    currency                  char(3) NOT NULL,
    pickup_lat                double precision NOT NULL,
    pickup_lng                double precision NOT NULL,
    dropoff_lat               double precision NOT NULL,
    dropoff_lng               double precision NOT NULL,
    route_distance_m          integer NOT NULL CHECK (route_distance_m >= 0),
    route_duration_s          integer NOT NULL CHECK (route_duration_s >= 0),
    suggested_fare_minor      bigint NOT NULL CHECK (suggested_fare_minor >= 0),
    agreed_fare_minor         bigint CHECK (agreed_fare_minor > 0),
    driver_payout_minor       bigint,
    -- RN-KYQ-001: comisión cero, siempre.
    platform_commission_minor bigint NOT NULL DEFAULT 0 CHECK (platform_commission_minor = 0),
    status                    trip_status NOT NULL,
    cancel_reason             trip_cancel_reason,
    -- Plazo de la respuesta pendiente (oferta 25 s, confirmación o propuesta 30 s).
    respond_by                timestamptz,
    negotiation_expires_at    timestamptz,
    created_at                timestamptz NOT NULL DEFAULT now(),
    accepted_at               timestamptz,
    arrived_at                timestamptz,
    started_at                timestamptz,
    completed_at              timestamptz,
    cancelled_at              timestamptz,
    CHECK (driver_payout_minor IS NULL OR driver_payout_minor = agreed_fare_minor)
);

-- FR-012: un viaje activo por conductor y por pasajero.
CREATE UNIQUE INDEX trips_one_active_per_driver ON trips (driver_id)
    WHERE status NOT IN ('COMPLETED', 'CANCELLED');
CREATE UNIQUE INDEX trips_one_active_per_passenger ON trips (passenger_id)
    WHERE status NOT IN ('COMPLETED', 'CANCELLED');
CREATE INDEX trips_respond_by_idx ON trips (respond_by) WHERE respond_by IS NOT NULL;

CREATE TYPE fare_party AS ENUM ('driver', 'passenger');
CREATE TYPE fare_proposal_status AS ENUM ('open', 'accepted', 'rejected', 'superseded', 'expired');

CREATE TABLE fare_proposals (
    id           uuid PRIMARY KEY,
    trip_id      uuid NOT NULL REFERENCES trips (id) ON DELETE CASCADE,
    proposed_by  fare_party NOT NULL,
    amount_minor bigint NOT NULL CHECK (amount_minor > 0),
    status       fare_proposal_status NOT NULL,
    created_at   timestamptz NOT NULL,
    expires_at   timestamptz NOT NULL
);

CREATE UNIQUE INDEX fare_proposals_one_open ON fare_proposals (trip_id) WHERE status = 'open';

-- +goose Down
DROP TABLE fare_proposals;
DROP TYPE fare_proposal_status;
DROP TYPE fare_party;
DROP TABLE trips;
DROP TYPE trip_cancel_reason;
DROP TYPE trip_status;
DROP TABLE fare_tables;
ALTER TABLE drivers
    DROP COLUMN busy_estimate_updated_at,
    DROP COLUMN last_lng,
    DROP COLUMN last_lat;

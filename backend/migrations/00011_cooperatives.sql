-- +goose Up
-- 006: cooperativas, membresías, despacho con delegación (RN-KYQ-008) y canal PTT de grupo.

CREATE TYPE cooperative_status AS ENUM ('active', 'suspended');

CREATE TABLE cooperatives (
    id         uuid PRIMARY KEY,
    name       text NOT NULL CHECK (char_length(btrim(name)) BETWEEN 3 AND 80),
    city_code  text NOT NULL CHECK (char_length(city_code) BETWEEN 1 AND 40),
    nit        text CHECK (nit IS NULL OR char_length(nit) BETWEEN 1 AND 20),
    status     cooperative_status NOT NULL DEFAULT 'active',
    created_by uuid NOT NULL REFERENCES users (id),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX cooperatives_name_unique ON cooperatives (lower(btrim(name)));

CREATE TYPE cooperative_role AS ENUM ('member', 'coordinator');
CREATE TYPE membership_status AS ENUM ('pending', 'active', 'rejected', 'cancelled', 'left', 'removed');

CREATE TABLE cooperative_memberships (
    id             uuid PRIMARY KEY,
    cooperative_id uuid NOT NULL REFERENCES cooperatives (id),
    driver_id      uuid NOT NULL REFERENCES drivers (user_id) ON DELETE CASCADE,
    role           cooperative_role NOT NULL DEFAULT 'member',
    status         membership_status NOT NULL,
    reject_reason  text,
    requested_at   timestamptz NOT NULL DEFAULT now(),
    decided_by     uuid REFERENCES users (id),
    decided_at     timestamptz,
    ended_by       uuid REFERENCES users (id),
    ended_at       timestamptz,
    CHECK (status <> 'rejected' OR coalesce(btrim(reject_reason), '') <> '')
);

-- FR-003: un conductor pertenece como máximo a una cooperativa y tiene una solicitud a la vez.
CREATE UNIQUE INDEX cooperative_memberships_one_per_driver ON cooperative_memberships (driver_id)
    WHERE status IN ('pending', 'active');
CREATE INDEX cooperative_memberships_by_coop ON cooperative_memberships (cooperative_id, status);

-- Despacho del viaje: al Conductor Elegido o a su cooperativa, con delegación consentida.
CREATE TYPE trip_dispatch AS ENUM ('chosen_driver', 'cooperative');

ALTER TABLE trips
    ADD COLUMN dispatch            trip_dispatch NOT NULL DEFAULT 'chosen_driver',
    ADD COLUMN requested_driver_id uuid REFERENCES drivers (user_id),
    ADD COLUMN cooperative_id      uuid REFERENCES cooperatives (id),
    ADD COLUMN allow_delegation    boolean NOT NULL DEFAULT false,
    ADD COLUMN handover_count      smallint NOT NULL DEFAULT 0 CHECK (handover_count BETWEEN 0 AND 3);

UPDATE trips SET requested_driver_id = driver_id;
ALTER TABLE trips ALTER COLUMN requested_driver_id SET NOT NULL;
ALTER TABLE trips
    ADD CONSTRAINT trips_dispatch_needs_cooperative CHECK (dispatch = 'chosen_driver' OR cooperative_id IS NOT NULL),
    ADD CONSTRAINT trips_delegation_needs_cooperative CHECK (NOT allow_delegation OR cooperative_id IS NOT NULL);

-- PostgreSQL >= 12 admite ADD VALUE en la transacción si el valor no se usa en ella (research R7).
ALTER TYPE trip_cancel_reason ADD VALUE IF NOT EXISTS 'no_driver_available';

-- Conductores a los que se ofreció cada viaje: excluye repetir y deja rastro de la derivación.
CREATE TABLE trip_offers (
    trip_id    uuid NOT NULL REFERENCES trips (id) ON DELETE CASCADE,
    driver_id  uuid NOT NULL REFERENCES drivers (user_id),
    offered_at timestamptz NOT NULL,
    handover   boolean NOT NULL DEFAULT false,
    PRIMARY KEY (trip_id, driver_id)
);

INSERT INTO trip_offers (trip_id, driver_id, offered_at, handover)
SELECT id, driver_id, created_at, false FROM trips;

-- Canal de voz de grupo por cooperativa (tipo COOP_GROUP del SDD). La voz no se almacena.
CREATE TYPE ptt_channel_type AS ENUM ('COOP_GROUP');

CREATE TABLE group_ptt_channels (
    cooperative_id   uuid PRIMARY KEY REFERENCES cooperatives (id) ON DELETE CASCADE,
    channel_type     ptt_channel_type NOT NULL DEFAULT 'COOP_GROUP',
    room_name        text NOT NULL UNIQUE,
    floor_holder_id  uuid REFERENCES users (id),
    floor_expires_at timestamptz,
    created_at       timestamptz NOT NULL DEFAULT now(),
    CHECK ((floor_holder_id IS NULL) = (floor_expires_at IS NULL))
);

-- +goose Down
DROP TABLE group_ptt_channels;
DROP TYPE ptt_channel_type;
DROP TABLE trip_offers;
-- El valor 'no_driver_available' de trip_cancel_reason no se puede quitar de un enum; queda.
ALTER TABLE trips
    DROP CONSTRAINT trips_delegation_needs_cooperative,
    DROP CONSTRAINT trips_dispatch_needs_cooperative,
    DROP COLUMN handover_count,
    DROP COLUMN allow_delegation,
    DROP COLUMN cooperative_id,
    DROP COLUMN requested_driver_id,
    DROP COLUMN dispatch;
DROP TYPE trip_dispatch;
DROP TABLE cooperative_memberships;
DROP TYPE membership_status;
DROP TYPE cooperative_role;
DROP TABLE cooperatives;
DROP TYPE cooperative_status;

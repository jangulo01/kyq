-- +goose Up
-- 004: pago del viaje con Bold o en efectivo y libro de liquidación del conductor.

-- Medios que acepta el conductor (FR-018): al menos uno.
ALTER TABLE drivers
    ADD COLUMN accepts_cash boolean NOT NULL DEFAULT true,
    ADD COLUMN accepts_bold boolean NOT NULL DEFAULT true,
    ADD CONSTRAINT drivers_accepts_some_method CHECK (accepts_cash OR accepts_bold);

CREATE TYPE trip_payment_status AS ENUM (
    'pending', 'bold_in_progress', 'cash_reported', 'paid', 'unpaid', 'disputed', 'needs_review', 'voided'
);
CREATE TYPE trip_payment_method AS ENUM ('bold', 'cash');

CREATE TABLE trip_payments (
    id                        uuid PRIMARY KEY, -- también es la referencia en Bold
    trip_id                   uuid NOT NULL UNIQUE REFERENCES trips (id) ON DELETE CASCADE,
    driver_id                 uuid NOT NULL REFERENCES drivers (user_id) ON DELETE CASCADE,
    passenger_id              uuid NOT NULL REFERENCES users (id),
    amount_minor              bigint NOT NULL CHECK (amount_minor > 0),
    currency                  char(3) NOT NULL,
    -- RN-KYQ-001: el conductor recibe el 100 % y Kyq no cobra comisión, siempre.
    driver_amount_minor       bigint NOT NULL,
    platform_commission_minor bigint NOT NULL DEFAULT 0 CHECK (platform_commission_minor = 0),
    -- Medios del conductor al completarse el viaje.
    accepts_cash              boolean NOT NULL,
    accepts_bold              boolean NOT NULL,
    status                    trip_payment_status NOT NULL DEFAULT 'pending',
    method                    trip_payment_method,
    bold_link_id              text UNIQUE,
    checkout_url              text,
    link_created_at           timestamptz,
    bold_payment_id           text,
    payment_method_detail     text,
    cash_reported_at          timestamptz,
    cash_confirmed_at         timestamptz,
    disputed_at               timestamptz,
    unpaid_marked_at          timestamptz,
    paid_at                   timestamptz,
    reminded_at               timestamptz,
    review_note               text,
    resolved_by               uuid REFERENCES users (id),
    resolution_note           text,
    resolved_at               timestamptz,
    voided_by                 uuid REFERENCES users (id),
    void_reason               text,
    voided_at                 timestamptz,
    created_at                timestamptz NOT NULL,
    updated_at                timestamptz NOT NULL DEFAULT now(),
    CHECK (driver_amount_minor = amount_minor),
    CHECK (status <> 'paid' OR (method IS NOT NULL AND paid_at IS NOT NULL)),
    CHECK (status <> 'bold_in_progress' OR (bold_link_id IS NOT NULL AND link_created_at IS NOT NULL)),
    CHECK (status <> 'voided' OR coalesce(btrim(void_reason), '') <> '')
);

-- Pendientes del pasajero (FR-016), sondeo de enlaces (research R1), recordatorios (FR-015),
-- historial del conductor y panel por estado (FR-017).
CREATE INDEX trip_payments_passenger_open_idx ON trip_payments (passenger_id, created_at DESC)
    WHERE status IN ('pending', 'unpaid', 'bold_in_progress');
CREATE INDEX trip_payments_bold_in_flight_idx ON trip_payments (link_created_at) WHERE status = 'bold_in_progress';
CREATE INDEX trip_payments_remind_idx ON trip_payments (created_at) WHERE status = 'pending' AND reminded_at IS NULL;
CREATE INDEX trip_payments_driver_idx ON trip_payments (driver_id, created_at DESC);
CREATE INDEX trip_payments_status_idx ON trip_payments (status, created_at DESC);

CREATE TABLE driver_payouts (
    id           uuid PRIMARY KEY,
    driver_id    uuid NOT NULL REFERENCES drivers (user_id) ON DELETE CASCADE,
    amount_minor bigint NOT NULL CHECK (amount_minor > 0),
    currency     char(3) NOT NULL,
    reference    text NOT NULL CHECK (char_length(btrim(reference)) BETWEEN 1 AND 80),
    note         text CHECK (note IS NULL OR char_length(note) <= 200),
    created_by   uuid NOT NULL REFERENCES users (id),
    created_at   timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX driver_payouts_driver_idx ON driver_payouts (driver_id, created_at DESC);

CREATE TYPE ledger_entry_kind AS ENUM ('trip_credit', 'void_debit', 'payout');

-- Libro de solo inserción: saldo = suma por conductor y moneda (research R4).
CREATE TABLE driver_ledger_entries (
    id              uuid PRIMARY KEY,
    driver_id       uuid NOT NULL REFERENCES drivers (user_id) ON DELETE CASCADE,
    kind            ledger_entry_kind NOT NULL,
    amount_minor    bigint NOT NULL,
    currency        char(3) NOT NULL,
    trip_payment_id uuid REFERENCES trip_payments (id) ON DELETE CASCADE,
    payout_id       uuid REFERENCES driver_payouts (id) ON DELETE CASCADE,
    created_by      uuid REFERENCES users (id),
    created_at      timestamptz NOT NULL DEFAULT now(),
    CHECK (
        (kind = 'trip_credit' AND amount_minor > 0 AND trip_payment_id IS NOT NULL AND payout_id IS NULL)
        OR (kind = 'void_debit' AND amount_minor < 0 AND trip_payment_id IS NOT NULL AND payout_id IS NULL)
        OR (kind = 'payout' AND amount_minor < 0 AND payout_id IS NOT NULL AND trip_payment_id IS NULL)
    )
);

-- Idempotencia: un abono y un débito por pago (SC-003).
CREATE UNIQUE INDEX driver_ledger_one_per_payment ON driver_ledger_entries (trip_payment_id, kind)
    WHERE trip_payment_id IS NOT NULL;
CREATE INDEX driver_ledger_driver_idx ON driver_ledger_entries (driver_id, created_at DESC);

-- +goose Down
DROP TABLE driver_ledger_entries;
DROP TYPE ledger_entry_kind;
DROP TABLE driver_payouts;
DROP TABLE trip_payments;
DROP TYPE trip_payment_method;
DROP TYPE trip_payment_status;
ALTER TABLE drivers
    DROP CONSTRAINT drivers_accepts_some_method,
    DROP COLUMN accepts_bold,
    DROP COLUMN accepts_cash;

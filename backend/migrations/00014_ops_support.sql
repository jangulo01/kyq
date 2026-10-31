-- +goose Up
-- 009: inspección de viajes, centro de soporte, megáfono por zonas y dominios espejo.

-- Auditoría de cada apertura del detalle de un viaje desde el panel (FR-004).
CREATE TABLE trip_inspections (
    id        bigserial PRIMARY KEY,
    admin_id  uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    trip_id   uuid NOT NULL REFERENCES trips (id) ON DELETE CASCADE,
    opened_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX trip_inspections_trip_idx ON trip_inspections (trip_id, opened_at DESC);

CREATE TYPE support_topic AS ENUM ('trip', 'payment', 'lost_item', 'safety', 'account', 'other');
CREATE TYPE support_status AS ENUM ('open', 'in_progress', 'waiting_user', 'resolved', 'closed');

CREATE TABLE support_cases (
    id                   uuid PRIMARY KEY,
    user_id              uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    user_role            user_role NOT NULL,
    -- Otra parte de un caso de pago (004): también lo ve y puede escribir.
    counterpart_id       uuid REFERENCES users (id) ON DELETE SET NULL,
    topic                support_topic NOT NULL,
    subject              text NOT NULL CHECK (char_length(subject) BETWEEN 1 AND 120),
    trip_id              uuid REFERENCES trips (id) ON DELETE SET NULL,
    trip_payment_id      uuid UNIQUE REFERENCES trip_payments (id) ON DELETE SET NULL,
    status               support_status NOT NULL DEFAULT 'open',
    assigned_to          uuid REFERENCES users (id) ON DELETE SET NULL,
    created_at           timestamptz NOT NULL,
    last_message_at      timestamptz NOT NULL,
    last_user_message_at timestamptz,
    -- El último mensaje visible es del usuario: el caso espera respuesta (FR-008).
    last_author_is_user  boolean NOT NULL DEFAULT true,
    resolved_at          timestamptz,
    closed_at            timestamptz
);

CREATE INDEX support_cases_user_idx ON support_cases (user_id, last_message_at DESC);
CREATE INDEX support_cases_counterpart_idx ON support_cases (counterpart_id, last_message_at DESC)
    WHERE counterpart_id IS NOT NULL;
CREATE INDEX support_cases_inbox_idx ON support_cases (status, last_user_message_at);

CREATE TABLE support_messages (
    id          uuid PRIMARY KEY,
    case_id     uuid NOT NULL REFERENCES support_cases (id) ON DELETE CASCADE,
    -- NULL: mensaje del sistema (por ejemplo, la disputa de 004 o su resolución).
    author_id   uuid REFERENCES users (id) ON DELETE SET NULL,
    author_kind text NOT NULL CHECK (author_kind IN ('user', 'admin', 'system')),
    body        text NOT NULL CHECK (char_length(btrim(body)) BETWEEN 1 AND 2000),
    internal    boolean NOT NULL DEFAULT false,
    created_at  timestamptz NOT NULL,
    CHECK (NOT internal OR author_kind = 'admin')
);

CREATE INDEX support_messages_case_idx ON support_messages (case_id, created_at);

-- Comunicados de voz a zonas H3; la voz no se guarda (FR-016).
CREATE TABLE megaphone_broadcasts (
    id              uuid PRIMARY KEY,
    admin_id        uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    room_name       text NOT NULL UNIQUE,
    cells           text[] NOT NULL CHECK (cardinality(cells) BETWEEN 1 AND 50),
    resolution      smallint NOT NULL CHECK (resolution BETWEEN 6 AND 9),
    started_at      timestamptz NOT NULL,
    ends_at         timestamptz NOT NULL,
    ended_at        timestamptz,
    recipient_count integer NOT NULL DEFAULT 0
);

CREATE INDEX megaphone_broadcasts_open_idx ON megaphone_broadcasts (ends_at) WHERE ended_at IS NULL;
CREATE INDEX megaphone_broadcasts_started_idx ON megaphone_broadcasts (started_at DESC);

CREATE TABLE megaphone_recipients (
    broadcast_id uuid NOT NULL REFERENCES megaphone_broadcasts (id) ON DELETE CASCADE,
    driver_id    uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    PRIMARY KEY (broadcast_id, driver_id)
);

-- Dominios espejo de la API y del tiempo real (FR-019).
CREATE TABLE mirror_domains (
    id           uuid PRIMARY KEY,
    api_url      text NOT NULL UNIQUE CHECK (api_url ~ '^https?://[^/\s]+$'),
    realtime_url text NOT NULL CHECK (realtime_url ~ '^wss?://\S+$'),
    position     integer NOT NULL,
    active       boolean NOT NULL DEFAULT true,
    created_at   timestamptz NOT NULL,
    updated_at   timestamptz NOT NULL
);

-- Versión de la lista firmada: sube en cada cambio de mirror_domains.
CREATE TABLE mirror_domains_version (
    id         boolean PRIMARY KEY DEFAULT true CHECK (id),
    version    bigint NOT NULL,
    updated_at timestamptz NOT NULL
);

INSERT INTO mirror_domains_version (id, version, updated_at) VALUES (true, 0, now());

-- +goose Down
DROP TABLE mirror_domains_version;
DROP TABLE mirror_domains;
DROP TABLE megaphone_recipients;
DROP TABLE megaphone_broadcasts;
DROP TABLE support_messages;
DROP TABLE support_cases;
DROP TYPE support_status;
DROP TYPE support_topic;
DROP TABLE trip_inspections;

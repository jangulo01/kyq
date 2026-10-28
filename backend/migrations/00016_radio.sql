-- +goose Up
-- 011 Radio Kyq: walkie-talkie permanente con registro a demanda (RN-KYQ-017, data-model.md).

CREATE TYPE radio_conversation_kind AS ENUM ('direct', 'client', 'channel', 'cooperative');
CREATE TYPE radio_conversation_status AS ENUM ('active', 'suspended', 'deleted');
CREATE TYPE radio_join_mode AS ENUM ('open_link', 'approval');
CREATE TYPE radio_role AS ENUM ('owner', 'moderator', 'member', 'listener');
CREATE TYPE radio_member_status AS ENUM ('pending', 'active', 'muted', 'removed', 'blocked', 'rejected');
CREATE TYPE radio_message_kind AS ENUM ('voice', 'text', 'photo', 'location', 'alert', 'emergency');
CREATE TYPE radio_message_status AS ENUM ('recording', 'ready', 'discarded', 'deleted');
CREATE TYPE radio_presence_status AS ENUM ('available', 'busy', 'listen_only');
CREATE TYPE radio_trial_policy AS ENUM ('trial', 'subscription_only', 'listen_only');
CREATE TYPE radio_passenger_policy AS ENUM ('none', 'listen_only', 'all_roles');
CREATE TYPE radio_invite_status AS ENUM ('pending', 'sent', 'failed', 'accepted', 'already_member', 'expired');

CREATE TABLE radio_conversations (
    id                 uuid PRIMARY KEY,
    kind               radio_conversation_kind NOT NULL,
    name               text CHECK (name IS NULL OR char_length(btrim(name)) BETWEEN 3 AND 40),
    description        text CHECK (description IS NULL OR char_length(description) <= 200),
    photo_key          text,
    join_mode          radio_join_mode,
    passenger_role_max radio_role,
    cooperative_id     uuid UNIQUE REFERENCES cooperatives (id) ON DELETE CASCADE,
    -- Contactos 1 a 1 y clientes: el par ordenado (pair_a < pair_b) no se repite entre activos.
    pair_a             uuid REFERENCES users (id) ON DELETE CASCADE,
    pair_b             uuid REFERENCES users (id) ON DELETE CASCADE,
    room_name          text NOT NULL UNIQUE,
    status             radio_conversation_status NOT NULL DEFAULT 'active',
    created_by         uuid REFERENCES users (id) ON DELETE SET NULL,
    created_at         timestamptz NOT NULL,
    suspended_at       timestamptz,
    deleted_at         timestamptz,
    CHECK ((kind IN ('direct', 'client')) = (pair_a IS NOT NULL AND pair_b IS NOT NULL)),
    CHECK (pair_a IS NULL OR pair_a < pair_b),
    CHECK ((kind = 'channel') = (name IS NOT NULL AND join_mode IS NOT NULL)),
    CHECK ((kind = 'cooperative') = (cooperative_id IS NOT NULL)),
    CHECK ((status = 'deleted') = (deleted_at IS NOT NULL))
);

CREATE UNIQUE INDEX radio_channel_name_unique ON radio_conversations (lower(btrim(name)))
    WHERE kind = 'channel' AND status = 'active';
CREATE UNIQUE INDEX radio_pair_unique ON radio_conversations (kind, pair_a, pair_b)
    WHERE pair_a IS NOT NULL AND status <> 'deleted';

CREATE TABLE radio_members (
    conversation_id      uuid NOT NULL REFERENCES radio_conversations (id) ON DELETE CASCADE,
    user_id              uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    role                 radio_role NOT NULL DEFAULT 'member',
    status               radio_member_status NOT NULL,
    listening            boolean NOT NULL DEFAULT true,
    -- Conversación de cliente: el conductor silencia o bloquea al pasajero (FR-003).
    muted_by_peer        boolean NOT NULL DEFAULT false,
    blocked_by_peer      boolean NOT NULL DEFAULT false,
    joined_at            timestamptz NOT NULL,
    updated_at           timestamptz NOT NULL,
    last_read_message_id uuid,
    PRIMARY KEY (conversation_id, user_id)
);

CREATE INDEX radio_members_user_idx ON radio_members (user_id) WHERE status IN ('active', 'muted', 'pending');

-- Un turno por conversación (FR-006), con el mismo criterio fail-closed de 001.
CREATE TABLE radio_floors (
    conversation_id uuid PRIMARY KEY REFERENCES radio_conversations (id) ON DELETE CASCADE,
    holder_id       uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    message_id      uuid NOT NULL,
    granted_at      timestamptz NOT NULL,
    expires_at      timestamptz NOT NULL,
    -- Último audio visto en la sala; sin audio 3 s el barrido libera el turno.
    last_audio_at   timestamptz
);

CREATE TABLE radio_messages (
    id              uuid PRIMARY KEY,
    conversation_id uuid NOT NULL REFERENCES radio_conversations (id) ON DELETE CASCADE,
    author_id       uuid REFERENCES users (id) ON DELETE SET NULL,
    kind            radio_message_kind NOT NULL,
    status          radio_message_status NOT NULL,
    body            text,
    lat             double precision,
    lng             double precision,
    object_key      text,
    duration_ms     integer CHECK (duration_ms IS NULL OR duration_ms >= 0),
    size_bytes      bigint CHECK (size_bytes IS NULL OR size_bytes >= 0),
    egress_id       text UNIQUE,
    sos_alert_id    uuid,
    expires_at      timestamptz NOT NULL,
    reported        boolean NOT NULL DEFAULT false,
    created_at      timestamptz NOT NULL,
    CHECK (status <> 'recording' OR kind IN ('voice', 'photo')),
    CHECK (kind <> 'text' OR char_length(body) BETWEEN 1 AND 500),
    CHECK (kind <> 'alert' OR body IS NULL OR char_length(body) <= 80),
    CHECK (kind NOT IN ('location', 'emergency') OR (lat IS NOT NULL AND lng IS NOT NULL))
);

CREATE INDEX radio_messages_conversation_idx ON radio_messages (conversation_id, created_at DESC, id DESC);
CREATE INDEX radio_messages_author_idx ON radio_messages (conversation_id, author_id, kind, created_at);
CREATE INDEX radio_messages_expiry_idx ON radio_messages (expires_at) WHERE status IN ('ready', 'recording');

CREATE TABLE radio_receipts (
    message_id uuid NOT NULL REFERENCES radio_messages (id) ON DELETE CASCADE,
    user_id    uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    heard_at   timestamptz,
    saved_at   timestamptz,
    -- Copia del objeto en kyq-radio-saved; vence al año (FR-012).
    saved_key  text,
    PRIMARY KEY (message_id, user_id)
);

CREATE INDEX radio_receipts_saved_idx ON radio_receipts (user_id) WHERE saved_at IS NOT NULL;

CREATE TABLE radio_presence (
    user_id         uuid PRIMARY KEY REFERENCES users (id) ON DELETE CASCADE,
    status          radio_presence_status NOT NULL DEFAULT 'available',
    -- Estado al que vuelve al terminar un horario de silencio (FR-021).
    status_before_quiet radio_presence_status,
    radio_on        boolean NOT NULL DEFAULT false,
    last_seen_at    timestamptz,
    push_mode       text NOT NULL DEFAULT 'hold' CHECK (push_mode IN ('hold', 'toggle')),
    timezone        text NOT NULL DEFAULT 'America/Bogota',
    -- Conductor: "Radio con mis clientes" (FR-003), apagado por defecto.
    clients_enabled boolean NOT NULL DEFAULT false,
    updated_at      timestamptz NOT NULL
);

CREATE TABLE radio_quiet_hours (
    id       uuid PRIMARY KEY,
    user_id  uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    weekdays smallint[] NOT NULL CHECK (cardinality(weekdays) BETWEEN 1 AND 7 AND weekdays <@ ARRAY[1,2,3,4,5,6,7]::smallint[]),
    starts   time NOT NULL,
    ends     time NOT NULL,
    enabled  boolean NOT NULL DEFAULT true
);

CREATE INDEX radio_quiet_hours_user_idx ON radio_quiet_hours (user_id);

CREATE TABLE radio_bulk_uploads (
    id           uuid PRIMARY KEY,
    admin_id     uuid NOT NULL REFERENCES users (id),
    file_name    text NOT NULL,
    rows_total   integer NOT NULL,
    rows_valid   integer NOT NULL,
    rows_invalid integer NOT NULL,
    status       text NOT NULL CHECK (status IN ('validated', 'sending', 'done')),
    created_at   timestamptz NOT NULL,
    confirmed_at timestamptz
);

CREATE TABLE radio_invites (
    id              uuid PRIMARY KEY,
    code            text NOT NULL UNIQUE CHECK (code ~ '^[0-9A-Za-z]{10}$'),
    inviter_id      uuid REFERENCES users (id) ON DELETE SET NULL,
    conversation_id uuid REFERENCES radio_conversations (id) ON DELETE CASCADE,
    contact_of      uuid REFERENCES users (id) ON DELETE CASCADE,
    phone_e164      text CHECK (phone_e164 IS NULL OR phone_e164 ~ '^\+[1-9][0-9]{6,14}$'),
    invitee_kind    user_role NOT NULL,
    role            radio_role,
    bulk_id         uuid REFERENCES radio_bulk_uploads (id) ON DELETE CASCADE,
    -- Fila de la carga masiva (para mostrarla sin el teléfono completo).
    line            integer,
    invitee_name    text,
    channel_name    text,
    status          radio_invite_status NOT NULL DEFAULT 'pending',
    error           text,
    accepted_by     uuid REFERENCES users (id) ON DELETE SET NULL,
    created_at      timestamptz NOT NULL,
    sent_at         timestamptz,
    expires_at      timestamptz NOT NULL,
    CHECK (conversation_id IS NOT NULL OR contact_of IS NOT NULL OR bulk_id IS NOT NULL)
);

CREATE INDEX radio_invites_phone_idx ON radio_invites (phone_e164) WHERE phone_e164 IS NOT NULL AND status IN ('pending', 'sent');
CREATE INDEX radio_invites_bulk_idx ON radio_invites (bulk_id, line) WHERE bulk_id IS NOT NULL;

-- Teléfonos que pidieron no recibir más invitaciones por SMS (FR-035).
CREATE TABLE radio_sms_optouts (
    phone_e164 text PRIMARY KEY CHECK (phone_e164 ~ '^\+[1-9][0-9]{6,14}$'),
    at         timestamptz NOT NULL
);

CREATE TABLE radio_settings (
    id                     smallint PRIMARY KEY CHECK (id = 1),
    trial_policy           radio_trial_policy NOT NULL DEFAULT 'trial',
    trial_days             integer NOT NULL DEFAULT 14 CHECK (trial_days BETWEEN 1 AND 90),
    passengers_in_channels radio_passenger_policy NOT NULL DEFAULT 'none',
    retention_days         integer NOT NULL DEFAULT 30 CHECK (retention_days IN (7, 30, 90)),
    updated_by             uuid REFERENCES users (id) ON DELETE SET NULL,
    updated_at             timestamptz NOT NULL DEFAULT now()
);

INSERT INTO radio_settings (id) VALUES (1);

CREATE TABLE radio_settings_audit (
    id       uuid PRIMARY KEY,
    admin_id uuid NOT NULL REFERENCES users (id),
    before   jsonb NOT NULL,
    after    jsonb NOT NULL,
    at       timestamptz NOT NULL
);

CREATE TABLE radio_consents (
    user_id                 uuid PRIMARY KEY REFERENCES users (id) ON DELETE CASCADE,
    retention_days_accepted integer NOT NULL,
    accepted_at             timestamptz NOT NULL
);

CREATE TABLE radio_reports (
    id          uuid PRIMARY KEY,
    message_id  uuid NOT NULL REFERENCES radio_messages (id) ON DELETE CASCADE,
    reporter_id uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    reason      text NOT NULL DEFAULT '' CHECK (char_length(reason) <= 200),
    status      text NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'resolved')),
    decision    text CHECK (decision IS NULL OR decision IN ('dismissed', 'message_deleted', 'channel_suspended', 'user_suspended')),
    note        text CHECK (note IS NULL OR char_length(note) <= 200),
    resolved_by uuid REFERENCES users (id),
    resolved_at timestamptz,
    created_at  timestamptz NOT NULL,
    UNIQUE (message_id, reporter_id),
    CHECK ((status = 'resolved') = (decision IS NOT NULL AND resolved_at IS NOT NULL))
);

CREATE TABLE radio_report_access (
    report_id uuid NOT NULL REFERENCES radio_reports (id) ON DELETE CASCADE,
    admin_id  uuid NOT NULL REFERENCES users (id),
    at        timestamptz NOT NULL
);

-- Emergencia desde Radio sin viaje (R7): el viaje pasa a ser opcional solo para Radio.
CREATE TYPE sos_raised_from AS ENUM ('trip', 'radio');
ALTER TABLE sos_alerts
    ALTER COLUMN trip_id DROP NOT NULL,
    ADD COLUMN raised_from sos_raised_from NOT NULL DEFAULT 'trip',
    ADD COLUMN radio_conversation_id uuid REFERENCES radio_conversations (id) ON DELETE SET NULL,
    ADD CONSTRAINT sos_alerts_trip_or_radio CHECK (trip_id IS NOT NULL OR raised_from = 'radio');
-- Una alerta abierta sin viaje por persona, como la del viaje.
CREATE UNIQUE INDEX sos_alerts_open_radio ON sos_alerts (raised_by)
    WHERE trip_id IS NULL AND status IN ('open', 'claimed');

ALTER TABLE radio_messages
    ADD CONSTRAINT radio_messages_sos_fk FOREIGN KEY (sos_alert_id) REFERENCES sos_alerts (id) ON DELETE SET NULL;

-- Coste medido (FR-038, R11).
ALTER TYPE cost_concept ADD VALUE IF NOT EXISTS 'radio_storage';
ALTER TYPE cost_concept ADD VALUE IF NOT EXISTS 'sms_invite';
ALTER TABLE driver_usage_daily
    ADD COLUMN radio_voice_seconds bigint NOT NULL DEFAULT 0,
    ADD COLUMN radio_messages      bigint NOT NULL DEFAULT 0,
    ADD COLUMN radio_storage_bytes bigint NOT NULL DEFAULT 0;

-- +goose Down
ALTER TABLE driver_usage_daily
    DROP COLUMN radio_storage_bytes,
    DROP COLUMN radio_messages,
    DROP COLUMN radio_voice_seconds;
-- Los valores nuevos de cost_concept no se pueden quitar de un enum; quedan sin uso.
ALTER TABLE radio_messages DROP CONSTRAINT radio_messages_sos_fk;
DELETE FROM sos_alerts WHERE trip_id IS NULL;
DROP INDEX sos_alerts_open_radio;
ALTER TABLE sos_alerts
    DROP CONSTRAINT sos_alerts_trip_or_radio,
    DROP COLUMN radio_conversation_id,
    DROP COLUMN raised_from,
    ALTER COLUMN trip_id SET NOT NULL;
DROP TYPE sos_raised_from;
DROP TABLE radio_report_access;
DROP TABLE radio_reports;
DROP TABLE radio_consents;
DROP TABLE radio_settings_audit;
DROP TABLE radio_settings;
DROP TABLE radio_sms_optouts;
DROP TABLE radio_invites;
DROP TABLE radio_bulk_uploads;
DROP TABLE radio_quiet_hours;
DROP TABLE radio_presence;
DROP TABLE radio_receipts;
DROP TABLE radio_messages;
DROP TABLE radio_floors;
DROP TABLE radio_members;
DROP TABLE radio_conversations;
DROP TYPE radio_invite_status;
DROP TYPE radio_passenger_policy;
DROP TYPE radio_trial_policy;
DROP TYPE radio_presence_status;
DROP TYPE radio_message_status;
DROP TYPE radio_message_kind;
DROP TYPE radio_member_status;
DROP TYPE radio_role;
DROP TYPE radio_join_mode;
DROP TYPE radio_conversation_status;
DROP TYPE radio_conversation_kind;

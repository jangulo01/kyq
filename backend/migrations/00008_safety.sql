-- +goose Up
-- 003: botón SOS, consola de emergencias, viaje compartido, contactos de emergencia y PIN
-- (RN-KYQ-015).

-- Operadores de emergencias: administradores con permiso de consola; on_duty recibe la escalada
-- por SMS de alertas sin tomar (FR-011, FR-012). Tabla aparte en lugar de columnas de users para
-- no cambiar las consultas de usuarios de 001.
CREATE TABLE emergency_operators (
    user_id    uuid PRIMARY KEY REFERENCES users (id) ON DELETE CASCADE,
    on_duty    boolean NOT NULL DEFAULT false,
    granted_at timestamptz NOT NULL DEFAULT now()
);

CREATE TYPE sos_role AS ENUM ('passenger', 'driver');
CREATE TYPE sos_status AS ENUM ('open', 'claimed', 'closed', 'cancelled_by_user');
CREATE TYPE sos_outcome AS ENUM ('false_alarm', 'resolved', 'escalated_authorities', 'no_response');

CREATE TABLE sos_alerts (
    id                 uuid PRIMARY KEY,
    trip_id            uuid NOT NULL REFERENCES trips (id),
    raised_by          uuid NOT NULL REFERENCES users (id),
    raised_role        sos_role NOT NULL,
    status             sos_status NOT NULL DEFAULT 'open',
    -- Intento de cancelar sin el PIN correcto: posible coacción (FR-005).
    cancel_without_pin boolean NOT NULL DEFAULT false,
    claimed_by         uuid REFERENCES users (id),
    -- Operador al que LiveKit pudo haber concedido publicar: se borra solo cuando LiveKit confirma
    -- la retirada (mismo criterio fail-closed que el turno PTT de 001).
    voice_holder_id    uuid REFERENCES users (id),
    outcome            sos_outcome,
    room_name          text NOT NULL UNIQUE,
    egress_id          text,
    recording_key      text,
    escalated_at       timestamptz,
    created_at         timestamptz NOT NULL,
    claimed_at         timestamptz,
    closed_at          timestamptz,
    -- Sala de voz borrada y grabación detenida tras cerrar; el barrido reintenta mientras sea NULL.
    voice_closed_at    timestamptz,
    -- Al cerrar se conserva quién la atendió.
    CHECK (status <> 'claimed' OR claimed_by IS NOT NULL),
    CHECK (status <> 'open' OR claimed_by IS NULL),
    CHECK ((status IN ('closed', 'cancelled_by_user')) = (closed_at IS NOT NULL)),
    CHECK ((status = 'closed') = (outcome IS NOT NULL))
);

-- Una alerta abierta por persona y viaje; pasajero y conductor pueden tener una cada uno.
CREATE UNIQUE INDEX sos_alerts_one_open ON sos_alerts (trip_id, raised_by)
    WHERE status IN ('open', 'claimed');
CREATE INDEX sos_alerts_open ON sos_alerts (created_at) WHERE status IN ('open', 'claimed');
CREATE INDEX sos_alerts_history ON sos_alerts (created_at DESC);
CREATE INDEX sos_alerts_voice_pending ON sos_alerts (closed_at)
    WHERE closed_at IS NOT NULL AND voice_closed_at IS NULL;

-- Ubicación a 1 Hz durante la alerta (FR-003).
CREATE TABLE sos_locations (
    alert_id   uuid NOT NULL REFERENCES sos_alerts (id) ON DELETE CASCADE,
    at         timestamptz NOT NULL,
    lat        double precision NOT NULL CHECK (lat BETWEEN -90 AND 90),
    lng        double precision NOT NULL CHECK (lng BETWEEN -180 AND 180),
    accuracy_m real CHECK (accuracy_m IS NULL OR accuracy_m >= 0),
    PRIMARY KEY (alert_id, at)
);

CREATE TABLE sos_notes (
    id          uuid PRIMARY KEY,
    alert_id    uuid NOT NULL REFERENCES sos_alerts (id) ON DELETE CASCADE,
    operator_id uuid NOT NULL REFERENCES users (id),
    body        text NOT NULL CHECK (char_length(btrim(body)) BETWEEN 1 AND 2000),
    created_at  timestamptz NOT NULL
);

CREATE INDEX sos_notes_alert ON sos_notes (alert_id, created_at);

-- Auditoría de la consola: cada acceso y acción de un operador (FR-012).
CREATE TABLE sos_audit (
    id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    operator_id uuid NOT NULL REFERENCES users (id),
    alert_id    uuid REFERENCES sos_alerts (id) ON DELETE CASCADE,
    action      text NOT NULL,
    created_at  timestamptz NOT NULL
);

CREATE INDEX sos_audit_alert ON sos_audit (alert_id, created_at);

-- Enlace del viaje en vivo (FR-013..FR-015): 128 bits aleatorios en base64url. Uno por persona
-- y viaje; vigente hasta 15 min después de terminar el viaje.
CREATE TABLE share_links (
    token      text PRIMARY KEY CHECK (char_length(token) >= 22),
    trip_id    uuid NOT NULL REFERENCES trips (id),
    created_by uuid NOT NULL REFERENCES users (id),
    created_at timestamptz NOT NULL,
    UNIQUE (trip_id, created_by)
);

-- Contactos de emergencia: máximo 3 por usuario (lo comprueba el servicio).
CREATE TABLE emergency_contacts (
    user_id    uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    position   smallint NOT NULL CHECK (position BETWEEN 1 AND 3),
    name       text NOT NULL CHECK (char_length(name) BETWEEN 2 AND 60),
    phone_e164 text NOT NULL CHECK (phone_e164 ~ '^\+[1-9][0-9]{6,14}$'),
    created_at timestamptz NOT NULL,
    PRIMARY KEY (user_id, position)
);

-- PIN de seguridad de 4 dígitos con bcrypt; 5 intentos fallidos bloquean la cancelación hasta
-- que el operador cierre la alerta.
CREATE TABLE safety_pins (
    user_id         uuid PRIMARY KEY REFERENCES users (id) ON DELETE CASCADE,
    pin_hash        text NOT NULL,
    failed_attempts smallint NOT NULL DEFAULT 0 CHECK (failed_attempts >= 0),
    updated_at      timestamptz NOT NULL
);

-- +goose Down
DROP TABLE safety_pins;
DROP TABLE emergency_contacts;
DROP TABLE share_links;
DROP TABLE sos_audit;
DROP TABLE sos_notes;
DROP TABLE sos_locations;
DROP TABLE sos_alerts;
DROP TYPE sos_outcome;
DROP TYPE sos_status;
DROP TYPE sos_role;
DROP TABLE emergency_operators;

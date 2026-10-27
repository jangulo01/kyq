-- +goose Up
CREATE TYPE user_role AS ENUM ('passenger', 'driver', 'admin');

CREATE TABLE users (
    id           uuid PRIMARY KEY,
    phone_e164   text NOT NULL UNIQUE CHECK (phone_e164 ~ '^\+[1-9][0-9]{6,14}$'),
    role         user_role NOT NULL,
    display_name text NOT NULL CHECK (char_length(display_name) BETWEEN 2 AND 60),
    created_at   timestamptz NOT NULL DEFAULT now()
);

CREATE TYPE driver_presence AS ENUM ('offline', 'free', 'busy');

CREATE TABLE drivers (
    user_id             uuid PRIMARY KEY REFERENCES users (id) ON DELETE CASCADE,
    qr_token            text NOT NULL UNIQUE,
    vehicle_plate       text NOT NULL,
    vehicle_description text NOT NULL,
    presence            driver_presence NOT NULL DEFAULT 'offline',
    last_location       geography(Point, 4326),
    last_location_at    timestamptz,
    busy_until_estimate timestamptz,
    CHECK (busy_until_estimate IS NULL OR presence = 'busy')
);

CREATE TABLE subscriptions (
    driver_id  uuid PRIMARY KEY REFERENCES drivers (user_id) ON DELETE CASCADE,
    paid_until timestamptz NOT NULL,
    updated_by uuid NOT NULL REFERENCES users (id),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TYPE driver_doc_type AS ENUM ('license', 'mandatory_insurance', 'vehicle_registration');

CREATE TABLE driver_documents (
    id          uuid PRIMARY KEY,
    driver_id   uuid NOT NULL REFERENCES drivers (user_id) ON DELETE CASCADE,
    doc_type    driver_doc_type NOT NULL,
    expires_at  date NOT NULL,
    approved_by uuid REFERENCES users (id),
    approved_at timestamptz,
    UNIQUE (driver_id, doc_type)
);

CREATE TABLE refresh_tokens (
    id         uuid PRIMARY KEY,
    user_id    uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    token_hash bytea NOT NULL UNIQUE,
    expires_at timestamptz NOT NULL,
    rotated_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX refresh_tokens_user_id_idx ON refresh_tokens (user_id);

-- +goose Down
DROP TABLE refresh_tokens;
DROP TABLE driver_documents;
DROP TYPE driver_doc_type;
DROP TABLE subscriptions;
DROP TABLE drivers;
DROP TYPE driver_presence;
DROP TABLE users;
DROP TYPE user_role;

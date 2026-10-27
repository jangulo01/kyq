-- +goose Up
CREATE TYPE affiliation_source AS ENUM ('qr_scan');

CREATE TABLE affiliations (
    passenger_id uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    driver_id    uuid NOT NULL REFERENCES drivers (user_id) ON DELETE CASCADE,
    source       affiliation_source NOT NULL,
    created_at   timestamptz NOT NULL DEFAULT now(),
    removed_at   timestamptz,
    PRIMARY KEY (passenger_id, driver_id)
);

CREATE INDEX affiliations_active_driver_idx ON affiliations (driver_id) WHERE removed_at IS NULL;

-- +goose Down
DROP TABLE affiliations;
DROP TYPE affiliation_source;

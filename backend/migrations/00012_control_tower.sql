-- +goose Up
-- 007: moderación de usuarios (suspensión y auditoría) e índices de la torre y del CRM.

ALTER TABLE users
    ADD COLUMN suspended_at      timestamptz,
    ADD COLUMN suspension_reason text,
    ADD CONSTRAINT users_suspension_consistent CHECK ((suspended_at IS NULL) = (suspension_reason IS NULL)),
    ADD CONSTRAINT users_suspension_reason_len CHECK (
        suspension_reason IS NULL OR char_length(btrim(suspension_reason)) BETWEEN 3 AND 500);

CREATE INDEX users_suspended_idx ON users (suspended_at) WHERE suspended_at IS NOT NULL;

CREATE TYPE moderation_kind AS ENUM ('suspend', 'reactivate');

-- Auditoría de moderación: solo se inserta (FR-017).
CREATE TABLE moderation_actions (
    id         uuid PRIMARY KEY,
    user_id    uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    action     moderation_kind NOT NULL,
    reason     text NOT NULL CHECK (char_length(btrim(reason)) BETWEEN 3 AND 500),
    actor_id   uuid NOT NULL REFERENCES users (id),
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX moderation_actions_user_idx ON moderation_actions (user_id, created_at DESC);

-- Torre (solicitudes de la última hora), SC-008 y repetición de viajes (CRM).
CREATE INDEX trips_created_at_idx ON trips (created_at);
CREATE INDEX trips_completed_at_idx ON trips (completed_at) WHERE status = 'COMPLETED';
CREATE INDEX affiliations_created_at_idx ON affiliations (created_at);
CREATE INDEX affiliations_removed_at_idx ON affiliations (removed_at) WHERE removed_at IS NOT NULL;

-- +goose Down
DROP INDEX affiliations_removed_at_idx;
DROP INDEX affiliations_created_at_idx;
DROP INDEX trips_completed_at_idx;
DROP INDEX trips_created_at_idx;
DROP TABLE moderation_actions;
DROP TYPE moderation_kind;
DROP INDEX users_suspended_idx;
ALTER TABLE users
    DROP CONSTRAINT users_suspension_reason_len,
    DROP CONSTRAINT users_suspension_consistent,
    DROP COLUMN suspension_reason,
    DROP COLUMN suspended_at;

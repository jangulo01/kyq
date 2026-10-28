-- Los identificadores UUID v7 se generan en la aplicación (google/uuid NewV7).

-- +goose Up
CREATE EXTENSION IF NOT EXISTS postgis;

-- +goose Down
-- La extensión puede estar compartida con otros esquemas; no se elimina.
SELECT 1;

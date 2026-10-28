-- +goose Up
-- Coste por conductor (constitución VII). uuid nulo = sin conductor (cotizaciones antes de elegir).
CREATE TABLE driver_usage_daily (
    driver_id                 uuid NOT NULL,
    day                       date NOT NULL,
    voice_participant_seconds bigint NOT NULL DEFAULT 0,
    realtime_events           bigint NOT NULL DEFAULT 0,
    route_requests            bigint NOT NULL DEFAULT 0,
    PRIMARY KEY (driver_id, day)
);

-- +goose Down
DROP TABLE driver_usage_daily;

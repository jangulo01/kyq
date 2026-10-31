-- +goose Up
-- 008: bolsa zonal (opción 3 del selector de despacho), tarifa preferencial para la cartera
-- (RN-KYQ-013) y origen de las afiliaciones (QR, después del viaje, enlace).

-- PostgreSQL >= 12 admite ADD VALUE en la transacción si el valor no se usa en ella.
ALTER TYPE trip_dispatch ADD VALUE IF NOT EXISTS 'zone_pool';
ALTER TYPE affiliation_source ADD VALUE IF NOT EXISTS 'post_trip';
ALTER TYPE affiliation_source ADD VALUE IF NOT EXISTS 'link';

-- Preferencias de despacho del conductor: la bolsa es opcional (por defecto no la recibe) y el
-- descuento preferencial aplica solo a los pasajeros de su cartera.
ALTER TABLE drivers
    ADD COLUMN accepts_zone_pool         boolean NOT NULL DEFAULT false,
    ADD COLUMN preferential_discount_pct smallint NOT NULL DEFAULT 0
        CHECK (preferential_discount_pct BETWEEN 0 AND 30);

-- Tarifa de la tabla y descuento aplicado a la oferta vigente; suggested_fare_minor es lo ofrecido.
ALTER TABLE trips
    ADD COLUMN list_fare_minor           bigint,
    ADD COLUMN preferential_discount_pct smallint NOT NULL DEFAULT 0
        CHECK (preferential_discount_pct BETWEEN 0 AND 30);
UPDATE trips SET list_fare_minor = suggested_fare_minor;
ALTER TABLE trips ALTER COLUMN list_fare_minor SET NOT NULL;

-- La bolsa no tiene cooperativa: solo el despacho a la cooperativa la exige.
ALTER TABLE trips DROP CONSTRAINT trips_dispatch_needs_cooperative;
ALTER TABLE trips ADD CONSTRAINT trips_dispatch_needs_cooperative
    CHECK (dispatch <> 'cooperative' OR cooperative_id IS NOT NULL);

-- Candidatos de la bolsa: conductores libres que la aceptan.
CREATE INDEX drivers_zone_pool_free_idx ON drivers (user_id)
    WHERE accepts_zone_pool AND presence = 'free';

-- +goose Down
DROP INDEX drivers_zone_pool_free_idx;
ALTER TABLE trips DROP CONSTRAINT trips_dispatch_needs_cooperative;
ALTER TABLE trips ADD CONSTRAINT trips_dispatch_needs_cooperative
    CHECK (dispatch = 'chosen_driver' OR cooperative_id IS NOT NULL);
ALTER TABLE trips DROP COLUMN preferential_discount_pct, DROP COLUMN list_fare_minor;
ALTER TABLE drivers DROP COLUMN preferential_discount_pct, DROP COLUMN accepts_zone_pool;
-- Los valores de enum añadidos no se pueden quitar; quedan.

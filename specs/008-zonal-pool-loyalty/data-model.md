# Data Model: Bolsa zonal y fidelización ampliada

Migración `backend/migrations/00013_zonal_pool.sql`.

## drivers (cambios)

| Columna | Tipo | Regla |
|---|---|---|
| `accepts_zone_pool` | boolean NOT NULL DEFAULT false | FR-008: por defecto no recibe la bolsa |
| `preferential_discount_pct` | smallint NOT NULL DEFAULT 0 | CHECK 0–30 (FR-011) |

## trips (cambios)

| Columna | Tipo | Regla |
|---|---|---|
| `dispatch` | `trip_dispatch` + valor `zone_pool` | FR-001 |
| `list_fare_minor` | bigint NOT NULL | tarifa de la tabla; filas previas = `suggested_fare_minor` |
| `preferential_discount_pct` | smallint NOT NULL DEFAULT 0 | CHECK 0–30; descuento aplicado a la oferta vigente |

Restricción cambiada: `trips_dispatch_needs_cooperative` pasa a
`dispatch <> 'cooperative' OR cooperative_id IS NOT NULL` (la bolsa no tiene cooperativa).

`requested_driver_id` en la bolsa = primer conductor ofertado (research R2).

Transiciones: las de 006. Con `dispatch = zone_pool`, una oferta que termina por rechazo o
vencimiento (`offer_rejected`, `offer_expired`) espera traspaso aunque no haya cooperativa ni
consentimiento; máximo 3 traspasos (`handover_count`); sin candidato → `no_driver_available`.

## affiliations (cambios)

| Columna | Tipo | Regla |
|---|---|---|
| `source` | `affiliation_source` + valores `post_trip`, `link` | FR-016; reactivar actualiza el origen |

## Vistas y eventos (sin tabla)

- **Preferencias de despacho** (`GET/PUT /v1/driver/dispatch-settings`): `accepts_zone_pool`,
  `preferential_discount_pct`, `affiliate_link`.
- **Cotización** (`POST /v1/fares/quote`, `driver_id` opcional): `suggested_fare_minor` con el
  descuento si aplica, `list_fare_minor`, `preferential_discount_pct`.
- **trip.offer** (realtime): `origin`, `loyal_client`, `trips_together`, `pickup_distance_m`.
- **Informe CRM** (`GET /v1/admin/crm`): `affiliations.created_by_source` = `{qr_scan, post_trip, link}`.

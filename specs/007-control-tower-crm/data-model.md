# Data Model: Torre de control H3, CRM y economía unitaria

Extiende el modelo de 001 y 002 con la migración `00012_control_tower.sql`. La torre, Finanzas,
Fidelización y Salud son vistas calculadas al pedirlas: no añaden tablas.

## users (cambios)

| Campo | Tipo | Reglas |
|---|---|---|
| suspended_at | timestamptz NULL | No nulo = suspendido (FR-016) |
| suspension_reason | text NULL | Obligatorio (3–500) si `suspended_at` no es nulo; nulo si no |

`CHECK ((suspended_at IS NULL) = (suspension_reason IS NULL))`. Índice parcial
`users_suspended_idx (suspended_at) WHERE suspended_at IS NOT NULL` para el filtro del panel.

## moderation_actions (nueva)

| Campo | Tipo | Reglas |
|---|---|---|
| id | uuid PK | v7 desde la aplicación |
| user_id | uuid FK users ON DELETE CASCADE | Usuario moderado (pasajero o conductor) |
| action | enum `suspend` \| `reactivate` | |
| reason | text | 3–500 caracteres tras recortar espacios |
| actor_id | uuid FK users | Administrador que actuó |
| created_at | timestamptz | `now()` |

Índice `(user_id, created_at DESC)`. Solo se inserta; nunca se actualiza ni borra (auditoría,
FR-017).

## trips (índices nuevos)

| Índice | Uso |
|---|---|
| `trips_created_at_idx (created_at)` | Solicitudes de la última hora (torre) y SC-008 |
| `trips_completed_at_idx (completed_at) WHERE status = 'COMPLETED'` | Parejas que repiten (CRM) |

## affiliations (índices nuevos)

| Índice | Uso |
|---|---|
| `affiliations_created_at_idx (created_at)` | Afiliaciones nuevas y SC-008 por periodo |
| `affiliations_removed_at_idx (removed_at) WHERE removed_at IS NOT NULL` | Bajas por periodo |

## Vistas calculadas (sin tabla)

### TowerSnapshot

| Campo | Origen |
|---|---|
| generated_at, resolution (6–9), window_minutes (60), stale_after_seconds (120) | Petición |
| totals: online, free, busy, without_location, stale, active_trips, requests, unserved_requests | Agregado |
| cells[]: cell (H3 hex), center, boundary[], free_drivers, busy_drivers, active_trips, requests, unserved_requests, pressure (solicitudes / libres o null), level (`none` \| `balanced` \| `high` \| `no_supply`) | `drivers.last_lat/lng`, `trips` |
| drivers[]: driver_id, display_name, presence, lat, lng, location_at, stale, cell | `drivers` + `users` |

Orden de `cells`: `no_supply`, `high`, `balanced`, `none`; dentro, más solicitudes primero.

### FinanceMonth (por mes)

`month`, `currency`, `revenue_minor` (Σ pagos aprobados con `covers_from` en el mes),
`infra_cost_minor` (Σ `total_cost_minor` de 002 de los conductores creados antes del fin del
mes), `margin_minor`, `margin_pct` (null si ingresos 0), `drivers` (conductores existentes),
`active_drivers` (uso o pago en el mes), `paying_drivers`, `negative_margin_drivers`,
`cost_per_active_driver_minor`, `revenue_per_paying_driver_minor` (null si el divisor es 0),
`cost_by_concept[]` (concepto, costo) y `rates_missing` (sin tarifas vigentes en el mes).

### CrmReport

- `affiliations`: `active_now`, `active_at_start`, `created`, `removed`, `net`, `churn_rate`,
  `weekly[]` (`week_start`, `created`, `removed`, `active_end`).
- `repeat`: `pairs`, `repeat_pairs`, `repeat_rate`, `completed_trips`, `avg_trips_per_pair`.
- `sc008`: `matured`, `with_request_30d`, `rate`, `target` (0.8), `met`, `pending`.
- `churned_drivers[]` (máx. 10): `driver_id`, `display_name`, `removed`, `active_now`.
- `inactive_chosen_drivers[]` (máx. 20): `driver_id`, `display_name`, `active_affiliations`,
  `last_completed_at`.

### HealthReport

`status` (`ok` \| `degraded` \| `down`), `checked_at`, `checks[]`: `name` (`database`,
`centrifugo`, `livekit`, `osrm`, `storage`, `bold`), `status` (`ok` \| `down` \| `disabled`),
`latency_ms` (null si desactivada), `detail`.

## Transiciones de moderación

```text
activo --suspend(motivo)--> suspendido --reactivate(motivo)--> activo
```

- `suspend` sobre suspendido → 409 `already_suspended`; `reactivate` sobre activo → 409
  `not_suspended`; sobre un admin → 409 `cannot_moderate_admin`.
- Efectos de `suspend`: refresh tokens revocados; conductor `free`/`busy` sin viaje activo →
  `offline` (+ evento `driver.presence`).

# Data Model: Cooperativas y delegación inteligente

Extiende el modelo de 001 y 002. Migración `backend/migrations/00011_cooperatives.sql`.

## cooperatives

| Campo | Tipo | Reglas |
|---|---|---|
| id | uuid PK | |
| name | text | 3–80 caracteres; único sin distinguir mayúsculas (`lower(name)`) |
| city_code | text | Ciudad de operación (p. ej. `bogota`) |
| nit | text NULL | ≤ 20 caracteres |
| status | enum `active` \| `suspended` | Suspendida: sin delegaciones ni canal de grupo |
| created_by | uuid FK users | Administrador |
| created_at, updated_at | timestamptz | |

## cooperative_memberships

| Campo | Tipo | Reglas |
|---|---|---|
| id | uuid PK | |
| cooperative_id | uuid FK cooperatives | |
| driver_id | uuid FK drivers | |
| role | enum `member` \| `coordinator` | Solo el admin lo cambia |
| status | enum `pending` \| `active` \| `rejected` \| `cancelled` \| `left` \| `removed` | |
| reject_reason | text NULL | Obligatorio si `rejected` |
| requested_at | timestamptz | |
| decided_by, decided_at | uuid FK users NULL, timestamptz NULL | Aprobación o rechazo (admin o coordinador) |
| ended_by, ended_at | uuid FK users NULL, timestamptz NULL | Salida, retiro o retirada de la solicitud |

Índice único parcial `(driver_id) WHERE status IN ('pending','active')`: un conductor, una
cooperativa y una solicitud en curso (FR-003). Transiciones:

```text
pending → active (aprobada) | rejected (motivo) | cancelled (la retira el conductor)
active  → left (sale el conductor) | removed (admin o coordinador)
```

## trips (cambios)

| Campo | Tipo | Reglas |
|---|---|---|
| dispatch | enum `chosen_driver` \| `cooperative` | Por defecto `chosen_driver` |
| requested_driver_id | uuid FK drivers | Conductor Elegido pedido; la migración copia `driver_id` |
| cooperative_id | uuid FK cooperatives NULL | Fijada al pedir (FR-019); obligatoria si `dispatch = cooperative` o `allow_delegation` |
| allow_delegation | boolean | Consentimiento del pasajero (FR-010) |
| handover_count | smallint 0–3 | Pasos a compañeros (FR-017) |
| driver_id | (existente) | Ahora cambia en cada paso: siempre es el conductor con la oferta o el viaje |

`trip_cancel_reason` añade `no_driver_available`.

## trip_offers

| Campo | Tipo | Reglas |
|---|---|---|
| trip_id | uuid FK trips | PK con driver_id |
| driver_id | uuid FK drivers | |
| offered_at | timestamptz | |
| handover | boolean | La oferta llegó por derivación |

## group_ptt_channels

| Campo | Tipo | Reglas |
|---|---|---|
| cooperative_id | uuid PK FK cooperatives | Se crea con la cooperativa |
| channel_type | enum `COOP_GROUP` | Tipo de canal del SDD |
| room_name | text UNIQUE | `coop-{cooperative_id}` |
| floor_holder_id | uuid FK users NULL | Turno único del grupo |
| floor_expires_at | timestamptz NULL | 60 s; NULL a la vez que `floor_holder_id` |
| created_at | timestamptz | |

## Estados del viaje con delegación

```text
REQUESTED(elegido) ──rechaza / vence 25 s / "pasar"──► [con cooperativa y consentimiento]
    ├─ hay compañero libre y handover_count < 3 ─► REQUESTED(compañero, 25 s, handover_count+1)
    └─ no hay o se agotaron ─────────────────────► CANCELLED(no_driver_available)
[sin consentimiento] ─► CANCELLED(offer_rejected | offer_expired) como en 001
```

Al pasar: el conductor anterior queda libre y recibe `trip.offer_closed`; el nuevo queda
reservado (`busy`) y recibe `trip.offer`; el pasajero recibe `trip.delegated`.

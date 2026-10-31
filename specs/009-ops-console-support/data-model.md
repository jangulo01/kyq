# Data Model: Operación del panel

Migración `backend/migrations/00014_ops_support.sql`.

## trip_inspections (FR-004)

| Columna | Tipo | Notas |
|---|---|---|
| id | bigserial PK | |
| admin_id | uuid FK users | |
| trip_id | uuid FK trips | |
| opened_at | timestamptz | `now()` |

Índice `(trip_id, opened_at DESC)`.

## support_cases (FR-005–FR-012)

| Columna | Tipo | Notas |
|---|---|---|
| id | uuid PK | |
| user_id | uuid FK users | quien abre el caso |
| user_role | user_role | pasajero o conductor |
| counterpart_id | uuid FK users NULL | otra parte de un caso de pago (también lo ve) |
| topic | support_topic | `trip`, `payment`, `lost_item`, `safety`, `account`, `other` |
| subject | text | primeras palabras o título del sistema (≤ 120) |
| trip_id | uuid FK trips NULL | debe ser del usuario y de los últimos 30 días |
| trip_payment_id | uuid FK trip_payments NULL UNIQUE | caso de una disputa o "no pagado" de 004 |
| status | support_status | `open`, `in_progress`, `waiting_user`, `resolved`, `closed` |
| assigned_to | uuid FK users NULL | administrador |
| created_at | timestamptz | |
| last_message_at | timestamptz | |
| last_user_message_at | timestamptz NULL | para "sin respuesta" y el cierre automático |
| last_author_is_user | boolean | `true` si el último mensaje no interno es del usuario |
| resolved_at, closed_at | timestamptz NULL | |

Índices `(user_id, last_message_at DESC)`, `(counterpart_id, last_message_at DESC)`,
`(status, last_user_message_at)`.

**Transiciones**: `open|in_progress|waiting_user|resolved → (cualquiera)` por el administrador
salvo volver desde `closed`; mensaje del usuario en `waiting_user|resolved → open`; mensaje del
usuario en `closed` → `409 case_closed`; barrido: `resolved` con `resolved_at` y sin mensaje del
usuario posterior en 7 días → `closed`.

## support_messages

| Columna | Tipo | Notas |
|---|---|---|
| id | uuid PK | |
| case_id | uuid FK support_cases | |
| author_id | uuid FK users NULL | NULL = mensaje del sistema |
| author_kind | text | `user`, `admin`, `system` |
| body | text | 1–2 000 caracteres |
| internal | boolean | nota interna, solo administradores |
| created_at | timestamptz | |

Índice `(case_id, created_at)`.

## megaphone_broadcasts (FR-013–FR-016)

| Columna | Tipo | Notas |
|---|---|---|
| id | uuid PK | |
| admin_id | uuid FK users | |
| room_name | text | `mega-{id}` |
| cells | text[] | hexágonos H3 elegidos |
| resolution | smallint | 6–9 |
| started_at | timestamptz | |
| ends_at | timestamptz | `started_at + 60 s` |
| ended_at | timestamptz NULL | |
| recipient_count | integer | |

## megaphone_recipients

`(broadcast_id uuid FK, driver_id uuid FK users)`, PK compuesta.

## mirror_domains (FR-019)

| Columna | Tipo | Notas |
|---|---|---|
| id | uuid PK | |
| api_url | text UNIQUE | `https://…`, sin barra final |
| realtime_url | text | `wss://…/connection/websocket` |
| position | integer | orden en la lista |
| active | boolean | |
| created_at, updated_at | timestamptz | |

## mirror_domains_version

Fila única `(id boolean PK CHECK id, version bigint, updated_at timestamptz)`; sube en cada cambio
de `mirror_domains` (desde el servicio, en la misma transacción).

## Lista firmada (sin tabla)

```json
{"payload": "{\"version\":3,\"issued_at\":\"2026-10-28T12:00:00Z\",\"domains\":[{\"api_url\":\"https://api.kyq.co\",\"realtime_url\":\"wss://rt.kyq.co/connection/websocket\"}]}",
 "signature": "base64(Ed25519(payload bytes))"}
```

## Sesión de alcance support (sin tabla)

Claim `scp = "support"` en el token de acceso y campo `scope` en la respuesta de sesión.

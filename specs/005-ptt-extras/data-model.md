# Data Model: PTT extra

Migración `backend/migrations/00010_ptt_extras.sql`.

## drivers (columna nueva)

| Campo | Tipo | Reglas |
|---|---|---|
| accepts_preconsults | boolean NOT NULL DEFAULT false | Recibe consultas de voz de sus clientes (FR-001) |

## affiliations (columna nueva)

| Campo | Tipo | Reglas |
|---|---|---|
| preconsults_blocked | boolean NOT NULL DEFAULT false | Cliente silenciado por el conductor (FR-002) |

## ptt_preconsults

| Campo | Tipo | Reglas |
|---|---|---|
| id | uuid PK | |
| passenger_id | uuid FK users | Afiliado al conductor al abrir |
| driver_id | uuid FK drivers | |
| room_name | text UNIQUE | `pre-{id}` |
| opened_at | timestamptz | |
| join_deadline | timestamptz | `opened_at + 30 s` |
| closes_at | timestamptz | `opened_at + 2 min`; terminar o desactivar la adelanta a ahora |
| joined_at | timestamptz NULL | Primer token del conductor |
| answered_at | timestamptz NULL | Primer turno del conductor |
| closed_at | timestamptz NULL | Lo pone el barrido tras borrar la sala |
| close_reason | text NULL | `ended_by_passenger`, `ended_by_driver`, `disabled`, `missed`, `driver_unavailable`, `expired` |
| floor_holder_id | uuid FK users NULL | Turno exclusivo |
| floor_expires_at | timestamptz NULL | Turno de 15 s |

Índices: único parcial `(driver_id) WHERE closed_at IS NULL` y `(passenger_id) WHERE closed_at
IS NULL` (una abierta por persona, FR-007); `(passenger_id, opened_at)` y `(driver_id,
opened_at)` para límites y bandeja; `(closed_at)` para el borrado a 30 días (FR-008).

### Estado derivado (API)

| status | Condición |
|---|---|
| `open` | `closed_at IS NULL` |
| `missed` | cerrada sin `joined_at` |
| `answered` | cerrada con `answered_at` |
| `unanswered` | cerrada, conductor conectado, sin `answered_at` |

### Transiciones

```text
abierta ──conductor pide token──► conectada ──conductor toma turno──► respondida
   │                                  │
   └── 30 s sin conectar ─► cerrada (missed)
cualquier estado abierto ── 2 min / terminar / desactivar / silenciar / conductor no libre ─► cerrada
cerrada ── 30 días ─► borrada
```

## Preferencias locales (Kyq Conductor, `shared_preferences`)

| Clave | Por defecto | Uso |
|---|---|---|
| `handsfree.media_button` | true | Capturar el botón multimedia (FR-015) |
| `handsfree.bubble` | true | Mostrar la burbuja si hay permiso (FR-015) |

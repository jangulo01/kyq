# Data Model: Pago del viaje con Bold o en efectivo

Extiende el modelo de 001 y 002. Importes en unidades mínimas de moneda (`bigint`, centavos),
fechas `timestamptz`. Migración `backend/migrations/00009_trip_payments.sql`.

## drivers (cambios)

| Campo | Tipo | Reglas |
|---|---|---|
| accepts_cash | boolean NOT NULL DEFAULT true | FR-018 |
| accepts_bold | boolean NOT NULL DEFAULT true | FR-018 |
| — | CHECK `accepts_cash OR accepts_bold` | Al menos un medio |

## trip_payments

| Campo | Tipo | Reglas |
|---|---|---|
| id | uuid PK | También es la `reference` del enlace de Bold |
| trip_id | uuid FK trips UNIQUE | Un pago por viaje completado |
| driver_id | uuid FK drivers | |
| passenger_id | uuid FK users | |
| amount_minor | bigint > 0 | Tarifa acordada (FR-001) |
| currency | char(3) | La del viaje |
| driver_amount_minor | bigint | CHECK `= amount_minor` (RN-KYQ-001) |
| platform_commission_minor | bigint DEFAULT 0 | CHECK `= 0` (RN-KYQ-001) |
| accepts_cash, accepts_bold | boolean | Copia de los medios del conductor al completar |
| status | enum `pending` \| `bold_in_progress` \| `cash_reported` \| `paid` \| `unpaid` \| `disputed` \| `needs_review` \| `voided` | research R3 |
| method | enum `bold` \| `cash` NULL | Medio con que se pagó (o se intenta pagar con Bold) |
| bold_link_id | text UNIQUE NULL | Enlace en curso o el último usado |
| checkout_url | text NULL | Solo se muestra en `bold_in_progress` |
| link_created_at | timestamptz NULL | Caducidad del enlace (30 min) y ventana de sondeo (2 h) |
| bold_payment_id, payment_method_detail | text NULL | Lo que confirma Bold |
| cash_reported_at | timestamptz NULL | Reporte del pasajero (FR-004) |
| cash_confirmed_at | timestamptz NULL | Confirmación del conductor (FR-005) |
| disputed_at | timestamptz NULL | Disputa del conductor (FR-005) |
| unpaid_marked_at | timestamptz NULL | "No me pagó" (FR-006) |
| paid_at | timestamptz NULL | Obligatorio si `paid` |
| reminded_at | timestamptz NULL | Recordatorio único (FR-015) |
| review_note | text NULL | Valor distinto o segundo cobro de Bold |
| resolved_by, resolution_note, resolved_at | uuid FK users / text / timestamptz NULL | Resolución del admin (FR-017) |
| voided_by, void_reason, voided_at | uuid FK users / text / timestamptz NULL | Anulación (FR-014); `void_reason` obligatorio si `voided` |
| created_at, updated_at | timestamptz | `created_at` = momento en que se completó el viaje |

Índices: `(passenger_id)` parcial en estados abiertos (`pending`, `unpaid`,
`bold_in_progress`); `(link_created_at)` parcial en `bold_in_progress` (sondeo);
`(created_at)` parcial en `pending` sin `reminded_at` (recordatorios); `(driver_id, created_at
DESC)`; `(status, created_at DESC)` para el panel.

## driver_payouts

| Campo | Tipo | Reglas |
|---|---|---|
| id | uuid PK | |
| driver_id | uuid FK drivers | |
| amount_minor | bigint > 0 | ≤ saldo al registrarlo (servicio, con la fila del conductor bloqueada) |
| currency | char(3) | |
| reference | text NOT NULL (1–80) | Referencia de la transferencia |
| note | text NULL (≤ 200) | |
| created_by | uuid FK users | Administrador |
| created_at | timestamptz | |

## driver_ledger_entries

| Campo | Tipo | Reglas |
|---|---|---|
| id | uuid PK | |
| driver_id | uuid FK drivers | |
| kind | enum `trip_credit` \| `void_debit` \| `payout` | |
| amount_minor | bigint | `trip_credit` > 0; `void_debit` y `payout` < 0 |
| currency | char(3) | |
| trip_payment_id | uuid FK trip_payments NULL | Obligatorio en `trip_credit` y `void_debit` |
| payout_id | uuid FK driver_payouts NULL | Obligatorio en `payout` |
| created_by | uuid FK users NULL | Admin en anulaciones manuales y giros |
| created_at | timestamptz | |

Índice único `(trip_payment_id, kind)` (idempotencia del abono y del débito). Saldo = Σ
`amount_minor` por conductor y moneda; abonado = Σ `trip_credit`; girado = −Σ `payout`.

## Relaciones

```text
trips 1 ── 0..1 trip_payments ── 0..2 driver_ledger_entries (abono, débito)
drivers 1 ── * driver_payouts 1 ── 1 driver_ledger_entries (giro)
```

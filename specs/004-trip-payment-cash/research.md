# Research: Pago del viaje con Bold o en efectivo

Base: research de 002 (R1–R3: API Link de pagos de Bold, sondeo y webhook firmado), verificado
contra el sandbox de Bold el 2026-10-27.

## R1. Cobro con Bold reutilizando 002

- **Decision**: el pago del viaje usa el mismo `billing.BoldAPI` (`POST /online/link/v1` con
  `amount_type: CLOSE`, `reference` = id del pago del viaje, caducidad 30 min) y la misma
  clasificación del estado del enlace, ahora exportada como `billing.ClassifyLink` (incluye el
  caso del sandbox que sigue diciendo `ACTIVE` tras caducar). Un enlace en curso por pago; si
  caduca o se rechaza, el pasajero puede pedir otro.
- **Rationale**: principio II; un solo cliente probado contra el sandbox; el valor lo fija el
  servidor (tarifa acordada).
- **Alternatives considered**: un segundo cliente o una cuenta Bold por conductor (Kyq no puede
  abrir cuentas a nombre de terceros; dispersión automática no disponible en la API pública).

## R2. Un solo webhook para suscripción y viajes

- **Decision**: Bold admite una URL de webhook por cuenta, así que `POST /v1/billing/bold/webhook`
  sigue siendo el único. `billing.Service.HandleWebhook` verifica la firma, busca la referencia en
  `payments`; si no existe, la ofrece a `billing.Service.References` (interfaz
  `ReferenceHandler`), que `trippay` implementa. Las referencias son UUID v7, sin colisiones.
- **Rationale**: no duplicar verificación de firma ni ruta; `billing` no conoce los viajes.
- **Alternatives considered**: prefijos en la referencia (`trip:`) — rompe la compatibilidad de
  los enlaces de suscripción ya emitidos y no aporta.

## R3. Estados del pago y transiciones

- **Decision**: `pending`, `bold_in_progress`, `cash_reported`, `paid`, `unpaid`, `disputed`,
  `needs_review`, `voided`. Función pura `Transition(estado, acción, parte)` probada por tabla:

  | Acción | Parte | Desde | Hacia |
  |---|---|---|---|
  | `report_cash` | pasajero | pending, unpaid | cash_reported |
  | `confirm_cash` | conductor | pending, cash_reported, unpaid, disputed | paid (efectivo) |
  | `dispute_cash` | conductor | cash_reported | disputed |
  | `mark_unpaid` | conductor | pending | unpaid |
  | `start_bold` | pasajero | pending, unpaid | bold_in_progress |
  | Bold aprobado | sistema | bold_in_progress, pending, unpaid, cash_reported, disputed | paid (Bold) + abono |
  | Bold rechazado/caducado | sistema | bold_in_progress | pending o unpaid (si el conductor lo marcó) |
  | Bold anulado / anulación admin | sistema/admin | paid (Bold), needs_review | voided (+ débito si hubo abono) |
  | resolver | admin | disputed, unpaid | paid (efectivo) o unpaid |

- **Rationale**: el efectivo depende de la palabra de las partes; Bold es verificable y gana
  ante un conflicto (spec, Edge Cases). Cada reporte guarda su marca de tiempo (FR-004, FR-005).

## R4. Libro de liquidación

- **Decision**: tabla `driver_ledger_entries` con valores con signo (`trip_credit` > 0,
  `void_debit` < 0, `payout` < 0) y saldo = suma por conductor y moneda. Índice único
  `(trip_payment_id, kind)` para idempotencia: un abono y un débito por pago. Los giros
  (`driver_payouts`) se registran bloqueando la fila del conductor y validando
  `valor ≤ saldo`.
- **Rationale**: libro de solo inserción, auditable, que cuadra por construcción (SC-004).
- **Alternatives considered**: columna de saldo en `drivers` (pierde el detalle y se descuadra
  ante errores); giros automáticos (fuera de alcance, Assumptions).

## R5. Gancho al completar el viaje

- **Decision**: `trips.Service.Payments` (interfaz `PaymentOpener`) se llama dentro de la
  transacción que pasa el viaje a `COMPLETED`; `trippay` inserta el pago con `ON CONFLICT DO
  NOTHING`. Sin gancho (pruebas de 001) el viaje funciona como antes.
- **Rationale**: atomicidad (no hay viaje completado sin pago) sin que `trips` importe `trippay`.

## R6. Recordatorio y avisos

- **Decision**: barrido cada 10 s junto al sondeo; los recordatorios se evalúan cada minuto:
  pagos `pending` sin `reminded_at` y completados hace ≥ 10 min → evento `trip_payment.reminder`
  al pasajero y aviso `trip_payment_pending` al conductor (deduplicado por pago), y se marca
  `reminded_at`. Cada cambio de estado publica `trip_payment.updated` a ambos. El pasajero no
  tiene avisos persistentes (la tabla `notices` es de conductores): al abrir la app consulta
  `GET /v1/trip-payments/pending`.
- **Rationale**: sin push (002, R5); el aviso persistente al pasajero es la lista de pendientes.

## R7. Medios aceptados

- **Decision**: columnas `accepts_cash` y `accepts_bold` en `drivers` (por defecto `true`, CHECK
  al menos uno). Se copian al pago al completarse el viaje. Bold solo se ofrece si además está
  configurado en el servidor (`KYQ_BOLD_ENV`).

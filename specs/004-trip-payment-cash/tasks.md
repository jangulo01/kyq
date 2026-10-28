# Tasks: Pago del viaje con Bold o en efectivo

**Input**: Design documents from `/specs/004-trip-payment-cash/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/api.yaml, quickstart.md

**Tests**: incluidas; la constitución (V, VI) exige una prueba por regla RN-KYQ y pruebas de
integración de contratos.

## Format: `[ID] [P?] [Story] Description`

## Phase 1: Setup

- [X] T001 [P] Añadir `url_launcher` (la versión de la app del conductor) a `apps/kyq_rider_app/pubspec.yaml`

## Phase 2: Foundational

- [X] T002 Migración `backend/migrations/00009_trip_payments.sql`: `accepts_cash`/`accepts_bold` en `drivers` (CHECK al menos uno); `trip_payments` con enums de estado y medio, CHECK RN-KYQ-001 (`platform_commission_minor = 0`, `driver_amount_minor = amount_minor`), `paid` con medio y fecha, `voided` con motivo, índices parciales; `driver_payouts`; `driver_ledger_entries` con CHECK de signo por tipo e índice único `(trip_payment_id, kind)`
- [X] T003 Consultas sqlc en `backend/internal/store/queries/trip_payments.sql` y `sqlc generate`
- [X] T004 Exportar `billing.ClassifyLink` (estado del enlace → resultado, con el caso ACTIVE caducado) y usarlo en el sondeo de 002; añadir `billing.ReferenceHandler` y `Service.References` para delegar webhooks con referencia desconocida, con pruebas en `backend/internal/billing/billing_test.go`
- [X] T005 Gancho `trips.PaymentOpener` en `backend/internal/trips/service.go`, llamado en la transacción que completa el viaje
- [X] T006 [P] Modelos y métodos nuevos en `packages/kyq_api` (pago del viaje, medios, libro, liquidaciones, giros y rutas admin) con `build_runner` y pruebas del cliente
- [X] T007 [P] Eventos `trip_payment.updated` y `trip_payment.reminder` en `packages/kyq_realtime` con prueba; documentarlos en `specs/001-chosen-driver-trip-ptt/contracts/realtime.md`
- [X] T008 [P] Etiquetas de estado del pago en `packages/kyq_ui/lib/src/labels.dart`
- [X] T009 Fusionar `specs/004-trip-payment-cash/contracts/api.yaml` en el contrato principal `specs/001-chosen-driver-trip-ptt/contracts/api.yaml`

**Checkpoint**: migración, consultas, gancho y contrato listos.

## Phase 3: User Story 1 - Efectivo reportado y confirmado (P1)

**Goal**: el pasajero reporta efectivo y el conductor confirma o disputa.

**Independent Test**: escenarios 1–5 de quickstart.md.

- [X] T010 [P] [US1] Prueba de tabla de transiciones y de la liquidación (RN-KYQ-001) en `backend/internal/trippay/transition_test.go`
- [X] T011 [US1] Dominio y servicio en `backend/internal/trippay/`: `Transition`, abrir el pago al completar (`OpenForTrip`), vista para participantes, `ReportCash`, `ConfirmCash`, `DisputeCash`, eventos `trip_payment.updated` y avisos al conductor
- [X] T012 [US1] Rutas `GET /v1/trips/{id}/payment`, `POST .../payment/cash`, `.../cash-received`, `.../cash-dispute` en `backend/internal/trippay/handlers.go`; montar en `backend/internal/httpapi/router.go` y `backend/cmd/api/main.go`
- [X] T013 [P] [US1] Pruebas de integración de efectivo en `backend/internal/trippay/integration_test.go` (pago abierto al completar; reporte, confirmación, disputa; partes y estados inválidos; medio no aceptado)
- [X] T014 [US1] Sección de pago en el resumen del pasajero: `apps/kyq_rider_app/lib/trip/trip_payment_cubit.dart` y `trip_payment_section.dart` en `trip_summary_view.dart`
- [X] T015 [US1] Pago en el resumen del conductor (estado, "Recibí el efectivo", "No recibí el efectivo") en `apps/kyq_driver_app/lib/trip/trip_payment_card.dart` con su cubit
- [X] T016 [P] [US1] Pruebas de cubit y widget en `apps/kyq_rider_app/test/trip/trip_payment_test.dart` y `apps/kyq_driver_app/test/trip/trip_payment_test.dart`

## Phase 4: User Story 2 - Pago con Bold y abono al conductor (P1)

**Goal**: el pasajero paga con Bold; el abono del 100 % queda en el libro una sola vez.

**Independent Test**: escenarios 6–8 de quickstart.md.

- [X] T017 [US2] Bold en `backend/internal/trippay/bold.go`: `StartBold` (enlace por la tarifa, reutiliza el vigente), `Refresh`, sondeo, `HandleBoldOutcome` (delegado del webhook), aprobación con abono idempotente, valor distinto → `needs_review`, segundo cobro → nota de revisión, rechazo/caducidad → `pending` o `unpaid`, anulación de Bold → `voided` + débito
- [X] T018 [US2] Rutas `POST .../payment/bold` y `.../payment/refresh`; `billingService.References` y el `BoldAPI` compartido en `backend/cmd/api/main.go`
- [X] T019 [P] [US2] Pruebas de integración con un servidor Bold falso (`httptest`) detrás de `billing.BoldClient`: enlace por la tarifa exacta, sondeo y webhook firmado duplicados abonan una vez (SC-003), abono = 100 % y comisión 0 (RN-KYQ-001), valor distinto, rechazo y caducidad, Bold gana a un reporte de efectivo, anulación de Bold
- [X] T020 [US2] Botón "Pagar con Bold" con Custom Tab y comprobación al volver en la app del pasajero (`apps/kyq_rider_app/lib/trip/checkout_launcher.dart`) con prueba

## Phase 5: User Story 3 - Recordatorio y no pagado (P1)

**Goal**: recordatorio único, aviso de pendientes y "no pagado" visible en el panel.

**Independent Test**: escenarios 9–10 de quickstart.md.

- [X] T021 [US3] `MarkUnpaid`, `GET /v1/trip-payments/pending` y barrido (`backend/internal/trippay/sweeper.go`): sondeo cada 10 s y recordatorios a los 10 min (evento al pasajero, aviso al conductor, `reminded_at`)
- [X] T022 [P] [US3] Pruebas de integración: recordatorio único; no pagado y pago posterior; no pagado bloqueado con Bold en curso
- [X] T023 [US3] Aviso "Tienes un viaje sin pagar" en la pantalla principal del pasajero (`apps/kyq_rider_app/lib/payments/`) con recarga por `trip_payment.reminder`, y botón "No me pagó" en la app del conductor
- [X] T024 [P] [US3] Pruebas de widget del aviso de pendientes y del botón "No me pagó"

## Phase 6: User Story 4 - Medios aceptados (P2)

**Goal**: el conductor elige efectivo, Bold o ambos.

**Independent Test**: escenario 11 de quickstart.md.

- [X] T025 [US4] `GET/PUT /v1/driver/payment-methods` en `backend/internal/trippay/` con prueba (al menos uno; copia al completar)
- [X] T026 [US4] Pantalla "Pagos de viajes" del conductor (`apps/kyq_driver_app/lib/trip_payments/`): medios aceptados, saldo por girar, libro y pagos recientes con acciones; acceso desde el inicio; con prueba

## Phase 7: User Story 5 - Liquidación y panel (P2)

**Goal**: el admin ve saldos, registra giros, resuelve incidencias y anula pagos de Bold.

**Independent Test**: escenarios 4–5, 12–13 de quickstart.md.

- [X] T027 [P] [US5] Pruebas de integración en `backend/internal/trippay/settlement_test.go`: saldo = abonos − débitos − giros; giro mayor al saldo → 409; giro auditado y avisado; resolución de disputa y no pagado; anulación manual con débito
- [X] T028 [US5] Libro, giros y panel en `backend/internal/trippay/settlement.go` y `admin.go`: `GET /v1/driver/settlement`, `GET /v1/admin/trip-payments`, `POST .../resolve`, `POST .../void`, `GET /v1/admin/settlements`, `GET /v1/admin/drivers/{id}/settlement`, `POST /v1/admin/drivers/{id}/payouts`
- [X] T029 [US5] Panel: pagos de viajes por estado con incidencias, resolver y anular (`apps/kyq_admin_web/lib/trip_payments/trip_payments_page.dart`), liquidaciones y libro de un conductor con registro de giro (`settlements_page.dart`, `driver_ledger_page.dart`); accesos en el inicio
- [X] T030 [P] [US5] Pruebas de widget del panel en `apps/kyq_admin_web/test/trip_payments/`

## Phase 8: Polish & Cross-Cutting Concerns

- [X] T031 Prueba de contrato `backend/internal/contracttest/trip_payments_test.go`: recorrer todas las rutas de 004 contra el contrato fusionado; la vista de 004 es OpenAPI válido
- [X] T032 [P] Prueba de privacidad: un tercero no ve el pago (404) y el pasajero no ve notas de revisión ni datos del libro
- [ ] T033 Desplegar en la VM (migración 00009) y recorrer quickstart.md en los teléfonos con el sandbox de Bold; registrar resultados en `specs/004-trip-payment-cash/validation.md` (lo hace el coordinador)

## Dependencies & Execution Order

- Setup (T001) → Foundational (T002–T009) → historias.
- US1 (T010–T016) antes de US2 (comparte servicio y vistas) y de US3.
- US4 y US5 dependen de US1/US2 (pagos y abonos existentes).
- Polish al final; T033 queda para el coordinador.

## Parallel Opportunities

- T006, T007, T008 en paralelo con el backend.
- En cada historia, las pruebas [P] y las pantallas de las apps van en paralelo con el backend.

## Implementation Strategy

MVP de esta fase = US1 + US2 + US3 (efectivo, Bold y cierre de impagos); US4 y US5 son
incrementos.

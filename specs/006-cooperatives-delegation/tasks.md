# Tasks: Cooperativas y delegación inteligente

**Input**: Design documents from `/specs/006-cooperatives-delegation/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/api.yaml, quickstart.md

**Tests**: incluidas; la constitución (V, VI) exige una prueba por regla RN-KYQ y pruebas de
integración de contratos.

## Format: `[ID] [P?] [Story] Description`

## Phase 1: Setup

- [X] T001 Fusionar `specs/006-cooperatives-delegation/contracts/api.yaml` en el contrato principal `specs/001-chosen-driver-trip-ptt/contracts/api.yaml` (rutas, campos nuevos de `Trip` y `ChosenDriver`, esquemas) y documentar los eventos nuevos en `specs/001-chosen-driver-trip-ptt/contracts/realtime.md`

## Phase 2: Foundational

- [X] T002 Migración `backend/migrations/00011_cooperatives.sql`: `cooperatives` (nombre único sin mayúsculas, estado), `cooperative_memberships` (rol, estado, índice único parcial de una membresía en curso por conductor), columnas de despacho en `trips` (`dispatch`, `requested_driver_id` rellenado desde `driver_id`, `cooperative_id`, `allow_delegation`, `handover_count`), valor `no_driver_available` en `trip_cancel_reason`, `trip_offers` (rellenada) y `group_ptt_channels` (`COOP_GROUP`)
- [X] T003 Consultas sqlc en `backend/internal/store/queries/cooperatives.sql` (cooperativas, membresías, candidatos PostGIS, canal de grupo), cambios en `trips.sql` (insertar y actualizar las columnas nuevas, ofertas, nombres) y `affiliations.sql` (cooperativa del Conductor Elegido); `sqlc generate`
- [X] T004 [P] Modelos y métodos nuevos en `packages/kyq_api` (`cooperative_models.dart` con `build_runner`; `Trip` y `ChosenDriver` con los campos nuevos; métodos de conductor, coordinador, PTT de grupo y admin) y pruebas del cliente
- [X] T005 [P] Eventos `trip.delegated`, `cooperative.membership` y campos nuevos de `trip.offer` en `packages/kyq_realtime` con pruebas

**Checkpoint**: migración aplicada, consultas y clientes listos.

## Phase 3: User Story 1 - Cooperativas en el panel (P1)

**Goal**: el admin crea cooperativas y gestiona miembros, solicitudes y coordinadores.

**Independent Test**: escenarios 1–3 y 15 de quickstart.md.

- [X] T006 [P] [US1] Pruebas de integración en `backend/internal/cooperatives/service_test.go`: crear con nombre duplicado → `cooperative_name_taken`; agregar miembro; un conductor en dos cooperativas → `already_in_cooperative`; aprobar/rechazar (motivo obligatorio); cambiar rol; retirar; suspender
- [X] T007 [US1] Módulo `backend/internal/cooperatives/` (servicio y handlers admin de contracts/api.yaml) y montaje en `backend/internal/httpapi/router.go` y `backend/cmd/api/main.go`
- [X] T008 [US1] Panel: lista y alta de cooperativas, detalle con miembros, solicitudes, roles, retiro y suspensión en `apps/kyq_admin_web/lib/cooperatives/` y ruta en `app.dart`
- [X] T009 [P] [US1] Pruebas de widget del panel en `apps/kyq_admin_web/test/cooperatives/cooperatives_test.dart`

## Phase 4: User Story 2 - El conductor pide entrar (P1)

**Goal**: solicitudes desde la app, decisión por coordinador o admin, salir.

**Independent Test**: escenarios 2, 4 y 5 de quickstart.md.

- [X] T010 [P] [US2] Pruebas de integración: solicitud, retirada, salida, coordinador decide y retira (no a coordinadores), miembro no coordinador → 403, evento `cooperative.membership`
- [X] T011 [US2] Rutas de conductor y coordinador en `backend/internal/cooperatives/handlers.go`
- [X] T012 [US2] Pantalla "Mi cooperativa" (sin cooperativa: lista y pedir; pendiente: retirar; miembro: compañeros, salir; coordinador: solicitudes y retiro) en `apps/kyq_driver_app/lib/cooperative/` y acceso desde el inicio
- [X] T013 [P] [US2] Pruebas del cubit y la página en `apps/kyq_driver_app/test/cooperative/`

## Phase 5: User Story 3 - Delegación inteligente (P1) 🎯 RN-KYQ-008

**Goal**: la solicitud pasa al compañero libre más cercano cuando el elegido no puede.

**Independent Test**: escenarios 6–10 de quickstart.md.

- [X] T014 [P] [US3] Pruebas de unidad del agregado en `backend/internal/trips/trip_delegation_test.go`: `Delegate` solo conductor, en REQUESTED, dentro del plazo y con consentimiento; `HandOver` reinicia la oferta de 25 s con el nuevo conductor; `GiveUp` deja `no_driver_available`; máximo 3 pasos
- [X] T015 [P] [US3] Pruebas de integración en `backend/internal/trips/delegation_test.go`: elegido ocupado → compañero más cercano; rechazo, vencimiento y "pasar" → siguiente; sin consentimiento → como 001; candidatos lejanos, con ubicación vieja, de otra cooperativa o de cooperativa suspendida excluidos; máximo de pasos; viaje derivado completado con comisión 0 y 100 % al compañero (RN-KYQ-001); eventos y presencias
- [X] T016 [US3] Despacho y delegación en `backend/internal/trips/` (`dispatch.go`, cambios en `trip.go`, `service.go`, `repo.go`, `events.go`, `handlers.go`: `POST /v1/trips` con `dispatch` y `allow_delegation`, `POST /v1/trips/{tripId}/delegate`, vista con los campos nuevos)
- [X] T017 [US3] Conductor: oferta derivada ("Solicitud de la cooperativa, cliente de …") y botón "Pasar a mi cooperativa" en `apps/kyq_driver_app/lib/offers/`
- [X] T018 [US3] Pasajero: casilla de consentimiento en la solicitud, aviso "Tu solicitud pasó a un compañero de …", nombre del conductor real y motivo `no_driver_available` en `apps/kyq_rider_app/lib/request/` y `lib/trip/`
- [X] T019 [P] [US3] Pruebas de cubit y widget en ambas apps

## Phase 6: User Story 4 - Selector de despacho (P2)

**Goal**: "Mi conductor" o "Su cooperativa"; la opción 3 se ve deshabilitada.

**Independent Test**: escenarios 11 y 12 de quickstart.md.

- [X] T020 [US4] Cooperativa del Conductor Elegido en `GET /v1/affiliations` (`backend/internal/affiliations/`)
- [X] T021 [US4] Selector de despacho en `apps/kyq_rider_app/lib/request/request_page.dart` y `request_cubit.dart`, con prueba de widget

## Phase 7: User Story 5 - Canal de grupo (P2)

**Goal**: walkie-talkie de grupo por cooperativa con turno único.

**Independent Test**: escenarios 13 y 14 de quickstart.md.

- [X] T022 [P] [US5] Pruebas de integración en `backend/internal/ptt/group_test.go`: token solo para miembros activos de cooperativa activa; turno único; liberar; caducidad del turno; `LeaveGroup` retira permiso, turno y participante
- [X] T023 [US5] Canal de grupo en `backend/internal/ptt/group.go` y `group_handlers.go`; sala de hasta 50 participantes en `livekit.go`; caducidad en el barrido; `LeaveGroup` llamado al salir, ser retirado o suspender
- [X] T024 [US5] `KyqCoopPttApi` en `packages/kyq_ptt` y botón de grupo en "Mi cooperativa" del conductor

## Phase 8: Polish & Cross-Cutting

- [X] T025 Prueba de contrato de las rutas de 006 en `backend/internal/contracttest/cooperatives_test.go`
- [X] T026 `gofmt`, `go vet`, `go test ./...` con base real; `melos run analyze` y `melos run test`; APK debug de conductor y pasajero

## Dependencies & Execution Order

- Phase 2 bloquea todo. US1 (cooperativas) precede a US2–US5. US3 depende de membresías (US1).
- US4 depende de US3 (mismo despacho). US5 solo depende de US1.

## Trazabilidad de reglas

| Regla | Prueba |
|---|---|
| RN-KYQ-008 | `trips/delegation_test.go`, `trips/trip_delegation_test.go` (`TestDelegate*`, `TestHandOver*`) |
| RN-KYQ-001 | `trips/delegation_test.go` (`TestIntegrationDelegatedTripZeroCommission`) |
| RN-KYQ-007 | `trips/delegation_test.go` (cada paso con 25 s y vencimiento) |
| FR-003 (una cooperativa) | `cooperatives/service_test.go` |
| FR-022–FR-024 | `ptt/group_test.go` |

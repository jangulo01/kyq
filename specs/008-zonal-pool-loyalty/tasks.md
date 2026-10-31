# Tasks: Bolsa zonal y fidelización ampliada

**Input**: [spec.md](spec.md), [plan.md](plan.md), [research.md](research.md),
[data-model.md](data-model.md), [quickstart.md](quickstart.md)

## Format: `[ID] [P?] [Story] Description`

- **[P]**: paralelizable (archivos distintos, sin dependencias pendientes)

## Phase 1: Setup

- [X] T001 Migración `backend/migrations/00013_zonal_pool.sql` (data-model.md) y consultas sqlc nuevas o cambiadas en `backend/internal/store/queries/` (candidatos de la bolsa, preferencias de despacho, cartera y viajes juntos, afiliación con origen, informe por origen); `sqlc generate`
- [X] T002 Contrato: `specs/001-chosen-driver-trip-ptt/contracts/api.yaml` (dispatch `zone_pool`, `driver_id` opcional, cotización con `driver_id`, `/v1/driver/dispatch-settings`, afiliación con origen o viaje, `created_by_source`) y `realtime.md` (campos nuevos de `trip.offer`); vista propia en `specs/008-zonal-pool-loyalty/contracts/api.yaml`

## Phase 2: Foundational

- [X] T003 Agregado del viaje en `backend/internal/trips/trip.go` y `dispatch.go`: `DispatchZonePool`, traspaso en la bolsa sin cooperativa, `findCandidate` por modo, con pruebas de unidad
- [X] T004 [P] Modelos y métodos en `packages/kyq_api` (dispatch `zonePool`, preferencias de despacho, cotización con conductor, afiliación por enlace y por viaje, origen en clientes, `createdBySource`) y campos de `TripOffered` en `packages/kyq_realtime`, con pruebas

## Phase 3: User Story 1 + 2 - Bolsa zonal (P1) 🎯 MVP

- [X] T005 [US1] `trips.Service.RequestWith` con `zone_pool`: sin afiliación, primer candidato de la bolsa, `requested_driver_id` = primer ofertado; handler `POST /v1/trips` con `driver_id` opcional en la bolsa
- [X] T006 [US2] Preferencias de despacho del conductor: `GET/PUT /v1/driver/dispatch-settings` en `backend/internal/drivers/`
- [X] T007 [US1] Pruebas de integración `backend/internal/trips/zone_pool_test.go`: solo conductores con bolsa, más cercano, frescura y radio, suspendido excluido, traspaso hasta 3 y cierre, cancelación, comisión 0
- [X] T008 [US1] App del pasajero: "Pedir un viaje a un conductor cercano" en el inicio, opción 3 del selector habilitada, solicitud sin conductor y espera "Buscando un conductor cercano" (`apps/kyq_rider_app/lib/request/`, `chosen_drivers/`)
- [X] T009 [US2] App del conductor: pantalla "Despacho y tarifas" con la bolsa (`apps/kyq_driver_app/lib/dispatch/`) y acceso desde el inicio
- [X] T010 [P] [US1] Pruebas de cubit y widget de la solicitud a la bolsa y del ajuste del conductor

## Phase 4: User Story 3 - Origen de la oferta (P2)

- [X] T011 [US3] Contexto de la oferta en el servicio (`origin`, `loyal_client`, `trips_together`, `pickup_distance_m`) al crear, traspasar o volver a ofertar; pruebas de integración del evento
- [X] T012 [US3] Tarjeta de oferta del conductor con "⭐ Cliente de tu cartera", "De tu cooperativa" o "Bolsa zonal" y distancia (`apps/kyq_driver_app/lib/offers/`), con pruebas de widget

## Phase 5: User Story 4 - Tarifa preferencial (P2)

- [X] T013 [US4] Tarifa preferencial en `trips` y `fares`: cálculo con redondeo de la tabla, aplicar al crear la oferta a un conductor con el pasajero en cartera, volver a lista al traspasar, cotización con `driver_id`; pruebas de unidad e integración (RN-KYQ-013, RN-KYQ-001)
- [X] T014 [US4] Descuento en "Despacho y tarifas" (0–30 %) y aviso de tarifa preferencial en la solicitud del pasajero, con pruebas

## Phase 6: User Story 5 - Afiliación sin QR (P2)

- [X] T015 [US5] `affiliations`: origen al insertar y reactivar, afiliación por viaje completado y por enlace (`source=link`), página pública `GET /a/{token}`; pruebas de servicio e integración
- [X] T016 [US5] Informe de fidelización con `created_by_source` en `backend/internal/crm/` y en el panel (`apps/kyq_admin_web/lib/crm/`), con pruebas
- [X] T017 [US5] App del pasajero: "Guardar como Conductor Elegido" en el resumen del viaje y apertura del enlace `kyq://affiliate/{token}` (intent-filter); pruebas
- [X] T018 [US5] App del conductor: "Compartir mi enlace" en Mi QR y origen en "Mis clientes"; pruebas

## Phase 7: Polish

- [X] T019 [P] Etiquetar con su regla las pruebas existentes de RN-KYQ-006 y RN-KYQ-011 (principio V)
- [X] T020 `cd backend && go vet ./... && go test ./...` con base real; `melos run analyze` y `melos run test`
- [ ] T021 Desplegar en la VM y recorrer [quickstart.md](quickstart.md); registrar en `validation.md` (lo hace el responsable)

## Dependencies & Execution Order

- T001 y T002 bloquean todo. T003 y T004 bloquean las historias.
- US1/US2 (MVP) primero; US3 y US4 dependen del contexto de oferta y del cálculo de tarifa; US5
  es independiente de US1–US4.

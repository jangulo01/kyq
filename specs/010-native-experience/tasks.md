# Tasks: Experiencia nativa

**Input**: [spec.md](spec.md), [plan.md](plan.md), [research.md](research.md),
[data-model.md](data-model.md), [quickstart.md](quickstart.md)

## Format: `[ID] [P?] [Story] Description`

- **[P]**: paralelizable (archivos distintos, sin dependencias pendientes)

## Phase 1: Setup

- [X] T001 Migración `backend/migrations/00015_native_experience.sql` y consultas sqlc (`reservations.sql`, notas, llegada, zona); `sqlc generate`
- [X] T002 Contrato: rutas y esquemas en `specs/001-chosen-driver-trip-ptt/contracts/api.yaml`, eventos en `realtime.md` y vista en `specs/010-native-experience/contracts/api.yaml`

## Phase 2: Foundational

- [X] T003 [P] Modelos y métodos en `packages/kyq_api` (reservas, ficha y nota del cliente, lugares, zona, `accuracy_m`) y eventos `reservation.updated` y campos nuevos de `trip.offer` en `packages/kyq_realtime`; pruebas

## Phase 3: US1 Agenda (P1)

- [X] T004 [US1] Módulo `backend/internal/reservations/`: reservar (cotización con la preferencial), aceptar, rechazar, cancelar, agenda, máximo 3, barrido (vencer, recordar, cumplir con `RequestWith` y tarifa reservada); pruebas de unidad e integración
- [X] T005 [US1] `trips`: `RequestOptions.ReservedFare` y `Reservation`, `reservation` en `trip.offer`
- [X] T006 [US1] Pasajero: "Reservar" desde el Conductor Elegido y "Mis reservas" con cancelar (`apps/kyq_rider_app/lib/reservations/`); pruebas
- [X] T007 [US1] Conductor: "Agenda" con aceptar, rechazar, cancelar y aviso de solape; etiqueta "Reserva" en la oferta (`apps/kyq_driver_app/lib/reservations/`); pruebas

## Phase 4: US5 Direcciones (P1)

- [X] T008 [US5] Módulo `backend/internal/places/` (cliente de Photon, caja de la ciudad, caché, `GET /v1/places`); pruebas con servidor falso
- [X] T009 [US5] Pasajero: buscador de direcciones con Casa, Trabajo y recientes en la solicitud y la reserva (`apps/kyq_rider_app/lib/places/`); pruebas
- [X] T010 [P] [US5] Photon en `infra/docker-compose.yml` y su guía en `infra/README.md`

## Phase 5: US2 Notas (P2)

- [X] T011 [US2] Ficha del cliente y nota (`backend/internal/drivers/clients.go`), `client_note` en la oferta, borrado al quitar la afiliación; pruebas (SC-005)
- [X] T012 [US2] Conductor: ficha del cliente con nota y nota en la tarjeta de oferta; pruebas

## Phase 6: US3 Llegada automática (P2)

- [X] T013 [US3] `accuracy_m` en la ubicación y `trips.Service.ObserveArrival` con `near_pickup_since`; pruebas de unidad e integración
- [X] T014 [US3] Conductor: enviar la precisión del GPS; pruebas

## Phase 7: US4 Escaneo (P2)

- [X] T015 [US4] Conductor: escaneo con ML Kit, recorte manual de cuatro esquinas sin GMS y aviso de foto borrosa (`apps/kyq_driver_app/lib/onboarding/`); pruebas de recorte y nitidez

## Phase 8: US6 Mapa (P3)

- [X] T016 [US6] `ChosenDriver.zone` (res. 8, solo libres con ubicación reciente) en `affiliations`; pruebas
- [X] T017 [US6] Pasajero: interpolación y rumbo del vehículo en el seguimiento y mapa de pines dorados en el inicio; pruebas

## Phase 9: Polish

- [X] T018 Variables nuevas en `infra/README.md` y `backend/.env.example`
- [X] T019 `cd backend && go vet ./... && go test ./...` con base real; `melos run analyze` y `melos run test`
- [ ] T020 Desplegar en la VM y recorrer [quickstart.md](quickstart.md); registrar en `validation.md` (lo hace el responsable)

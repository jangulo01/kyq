# Tasks: Torre de control H3, CRM y economía unitaria

**Input**: Design documents from `/specs/007-control-tower-crm/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/api.yaml, quickstart.md

**Tests**: incluidas; la constitución (VI) exige pruebas de dominio, de integración de contratos y
de widget en la UI.

## Format: `[ID] [P?] [Story] Description`

## Phase 1: Setup

- [X] T001 Añadir `github.com/ziprecruiter/h3-go` v0.5.0 a `backend/go.mod`
- [X] T002 [P] Namespace `admin` (historial 1, 60 s, sin recuperación forzada) en `infra/centrifugo.json`
- [X] T003 [P] Añadir `maplibre_gl` y `kyq_realtime` a `apps/kyq_admin_web/pubspec.yaml`; en `apps/kyq_admin_web/web/index.html` cargar `maplibre-gl@6.4.1` (ESM y CSS) y `pmtiles@4.4.1`, registrar el protocolo `pmtiles` y publicar `globalThis.maplibregl` (research R4)

## Phase 2: Foundational

- [X] T004 Paquete `backend/internal/hexgrid/`: `CellAt`, `ParseCell`, `Center`, `Boundary`; tablas generadas desde H3 v4.4.1 (`tables.go`) y geometría portada (`geometry.go`)
- [X] T005 [P] Prueba `backend/internal/hexgrid/hexgrid_test.go` contra `testdata/h3js_fixtures.json` (204 casos de h3-js 4.4.0, incluidos pentágonos)
- [X] T006 Migración `backend/migrations/00012_control_tower.sql` según data-model.md (suspensión en `users`, `moderation_actions`, índices de `trips` y `affiliations`) y prueba de subida/bajada en `backend/internal/crm/migration_test.go`
- [X] T007 Consultas sqlc en `backend/internal/store/queries/{control,crm,moderation,finance}.sql`; columnas de suspensión en `users.sql`; `sqlc generate`
- [X] T008 [P] Modelos y métodos nuevos en `packages/kyq_api` (torre, finanzas, CRM, usuarios, moderación, salud) con `build_runner` y pruebas del cliente
- [X] T009 [P] Evento `tower.changed` y canal `Channels.adminTower` en `packages/kyq_realtime` con su prueba
- [X] T010 Fusionar `specs/007-control-tower-crm/contracts/api.yaml` en `specs/001-chosen-driver-trip-ptt/contracts/api.yaml` y el canal en `realtime.md`; prueba de que la vista 007 es válida

**Checkpoint**: H3 verificado, migración aplicada, modelos listos.

## Phase 3: User Story 1 - Torre de control en vivo (P1)

**Goal**: el admin ve conductores, viajes y solicitudes por hexágono, actualizado en vivo.

**Independent Test**: escenarios 1–6 de quickstart.md.

- [X] T011 [P] [US1] Pruebas unitarias en `backend/internal/control/tower_test.go`: agregación por celda (libres, ocupados, viaje activo en la posición del conductor o en la recogida, solicitudes y no atendidas), niveles `none`/`balanced`/`high`/`no_supply`, ubicaciones desactualizadas, sin ubicación, orden por presión
- [X] T012 [US1] Instantánea en `backend/internal/control/tower.go` y `GET /v1/admin/tower?res=` en `backend/internal/control/handlers.go` (400 `invalid_resolution`)
- [X] T013 [US1] Aviso en vivo en `backend/internal/control/notifier.go`: huella cada 3 s, `tower.changed` en `admin:tower` solo si cambia; prueba con publicador falso
- [X] T014 [US1] Canal `admin:tower` solo para admins en `backend/internal/realtime/realtime.go` (`AuthorizeRole`) y `handlers.go`, con prueba
- [X] T015 [US1] Montar el módulo y el aviso en `backend/internal/httpapi/router.go` y `backend/cmd/api/main.go`
- [X] T016 [P] [US1] Prueba de integración `backend/internal/control/integration_test.go` con base real: conductores, viajes y solicitudes sembrados → instantánea esperada
- [X] T017 [US1] Pantalla Torre en `apps/kyq_admin_web/lib/tower/`: cubit (carga, resolución, suscripción a `tower.changed` sin solapar cargas, sondeo de 30 s de respaldo), mapa MapLibre inyectable (hexágonos coloreados por nivel, conductores por estado), totales y lista de zonas con presión
- [X] T018 [P] [US1] Pruebas de cubit y widget en `apps/kyq_admin_web/test/tower/`

## Phase 4: User Story 2 - Finanzas (P1)

**Goal**: ingresos por suscripción frente a costo de infraestructura por mes.

**Independent Test**: escenarios 7–8 de quickstart.md.

- [X] T019 [P] [US2] Pruebas en `backend/internal/telemetry/finance_test.go`: agregado puro (margen, %, divisores en cero, tarifas ausentes) e integración: total del mes = suma de `GET /v1/admin/costs` del mismo mes (SC-003); conductores creados después del mes no cuentan
- [X] T020 [US2] `GET /v1/admin/finance` en `backend/internal/telemetry/finance.go` sobre `CostHandlers.breakdowns`; `GET /v1/admin/costs` deja de incluir conductores creados después del mes (research R5)
- [X] T021 [US2] Pantalla Finanzas en `apps/kyq_admin_web/lib/finance/` (tarjetas del último mes, tabla por mes con margen negativo destacado, aviso de tarifas faltantes, enlace a Costos) con su prueba

## Phase 5: User Story 3 - Fidelización (P2)

**Goal**: indicadores de afiliación, repetición, SC-008 y abandono.

**Independent Test**: escenario 9 de quickstart.md.

- [X] T022 [P] [US3] Prueba de integración `backend/internal/crm/report_test.go`: afiliaciones activas al inicio y hoy, nuevas, bajas, abandono, serie semanal, parejas repetidas, SC-008 (4 de 5 = 80 %, pendientes) e inactivos
- [X] T023 [US3] Informe en `backend/internal/crm/report.go` y `GET /v1/admin/crm` (400 `invalid_range`: fechas inválidas, invertidas o > 366 días)
- [X] T024 [US3] Pantalla Fidelización en `apps/kyq_admin_web/lib/crm/` (periodo, tarjetas, serie semanal con barras, SC-008 frente a la meta, listas de abandono) con su prueba

## Phase 6: User Story 4 - Moderación (P2)

**Goal**: suspender y reactivar usuarios con motivo y auditoría.

**Independent Test**: escenarios 10–12 de quickstart.md.

- [X] T025 [P] [US4] Pruebas de integración `backend/internal/crm/moderation_test.go`: buscar por nombre/teléfono, rol y estado; suspender exige motivo; no a admins; revoca refresh; conductor libre → OFFLINE con evento; con viaje activo sigue ocupado; ya suspendido / no suspendido → 409; reactivar; historial
- [X] T026 [US4] Moderación en `backend/internal/crm/moderation.go`: `GET /v1/admin/users`, `POST .../suspend`, `POST .../reactivate`, `GET .../moderation`
- [X] T027 [US4] `auth`: `ErrAccountSuspended` en `VerifyOTP` y `Refresh` (403 `account_suspended`) con pruebas en `backend/internal/auth/auth_test.go`; `drivers`: 409 `account_suspended` al ponerse ONLINE con prueba
- [X] T028 [US4] Pantalla Usuarios en `apps/kyq_admin_web/lib/users/` (búsqueda, filtros, suspender/reactivar con motivo, historial) con su prueba

## Phase 7: User Story 5 - Salud (P2)

**Goal**: estado y latencia de las dependencias.

**Independent Test**: escenarios 13–14 de quickstart.md.

- [X] T029 [P] [US5] Pruebas en `backend/internal/health/health_test.go` con servidores HTTP falsos: disponible, HTTP 503, tiempo agotado, desactivada, estado global, ningún secreto ni URL en el detalle
- [X] T030 [US5] Módulo `backend/internal/health/` (comprobaciones en paralelo con 3 s) y `GET /v1/admin/health`; `Ping` en `backend/internal/storage/`
- [X] T031 [US5] Pantalla Salud en `apps/kyq_admin_web/lib/health/` (tarjetas por dependencia, estado global, refresco cada 30 s) con su prueba

## Phase 8: Polish & Cross-Cutting Concerns

- [X] T032 Navegación del panel: secciones nuevas en `apps/kyq_admin_web/lib/drivers/drivers_page.dart` y rutas en `lib/app/app.dart`
- [X] T033 [P] Prueba de contrato `backend/internal/contracttest/control_tower_test.go`: todas las rutas nuevas, 403 a no admins, 403 `account_suspended` en verify/refresh
- [X] T034 [P] Prueba de privacidad: `tower.changed` no lleva datos y las rutas 007 no son accesibles a pasajeros ni conductores (`backend/internal/contracttest/privacy_test.go`)
- [X] T035 Verificación: gofmt, go vet, `go test` con base real, `melos run analyze`, `melos run test`, `flutter build web` del panel
- [ ] T036 Desplegar en la VM y recorrer quickstart.md (fuera de esta entrega: no se despliega desde la rama)

## Dependencies & Execution Order

- Setup (T001–T003) → Foundational (T004–T010) → historias.
- US1 depende de T004 (H3) y T014; US4 depende de T006–T007 (migración y consultas).
- US2, US3, US4 y US5 son independientes entre sí tras Foundational.
- Polish al final.

## Parallel Opportunities

- T002, T003; T005, T008, T009 en paralelo.
- En cada historia, las pruebas [P] y la pantalla del panel van en paralelo con el backend.

## Implementation Strategy

MVP de esta fase = US1 + US2 (torre y finanzas, P1); US3–US5 son incrementos independientes.

# Tasks: Operación del panel

**Input**: [spec.md](spec.md), [plan.md](plan.md), [research.md](research.md),
[data-model.md](data-model.md), [quickstart.md](quickstart.md)

## Format: `[ID] [P?] [Story] Description`

- **[P]**: paralelizable (archivos distintos, sin dependencias pendientes)

## Phase 1: Setup

- [ ] T001 Migración `backend/migrations/00014_ops_support.sql` (data-model.md) y consultas sqlc en `backend/internal/store/queries/` (`support.sql`, `megaphone.sql`, `domains.sql`, inspección en `control.sql`); `sqlc generate`
- [ ] T002 Contrato: rutas y esquemas nuevos en `specs/001-chosen-driver-trip-ptt/contracts/api.yaml`, eventos en `realtime.md` y vista en `specs/009-ops-console-support/contracts/api.yaml`

## Phase 2: Foundational

- [ ] T003 Sesión de alcance `support` para suspendidos en `backend/internal/auth/` (claim, login, renovación, middleware que limita rutas); pruebas
- [ ] T004 [P] Canal `admin:support` en `backend/internal/realtime/`
- [ ] T005 [P] Modelos y métodos en `packages/kyq_api` (detalle de viaje, soporte, megáfono, dominios, sesiones) y eventos `support.case`, `megaphone.started`, `megaphone.ended` en `packages/kyq_realtime`; pruebas

## Phase 3: US1 Inspección (P1)

- [ ] T006 [US1] `active_trip_id` y `trip_ids` en la instantánea de la torre; `GET /v1/admin/trips/{tripId}` con auditoría en `backend/internal/control/`; pruebas de unidad e integración
- [ ] T007 [US1] Panel: clic en conductor ocupado o hexágono → lista y detalle del viaje con refresco de 5 s y acceso a la alerta SOS (`apps/kyq_admin_web/lib/tower/`); pruebas de widget

## Phase 4: US2 Soporte (P1)

- [ ] T008 [US2] Módulo `backend/internal/support/`: servicio (abrir, mensajes, notas, estados, asignación, bandeja con filtros, cierre automático), handlers de usuario y de admin, eventos; pruebas de unidad e integración
- [ ] T009 [US2] Casos de pago en `backend/internal/trippay/`: crear al disputar o marcar no pagado, resolver al resolverse; resolver el pago desde el caso; pruebas de integración (SC-002)
- [ ] T010 [US2] Pantallas de Ayuda compartidas en `packages/kyq_ui` (lista, nuevo caso con tema y viaje, conversación en vivo) y modo "cuenta suspendida"; acceso desde las apps de pasajero y conductor; pruebas
- [ ] T011 [US2] Panel: bandeja con filtros, caso con conversación, notas internas, estado, asignación y resolución del pago (`apps/kyq_admin_web/lib/support/`); pruebas

## Phase 5: US3 Megáfono (P2)

- [ ] T012 [US3] Módulo `backend/internal/megaphone/`: destinatarios por hexágonos, sala LiveKit, tokens, avisos, fin y barrido de 60 s, registro; pruebas de unidad e integración
- [ ] T013 [US3] Conductor: cola de comunicados que espera el turno del viaje y aviso "Comunicado de Kyq" (`apps/kyq_driver_app/lib/megaphone/`); pruebas
- [ ] T014 [US3] Panel: selección de hexágonos en la torre, botón "Megáfono" (mantener pulsado) y registro de comunicados; pruebas

## Phase 6: US5 Dominios espejo (P2)

- [ ] T015 [US5] Módulo `backend/internal/domains/` (CRUD, orden, comprobación, versión, lista firmada pública) y `backend/cmd/domainsign`; pruebas
- [ ] T016 [US5] `DomainRotator` en `packages/kyq_api` (verificación Ed25519, guardado, rotación tras 3 fallos, refresco de 10 min) y uso en las tres apps; pruebas
- [ ] T017 [US5] Panel: página de dominios con estado y latencia (`apps/kyq_admin_web/lib/domains/`); pruebas

## Phase 7: US4 Sesiones sin fallos (P3)

- [ ] T018 [US4] `GET /v1/admin/health/sessions` en `backend/internal/health/` con cliente de Sentry, caché y estados; pruebas con servidor falso
- [ ] T019 [US4] Panel: tarjeta de sesiones sin fallos en Salud (`apps/kyq_admin_web/lib/health/`); pruebas

## Phase 8: Polish

- [ ] T020 Variables nuevas en `infra/README.md` y `backend/.env.example`
- [ ] T021 `cd backend && go vet ./... && go test ./...` con base real; `melos run analyze` y `melos run test`
- [ ] T022 Desplegar en la VM y recorrer [quickstart.md](quickstart.md); registrar en `validation.md` (lo hace el responsable)

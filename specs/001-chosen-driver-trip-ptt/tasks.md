---

description: "Tareas de implementación del MVP 001 Conductor Elegido + Viaje + PTT 1 a 1"
---

# Tasks: MVP Conductor Elegido + Viaje + PTT 1 a 1 (Android)

**Input**: Design documents from `/specs/001-chosen-driver-trip-ptt/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md),
[data-model.md](data-model.md), [contracts/api.yaml](contracts/api.yaml),
[contracts/realtime.md](contracts/realtime.md), [quickstart.md](quickstart.md)

**Tests**: incluidas. La constitución (principios V y VI) exige una prueba por regla RN-KYQ y
pruebas de contrato de la API.

**Organization**: tareas agrupadas por historia de usuario.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: paralelizable (archivos distintos, sin dependencias pendientes)
- **[Story]**: historia a la que pertenece (US1, US2, US3)

## Path Conventions

Monorepo: `backend/` (Go), `apps/` (Flutter), `packages/` (Dart/Flutter compartidos), `infra/`.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: dependencias, servicios locales y esqueletos de paquetes

- [X] T001 Ajustar `infra/docker-compose.yml`: quitar `redis`, añadir servicio `osrm` (imagen `osrm/osrm-backend`, perfil car, datos en `infra/data/osrm/`) y volumen para PMTiles; documentar en `infra/README.md` cómo descargar el extracto OSM de la ciudad piloto y preprocesarlo (`osrm-extract`, `osrm-partition`, `osrm-customize`)
- [X] T002 Añadir dependencias Go en `backend/go.mod`: pgx v5, goose, golang-jwt v5, google/uuid, testify, kin-openapi; generar `backend/go.sum`. River y LiveKit server SDK se añaden en T049 y T068, cuando se usan (go mod tidy elimina dependencias sin uso)
- [X] T003 [P] Crear `backend/sqlc.yaml` (engine postgresql, queries en `backend/internal/store/queries/`, esquema en `backend/migrations/`, salida `backend/internal/store/`)
- [X] T004 [P] Crear paquete `packages/kyq_api` (Dart puro, dio, freezed, json_serializable) y añadirlo al `workspace` de `pubspec.yaml`
- [X] T005 [P] Crear paquete `packages/kyq_realtime` (Dart, dependencia `centrifuge`) y añadirlo al `workspace`
- [X] T006 [P] Crear paquete Flutter `packages/kyq_ptt` (dependencias `livekit_client`, `audio_session`) y añadirlo al `workspace`
- [X] T007 [P] Crear paquete Flutter `packages/kyq_ui` (tema Kyq con `colorSchemeSeed: Color(0xFF6A1B9A)`, botones y estados vacíos comunes) y añadirlo al `workspace`
- [X] T008 [P] Añadir a `apps/kyq_driver_app/pubspec.yaml` y `apps/kyq_rider_app/pubspec.yaml`: flutter_bloc, go_router, freezed_annotation, geolocator, maplibre_gl, más los paquetes `kyq_*`; a `apps/kyq_admin_web/pubspec.yaml`: flutter_bloc, go_router, `kyq_api`, `kyq_ui`
- [X] T009 [P] Crear CI en `.github/workflows/ci.yml`: job Flutter (`melos run analyze`, `melos run test`) y job Go con servicio `postgis/postgis:17-3.5` (`go vet ./...`, `go test ./...`)
- [X] T010 [P] Crear `backend/.env.example` con `KYQ_HTTP_ADDR`, `KYQ_DATABASE_URL`, `KYQ_JWT_SECRET`, `KYQ_CENTRIFUGO_API_URL`, `KYQ_CENTRIFUGO_API_KEY`, `KYQ_CENTRIFUGO_TOKEN_SECRET`, `KYQ_LIVEKIT_URL`, `KYQ_LIVEKIT_API_KEY`, `KYQ_LIVEKIT_API_SECRET`, `KYQ_OSRM_URL`, `KYQ_TWILIO_*`, `KYQ_DEV_OTP_CODE`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: base de datos, autenticación, tiempo real, alta de conductores y admin mínimo

**⚠️ CRITICAL**: ninguna historia empieza antes de cerrar esta fase

### Backend

- [X] T011 Crear `backend/internal/config/config.go`: carga y valida las variables de `backend/.env.example`
- [X] T012 Crear `backend/cmd/migrate/main.go` (goose up/down/status sobre `KYQ_DATABASE_URL`) y `backend/migrations/00001_init.sql` con la extensión `postgis`; los UUID v7 se generan en Go (`google/uuid`)
- [X] T013 Crear `backend/migrations/00002_users_drivers.sql` con tablas `users` (`phone_e164` UNIQUE, `role` enum `passenger | driver | admin`, `display_name` 2–60 caracteres), `drivers` (`qr_token` UNIQUE, `presence` enum `offline | free | busy`, `last_location geography(Point)`, `busy_until_estimate` NULL), `subscriptions` (`paid_until`), `driver_documents` (`doc_type` enum `license | mandatory_insurance | vehicle_registration`, `expires_at date`, `approved_by` NULL) y `refresh_tokens` (`token_hash` UNIQUE, `expires_at`, `rotated_at`) según [data-model.md](data-model.md)
- [X] T014 Crear `backend/internal/store/db.go` (pool pgx, transacciones) y consultas sqlc de usuarios y conductores en `backend/internal/store/queries/users.sql` y `drivers.sql`
- [X] T015 [P] Crear `backend/internal/httpapi/errors.go` y `middleware.go`: respuesta `Error{code,message}`, request ID, logging slog, recuperación de pánicos, límite de tamaño de cuerpo
- [X] T016 [P] Escribir pruebas de `backend/internal/auth/` en `backend/internal/auth/auth_test.go`: OTP válido/ inválido/caducado, emisión de JWT 15 min, rotación de refresh token 30 días, rechazo de refresh reutilizado
- [X] T017 Implementar `backend/internal/auth/`: interfaz `OTPSender` con implementaciones Twilio Verify y dev (código fijo `KYQ_DEV_OTP_CODE`), handlers `/v1/auth/otp/request`, `/v1/auth/otp/verify`, `/v1/auth/refresh`, middleware JWT con rol; límite de 5 solicitudes OTP por teléfono y hora
- [X] T018 [P] Implementar `backend/internal/realtime/`: cliente de la API HTTP de Centrifugo (`Publish`), emisión de tokens de conexión y suscripción, y autorización de canales `user:{id}`, `driver_presence:{driverId}` (solo pasajeros afiliados), `trip:{tripId}` (solo participantes) según [contracts/realtime.md](contracts/realtime.md); handlers `/v1/realtime/token` y `/v1/realtime/subscription-token`
- [X] T019 [P] Escribir `backend/internal/drivers/gate_test.go` con las reglas RN-KYQ-002, RN-KYQ-003 (gracia 72 h y viaje en curso) y RN-KYQ-016 (documento faltante, no aprobado o con `expires_at <= hoy`)
- [X] T020 Implementar `backend/internal/drivers/gate.go`: `EvaluateOnline(subscription, documents, hasActiveTrip, now)` equivalente a `packages/kyq_domain/lib/src/online_gate.dart`
- [X] T021 Implementar `backend/internal/admin/`: `GET/POST /v1/admin/drivers`, `PUT /v1/admin/drivers/{driverId}/subscription`, `PUT /v1/admin/drivers/{driverId}/documents/{docType}`; alta de conductor genera `qr_token` aleatorio de 128 bits; solo rol `admin`
- [X] T022 Registrar rutas de auth, realtime y admin en `backend/internal/httpapi/router.go` y cablear dependencias en `backend/cmd/api/main.go`
- [X] T023 [P] Crear `backend/internal/contracttest/contract_test.go`: valida respuestas reales contra `specs/001-chosen-driver-trip-ptt/contracts/api.yaml` (kin-openapi) para auth y realtime; admin se cubre con la prueba de integración `backend/internal/admin/admin_test.go`
- [X] T024 Crear comando de semilla `backend/cmd/seed/main.go`: un admin con teléfono de `KYQ_SEED_ADMIN_PHONE`

### Clientes

- [X] T025 [P] Implementar en `packages/kyq_api/lib/`: cliente dio con base URL, interceptor de JWT con refresco automático, modelos freezed de `Error`, `Tokens`, `DriverMe`, `ChosenDriver`, `Trip`, `FareQuote`, `FareProposal` según [contracts/api.yaml](contracts/api.yaml); pruebas en `packages/kyq_api/test/`
- [X] T026 [P] Implementar en `packages/kyq_realtime/lib/`: conexión Centrifugo con token del backend, suscripción tipada a `user:`, `driver_presence:` y `trip:`, decodificación de los eventos de [contracts/realtime.md](contracts/realtime.md) y reconexión con recuperación; pruebas de decodificación en `packages/kyq_realtime/test/`
- [X] T027 [P] Crear flujo de login por OTP (pantalla teléfono, pantalla código, nombre en primer registro) en `packages/kyq_ui/lib/src/auth/` con `AuthCubit` y almacenamiento seguro de tokens; prueba de widget en `packages/kyq_ui/test/auth_flow_test.dart`
- [X] T028 Montar en `apps/kyq_driver_app/lib/app/` y `apps/kyq_rider_app/lib/app/` el router go_router con guardia de sesión y el login de T027
- [X] T029 Implementar en `apps/kyq_admin_web/lib/drivers/`: lista de conductores, alta, registro de `paid_until` y aprobación de los tres documentos con su vencimiento (FR-004)

**Checkpoint**: login funciona en las tres apps; un admin da de alta un conductor con suscripción y documentos

---

## Phase 3: User Story 1 - Afiliar un Conductor Elegido por QR (Priority: P1) 🎯 MVP

**Goal**: el pasajero escanea el QR del conductor y queda vinculado en ambas apps

**Independent Test**: escenario 1 de [quickstart.md](quickstart.md)

### Tests for User Story 1

- [X] T030 [P] [US1] Escribir `backend/internal/affiliations/service_test.go`: alta por QR, re-escaneo sin duplicado (responde 200), QR inexistente (404), baja lógica con `removed_at` y reactivación al re-escanear, cartera del conductor (RN-KYQ-005)
- [X] T031 [P] [US1] Prueba de widget en `apps/kyq_rider_app/test/chosen_drivers/scan_result_test.dart`: QR válido muestra confirmación; inválido muestra error sin crear vínculo

### Implementation for User Story 1

- [X] T032 [US1] Crear `backend/migrations/00003_affiliations.sql`: tabla `affiliations` (PK compuesta `passenger_id`, `driver_id`; `source` enum `qr_scan`; `created_at`; `removed_at` NULL) y consultas en `backend/internal/store/queries/affiliations.sql`
- [X] T033 [US1] Implementar `backend/internal/affiliations/`: `POST /v1/affiliations`, `GET /v1/affiliations`, `DELETE /v1/affiliations/{driverId}`, `GET /v1/driver/clients`
- [X] T034 [US1] Implementar `GET /v1/driver/me` en `backend/internal/drivers/handlers.go` (perfil, `qr_token`, presencia, suscripción, documentos, `can_go_online`, `block_reason`)
- [X] T035 [P] [US1] Pantalla "Mi código QR" en `apps/kyq_driver_app/lib/onboarding/my_qr_page.dart` con `qr_flutter` (contenido `kyq://driver/{qr_token}`) y exportación a PDF imprimible
- [X] T036 [P] [US1] Pantalla "Mis clientes" en `apps/kyq_driver_app/lib/onboarding/clients_page.dart` usando `GET /v1/driver/clients`
- [X] T037 [US1] Escáner en `apps/kyq_rider_app/lib/chosen_drivers/scan_page.dart` con `mobile_scanner`, que acepta solo `kyq://driver/{token}` y llama a `POST /v1/affiliations`
- [X] T038 [US1] Lista "Mis Conductores Elegidos" con eliminar en `apps/kyq_rider_app/lib/chosen_drivers/chosen_drivers_page.dart` y `chosen_drivers_cubit.dart`

**Checkpoint**: US1 funciona y se valida sola

---

## Phase 4: User Story 2 - Ver disponibilidad y pedir viaje (Priority: P1)

**Goal**: presencia en vivo, solicitud nominal con tarifa sugerida, edición o negociación de
tarifa, ciclo completo del viaje y liquidación 100 % conductor

**Independent Test**: escenarios 2, 3, 6, 8–12 de [quickstart.md](quickstart.md)

**Depends on**: US1 (el pasajero necesita un conductor afiliado)

### Tests for User Story 2

- [X] T039 [P] [US2] Escribir `backend/internal/fares/quote_test.go`: tarifa = `max(minimum, base + per_km × km + per_minute × min)` con redondeo, y RN-KYQ-013 (tabla por ciudad)
- [X] T040 [P] [US2] Escribir `backend/internal/trips/statemachine_test.go`: todas las transiciones válidas e inválidas de la máquina de [data-model.md](data-model.md), incluidos FARE_PENDING, NEGOTIATION_PENDING y NEGOTIATING
- [X] T041 [P] [US2] Escribir `backend/internal/trips/rules_test.go`: autorización por parte y rol de la descripción de [contracts/api.yaml](contracts/api.yaml) (404 a terceros, 403 por rol o por aceptar la propia propuesta), RN-KYQ-001 (`platform_commission_minor` = 0 y `driver_payout_minor` = `agreed_fare_minor`), RN-KYQ-007 (oferta exclusiva 25 s), FR-010a (confirmación 30 s), FR-010c (propuesta 30 s, negociación 3 min, rechazo vuelve a REQUESTED con 25 s nuevos), FR-012 (un viaje activo por conductor)
- [X] T042 [P] [US2] Escribir `backend/internal/trips/integration_test.go` contra PostgreSQL: pasajero pide, conductor acepta, avanza a COMPLETED; dos pasajeros piden al mismo conductor a la vez y solo uno obtiene oferta
- [ ] T043 [P] [US2] Pruebas bloc en `apps/kyq_driver_app/test/offers/offer_cubit_test.dart` y `apps/kyq_rider_app/test/request/request_cubit_test.dart`: cuenta atrás, aceptar, cambiar tarifa, negociar y vencimientos

### Implementation for User Story 2 — backend

- [X] T044 [US2] Crear `backend/migrations/00004_trips.sql`: `fare_tables` (`currency char(3)`, importes ≥ 0), `trips` (estados y `cancel_reason` del data model, CHECK `platform_commission_minor = 0`, índice único parcial de viaje activo por `driver_id`), `fare_proposals` (`amount_minor > 0`, `status` enum `open | accepted | superseded | expired`, una `open` por viaje) y consultas en `backend/internal/store/queries/trips.sql`
- [X] T045 [P] [US2] Implementar `backend/internal/fares/route.go`: interfaz `RouteEstimator` y cliente OSRM (`/route/v1/driving`) que devuelve distancia en metros y duración en segundos
- [X] T046 [US2] Implementar `backend/internal/fares/`: `PUT /v1/admin/fare-tables/{cityCode}` y `POST /v1/fares/quote`
- [X] T047 [US2] Implementar `backend/internal/drivers/presence.go`: `POST /v1/driver/presence` usando el gate de T020 (409 con `subscription_suspended`, `kyc_expired` o `trip_in_progress`), `POST /v1/driver/location`, publicación `driver.presence` y `trip.location`; recálculo de `busy_until_estimate` con OSRM como máximo cada 30 s
- [X] T048 [US2] Implementar `backend/internal/trips/statemachine.go` (transiciones puras) y `service.go` (transacciones, validación de afiliación y conductor `free`)
- [X] T049 [US2] (Hecho con columna `respond_by` y barrido SQL cada segundo en `backend/internal/trips/service.go` en lugar de River; ver research R10) Implementar trabajos River en `backend/internal/trips/jobs.go`: vencimiento de oferta 25 s, confirmación de tarifa 30 s, propuesta 30 s y negociación 3 min; cada trabajo revalida el estado antes de actuar
- [X] T050 [US2] Implementar handlers en `backend/internal/trips/handlers.go`: `POST /v1/trips`, `GET /v1/trips/{tripId}`, `accept`, `reject`, `negotiation`, `negotiation/response`, `proposals`, `proposals/{proposalId}/{decision}`, `arrive`, `start`, `complete`, `cancel`
- [X] T051 [US2] Publicar eventos `trip.offer`, `trip.offer_closed`, `trip.status`, `trip.fare_proposal` y `trip.negotiation_requested` desde `backend/internal/trips/events.go`
- [X] T052 [US2] Arrancar el cliente River junto al servidor en `backend/cmd/api/main.go` y registrar rutas en `backend/internal/httpapi/router.go`
- [X] T053 [P] [US2] Tabla de tarifas en `apps/kyq_admin_web/lib/fares/fare_table_page.dart` (FR-010b)

### Implementation for User Story 2 — app del conductor

- [ ] T054 [US2] Servicio en primer plano en `apps/kyq_driver_app/lib/background/foreground_service.dart` con `flutter_foreground_task` (tipos `location|microphone|mediaPlayback`) mientras está ONLINE; declarar permisos en `apps/kyq_driver_app/android/app/src/main/AndroidManifest.xml`
- [ ] T055 [US2] Envío de ubicación cada 3 s en `apps/kyq_driver_app/lib/background/location_reporter.dart` con `geolocator` (`forceLocationManager` si no hay Google Play Services)
- [ ] T056 [US2] Pantalla de inicio con interruptor ONLINE, motivo de bloqueo y asistente de permisos (ubicación en segundo plano, micrófono, exclusión de batería) en `apps/kyq_driver_app/lib/onboarding/home_page.dart`
- [ ] T057 [US2] Tarjeta de oferta con cuenta atrás de 25 s, aceptar, aceptar con otra tarifa, proponer negociar y rechazar en `apps/kyq_driver_app/lib/offers/`
- [X] T058 [US2] Pantalla de negociación compartida (propuesta actual, contrapropuesta, aceptar, abandonar, cuenta atrás 30 s y total 3 min) en `packages/kyq_ui/lib/src/negotiation/negotiation_panel.dart`
- [ ] T059 [US2] Pantalla del viaje con botones Llegué / Iniciar / Finalizar, cancelar antes de IN_PROGRESS y abrir ruta en app externa (`geo:` / Waze / Google Maps) en `apps/kyq_driver_app/lib/trip/trip_page.dart`
- [ ] T060 [US2] Resumen del viaje con tarifa acordada, 100 % para el conductor y comisión 0 en `apps/kyq_driver_app/lib/trip/trip_summary_page.dart`

### Implementation for User Story 2 — app del pasajero

- [ ] T061 [US2] Presencia en vivo de los conductores elegidos (Libre / Ocupado + minutos / Desconectado) en `apps/kyq_rider_app/lib/chosen_drivers/chosen_drivers_page.dart` suscribiéndose a `driver_presence:{driverId}`
- [ ] T062 [US2] Pantalla de solicitud con mapa MapLibre (PMTiles), origen por ubicación actual, selección de destino, cotización y botón pedir en `apps/kyq_rider_app/lib/request/request_page.dart`
- [ ] T063 [US2] Espera de respuesta, confirmación de nueva tarifa en 30 s y aceptación de negociación usando T058 en `apps/kyq_rider_app/lib/request/awaiting_driver_page.dart`
- [ ] T064 [US2] Seguimiento del viaje con posición del conductor (`trip:{tripId}`), estado y cancelar en `apps/kyq_rider_app/lib/trip/trip_page.dart`, y resumen final en `trip_summary_page.dart`

**Checkpoint**: US1 + US2 funcionan; viaje completo con las tres vías de tarifa

---

## Phase 5: User Story 3 - Walkie-talkie 1 a 1 (Priority: P2)

**Goal**: canal de voz privado desde ACCEPTED hasta 15 min después del viaje, con turno,
reproducción automática y atenuación del GPS

**Independent Test**: escenarios 4, 5 y 7 de [quickstart.md](quickstart.md)

**Depends on**: US2 (el canal se abre al aceptar un viaje)

### Tests for User Story 3

- [X] T065 [P] [US3] Escribir `backend/internal/ptt/service_test.go`: apertura al ACCEPTED (RN-KYQ-009), token solo para participantes, turno exclusivo con caducidad de 60 s, 409 si ocupado, cierre a `completed_at + 15 min` y al cancelar (RN-KYQ-014), 410 tras el cierre
- [X] T066 [P] [US3] Pruebas en `packages/kyq_ptt/test/ptt_controller_test.dart`: pulsar pide turno y activa micrófono, soltar libera, turno denegado muestra ocupado, voz entrante pide foco con atenuación y lo libera al terminar (RN-KYQ-011)

### Implementation for User Story 3

- [X] T067 [US3] Crear `backend/migrations/00005_ptt.sql`: `ptt_channels` (`room_name` UNIQUE `trip-{tripId}`, `opened_at`, `closes_at` NULL, `closed_at` NULL, `floor_holder_id` NULL, `floor_expires_at` NULL) y consultas en `backend/internal/store/queries/ptt.sql`
- [X] T068 [US3] Implementar `backend/internal/ptt/`: creación de sala LiveKit al ACCEPTED, `POST /v1/trips/{tripId}/ptt/token` (permiso de publicar audio solo para los dos participantes, TTL hasta `closes_at`), `POST` y `DELETE /v1/trips/{tripId}/ptt/floor` con `UPDATE ... WHERE floor_holder_id IS NULL OR floor_expires_at < now()`
- [X] T069 [US3] Trabajo River de cierre en `backend/internal/ptt/jobs.go`: borra la sala en LiveKit, marca `closed_at` y publica `ptt.closed`; programarlo desde la transición a COMPLETED (15 min) y CANCELLED (inmediato) en `backend/internal/trips/service.go` (hecho con barrido `ptt.Service.CloseDue` cada segundo en lugar de River, ver R10)
- [X] T070 [US3] Implementar `packages/kyq_ptt/lib/src/ptt_controller.dart`: conexión a la sala al ACCEPTED con micrófono publicado y silenciado, pedir/liberar turno, mensajes de datos `floor.taken` / `floor.released`, reconexión
- [X] T071 [US3] Implementar `packages/kyq_ptt/lib/src/audio_focus.dart` con `audio_session`: foco transitorio con atenuación (`gainTransientMayDuck`) al reproducir voz entrante y altavoz por defecto
- [X] T072 [US3] Generar tonos propios de inicio, fin y ocupado (síntesis PCM, sin assets de terceros) en `packages/kyq_ptt/lib/src/tones.dart`
- [X] T073 [US3] Botón PTT (mantener pulsado, indicador de quién habla, estado ocupado, permiso de micrófono denegado) en `packages/kyq_ptt/lib/src/ptt_button.dart`; prueba de widget en `packages/kyq_ptt/test/ptt_button_test.dart`
- [X] T074 [US3] Integrar `PttButton` en `apps/kyq_driver_app/lib/trip/trip_page.dart` y `trip_summary_page.dart` (ventana de 15 min) y mantener la sala activa en segundo plano mediante el servicio de T054
- [X] T075 [US3] Integrar `PttButton` en `apps/kyq_rider_app/lib/trip/trip_page.dart` y `trip_summary_page.dart`; ocultarlo al recibir `ptt.closed`

**Checkpoint**: las tres historias funcionan

---

## Phase 6: Polish & Cross-Cutting Concerns

- [ ] T076 [P] Integrar Sentry (Flutter y Go) con datos personales filtrados en `apps/*/lib/app/bootstrap.dart` y `backend/internal/observability/sentry.go`
- [ ] T077 [P] Métricas de coste por conductor (minutos de voz desde webhooks de LiveKit, eventos publicados, cotizaciones OSRM) en `backend/internal/telemetry/` (constitución VII)
- [ ] T078 [P] Comprobar que ninguna respuesta ni evento expone `phone_e164` de la otra parte (FR-020) con una prueba en `backend/internal/contracttest/privacy_test.go`
- [ ] T079 Probar en un teléfono sin Google Play Services (Huawei) los escenarios 2–7 de [quickstart.md](quickstart.md) y registrar resultados en `specs/001-chosen-driver-trip-ptt/validation.md`
- [ ] T080 Medir SC-002, SC-004 y SC-005 según la sección "Medición" de [quickstart.md](quickstart.md) y anotarlos en `specs/001-chosen-driver-trip-ptt/validation.md`
- [ ] T081 Actualizar `README.md` con el arranque completo (migraciones, semilla, OSRM, PMTiles)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: sin dependencias
- **Foundational (Phase 2)**: depende de Setup; bloquea todas las historias
- **US1 (Phase 3)**: depende de Foundational
- **US2 (Phase 4)**: depende de US1 (afiliación requerida para pedir viaje)
- **US3 (Phase 5)**: depende de US2 (el canal nace al aceptar un viaje)
- **Polish (Phase 6)**: depende de las historias que se entreguen

### Within Each User Story

- Pruebas primero y fallando; migración → consultas → servicio → handlers → UI
- T020 (gate) antes de T047 (presencia); T048 antes de T049–T051; T054 antes de T074

### Parallel Opportunities

- Setup: T003–T010 en paralelo tras T001–T002
- Foundational: T015, T016, T018, T019, T023 en paralelo; clientes T025–T027 en paralelo con el backend
- US1: T030 y T031 en paralelo; T035 y T036 en paralelo
- US2: T039–T043 en paralelo; T045 y T053 en paralelo con el resto del backend; app del conductor (T054–T060) y del pasajero (T061–T064) en paralelo una vez cerrado T050
- US3: T065 y T066 en paralelo; T070–T073 (cliente) en paralelo con T067–T069 (backend)

---

## Parallel Example: User Story 2

```bash
# Pruebas de US2 a la vez:
Task: "backend/internal/fares/quote_test.go"
Task: "backend/internal/trips/statemachine_test.go"
Task: "backend/internal/trips/rules_test.go"
Task: "backend/internal/trips/integration_test.go"

# Apps cuando T050 esté listo:
Task: "apps/kyq_driver_app/lib/offers/ (T057)"
Task: "apps/kyq_rider_app/lib/request/request_page.dart (T062)"
```

---

## Implementation Strategy

### MVP First

1. Setup + Foundational
2. US1 → validar escenario 1 (vínculo QR, ya entrega valor)
3. US2 → validar escenarios 2, 3, 6, 8–12 → piloto interno de viajes
4. US3 → validar escenarios 4, 5, 7 → piloto con usuarios

### Incremental Delivery

Cada fase cierra con su checkpoint y una demo en dos teléfonos. US1 puede publicarse como
prueba cerrada antes de tener viajes, para que los conductores empiecen a afiliar clientes.

---

## Notes

- [P] = archivos distintos, sin dependencias pendientes
- Hacer commit por tarea o grupo lógico
- Verificar que las pruebas fallan antes de implementar
- Toda tarea respeta el principio I de la constitución: nada de recursos ni código de terceros

# Tasks: Botón SOS, viaje compartido y consola de emergencias

**Input**: Design documents from `/specs/003-sos-emergency-console/`

**Tests**: incluidas (constitución V y VI).

## Phase 1: Setup

- [X] T001 Añadir `redis` y `egress` (LiveKit Egress, versión compatible con livekit-server v1.9.0) a `infra/docker-compose.yml` con su configuración (`infra/egress.yaml`: api key/secret de LiveKit, Redis, salida S3 a MinIO) y Redis en `infra/livekit.yaml`; bucket `kyq-sos` con regla de expiración de 90 días en el job de inicialización de MinIO
- [X] T002 [P] Añadir `share_plus` y lo necesario para el SOS a las apps (`apps/kyq_driver_app/pubspec.yaml`, `apps/kyq_rider_app/pubspec.yaml`), con versiones de ≥ 2 semanas compatibles con compileSdk 36 / minSdk 24

## Phase 2: Foundational

- [X] T003 Migración `backend/migrations/00008_safety.sql` según data-model.md (`sos_alerts` con estados `open | claimed | closed | cancelled_by_user`, desenlaces `false_alarm | resolved | escalated_authorities | no_response`, índice único parcial de una alerta abierta por persona y viaje; `sos_locations` PK `alert_id, at`; `sos_notes`; `share_links` token de 128 bits; `emergency_contacts` máximo 3 por usuario; `safety_pins` bcrypt; `users.emergency_operator`, `users.on_duty` — implementado como tabla `emergency_operators`, ver data-model.md) y consultas sqlc en `backend/internal/store/queries/safety.sql`
- [X] T004 Ampliar el autorizador de canales Centrifugo (`backend/internal/realtime/`) con el namespace `ops` (solo administradores con `emergency_operator`) y `sos:{alertId}` (operadores); añadir los namespaces a `infra/centrifugo.json`
- [X] T005 [P] Ampliar el cliente LiveKit (`backend/internal/ptt/livekit.go`) con token de usuario SOS (publica micrófono desde el inicio), token de operador (sin publicar) e inicio/parada de `RoomCompositeEgress` solo audio hacia S3
- [X] T006 [P] Modelos y métodos de seguridad en `packages/kyq_api` y eventos `sos.*` en `packages/kyq_realtime`, con pruebas

## Phase 3: User Story 1 - Botón SOS (P1)

- [X] T007 [P] [US1] Pruebas de integración en `backend/internal/safety/service_test.go`: alerta solo en la ventana del viaje (ACCEPTED hasta 15 min tras COMPLETED); una abierta por persona; sala y egress creados; lotes de ubicación guardados y publicados en `sos:{id}`; la otra parte no recibe eventos (FR-006); cancelar con PIN correcto / sin PIN / 5 intentos (RN-KYQ-015)
- [X] T008 [US1] Módulo `backend/internal/safety/`: `POST /v1/trips/{tripId}/sos`, `POST /v1/sos/{id}/locations`, `POST /v1/sos/{id}/cancel`, `GET /v1/sos/{id}/token`; montar en router y main
- [X] T009 [US1] `SosButton` (pulsación de 2 s con progreso y vibración), pantalla de alerta activa ("Ayuda en camino", estado de conexión, cancelar con PIN, llamar al 123) y conexión de voz en `packages/kyq_ui/lib/src/safety/`, reutilizando `kyq_ptt` para la sala
- [X] T010 [US1] Integrar el SOS en las pantallas de viaje del pasajero (`apps/kyq_rider_app/lib/trip/trip_page.dart`) y del conductor (`apps/kyq_driver_app/lib/trip/trip_page.dart`), con envío de ubicación a 1 Hz (conductor: servicio en primer plano; pasajero: stream con aviso de no cerrar la app)
- [X] T011 [P] [US1] Pruebas de widget y cubit del SOS en ambas apps y en `packages/kyq_ui/test/safety/`

## Phase 4: User Story 2 - Consola de emergencias (P1)

- [X] T012 [P] [US2] Pruebas en `backend/internal/safety/console_test.go`: tomar/liberar (solo quien toma puede publicar en LiveKit), notas, cierre con desenlace obligatorio detiene la ubicación y el egress, escalada SMS a los 60 s una sola vez, acceso solo con `emergency_operator`, auditoría
- [X] T013 [US2] Rutas de consola en `backend/internal/safety/console.go`: `GET /v1/ops/sos` (abiertas e historial filtrable), `GET /v1/ops/sos/{id}` (viaje, personas, recorrido, URL firmada de la grabación), `POST /v1/ops/sos/{id}/claim|release|notes|close`, `POST /v1/ops/sos/{id}/token`; barrido de escalada cada 10 s
- [X] T014 [US2] Consola en `apps/kyq_admin_web/lib/emergencies/`: cola en vivo con aviso sonoro y tiempo de espera, detalle con mapa MapLibre en vivo y recorrido, escuchar/hablar (LiveKit web), notas, cierre, copiar ubicación, historial y reproducción de la grabación
- [X] T015 [P] [US2] Pruebas de widget de la consola en `apps/kyq_admin_web/test/emergencies/`

## Phase 5: User Story 3 - Viaje compartido (P2)

- [X] T016 [P] [US3] Pruebas en `backend/internal/safety/share_test.go`: token no adivinable; respuesta sin teléfonos ni documentos (FR-015); "finalizado" y sin datos 15 min tras terminar
- [X] T017 [US3] `POST /v1/trips/{tripId}/share`, `GET /v1/share/{token}` y página `GET /s/{token}` (HTML embebido en `backend/web/share/` con MapLibre GL JS de versión fijada, sondeo cada 3 s)
- [X] T018 [US3] Botón "Compartir viaje" con el menú del sistema en ambas apps

## Phase 6: User Story 4 - Contactos y PIN (P2)

- [X] T019 [P] [US4] Pruebas: máximo 3 contactos, teléfono E.164, PIN bcrypt, SMS a cada contacto con el enlace al crear la alerta
- [X] T020 [US4] Rutas `GET/PUT /v1/me/emergency-contacts`, `PUT /v1/me/safety-pin` y envío de SMS al crear la alerta en `backend/internal/safety/`
- [X] T021 [US4] Pantalla "Seguridad" (contactos y PIN) en `packages/kyq_ui/lib/src/safety/` enlazada desde ambas apps, con pruebas

## Phase 7: Polish

- [X] T022 [P] Ampliar la prueba de privacidad (`backend/internal/contracttest/privacy_test.go`) con el enlace compartido y los eventos SOS
- [X] T023 Fusionar el contrato de 003 en `specs/001-chosen-driver-trip-ptt/contracts/api.yaml` y validarlo en las pruebas de contrato
- [ ] T024 Desplegar en la VM (redis, egress, migración 00008) y recorrer quickstart.md en el teléfono y el navegador; resultados en `specs/003-sos-emergency-console/validation.md`
- [X] T025 Actualizar `README.md` e `infra/README.md`

## Dependencies

Setup → Foundational → US1 → US2 (la consola necesita alertas) → US3 y US4 en paralelo → Polish.

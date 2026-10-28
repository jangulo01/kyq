# Tasks: PTT extra — pre-consulta, botón físico y burbuja

**Input**: Design documents from `/specs/005-ptt-extras/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/api.yaml, quickstart.md

**Tests**: incluidas; la constitución (V, VI) exige una prueba por regla RN-KYQ y pruebas de
integración de contratos.

## Format: `[ID] [P?] [Story] Description`

## Phase 1: Setup

- [X] T001 Añadir `shared_preferences` (2.5.6, ya en el lockfile) a `apps/kyq_driver_app/pubspec.yaml` y el permiso `SYSTEM_ALERT_WINDOW` a su `AndroidManifest.xml`

## Phase 2: Foundational

- [X] T002 Migración `backend/migrations/00010_ptt_extras.sql`: `drivers.accepts_preconsults`, `affiliations.preconsults_blocked` y tabla `ptt_preconsults` con índices según data-model.md
- [X] T003 Consultas sqlc en `backend/internal/store/queries/preconsults.sql` y `sqlc generate`
- [X] T004 Extraer el turno a prueba de fallos (conceder con deshacer, retirar antes de liberar, barrido de turnos vencidos) a `backend/internal/ptt/floor.go` y usarlo desde el canal del viaje sin cambiar su comportamiento (pruebas de 001 en verde)
- [X] T005 [P] Modelos `Preconsult` y `PreconsultSettings` y métodos del cliente en `packages/kyq_api` (`preconsult_models.dart`, `build_runner`) con pruebas
- [X] T006 [P] Eventos `preconsult.opened`, `preconsult.joined` y `preconsult.closed` en `packages/kyq_realtime/lib/src/events.dart` con pruebas
- [X] T007 Fusionar `specs/005-ptt-extras/contracts/api.yaml` en el contrato principal `specs/001-chosen-driver-trip-ptt/contracts/api.yaml`

**Checkpoint**: esquema, consultas, turno compartido y clientes listos.

## Phase 3: User Story 1 - Preguntar por voz al conductor (P1)

**Goal**: el pasajero abre una consulta en vivo y el conductor la oye y responde.

**Independent Test**: escenarios 3–10 de quickstart.md.

- [X] T008 [P] [US1] Pruebas de integración RN-KYQ-010 en `backend/internal/ptt/preconsult_test.go`: solo afiliado, activado, no silenciado y conductor libre; idempotencia con el mismo conductor; una abierta por persona; 3/h y 6/día; el pasajero no habla antes de que el conductor se una; turno de 15 s exclusivo y a prueba de fallos; cierre por 2 min, 30 s sin unirse, terminar, conductor ocupado; eventos; borrado a 30 días; estados HTTP
- [X] T009 [US1] Servicio de consulta en `backend/internal/ptt/preconsult.go` (abrir, ver, terminar, token con unión del conductor, turno, barrido de cierre y borrado) integrado en `RunSweeper`
- [X] T010 [US1] Rutas en `backend/internal/ptt/preconsult_handlers.go`, registradas por `ptt.Handlers` y cableadas en `backend/cmd/api/main.go`
- [X] T011 [P] [US1] Atribuir los segundos de voz de las salas `pre-{id}` al conductor en `backend/internal/telemetry/livekit_webhook.go` con prueba
- [X] T012 [P] [US1] Prueba de contrato de las rutas nuevas en `backend/internal/contracttest/preconsult_test.go`
- [X] T013 [P] [US1] `PreconsultPttApi`, `PttController.preconsult` (soltar 1 s antes del turno de 15 s) y el tono `incoming` en `packages/kyq_ptt`
- [X] T014 [US1] Consulta activa del conductor en `apps/kyq_driver_app/lib/preconsult/preconsult_cubit.dart`: unirse sola al recibir `preconsult.opened` con tono, cerrar con `preconsult.closed`, terminar; tarjeta con el botón PTT en el inicio y la bandeja
- [X] T015 [US1] Pantalla de consulta del pasajero en `apps/kyq_rider_app/lib/preconsult/` (abrir, esperar al conductor, hablar, tiempo restante, terminar, pedir viaje, motivos de cierre) y botón "Preguntar por voz" en la lista de Conductores Elegidos
- [X] T016 [P] [US1] Pruebas de cubit y widget en `apps/kyq_driver_app/test/preconsult/` y `apps/kyq_rider_app/test/preconsult/`

## Phase 4: User Story 2 - El conductor decide quién le consulta (P1)

**Goal**: interruptor global, silencio por cliente y bandeja de 24 h.

**Independent Test**: escenarios 1–3 y 11 de quickstart.md.

- [X] T017 [US2] Ajustes y bandeja en el servicio y rutas (`GET/PUT /v1/driver/preconsults/settings`, `PUT /v1/driver/clients/{passengerId}/preconsults`, `GET /v1/driver/preconsults`, `GET /v1/preconsults/drivers`) cerrando la consulta afectada al desactivar o silenciar
- [X] T018 [US2] Página de ajustes y bandeja en `apps/kyq_driver_app/lib/preconsult/` (interruptor, clientes con silencio, preferencias del manos libres) con acceso desde el inicio

## Phase 5: User Story 3 - Botón del volante o del auricular (P1)

**Goal**: botón multimedia como PTT con el canal abierto.

**Independent Test**: escenarios 13–16 de quickstart.md.

- [X] T019 [P] [US3] `HandsFreePtt` en `packages/kyq_ptt/lib/src/hands_free.dart` (pila de canales, clic alterna, pulsación ≥ 0,5 s mantiene, sesión multimedia solo con canal) y pruebas RN-KYQ-012 en `packages/kyq_ptt/test/hands_free_test.dart`
- [X] T020 [US3] Capa Kotlin `HandsFreeBridge.kt` (MediaSession del sistema → `button_down`/`button_up`) y `MainActivity.kt` con los canales `kyq/hands_free`
- [X] T021 [US3] Puente Dart `apps/kyq_driver_app/lib/handsfree/platform_hands_free.dart`, preferencias y adjuntar el canal del viaje y la consulta activa en `app.dart`

## Phase 6: User Story 4 - Burbuja flotante (P2)

**Goal**: burbuja sobre Waze/Google Maps con el canal abierto y Kyq en segundo plano.

**Independent Test**: escenario 12 de quickstart.md.

- [X] T022 [US4] Burbuja nativa en `HandsFreeBridge.kt` (`TYPE_APPLICATION_OVERLAY`, colores por estado, arrastre que suelta el turno) y visibilidad desde `HandsFreePtt` con el ciclo de vida de la app
- [X] T023 [US4] Pedir el permiso de superposición desde los ajustes con explicación (`permission_handler`)

## Phase 7: Polish

- [X] T024 gofmt, go vet, `go test ./...` con la base de pruebas, `melos run analyze`, `melos run test`
- [X] T025 APK debug de pasajero y conductor con las `dart-define` de la VM
- [X] T026 Revisar la constitución (I, II, V) en el plan; el grafo de `graphify` se regenera al integrar en la rama principal (no se versiona `graphify-out/`)

## Dependencies

- T002 → T003 → T004 → T009 → T010, T017.
- T005, T006 → T013 → T014, T015.
- T019 → T021 → T022.
- US1 y US2 comparten servicio; US3 y US4 comparten `HandsFreePtt` y la capa nativa.

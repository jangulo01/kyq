# Tasks: Radio Kyq

**Input**: [spec.md](spec.md), [phva.md](phva.md), [plan.md](plan.md), [research.md](research.md),
[data-model.md](data-model.md), [contracts/api.yaml](contracts/api.yaml), [quickstart.md](quickstart.md)

## Format: `[ID] [P?] [Story] Description`

- **[P]**: paralelizable (archivos distintos, sin dependencias pendientes)
- Cada tarea incluye sus pruebas (TDD: escribir la prueba primero y verla fallar).
- Todo en español (comentarios, textos de UI, mensajes de commit); identificadores en inglés.
- Principio I: ningún texto, ícono, color o sonido de la app walkie-talkie de terceros.

## Phase 1: Setup

- [X] T001 Enmienda de la constitución 1.0.0 → 1.1.0 en `.specify/memory/constitution.md`: RN-KYQ-017 "Radio Kyq permanente con registro a demanda" (Sync Impact Report y principio V: RN-KYQ-001 a 017); prueba de regla en `backend/internal/radio/rules_test.go` que falla si se graba el canal del viaje o la consulta previa, o si una respuesta de `/v1/radio/*` contiene un teléfono
- [X] T002 Contrato: fusionar rutas y esquemas de `specs/011-radio-kyq/contracts/api.yaml` en `specs/001-chosen-driver-trip-ptt/contracts/api.yaml`, dejar la vista de 011 con `$ref` (como 009), eventos `radio.*` en `specs/001-…/contracts/realtime.md`; `TestContract011ViewIsValid`
- [X] T003 Migración `backend/migrations/00016_radio.sql` según [data-model.md](data-model.md) (enums, tablas, cambios en `sos_alerts`, `cost_concept`, `driver_usage_daily`, fila inicial de `radio_settings`) con `Down`; consultas `backend/internal/store/queries/radio.sql`; `sqlc generate`
- [ ] T004 Spike de registro (research R3): sala LiveKit con egress automático por pista a MinIO en la VM; medir con 20 mensajes/min que la primera sílaba queda grabada y el uso de CPU de Egress; anotar resultado en `research.md` R3. Si falla, aplicar plan B antes de seguir con T012
- [X] T005 [P] Buckets `kyq-radio` (vence 90 días) y `kyq-radio-saved` (366 días) en `infra/docker-compose.yml` (`minio-init`) y `EnsureBucket`/`EnsureExpiry` en `backend/cmd/api/main.go`; variables `KYQ_S3_RADIO_BUCKET`, `KYQ_S3_RADIO_SAVED_BUCKET`, `KYQ_PLAY_DRIVER_URL`, `KYQ_PLAY_RIDER_URL` en `infra/.env.example` e `infra/README.md`
- [X] T006 [P] Paquete `packages/kyq_radio` (pubspec, `melos.yaml`, análisis) con dependencias `kyq_api`, `kyq_ptt`, `kyq_realtime`, `kyq_ui`, `just_audio`, `flutter_image_compress`, `image_picker`

## Phase 2: Foundational (bloquea todas las historias)

- [X] T007 `backend/internal/radio/access.go`: `Settings` con caché de 30 s y `Access(user, now)` → `full|listen|none` (data-model §Acceso, FR-005); pruebas de unidad por política, prueba, gracia y suspensión
- [X] T008 Módulo `radio` montado en `httpapi.Deps` y `cmd/api/main.go` (servicio, handlers, `RunSweeper`); middleware de acceso (`403 radio_access_denied`, `403 radio_listen_only`) y filtro de participación (`404`)
- [X] T009 [P] `packages/kyq_api`: modelos freezed y métodos de Radio (todas las rutas del contrato); pruebas de serialización
- [X] T010 [P] `packages/kyq_realtime`: eventos `radio.message`, `radio.presence`, `radio.alert`, `radio.emergency`, `radio.member`, `radio.invite`, `radio.settings`; pruebas
- [X] T011 `packages/kyq_ptt`: `VoiceRoom` multi-sala solo recepción (conectar N salas, silenciar pista remota localmente, publicar al obtener turno y despublicar al soltar) sin romper 001/005/006; pruebas con doble de `VoiceRoom`

## Phase 3: US1 Hablar con un compañero (P1) 🎯 MVP

- [X] T012 [US1] `radio/conversations.go` + `invites.go` (contactos): `POST /v1/radio/contacts/invites` (QR/enlace o teléfono sin revelar si existe), `GET/POST /v1/radio/invites/{code}[/accept]`, borrar contacto; `GET /v1/radio/conversations`; pruebas de integración (FR-002, FR-004)
- [X] T013 [US1] `radio/floor.go`: sala `radio-{id}-{hex}` con egress automático (opciones nuevas en `ptt/livekit.go`), token de 1 min, `POST/DELETE …/ptt/floor` con turno fail-closed de 60 s y liberación por 3 s sin audio; crea `radio_message` en `recording`; pruebas de integración con doble de salas (FR-006, edge cases)
- [X] T014 [US1] `kyq_radio`: `RadioController` (lista, conversación seleccionada, turno, modo mantener/tocar), pantalla de lista y de conversación (cabecera con nombre, estado y duración, botón grande central, "Repetir último", salida de audio, acceso a Emergencia), tonos de `kyq_ptt`; pruebas de cubit y widget (FR-007, FR-009, FR-039)
- [X] T015 [US1] Agregar contacto en `kyq_radio`: mostrar QR (`qr_flutter`), escanear (`mobile_scanner`), compartir enlace, invitar por teléfono, aceptar; pruebas de widget
- [X] T016 [US1] Montar `/radio` en `apps/kyq_driver_app` (entrada en el inicio) e intent-filter `kyq://radio` en el `AndroidManifest.xml` de las dos apps con redirección de go_router; aviso y aceptación de registro (FR-013); pruebas

## Phase 4: US2 Historial y reproducción (P1) 🎯 MVP

- [X] T017 [US2] `radio/egress.go`: webhook `egress_ended` de LiveKit (`telemetry/livekit_webhook.go`) → `ready` con `object_key` y duración, descarte < 0,5 s, evento `radio.message`; prefijo `radio-` en `roomDriver`; pruebas de integración (FR-010)
- [X] T018 [US2] `radio/messages.go`: historial paginado, `GET …/media` (URL prefirmada de 10 min), `PUT …/receipt` (escuchado, guardado con copia a `kyq-radio-saved`, límite 200, `409 saved_limit`); pruebas (FR-011, FR-012)
- [X] T019 [US2] `radio/retention.go`: barrido diario que borra vencidos según `retention_days` vigente, respeta guardados, borra objetos; pruebas con reloj falso
- [X] T020 [US2] `kyq_radio`: historial (nuevos/escuchados, contador), reproductor `just_audio` con 1x/1,5x/2x, "Reproducir nuevos" en cola, Guardar; pruebas de widget y de cola (FR-011)

## Phase 5: US4 Canales y cooperativa (P1)

- [X] T021 [US4] `radio/conversations.go` + `members.go` (canales): crear (nombre único, 10 por conductor, 200 miembros), editar, enlace/QR, pedir entrada, aprobar/rechazar, roles, silenciar, expulsar, bloquear, salir, borrar; rotación de sala al expulsar/salir/bloquear; pruebas de integración (FR-015, FR-016, FR-014)
- [X] T022 [US4] Política de pasajeros en canales (FR-017): validar contra `radio_settings` y `passenger_role_max`; degradar o sacar pasajeros al restringir la política, con aviso `radio.member`; pruebas por política
- [X] T023 [US4] `cooperatives`: sincronizar membresías y suspensión de 006 con la conversación `cooperative` (alta, baja, rotación), sin salir desde Radio (`403 cooperative_channel`); migrar el canal de grupo de 006 a la sala de Radio sin romper `/v1/driver/cooperative/ptt/*`; pruebas de integración (FR-018)
- [X] T024 [US4] `kyq_radio`: crear canal, detalle con miembros y estados, solicitudes pendientes, menú de moderación por rol; pruebas de widget

## Phase 6: US7 Varias conversaciones (P2)

- [ ] T025 [US7] `PUT …/listening` con límite de 10 (`409 listening_limit`); pruebas
- [ ] T026 [US7] `kyq_radio`: cola de reproducción (un emisor en vivo, los demás desde el registro al terminar, prioridad de viaje y SOS, hablar pausa la cola) y conexión de las salas con "Escuchar"; pruebas de unidad con 3 fuentes simultáneas (FR-024, FR-025, SC-006)

## Phase 7: US3 Clientes (P1)

- [X] T027 [US3] Conversaciones `client` derivadas de la afiliación activa: `PUT /v1/radio/clients` (desactivado por defecto), `PUT /v1/radio/clients/{passengerId}` (silenciar, bloquear), cierre al terminar la afiliación, límite de 20 mensajes/hora por pasajero y conductor (`429`); pruebas de integración (FR-003)
- [X] T028 [US3] Montar `/radio` en `apps/kyq_rider_app` (entrada desde la lista de Conductores Elegidos) con "Pedir viaje" hacia la solicitud de 001; ajustes del conductor "Radio con mis clientes" y lista de clientes silenciados o bloqueados; pruebas

## Phase 8: US10 Migración y configuración (P1)

- [X] T029 [US10] `radio/invites.go`: página `GET /r/{code}` (abre `kyq://radio/{code}` o la tienda según tipo), vencimiento a 14 días, uso único para invitaciones con teléfono; pruebas
- [X] T030 [US10] `auth`: al verificar el OTP aplicar las invitaciones pendientes con ese teléfono (`radio_invites_applied`); pruebas de integración
- [X] T031 [US10] Apps: Play Install Referrer (`play_install_referrer`) y "¿Tienes un enlace de invitación?" con portapapeles para equipos sin Google Play; llevar al canal tras el registro; pruebas (SC-004)
- [ ] T032 [US10] `radio/bulk.go`: `POST /v1/admin/radio/bulk-uploads` (CSV hasta 2 000 filas, normalización E.164, validación sin enviar, canales a crear con dueño), `…/send` a 20 SMS/s con reintento y `only_failed`, estados por fila, "ya estaba", teléfono enmascarado; texto del SMS con quién invita y cómo darse de baja; pruebas (FR-033–FR-035, SC-005)
- [ ] T033 [US10] `GET/PUT /v1/admin/radio/settings` con auditoría en `radio_settings_audit`, costo estimado por retención (uso de los últimos 30 días × `cost_rates`), evento `radio.settings`; nuevo aviso de aceptación al cambiar la retención; pruebas (FR-040)
- [ ] T034 [US10] Panel `apps/kyq_admin_web/lib/radio/`: página Configuración de Radio y página Cargas masivas (subir CSV con `file_picker`, errores, confirmar, estados, reenviar); pruebas de widget

## Phase 9: US5 Estados y alertas (P2)

- [ ] T035 [US5] `radio/presence.go`: `GET/PUT /v1/radio/me`, latido de 30 s y Desconectado a 90 s, `radio.presence` a contactos y canales, horarios de silencio con barrido de 1 min y zona horaria; pruebas con reloj falso (FR-019–FR-021)
- [ ] T036 [US5] Alerta de llamada: `POST …/messages` `kind=alert` (texto ≤ 80, 3 por emisor y destino en 10 min), evento `radio.alert`; en `kyq_radio` timbre y vibración en bucle hasta 60 s o al abrir, también en Ocupado; pruebas (FR-022)
- [ ] T037 [US5] `kyq_radio`: selector de estado en la barra superior, colores y formas de Kyq por estado, horarios de silencio; Ocupado no suena; pruebas de widget

## Phase 10: US6 Texto, foto y ubicación (P2)

- [ ] T038 [US6] Backend: `kind=text|location` y fotos (`POST …/photos` con `PresignPut`, `photo-uploaded`); pruebas
- [ ] T039 [US6] `kyq_radio`: caja de texto, cámara/galería con compresión ≤ 1280 px sin EXIF, ubicación actual o punto en el mapa, abrir en Waze/Google Maps, miniaturas y pantalla completa; pruebas de widget (FR-023)

## Phase 11: US8 Manos libres y US9 Emergencia (P2)

- [ ] T040 [US8] Conductor: "Radio encendida" en el servicio en primer plano (`background/foreground_service.dart`), aviso fijo con "Apagar radio", reconexión de Centrifugo y salas con pantalla bloqueada; pasajero: servicio en primer plano equivalente; atenuación de navegación con `AudioFocus`; pruebas (FR-026, FR-027)
- [ ] T041 [US8] `HandsFreePtt` (burbuja y botón Bluetooth de 005) hacia el canal del viaje si hay viaje y si no hacia la conversación de Radio seleccionada; modo auto en `kyq_radio` (botones ≥ 1/3 del ancho, alto contraste, flechas para cambiar de conversación, sin teclado); pruebas (FR-028, FR-029)
- [ ] T042 [US9] `safety`: `RaiseWithoutTrip` (`raised_from = radio`), webhook de salas `sos-` sin viaje, consola de 003 con "Sin viaje · desde Radio"; `POST …/emergency` (con viaje en curso abre el SOS del viaje), mensaje `emergency` a la conversación y a la cooperativa que suena en Ocupado; pruebas de integración (FR-030, FR-031)
- [ ] T043 [US9] `kyq_radio` y panel: botón Emergencia (mantener 2 s) con el flujo y PIN de 003, aviso de emergencia recibido; consola muestra alertas sin viaje; pruebas

## Phase 12: US11 Moderación y coste (P3)

- [ ] T044 [US11] `radio/reports.go`: reportar, cola, abrir con acceso registrado (`radio_report_access`), resolver (borrar mensaje, suspender canal, suspender usuario con `crm/moderation.go`); suspender o reactivar canal desde el panel; pruebas de integración (FR-036, FR-037)
- [ ] T045 [US11] `telemetry`: kinds `RadioVoiceSeconds`, `RadioMessages`, `RadioStorageBytes`, `cost_concept` `radio_storage` y `sms_invite`; columnas en `/v1/admin/usage` y economía unitaria del panel; pruebas (FR-038)
- [ ] T046 [US11] Panel: cola de reportes de Radio dentro de la moderación de 007 (`apps/kyq_admin_web/lib/users/` o `lib/radio/reports_page.dart`) con reproductor del mensaje reportado; pruebas de widget
- [ ] T047 [US11] Cuenta eliminada: autor anónimo y borrado inmediato de objetos de sus mensajes (habeas data); pruebas

## Phase 13: Polish

- [ ] T048 [P] Revisión clean-room (principio I): textos, íconos, colores y tonos propios; ninguna referencia a la marca de terceros en código, assets ni strings; anotar en `research.md`
- [ ] T049 `cd backend && go vet ./... && go test ./...` con base real; `melos run analyze` y `melos run test`; CI en verde
- [ ] T050 `graphify update .` y actualizar `README`/`infra/README.md` con Radio (variables, buckets, enlaces)
- [ ] T051 Desplegar en la VM y recorrer [quickstart.md](quickstart.md) con dos teléfonos; registrar en `validation.md`; prueba de usabilidad y piloto de phva.md §3 (lo hace el responsable)

## Dependencies & Execution Order

- Fase 1 → Fase 2 → historias. T004 (spike) antes de T013/T017.
- MVP = Fases 1–4 (US1 + US2): dos conductores se hablan y no pierden mensajes.
- US4 (Fase 5) y US3 (Fase 7) dependen de Fases 3–4; US7 depende de US4.
- US10 (Fase 8) depende de T012 y T021 (invitaciones de contacto y canal).
- US5, US6, US8, US9, US11 son independientes entre sí tras Fase 4.

## Parallel Opportunities

- T005, T006 en paralelo con T003.
- T009, T010, T011 en paralelo tras T003.
- Dentro de cada historia, backend y `kyq_radio` en paralelo una vez fijado el contrato (T002).

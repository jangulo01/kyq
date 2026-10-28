# Implementation Plan: Radio Kyq: walkie-talkie permanente entre conductores y con sus pasajeros

**Branch**: `011-radio-kyq` | **Date**: 2026-10-28 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/011-radio-kyq/spec.md`; análisis PHVA en
[phva.md](phva.md).

## Summary

Radio Kyq lleva el walkie-talkie fuera del viaje con la forma de uso que los usuarios ya conocen
(referencia funcional de phva.md §1.3). Piezas:

1. **Conversaciones** (`radio_conversations`, `radio_members`): contactos 1 a 1 entre conductores
   por invitación, conductor–cliente sobre la afiliación de Conductor Elegido, canales con roles y
   moderación, y la cooperativa de 006 sincronizada como un canal más.
2. **Voz en vivo**: una sala LiveKit persistente por conversación con el turno "fail-closed" de
   001/006 (60 s), tokens de 1 min solo de recepción y rotación de sala al expulsar o salir.
3. **Registro**: Track Egress automático por sala a `kyq-radio`; cada publicación de micrófono es
   un mensaje (`recording → ready` por el webhook `egress_ended`). Historial con voz, texto, foto,
   ubicación, alertas y emergencias; reproducción con `just_audio` a 1x/1,5x/2x; guardados.
4. **Varias conversaciones**: hasta 10 salas conectadas solo para recibir; cola en el cliente que
   reproduce desde el registro lo que llega mientras otro suena; viaje y SOS primero.
5. **Estados y alertas**: presencia con latido por Centrifugo, horarios de silencio evaluados en
   el backend, alerta de llamada en bucle 60 s.
6. **Manos libres**: servicio en primer plano de 005 con "Radio encendida", burbuja y botón
   Bluetooth hacia la conversación seleccionada si no hay viaje, modo auto.
7. **Emergencia**: SOS de 003 con `trip_id` opcional (`raised_from = radio`).
8. **Migración**: invitaciones con código corto, página `/r/{code}`, `kyq://radio/{code}`, Play
   Install Referrer, aplicación por teléfono al verificar el OTP, y carga masiva CSV con SMS.
9. **Panel**: configuración de Radio (acceso de conductores sin suscripción, pasajeros en canales,
   retención con costo estimado), cargas masivas, reportes con acceso auditado, uso y costo.

## Technical Context

**Language/Version**: Go 1.26 (backend); Dart 3.12 / Flutter 3.44 (apps).

**Primary Dependencies**: las existentes (pgx, sqlc, goose, LiveKit + Egress + Redis, Centrifugo,
MinIO, Twilio SMS, `livekit_client` 2.13, `centrifuge`, `dio`, `flutter_bloc`, `go_router`,
`qr_flutter`, `mobile_scanner`, `flutter_foreground_task`). Nuevas en Flutter: `just_audio`
(reproducción con velocidad), `flutter_image_compress`, `image_picker`,
`play_install_referrer`. En el panel: `file_picker` para el CSV. Sin dependencias nuevas en Go.

**Storage**: PostgreSQL 17 + PostGIS; migración `00016_radio.sql` ([data-model.md](data-model.md));
buckets MinIO `kyq-radio` (vencimiento 90 días) y `kyq-radio-saved` (vencimiento 366 días).

**Testing**: unidad (acceso por política, turno y roles, cola del cliente, horarios de silencio,
validación del CSV, límites), integración con base real (`TestIntegration*` con `testdb`:
conversaciones, rotación de sala, webhook de egress, retención y guardados, invitaciones por
teléfono al verificar OTP, sincronización con 006, SOS sin viaje), contrato
(`contracttest/radio_test.go` contra 001 fusionado), cubit y widget (`kyq_radio`, apps y panel).

**Target Platform**: Android 10+ (conductor y pasajero, con y sin Google Play Services); panel en
navegador.

**Project Type**: mobile + web admin + API (monorepo existente).

**Performance Goals**: voz p95 < 250 ms en 4G (SC-002); mensaje listo en el historial < 3 s tras
soltar; lista de conversaciones < 1 s; validación de 2 000 filas < 1 min (SC-005).

**Constraints**: sin teléfonos en ninguna respuesta de Radio (FR-004); el personal solo ve
mensajes reportados o SOS (FR-037); el canal del viaje y la consulta previa siguen sin grabarse
(FR-013); sin FCM/HMS (avisos por Centrifugo con servicio en primer plano); principio I en
diseño, textos y tonos.

**Scale/Scope**: piloto de 20–50 conductores en una ciudad (phva.md §2); diseño para 200 miembros
por canal y 10 conversaciones escuchadas por usuario.

## Constitution Check

| Principio | Cumplimiento |
|---|---|
| I. Clean-room | La investigación funcional solo describe comportamientos (phva.md §1.3); pantallas, textos, íconos, colores y tonos (`kyq_ptt/tones.dart`, sintetizados) propios. No se usa nada del APK descompilado. La revisión de código lo verifica explícitamente. |
| II. Adoptar antes que construir | LiveKit para voz y Egress para el registro, Centrifugo para presencia y avisos, MinIO para objetos, `just_audio` para reproducir con velocidad, Twilio para SMS. Sin código de medios propio. |
| III. Flutter | Paquete compartido `kyq_radio` usado por conductor y pasajero; panel en Flutter web. Nativo solo lo existente de 005 (burbuja, botón) y el Install Referrer. |
| IV. Monolito modular Go | Módulo nuevo `internal/radio`; cambios acotados en `safety`, `cooperatives`, `telemetry`, `auth` (aplicar invitaciones al verificar OTP). |
| V. Reglas como contrato | **Nueva regla RN-KYQ-017** "Radio Kyq permanente con registro a demanda": enmienda MINOR de la constitución (1.0.0 → 1.1.0) en T001, con prueba que falla si Radio graba el canal del viaje o la consulta previa, o si una respuesta de Radio trae un teléfono. RN-KYQ-002/003/011/012/015 se respetan. |
| VI. Pruebas | Según Technical Context; CI en verde antes de integrar. |
| VII. Coste medido | Minutos, mensajes y almacenamiento por conductor en economía unitaria; costo estimado visible antes de cambiar la retención; límites de canales, miembros, escuchas, guardados y mensajes por hora. |

**Desviaciones registradas**: (1) 001 FR-021 y 005 FR-008 prohibían almacenar voz; siguen
vigentes para viaje y consulta, y Radio es un canal distinto con aviso y aceptación (FR-013).
(2) `sos_alerts.trip_id` deja de ser obligatorio solo para `raised_from = radio` (CHECK en la
migración). **Re-check post-diseño**: sin otras desviaciones.

## Project Structure

### Documentation (this feature)

```text
specs/011-radio-kyq/
├── spec.md
├── phva.md                # análisis PHVA y referencia funcional de familiaridad
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/api.yaml     # rutas de 011 (se fusionan en 001 en T002)
├── checklists/requirements.md
└── tasks.md
```

### Source Code (repository root)

```text
.specify/memory/constitution.md        # RN-KYQ-017, versión 1.1.0
backend/
├── migrations/00016_radio.sql
├── internal/
│   ├── radio/                         # módulo nuevo
│   │   ├── access.go                  # radio.Access (FR-005) y settings con caché
│   │   ├── conversations.go           # contactos, clientes, canales, cooperativa
│   │   ├── members.go                 # roles, moderación, rotación de sala
│   │   ├── floor.go                   # turno y mensaje en recording
│   │   ├── messages.go                # historial, texto, foto, ubicación, alertas, recibos
│   │   ├── egress.go                  # webhook egress_ended → ready
│   │   ├── presence.go                # latido, estados, horarios de silencio
│   │   ├── invites.go                 # códigos, /r/{code}, aplicar por teléfono
│   │   ├── bulk.go                    # CSV, validación, envío de SMS
│   │   ├── retention.go               # barrido de vencidos y guardados
│   │   ├── reports.go                 # reportes y acceso auditado
│   │   ├── handlers.go, admin_handlers.go
│   │   └── *_test.go
│   ├── ptt/                           # opciones de egress automático por pista al crear la sala
│   ├── safety/                        # RaiseWithoutTrip, consola "Sin viaje · desde Radio"
│   ├── cooperatives/                  # sincroniza membresías con la conversación cooperative
│   ├── telemetry/                     # prefijo radio-, kinds nuevos
│   ├── auth/                          # aplicar invitaciones al verificar OTP
│   ├── store/queries/radio.sql
│   └── contracttest/radio_test.go
infra/
├── docker-compose.yml                 # buckets kyq-radio y kyq-radio-saved en minio-init
└── egress.yaml                        # sin cambios salvo bucket si hiciera falta
packages/
├── kyq_radio/                         # paquete nuevo compartido
│   ├── lib/src/controller/            # RadioController, cola, presencia
│   ├── lib/src/ui/                    # lista, conversación, historial, estados, modo auto
│   └── test/
├── kyq_api/                           # modelos y métodos de Radio
├── kyq_realtime/                      # eventos radio.*
└── kyq_ptt/                           # VoiceRoom multi-sala solo recepción
apps/
├── kyq_driver_app/lib/radio/          # montaje, HandsFree hacia la radio, servicio en primer plano
├── kyq_rider_app/lib/radio/           # montaje, entrada desde la lista de conductores
└── kyq_admin_web/lib/radio/           # configuración, cargas masivas, reportes
```

**Structure Decision**: monorepo existente; la UI de Radio vive en `packages/kyq_radio` porque es
la misma en conductor y pasajero.

## Fases de entrega (incrementos de phva.md §2)

| Incremento | Historias | Tareas |
|---|---|---|
| H1 Radio 1 a 1 | US1, US2, US8 (segundo plano) | Fases 1–4 |
| H2 Canales y cooperativa | US4, US7 | Fases 5–6 |
| H3 Clientes | US3 | Fase 7 |
| H4 Migración y configuración | US10, FR-040 | Fase 8 |
| H5 Comodidad y control | US5, US6, US8, US9, US11 | Fases 9–12 |

## Complexity Tracking

| Decisión | Por qué es necesaria | Alternativa más simple descartada |
|---|---|---|
| Hasta 10 salas LiveKit conectadas por usuario | Escuchar varias conversaciones en vivo (FR-024) | Unirse bajo demanda: pierde el inicio del mensaje (research R2) |
| Track Egress por mensaje | Registro reproducible (FR-010) sin código de medios | Grabación local: conflicto de micrófono en Android (research R3) |

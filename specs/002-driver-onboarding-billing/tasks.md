# Tasks: Alta autónoma del conductor, validación documental y suscripción con Bold

**Input**: Design documents from `/specs/002-driver-onboarding-billing/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/api.yaml, quickstart.md

**Tests**: incluidas; la constitución (V, VI) exige una prueba por regla RN-KYQ y pruebas de
integración de contratos.

## Format: `[ID] [P?] [Story] Description`

## Phase 1: Setup

- [X] T001 Añadir el servicio `minio` (imagen oficial fijada, puerto 9000 solo en la red interna y 9001 de consola en la VM) y un job `minio-init` que crea el bucket privado `kyq-kyc` en `infra/docker-compose.yml`; variables `KYQ_S3_ENDPOINT`, `KYQ_S3_ACCESS_KEY`, `KYQ_S3_SECRET_KEY`, `KYQ_S3_BUCKET`, `KYQ_S3_PUBLIC_ENDPOINT` y `KYQ_BOLD_ENV`, `KYQ_BOLD_IDENTITY_KEY`, `KYQ_BOLD_SECRET_KEY` en `infra/.env.example`, `backend/.env.example` y el servicio `api` (imagen de Chainguard fijada por digest: la oficial ya no se publica; research R4)
- [X] T002 [P] Añadir `github.com/minio/minio-go/v7` a `backend/go.mod` y los campos S3 y Bold a `backend/internal/config/config.go` (Bold obligatorio solo si `KYQ_BOLD_ENV` no está vacío)
- [X] T003 [P] Añadir `image_picker`, `flutter_image_compress` y `url_launcher` (versiones con ≥ 2 semanas, compileSdk 36) a `apps/kyq_driver_app/pubspec.yaml` y permisos de cámara en su `AndroidManifest.xml`

## Phase 2: Foundational

- [X] T004 Migración `backend/migrations/00007_kyc_billing.sql`: columnas de vehículo en `drivers` (`vehicle_brand`, `vehicle_model`, `vehicle_color` text NULL; `vehicle_year` smallint NULL); nuevo `driver_documents` con versiones según data-model.md (`doc_type` enum `national_id | license | mandatory_insurance | technical_inspection | vehicle_registration`, `status` enum `uploading | submitted | approved | rejected | superseded`, `reject_reason` obligatorio si `rejected`), migrando los documentos de 001 a `approved`; `document_photos` (PK `document_id, side`); `subscription_prices` (PK `city_code, effective_from`, `amount_minor > 0`); `payments` (estados `created | processing | approved | rejected | expired | voided | needs_review`, `bold_link_id` UNIQUE, índice parcial de pagos en curso); `subscriptions.updated_by` NULL; `notices` (UNIQUE `driver_id, dedup_key`); `cost_rates` (PK `concept, currency, effective_from`, `unit_cost_micro >= 0`)
- [X] T005 Consultas sqlc en `backend/internal/store/queries/{kyc,billing,notify,costs}.sql` y `sqlc generate`
- [X] T006 [P] Cliente S3 con URLs firmadas de subida (PUT, 10 min, `image/jpeg`, ≤ 2 MB) y lectura (5 min) en `backend/internal/storage/s3.go` detrás de una interfaz `Objects`, con un fake en memoria para pruebas
- [X] T007 [P] Módulo `backend/internal/notify/`: crear aviso idempotente por `dedup_key`, listar y marcar leído, enviar SMS pendientes por la interfaz `SMSSender` (Twilio / registro en dev) y publicar `notice.created` en `user:{id}`
- [X] T008 Actualizar el gate `EvaluateOnline` en `backend/internal/drivers/gate.go` y su prueba: obligatorios los cinco tipos, vigente = último `approved` con `expires_at > hoy` o `exempt_until > hoy` para la revisión técnico-mecánica; motivos de bloqueo por tipo (RN-KYQ-016)
- [X] T009 [P] Modelos y métodos nuevos en `packages/kyq_api` (onboarding, documentos, suscripción, pagos, costos, avisos y rutas admin de contracts/api.yaml) con `build_runner` y pruebas del cliente
- [X] T010 Fusionar `specs/002-driver-onboarding-billing/contracts/api.yaml` en el contrato principal `specs/001-chosen-driver-trip-ptt/contracts/api.yaml` para que las pruebas de contrato lo validen

**Checkpoint**: migración aplicada, gate actualizado, almacenamiento y avisos listos.

## Phase 3: User Story 1 - Alta autónoma y envío de documentos (P1)

**Goal**: un teléfono nuevo se registra como conductor y envía sus 5 documentos sin admin.

**Independent Test**: escenarios 1–3 de quickstart.md.

- [X] T011 [P] [US1] Pruebas en `backend/internal/auth/auth_test.go`: `role: driver` crea usuario + conductor + QR; teléfono con otro rol → 409 `phone_has_other_role`
- [X] T012 [P] [US1] Pruebas de integración en `backend/internal/kyc/service_test.go`: vehículo obligatorio antes de documentos; crear documento devuelve URLs firmadas por lado; `submit` sin todas las fotos → 409 `photos_missing`; estados `uploading → submitted`; estado de alta derivado `profile_incomplete → documents_pending → in_review`
- [X] T013 [US1] Alta como conductor en `backend/internal/auth/` (campo `role` en verify, transacción usuario + conductor + QR)
- [X] T014 [US1] Módulo `backend/internal/kyc/`: `PUT /v1/driver/vehicle` (placa `^[A-Z]{3}[0-9]{2}[0-9A-Z]$`, año 1990–año actual + 1), `GET /v1/driver/onboarding`, `POST /v1/driver/documents`, `POST /v1/driver/documents/{id}/submit`; `expires_at` obligatorio salvo `national_id` y `vehicle_registration`
- [X] T015 [US1] Montar el módulo en `backend/internal/httpapi/router.go` y `backend/cmd/api/main.go`
- [X] T016 [P] [US1] Pantalla "Soy conductor" en el login del conductor y formulario de vehículo en `apps/kyq_driver_app/lib/onboarding/vehicle_page.dart`
- [X] T017 [US1] Lista de documentos con estado y motivo de rechazo, y captura con cámara/galería (frente y reverso, compresión ≤ 1 MB, número y vencimiento) con subida reintentable en `apps/kyq_driver_app/lib/onboarding/documents_page.dart` y `document_capture_page.dart`, con su cubit
- [X] T018 [US1] Enrutar en `apps/kyq_driver_app/lib/app/app.dart`: sin vehículo → vehículo; documentos no al día → documentos; inicio muestra el estado de alta y no deja ONLINE
- [X] T019 [P] [US1] Pruebas de widget y cubit en `apps/kyq_driver_app/test/onboarding/`

## Phase 4: User Story 2 - Validación y vencimientos (P1)

**Goal**: el admin aprueba o rechaza documentos y el sistema avisa y bloquea por vencimiento.

**Independent Test**: escenarios 4, 5 y 11 de quickstart.md.

- [X] T020 [P] [US2] Pruebas en `backend/internal/kyc/review_test.go`: rechazar exige motivo; aprobar marca el anterior `superseded`; el aprobado anterior sigue vigente mientras el nuevo está en revisión; corrección de número/fecha y `exempt_until`; auditoría (revisor y fecha); avisos 15/3/0 días deduplicados
- [X] T021 [US2] Revisión en `backend/internal/kyc/`: `GET /v1/admin/kyc/queue` (más antiguos primero), `GET /v1/admin/kyc/drivers/{id}` con URLs firmadas de lectura, `POST /v1/admin/kyc/documents/{id}/review`; avisos `doc_approved` / `doc_rejected`
- [X] T022 [US2] Barrido de vencimientos cada minuto en `backend/internal/kyc/expiry.go`: avisos `doc_expiring` a 15 y 3 días (SMS a 3) y `doc_expired` el día del vencimiento (SMS)
- [X] T023 [P] [US2] Cola de revisión y expediente con fotos ampliables, aprobar/rechazar con motivos predefinidos (borrosa, no coincide, vencido, otra persona) o texto en `apps/kyq_admin_web/lib/kyc/`
- [X] T024 [US2] Avisos en la app del conductor (`apps/kyq_driver_app/lib/notices/`): lista, insignia en inicio y llegada en vivo por `notice.created`
- [X] T025 [P] [US2] Pruebas de widget del panel en `apps/kyq_admin_web/test/kyc/` y de avisos en `apps/kyq_driver_app/test/notices/`

## Phase 5: User Story 3 - Pago de la suscripción con Bold (P1)

**Goal**: el conductor paga con Bold y su suscripción se extiende una sola vez por pago.

**Independent Test**: escenarios 6–9 de quickstart.md con el sandbox de Bold.

- [X] T026 [P] [US3] Pruebas unitarias en `backend/internal/billing/billing_test.go`: `paid_until = max(paid_until, ahora) + 1 mes`; importe o moneda distintos → `needs_review` sin extender; firma `x-bold-signature` = hex(HMAC-SHA256(secreta, base64(cuerpo))) válida, inválida y con clave vacía en sandbox; mapeo de estados del enlace (`PAID` → approved; `REJECTED`/`CANCELLED` → rejected; `EXPIRED` → expired)
- [X] T027 [P] [US3] Pruebas de integración en `backend/internal/billing/integration_test.go` con un servidor Bold falso: crear pago y enlace; sondeo y webhook duplicados extienden una vez (SC-005); pago en suspendido reactiva al instante; recordatorios 5/1 días y gracia deduplicados (RN-KYQ-002/003)
- [X] T028 [US3] Cliente Bold en `backend/internal/billing/bold.go`: `POST /online/link/v1` (`amount_type: CLOSE`, `reference` = id del pago, `description`, `expiration_date` 30 min) y `GET /online/link/v1/{id}` con `Authorization: x-api-key <identidad>`; verificación de firma del webhook
- [X] T029 [US3] Servicio en `backend/internal/billing/service.go`: crear pago (requiere documentos al día; uno en curso a la vez), aplicar aprobación en transacción con bloqueo e idempotencia (`UPDATE ... WHERE status <> 'approved'`), periodo cubierto, avisos `payment_approved` / `payment_rejected`
- [X] T030 [US3] Rutas `GET /v1/driver/subscription`, `POST /v1/driver/payments`, `POST /v1/driver/payments/{id}/refresh` y `POST /v1/billing/bold/webhook` (respuesta 200 < 2 s, sin auth Kyq) en `backend/internal/billing/handlers.go`; montar en el router
- [X] T031 [US3] Barrido de pagos en curso cada 10 s (creados hace < 2 h) y recordatorios de suscripción (5 y 1 días antes con SMS, y al entrar en gracia) en `backend/internal/billing/sweeper.go`
- [X] T032 [US3] Pantalla "Mi suscripción" con estado, precio, botón Pagar (Custom Tab con `url_launcher`), comprobación al volver, "Pago en proceso / aprobado / rechazado" e historial de pagos en `apps/kyq_driver_app/lib/subscription/`
- [X] T033 [P] [US3] Pruebas de cubit y widget del pago en `apps/kyq_driver_app/test/subscription/`

## Phase 6: User Story 4 - Transparencia de costos (P2)

**Goal**: el conductor y el admin ven costo medido vs. precio (RN-KYQ-004).

**Independent Test**: escenario 12 de quickstart.md.

- [X] T034 [P] [US4] Prueba RN-KYQ-004 en `backend/internal/telemetry/costs_test.go`: costo = Σ uso diario × tarifa vigente ese día + fijo; cambio de tarifa a mitad de mes; margen = pagado − costo
- [X] T035 [US4] Cálculo y rutas `GET /v1/driver/costs`, `GET/PUT /v1/admin/cost-rates`, `GET /v1/admin/costs` en `backend/internal/telemetry/costs.go`
- [X] T036 [P] [US4] Sección "En qué se va tu suscripción" en `apps/kyq_driver_app/lib/subscription/costs_view.dart` con su prueba
- [X] T037 [P] [US4] Pantalla de costos por conductor (margen negativo destacado) y tarifas en `apps/kyq_admin_web/lib/costs/` con su prueba

## Phase 7: User Story 5 - Panel de suscripciones y pagos (P2)

**Goal**: el admin ve suscripciones por estado, registra pagos manuales y anula pagos.

**Independent Test**: escenario 10 de quickstart.md.

- [X] T038 [P] [US5] Pruebas en `backend/internal/billing/admin_test.go`: listado por estado; pago manual extiende igual que Bold y se audita; anular recalcula `paid_until` desde los pagos aprobados vigentes; precio con fecha de vigencia
- [X] T039 [US5] Rutas `GET /v1/admin/subscriptions`, `GET/POST /v1/admin/drivers/{id}/payments`, `POST /v1/admin/payments/{id}/void`, `PUT /v1/admin/subscription-prices/{city}` en `backend/internal/billing/admin.go`; retirar el registro manual de `paid_until` de 001 en `backend/internal/admin/` a favor del pago manual (la ruta de 001 queda como obsoleta en el contrato y sigue funcionando hasta que el panel use el pago manual; research R7)
- [X] T040 [P] [US5] Pantallas de suscripciones (filtro por estado), historial, pago manual, anulación y precio en `apps/kyq_admin_web/lib/billing/` con su prueba

## Phase 8: Polish & Cross-Cutting Concerns

- [X] T041 [P] Ampliar la prueba de privacidad `backend/internal/contracttest/privacy_test.go`: las fotos y números de documento nunca aparecen en respuestas de pasajeros ni en eventos (FR-011)
- [X] T042 [P] Sentry: no enviar números de documento ni URLs firmadas (ampliar los filtros de `backend/internal/observability` y `packages/kyq_ui` observability) — backend hecho (`observability.ScrubString`: números de documento y URLs firmadas); falta `packages/kyq_ui`
- [ ] T043 Desplegar en la VM (MinIO, migración 00007, llaves Bold de pruebas) y recorrer quickstart.md en el teléfono con el sandbox de Bold; registrar resultados en `specs/002-driver-onboarding-billing/validation.md`
- [ ] T044 Actualizar `README.md` e `infra/README.md` (MinIO, variables Bold, webhook de producción con HTTPS)

## Dependencies & Execution Order

- Setup (T001–T003) → Foundational (T004–T010) → historias.
- US1 (T011–T019) antes de US2 (necesita documentos enviados) y de US3 (el pago exige documentos al día).
- US3 depende de US1 y de T008 (gate). US4 y US5 dependen solo de Foundational y de US3 para tener pagos.
- Polish al final.

## Parallel Opportunities

- T002, T003; T006, T007, T009 en paralelo.
- En cada historia, las pruebas [P] y las pantallas [P] del panel/app van en paralelo con el backend.
- US4 y US5 en paralelo entre sí tras US3.

## Implementation Strategy

MVP de esta fase = US1 + US2 + US3 (alta, validación y cobro); US4 y US5 son incrementos.

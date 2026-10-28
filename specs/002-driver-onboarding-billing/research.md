# Research: Alta autónoma, KYC y suscripción con Bold

Fuentes de Bold: documentación oficial en developers.bold.co (botón de pagos, API link de pagos,
consulta de transacciones, webhook), consultada el 2026-10-27.

## R1. Cómo cobrar con Bold

- **Decision**: API **Link de pagos**. El backend crea un enlace por pago con
  `POST https://integrations.api.bold.co/online/link/v1` (`Authorization: x-api-key <llave de
  identidad>`), `amount_type: CLOSE`, `amount {currency, total_amount}`, `reference` = id del
  pago en Kyq, `description`, `expiration_date` (30 min). La app abre `payload.url` en una
  Custom Tab.
- **Rationale**: el importe y la referencia los fija el servidor (el cliente no puede alterarlos);
  Bold aloja el checkout (tarjeta, PSE, Nequi, Botón Bancolombia), así que Kyq no toca datos de
  tarjeta. Funciona desde una app sin web propia.
- **Verificado contra el sandbox (2026-10-27, desde la VM)**: la misma URL base sirve para
  pruebas (las llaves de pruebas marcan el enlace con `is_sandbox: true`). `expiration_date` va
  en **nanosegundos** desde la época: con milisegundos o segundos Bold responde 400 `PL_000`
  "The expiration date must be greater than or equal to the current date". `total_amount` va
  en pesos (Kyq guarda centavos: `amount_minor / 100`; por eso el precio en COP debe ser
  múltiplo de 100). Respuesta del POST: `{"payload": {"payment_link": "LNK_…", "url":
  "https://checkout.bold.co/payment/LNK_…"}, "errors": []}`; errores en `errors:
  [{"errors": "…", "code": "PL_000"}]` con `payload: {}`. Llave inválida: 403
  `{"Message": "User is not authorized…"}`. `GET /online/link/v1/payment_methods` lista
  CREDIT_CARD, PSE, BOTON_BANCOLOMBIA, NEQUI y QR_BOLD (mín. 1 000, máx. 10 000 000 COP); no se
  envía `payment_methods` para ofrecerlos todos.
- **Alternatives considered**: Botón de pagos con `data-integrity-signature`
  (SHA-256 de `{orderId}{monto}{divisa}{llaveSecreta}`) — necesita una página web servida por
  Kyq; pensado para tiendas web. API Integrations/datáfono — para pagos presenciales.

## R2. Confirmación del pago

- **Decision**: doble vía, idempotente por `reference`:
  1. **Sondeo**: un barrido cada 10 s consulta `GET /online/link/v1/{payment_link}` de los pagos
     en curso (`created`/`processing`) creados hace menos de 2 h; `PAID` → aprobado,
     `REJECTED`/`CANCELLED`/`EXPIRED` → rechazado/expirado. Además la app pide una
     comprobación inmediata al volver de la Custom Tab.
  2. **Webhook** (producción): `POST /v1/billing/bold/webhook`; firma `x-bold-signature` =
     hex(HMAC-SHA256(llave secreta, base64(cuerpo))), comparación en tiempo constante;
     `SALE_APPROVED` / `SALE_REJECTED` / `VOID_APPROVED` con `data.metadata.reference`. Responder
     200 en < 2 s; Bold reintenta 5 veces.
- **Verificado contra el sandbox**: `GET /online/link/v1/{id}` responde el enlace **plano**
  (sin `payload`): `{"id", "total", "subtotal", "tip_amount", "taxes", "status": "ACTIVE",
  "expiration_date" (ns), "creation_date" (ns), "description", "currency", "api_version",
  "payment_method": null, "transaction_id": null, "amount_type", "is_sandbox", "callback_url",
  "reference"}`; un enlace inexistente da 404 `{"payload": {}, "errors": [...]}`. El cliente
  acepta también la forma envuelta en `payload` por si Bold la unifica. `payment_method` y
  `transaction_id` se guardan como `payment_method_detail` y `bold_payment_id`.
- **Implementación**: el barrido corre cada 10 s; los pagos en curso de más de 2 h pasan a
  `expired` sin consultar (el enlace caduca a los 30 min). Un webhook `SALE_APPROVED` aplica
  aunque el pago estuviera `rejected`/`expired` (orden inverso); nunca se degrada un aprobado.
  El webhook solo se monta con `KYQ_BOLD_ENV` definido: en sandbox la llave es vacía y cualquiera
  podría firmar.
- **Rationale**: el sandbox de Bold no envía webhooks y en pruebas la firma usa clave vacía, así
  que el sondeo es imprescindible para desarrollo y además cubre webhooks perdidos (SC-003).
  Mismo patrón de barrido que R10 de 001.
- **Alternatives considered**: solo webhook (no funciona en sandbox ni en la VM sin HTTPS
  público); solo redirección `callback_url` (requiere https y el estado puede no ser definitivo).

## R3. Extensión de la suscripción

- **Decision**: al aprobarse un pago, en una transacción con bloqueo de la fila de suscripción:
  `paid_until = max(paid_until, now) + 1 mes calendario` (AddDate(0,1,0)); se guarda el periodo
  cubierto en el pago. Un pago aprobado solo se aplica si su estado anterior no era aprobado
  (`UPDATE ... WHERE status <> 'approved' RETURNING`). Importe o moneda distintos al precio con
  que se creó → `needs_review`, sin extender (FR-017). Anular resta el periodo recalculando
  `paid_until` desde los pagos aprobados vigentes.
- **Implementación**: el bloqueo es la fila del conductor (`SELECT … FOR UPDATE` en `drivers`,
  siempre antes que la del pago), porque la fila de `subscriptions` puede no existir aún. Cada
  pago aprobado guarda `prev_paid_until`. **Anular** (desviación menor de "recalcular desde los
  pagos aprobados"): si el pago anulado es la última extensión, `paid_until` vuelve a
  `prev_paid_until` (o se borra la suscripción si no había); si no, se resta su periodo
  (`covers_until - covers_from`). Así "anular deja el estado anterior" sin rehacer historias con
  periodos fijados a mano por el administrador en 001.
- **Rationale**: idempotente ante reintentos y carreras webhook/sondeo; auditable.

## R4. Almacenamiento de fotos

- **Decision**: bucket privado S3 compatible: **MinIO** (contenedor en la VM) en desarrollo,
  **Cloudflare R2** en producción, con `minio-go`. La app pide una URL firmada de subida
  (PUT, 10 min, `Content-Type: image/jpeg`, ≤ 2 MB) por foto y confirma; el panel ve las fotos con
  URLs firmadas de lectura de 5 min. Las claves de objeto no contienen datos personales
  (`kyc/{driverId}/{docId}/{n}.jpg`).
- **Rationale**: la subida no pasa por la API (menos carga), las fotos nunca son públicas
  (FR-011), y el mismo código sirve para MinIO y R2 (principio II).
- **Implementación**: la imagen oficial `minio/minio` ya no se publica en Docker Hub ni en
  quay.io; se usa la compilación de Chainguard (`cgr.dev/chainguard/minio` y `minio-client`,
  desde el código de MinIO, AGPLv3) fijada por digest, porque su nivel gratuito solo publica
  `latest`. El bucket lo crea el job `minio-init` (y la API lo asegura al arrancar). La URL de
  subida firma `content-type`: un PUT sin `image/jpeg` da 403; el tamaño (≤ 2 MB) se comprueba
  con `StatObject` al confirmar (`photo_invalid` y se borra), porque una URL PUT firmada no
  puede limitarlo. Las URLs se firman para `KYQ_S3_PUBLIC_ENDPOINT` (la IP de la VM en la LAN)
  con región fija, sin llamadas de red. Probado en la VM: PUT 200, GET firmado 200, GET sin
  firma 403.
- **Alternatives considered**: guardar en PostgreSQL (crece la base y los backups); subir por la
  API (más memoria y tiempo en el servidor).

## R5. Avisos

- **Decision**: módulo `notify` con tabla `notices` (conductor, tipo, clave de deduplicación,
  canal, programado, enviado). Un barrido cada minuto genera los avisos debidos (documentos a
  15/3/0 días, suscripción a 5/1 días y al entrar en gracia) y envía los SMS críticos por la
  interfaz `SMSSender` (Twilio en producción, registro en desarrollo). La app los lee con
  `GET /v1/driver/notices` y por el canal en tiempo real `user:{id}` (`notice.created`).
- **Rationale**: sin push en esta fase (R4 de 001); la clave de deduplicación evita repetir un
  aviso si el barrido corre dos veces.

## R6. Alta como conductor

- **Decision**: `POST /v1/auth/otp/verify` acepta `role: "driver"` en el primer registro (por
  defecto `passenger`, como hoy). Crea `users` (rol driver) + `drivers` (sin vehículo, QR
  generado) + estado de alta. Un teléfono existente con otro rol → 409 `phone_has_other_role`.
- **Rationale**: reutiliza el OTP y los límites anti-abuso de 001; un teléfono, un rol (FR-003).

## R7. Tipos y estados de documento

- **Decision**: tipos `national_id`, `license`, `mandatory_insurance` (SOAT),
  `technical_inspection` (revisión técnico-mecánica), `vehicle_registration` (tarjeta de
  propiedad). Una fila por envío (versiones); estados `submitted → approved | rejected`,
  `approved → superseded` cuando se aprueba uno nuevo del mismo tipo; "vencido" se deriva de
  `expires_at`. La revisión técnico-mecánica puede marcarse `exempt_until`. El gate de 001
  (`EvaluateOnline`) usa el último aprobado de cada tipo obligatorio.
- **Rationale**: mantener el aprobado anterior mientras se revisa el nuevo (FR-007) exige
  versiones; los conductores de 001 conservan sus documentos (migración de datos).
- **Migración de 001 (00007)**: los documentos de 001 pasan a `approved` (o `submitted` si no
  estaban aprobados) con sus fechas y `legacy = true` (sin fotos, número vacío). A cada conductor
  con algún documento aprobado en 001 (los revisó un administrador) se le crean dos
  **marcadores aprobados** `legacy`: cédula (no vence) y revisión técnico-mecánica **exenta 60
  días** (`exempt_until`), más un aviso `doc_legacy` pidiendo subir ambos. Así siguen pudiendo
  ponerse ONLINE (Carlos Prueba verificado en la VM tras migrar: `documents_ok`,
  `can_go_online: true`) y el barrido de vencimientos les avisa a 15/3/0 días del fin de la
  exención; después el gate los bloquea hasta que suban la revisión real. Se descartó tratar
  los tipos nuevos como "aviso de gracia" en el gate: dejaría una regla especial permanente en
  RN-KYQ-016. Cédula y tarjeta de propiedad nunca bloquean por fecha, aunque los datos de 001
  traigan una.
- **Compatibilidad con 001**: `GET /v1/driver/me` y `GET /v1/admin/drivers` mantienen su
  `documents` con la forma de 001 (solo license, mandatory_insurance y vehicle_registration con
  vencimiento) para no romper las apps publicadas; el detalle nuevo está en
  `/v1/driver/onboarding` y `/v1/admin/kyc/drivers/{id}`, y `DriverMe.blocked_documents`
  explica el bloqueo por tipo. `PUT /v1/admin/drivers/{id}/documents/{docType}` sigue
  funcionando (crea una versión aprobada sin fotos; `approved: false` retira la vigente) y
  `PUT /v1/admin/drivers/{id}/subscription` queda marcada obsoleta en el contrato.

## R8. Costos por conductor (RN-KYQ-004)

- **Decision**: tabla `cost_rates` (concepto, costo unitario en moneda menor, vigente desde) con
  conceptos `voice_minute`, `realtime_event`, `route_request`, `fixed_monthly`. El costo del mes =
  Σ uso diario × tarifa vigente ese día + fijo. Precio cobrado = pagos aprobados del mes.
- **Implementación**: el fijo mensual usa la tarifa vigente el último día del mes (o hoy en el
  mes en curso). "Precio cobrado del mes" = pagos aprobados cuyo periodo (`covers_from`) empieza
  en ese mes, en la moneda del precio de la ciudad. Costos redondeados a 0,01 unidad mínima.
- **Rationale**: reutiliza `driver_usage_daily` (T077 de 001); tarifas editables sin despliegue.

## R9. Avisos por SMS

- **Decision**: `notify.SMSSender` con dos implementaciones: `LogSMS` (desarrollo, con
  `KYQ_DEV_OTP_CODE`, solo registra el número de caracteres) y `TwilioSMS` (Messages API con
  `KYQ_TWILIO_SMS_FROM`, número o Messaging Service `MG…`). Un SMS que no se pudo enviar se
  reintenta cada minuto durante 24 h. Las fechas de los avisos se muestran en hora de Colombia.
- **Rationale**: Twilio Verify (OTP de 001) no envía textos libres.

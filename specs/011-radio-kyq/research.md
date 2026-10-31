# Research: Radio Kyq

Decisiones técnicas de 011 tomadas sobre el código de 001–010 (rama `011-radio-kyq`, que contiene
010 e `integracion`).

## R1. Una sala LiveKit por conversación, con el turno de siempre

- **Decision**: cada conversación (contacto 1 a 1 o canal) tiene una sala LiveKit persistente
  `radio-{conversationId}-{hex}` creada con `CreateGroupRoom` (máx. 200 en canales, 2 en
  contactos). El turno reutiliza el patrón "fail-closed" de `ptt/floor.go` (`grantPublish` /
  `revokeThenRelease` con `SetCanPublish`), una fila de turno por conversación como
  `group_ptt_channels`, `FloorTTL = 60s`, y el estado del turno va por mensajes de datos de
  LiveKit (`floor.taken` / `floor.released`) igual que en 001. Al expulsar, salir o bloquear se
  rota la sala (`rotateGroupRoom` de 006) y los tokens duran 1 min (`GroupTokenTTL`) con
  renovación mientras la conversación está encendida.
- **Rationale**: es el motor de voz probado en 001/005/006 (latencia < 250 ms, principio II); la
  rotación de sala ya resuelve que un expulsado no vuelva a entrar con un token viejo
  (RN-KYQ-014 aplicado a 006).
- **Alternatives considered**: una sala por usuario con reenvío del servidor — LiveKit no
  reenvía entre salas sin un agente propio (código nuevo de medios, contra principio II).

## R2. Escuchar varias conversaciones: conexiones activas + cola desde el registro

- **Decision**: con "Radio encendida", la app mantiene conectada una `Room` de `livekit_client`
  por cada conversación con "Escuchar" (máximo 10, FR-024), solo para recibir; para hablar se
  pide el turno en esa misma sala. La cola (FR-025) la hace el cliente: suena en vivo solo un
  emisor a la vez (el primero que empezó); las pistas que llegan mientras otra suena se silencian
  localmente y su mensaje se reproduce **desde el registro** apenas termina el actual y el
  archivo está listo. El canal del viaje (001) y el SOS silencian la radio en vivo y la encolan.
- **Rationale**: WebRTC no permite retrasar audio en vivo sin un búfer propio; reproducir desde
  el registro da orden estricto y cero mezcla (SC-006) reutilizando R3. Diez conexiones solo de
  recepción son baratas en LiveKit propio; se mide en el piloto (phva.md §3).
- **Alternatives considered**: unirse a la sala solo cuando alguien habla (aviso por Centrifugo
  y conexión bajo demanda) — añade ~1 s de conexión y se pierde el inicio del mensaje; mezclar
  audios — es justo lo que el usuario no quiere.

## R3. Registro de cada mensaje: Track Egress automático

- **Decision**: las salas de radio se crean con egress automático por pista
  (`RoomEgress.tracks`, salida OGG/Opus) hacia el bucket `kyq-radio`. El cliente publica la pista
  de micrófono al obtener el turno y la despublica al soltar, así que cada publicación es un
  archivo = un mensaje. Al conceder el turno el backend crea el `radio_message` en estado
  `recording`; el webhook de LiveKit `egress_ended` le pone `object_key`, duración y estado
  `ready`, y publica `radio.message` a los participantes. Menos de 0,5 s se descarta y se borra.
  Vencimiento por regla de ciclo de vida del bucket (`EnsureExpiry`, 90 días: el máximo) y
  barrido diario que borra los vencidos según la retención vigente y respeta los guardados
  (guardar copia el objeto a `kyq-radio-saved/` fuera de la regla).
- **Rationale**: mismo Egress, Redis y MinIO que ya graban el SOS (003); la grabación por pista
  no compone (barato en CPU) y no depende de que el emisor suba nada.
- **Alternatives considered**: `StartRoomCompositeEgress` por mensaje como el SOS — arranque de
  1–2 s por mensaje y alto uso de CPU; grabación local en el teléfono y subida — el micrófono ya
  lo usa LiveKit y en Android abrirlo dos veces falla en varios modelos. **Spike obligatorio**
  (T004): medir que la primera sílaba queda grabada y el costo de CPU con 20 mensajes/min; si
  falla, plan B: el cliente envía también los paquetes Opus por un `DataTrack` al backend.
- **Estado (implementación)**: se implementó el plan principal detrás de la interfaz de salas
  (`radio.Rooms.CreateRadioRoom(…, record)`, `ptt.RadioRooms`): cambiar a plan B es otra
  implementación de esa interfaz y de los avisos `EgressStarted`/`EgressEnded`, sin tocar el
  resto de Radio. `KYQ_RADIO_RECORDING=false` apaga el registro. El spike T004 sigue pendiente
  en la VM.

## R4. Reproducción con velocidad sin cambiar el tono

- **Decision**: `just_audio` sobre URL prefirmada `PresignGet` (10 min) del mensaje;
  `setSpeed(1.0|1.5|2.0)` (ExoPlayer conserva el tono por defecto). La cola de "Reproducir
  nuevos" es una `ConcatenatingAudioSource`.
- **Rationale**: dependencia madura (principio II), sin procesado propio de audio.
- **Alternatives considered**: transcodificar en el servidor a varias velocidades — almacena 3
  veces y no aporta.

## R5. Presencia y estados sin notificaciones push

- **Decision**: tabla `radio_presence` (estado elegido, radio encendida, última señal). La app
  con radio encendida envía latido cada 30 s; sin latido en 90 s el usuario es Desconectado. Los
  cambios se publican por Centrifugo `radio.presence` en `user:{id}` de sus contactos y en el
  canal nuevo `radio:{conversationId}`. Los horarios de silencio se evalúan en el backend
  (barrido de 1 min con la zona horaria del usuario, `America/Bogota` por defecto).
- **Rationale**: hoy no hay FCM ni HMS (`notify/notify.go`); la radio en segundo plano se apoya en
  el servicio en primer plano de 005 con la conexión de Centrifugo viva, igual que los avisos.
- **Alternatives considered**: añadir FCM/HMS — fuera de alcance y la constitución exige
  alternativa HMS; queda como mejora (mensajes pendientes al abrir la app sí se ven: FR-010).

## R6. Alertas, texto, foto y ubicación en el mismo historial

- **Decision**: todo es un `radio_message` con `kind` (`voice`, `text`, `photo`, `location`,
  `alert`, `emergency`). La foto sube como KYC: `POST …/photos` devuelve URL `PresignPut` y la
  app comprime antes (`flutter_image_compress`, ≤ 1280 px, JPEG 75, sin EXIF). La alerta suena en
  el receptor con el tono `incoming` de `kyq_ptt` en bucle hasta 60 s o hasta abrirla.
- **Rationale**: un solo historial ordenado (FR-011) y una sola regla de retención.

## R7. Emergencia sin viaje

- **Decision**: migración que vuelve `sos_alerts.trip_id` opcional y añade `raised_from`
  (`trip` | `radio`) y `radio_conversation_id`; `safety.Service.RaiseWithoutTrip`. El webhook
  (`telemetry/livekit_webhook.go`, `roomDriver`) resuelve el conductor de salas `sos-` sin viaje
  por `raised_by`. La consola de 003 muestra "Sin viaje · desde Radio".
- **Rationale**: misma consola, mismos tiempos y grabación de 003 (RN-KYQ-015).

## R8. Políticas configurables

- **Decision**: tabla de una fila `radio_settings` (`trial_policy` `trial|subscription_only|
  listen_only`, `trial_days`, `passengers_in_channels` `none|listen_only|all_roles`,
  `retention_days` 7|30|90, `updated_by`, `updated_at`) y `radio_settings_audit` (solo
  inserción). El servicio la lee con caché de 30 s. El acceso del conductor se calcula en un solo
  lugar `radio.Access(user) → full | listen | none` (FR-005) con prueba por política.
- **Rationale**: no existe tabla genérica de configuración; una fila tipada evita valores libres.

## R9. Enlaces e invitaciones de migración

- **Decision**: `radio_invites` con código corto aleatorio (10 caracteres base62). Enlace
  `https://{KYQ_PUBLIC_HOST}/r/{code}` (página HTML servida por la API que abre
  `kyq://radio/{code}` o lleva a la tienda de la app según el tipo del invitado) y QR con el
  mismo enlace. Tras instalar: (1) Play Install Referrer con `code` cuando hay Google Play;
  (2) si la invitación tiene teléfono (carga masiva o por teléfono), se aplica sola al verificar
  ese teléfono en el OTP; (3) si no, la app ofrece "¿Tienes un enlace de invitación?" leyendo el
  portapapeles con permiso. intent-filter `kyq://radio` en las dos apps.
- **Carga masiva**: CSV (`nombre,telefono,tipo,canal,rol`) subido al panel, validación en el
  backend sin enviar nada (`dry_run`), confirmación y envío por `notify.SMSSender` a 20 SMS/s con
  reintento; estados por fila. Teléfonos normalizados a E.164 de Colombia.
- **Rationale**: reutiliza SMS (Twilio) y el patrón de QR/enlace de afiliación (008); el caso
  Huawei sin Play queda cubierto por (2) y (3).

## R10. Privacidad y acceso del personal

- **Decision**: rutas de usuario solo devuelven mensajes de conversaciones donde participa.
  `GET /v1/admin/radio/reports/{id}` es la única ruta del panel que entrega un mensaje (y su URL
  de audio o foto) y escribe en `moderation_actions`/auditoría. Borrado por cuenta eliminada:
  autor anónimo y borrado de objetos.
- **Rationale**: FR-037; el aviso y la aceptación (FR-013) quedan en `radio_consents`.

## R11. Coste medido

- **Decision**: nuevos `telemetry` kinds `RadioVoiceSeconds`, `RadioMessages`, `RadioStorageBytes`;
  `roomDriver` reconoce el prefijo `radio-` (minutos de participante al dueño o a cada conductor
  según la sala) y `cost_concept` añade `radio_storage` y `sms_invite`. La página de
  configuración muestra el costo estimado de cada retención con los datos de los últimos 30 días.

## R12. Paquete Flutter compartido

- **Decision**: paquete nuevo `packages/kyq_radio` con la lista, la conversación, el historial,
  el reproductor, los estados, el modo auto y el `RadioController` (Cubit) que usa `VoiceRoom`,
  `AudioFocus`, tonos y `PttButton` de `kyq_ptt`. Las dos apps lo montan en su ruta `/radio`;
  el conductor conecta `HandsFreePtt` (burbuja y botón) a la conversación seleccionada cuando no
  hay viaje abierto.
- **Rationale**: misma pantalla en conductor y pasajero (principio III); evita duplicar.

## Revisión clean-room (T048, principio I)

Revisado al cerrar la implementación de 011 (código, textos, íconos, colores, tonos y assets de
`packages/kyq_radio`, `kyq_ptt`, `kyq_realtime`, `kyq_api`, las dos apps, el panel y el backend):

- **Comportamiento**: el de un walkie-talkie permanente (phva.md §1.3): lista única con estado,
  botón grande central de mantener o tocar, turno único con tono de ocupado, reproducción en
  orden y modo auto. Nada se tomó de una app concreta: los flujos salen de la especificación.
- **Textos**: propios, en español, escritos para Kyq ("Radio", "Escuchar", "Solo escucha",
  "Radio encendida", "Mantén pulsado para hablar"…). Ningún nombre ni marca de terceros en
  strings, rutas, identificadores ni comentarios del código de 011 (búsqueda sin coincidencias).
- **Íconos y colores**: Material Icons de Flutter y la paleta de Kyq (verde Disponible, ámbar
  Ocupado, azul Solo escucha, gris Desconectado; cada estado con su forma además del color).
- **Tonos**: sintetizados en `kyq_ptt/tones.dart` (inicio, fin, ocupado, alerta, emergencia); no
  hay archivos de sonido de terceros.
- **Protocolos**: LiveKit (WebRTC) y Centrifugo propios de Kyq, contrato OpenAPI propio; no se
  usa ningún protocolo ni servidor de otra app. Abrir Waze o Google Maps es solo un enlace
  estándar de navegación del sistema.
- **Assets**: `kyq_radio` no trae imágenes ni sonidos.


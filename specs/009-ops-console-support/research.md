# Research: Operación del panel

## R1. Inspección del viaje desde la torre

- **Decision**: la instantánea de la torre añade `active_trip_id` a cada conductor ocupado y
  `trip_ids` a cada hexágono (la consulta de viajes activos ya trae el id). El detalle es
  `GET /v1/admin/trips/{tripId}` (solo admin) e inserta una fila en `trip_inspections` en cada
  apertura. El panel vuelve a pedir el detalle cada 5 s mientras el viaje está activo y deja de
  hacerlo al terminar.
- **Rationale**: cumple FR-003 (< 10 s) sin abrir al panel los canales de viaje de Centrifugo,
  que hoy solo autorizan a los participantes; el coste es una consulta por administrador mirando.
- **Alternatives considered**: suscribir el panel a `trip:{id}` — exigía cambiar el autorizador
  de canales y publicar la posición también allí; no aporta frente a 5 s.

## R2. Modelo del caso de soporte

- **Decision**: `support_cases` (usuario que abre, contraparte opcional para casos de pago, tema,
  viaje y pago vinculados, estado, asignado, fechas) y `support_messages` (autor, texto, interno).
  Estados `open → in_progress → waiting_user → resolved → closed`; responder el usuario a
  `waiting_user` o `resolved` lo pasa a `open`; `closed` no admite mensajes. Barrido cada minuto:
  `resolved` sin mensaje del usuario en 7 días pasa a `closed`.
- **Rationale**: el mínimo que piden FR-005–FR-012; una sola tabla de mensajes con marca de nota
  interna evita duplicar lógica y el filtro en las rutas de usuario es una condición SQL.
- **Alternatives considered**: integrar un servicio externo de tickets — rompe la vista
  unificada con 004 y añade coste; descartado.

## R3. Disputas de 004 como casos

- **Decision**: dentro de la transacción de `trippay.mutate`, si el pago pasa a `disputed` o
  `unpaid` y no tiene caso, se crea uno de tema `payment` vinculado (`trip_payment_id` único),
  abierto por quien actuó y con la otra parte como contraparte, con un primer mensaje del sistema.
  Al resolver el pago (`Resolve`, desde 004 o desde el caso) se marca el caso `resolved` con un
  mensaje del sistema. El caso resuelve el pago llamando a `trippay.Service.Resolve`, así las
  reglas de 004 no se duplican.
- **Rationale**: SC-002 exige que ambas pantallas coincidan; la misma transacción lo garantiza.
- **Alternatives considered**: crear el caso desde `support` escuchando eventos — puede perderse
  un evento y quedar desincronizado.

## R4. Soporte para usuarios suspendidos

- **Decision**: al iniciar sesión o renovarla, un usuario suspendido recibe una sesión con
  `scope = "support"` (nuevo claim). El middleware de autenticación rechaza con
  `403 account_suspended` toda ruta fuera de `/v1/support/`, `/v1/realtime/` y `/v1/auth/`.
  Las apps, con `scope = support`, solo muestran "Cuenta suspendida" y "Ayuda".
- **Rationale**: FR-011 pide que el suspendido pueda reclamar; 007 ya bloquea el resto en el
  login y aquí se bloquea en el middleware, de forma central.
- **Alternatives considered**: canal de soporte fuera de la app (correo) — contradice FR-011.

## R5. Megáfono

- **Decision**: sala LiveKit `mega-{id}` creada al empezar. El administrador recibe un token con
  permiso de publicar; los destinatarios, uno solo de escucha (`canPublish=false`,
  `canPublishData=false`). Destinatarios: conductores `presence <> offline` con ubicación ≤ 5 min
  cuya celda H3 (a la resolución del hexágono elegido) está en la selección; se fijan al empezar
  y se guardan en `megaphone_recipients`. Aviso `megaphone.started` en `user:{driverId}` con
  `broadcast_id`, `url`, `token`, `ends_at`; `megaphone.ended` al terminar. Fin: el administrador
  suelta (`POST …/end`) o el barrido corta a los 60 s y borra la sala. En la app del conductor,
  una cola reproduce los comunicados de uno en uno y espera a que termine el turno del viaje.
- **Rationale**: misma pieza que los canales de 001/006, sin grabar; los avisos por Centrifugo
  ya llegan con la app en segundo plano gracias al servicio en primer plano de 001.
- **Alternatives considered**: grabar y reenviar el audio — viola "sin grabación" y añade
  almacenamiento.

## R6. Sesiones sin fallos (Sentry)

- **Decision**: `GET {api}/api/0/organizations/{org}/sessions/` con
  `field=crash_free_rate(session)`, `project={id}`, `statsPeriod=24h|7d`, y otra consulta
  `groupBy=release`, `field=sum(session)`, `orderBy=-sum(session)`, `per_page=1` para la versión
  más usada. Configuración: `KYQ_SENTRY_API_URL` (por defecto `https://sentry.io`),
  `KYQ_SENTRY_API_TOKEN`, `KYQ_SENTRY_ORG` y `KYQ_SENTRY_PROJECTS`
  (`driver=ID,rider=ID,admin=ID`). Caché de 5 min. Sin token: `not_configured`; error o
  tiempo agotado (5 s): `unavailable`; nunca se devuelve el token ni la URL interna.
- **Rationale**: los datos ya los recoge `sentry_flutter` (sesiones activadas por defecto).

## R7. Dominios espejo y firma

- **Decision**: tabla `mirror_domains` y un contador `mirror_domains_version` que sube en cada
  cambio. `GET /v1/domains` (pública) devuelve `{payload, signature}` donde `payload` es el JSON
  `{"version":N,"issued_at":"…","domains":[{"api_url":…,"realtime_url":…}]}` y `signature` es
  Ed25519 (base64) de los bytes exactos de `payload`. Clave privada: `KYQ_DOMAINS_SIGNING_KEY`
  (semilla base64 de 32 bytes); sin clave, la ruta responde 503 y el panel avisa. La lista
  inicial de las apps se genera con `go run ./cmd/domainsign` y se pasa por `--dart-define`
  junto a la clave pública. El panel comprueba cada dominio con `GET {api_url}/healthz` (3 s) al
  abrir la página. No se puede dejar sin dominios activos (`409 last_active_domain`).
- **Rationale**: firmar los bytes del payload evita problemas de serialización canónica entre
  Go y Dart; Ed25519 es rápido, con claves cortas y disponible en ambos lados.
- **Alternatives considered**: DNS TXT o un archivo en un CDN — más piezas; JWT — sin ventaja
  sobre una firma desnuda.

## R8. Rotación en las apps

- **Decision**: `DomainRotator` en `kyq_api`: lista actual (inicial o guardada), índice en uso
  guardado, `verify(payload, signature)` con la clave pública y `version` mayor que la guardada.
  Un interceptor de Dio cuenta errores de red (conexión, tiempo de 10 s); al tercero seguido o
  ante un tiempo agotado cambia `baseUrl` al siguiente dominio y reintenta la petición una vez.
  Al conectar y cada 10 min pide `/v1/domains` al dominio actual. El tiempo real lee la URL del
  dominio en uso al reconectar. Los tokens no dependen del dominio: la sesión se conserva.
- **Rationale**: cumple FR-020–FR-022 y SC-005 (3 fallos × ≤ 10 s ≈ 30 s en el peor caso).

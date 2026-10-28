# Research: PTT extra — pre-consulta, botón físico y burbuja

## R1. Pre-consulta en vivo y no buzón de voz

- **Decision**: la pre-consulta es un canal walkie-talkie en vivo, igual que el del viaje: sala
  LiveKit `pre-{id}` con el turno exclusivo a prueba de fallos de `backend/internal/ptt`. No se
  graba ni se sube audio.
- **Rationale**: reutiliza todo lo que ya funciona y está probado (LiveKit, `PttController`,
  tonos, atenuación, permisos de publicar concedidos por el servidor); el conductor la oye en el
  momento con la navegación atenuada, que es lo que pide la regla ("le envían un audio corto
  PTT"); no añade dependencias de grabación ni reproducción en las apps, ni objetos en S3, ni
  datos de voz que proteger (constitución VII y FR-021 de 001).
- **Alternatives considered**: mensaje de voz grabado (≤ 15 s) subido a S3 con retención corta y
  reproducido al llegar. Da entrega diferida si el conductor no está conectado, pero exige
  grabadora y reproductor nuevos en las apps, URLs firmadas, borrado programado y moderación de
  audio guardado; y el caso de uso ("¿estás cerca?") pierde valor si se oye minutos después. Se
  descarta para el MVP; la bandeja muestra las consultas perdidas.

## R2. Límites

- **Decision**: turno de 15 s (`PreconsultFloorTTL`; la app suelta 1 s antes); ventana total de
  2 min desde que se abre; 30 s para que la app del conductor se conecte; una consulta abierta por
  conductor y por pasajero (índices únicos parciales); 3 por hora al mismo conductor y 6 por día
  en total por pasajero (429 `rate_limited`).
- **Rationale**: una pregunta y una respuesta caben en 15 s cada una; 2 min acota la distracción
  del conductor; los índices únicos hacen que dos peticiones simultáneas del mismo pasajero no
  puedan saltarse los límites.

## R3. Permiso del conductor

- **Decision**: interruptor global `drivers.accepts_preconsults` (desactivado por defecto) y
  silencio por cliente `affiliations.preconsults_blocked`. Desactivar o silenciar cierra en el
  acto la consulta abierta afectada. El pasajero silenciado ve lo mismo que si el conductor no
  recibiera consultas (403 `preconsults_disabled`).
- **Rationale**: "el autónomo puede autorizar" exige opt-in; el silencio por cliente cubre abusos
  sin romper la afiliación (y sin delatar el silencio).

## R4. Solo con el conductor libre

- **Decision**: abrir exige `drivers.presence = 'free'` (ONLINE y sin viaje). El barrido cierra
  la consulta con `driver_unavailable` si el conductor pasa a ocupado o desconectado.
- **Rationale**: con viaje en curso el conductor tiene su canal del viaje y no debe atender otra
  voz; desconectado no hay servicio en primer plano que reciba el audio.

## R5. Cierre y barrido

- **Decision**: misma pauta que el canal del viaje: terminar o desactivar fija `closes_at = now`
  con su motivo; el barrido (cada segundo, el mismo de `ptt.Service`) borra la sala en LiveKit,
  marca `closed_at`, publica `preconsult.closed` a ambos y deja el motivo calculado
  (`ended_by_passenger`, `ended_by_driver`, `disabled`, `missed`, `driver_unavailable`,
  `expired`). Si LiveKit no borra la sala, se reintenta. Los turnos vencidos se retiran con el
  mismo algoritmo a prueba de fallos que el viaje. Cada hora se borran las consultas cerradas
  hace más de 30 días.
- **Rationale**: un solo patrón de cierre en el módulo `ptt`; sin trabajos nuevos.

## R6. El conductor se une solo

- **Decision**: el backend publica `preconsult.opened` en `user:{driverId}`; la app del conductor
  (viva por el servicio ONLINE con tipo `microphone|mediaPlayback`) crea un `PttController` de
  consulta, toca un tono de aviso y pide el token. El primer token del conductor marca
  `joined_at` y publica `preconsult.joined` al pasajero; hasta entonces el turno del pasajero
  responde 409 `preconsult_waiting`.
- **Rationale**: el servidor garantiza que nadie habla a una sala vacía (FR-005).

## R7. Botón multimedia (Bluetooth, manos libres, volante)

- **Decision**: capa Kotlin delgada en `apps/kyq_driver_app/android` con
  `android.media.session.MediaSession` del sistema (sin dependencias), activa solo mientras hay
  un canal abierto y el conductor no la desactivó. Envía `button_down` / `button_up` a Dart por un
  `EventChannel`. La lógica (clic corto alterna, pulsación ≥ 0,5 s mantiene) está en Dart
  (`HandsFreePtt` en `kyq_ptt`) y tiene pruebas.
- **Rationale**: muchos botones de volante y auriculares solo envían "clic" (bajar y subir a la
  vez), por eso se combina alternar y mantener.
- **Alternatives considered**:
  - `audio_service` 0.18.x (mantenido): exige que la actividad sea `AudioServiceActivity` y
    arranca su propio servicio de reproducción con notificación multimedia, que choca con el
    servicio ONLINE de `flutter_foreground_task` y añade un reproductor que no se usa.
  - `hardware_button_listener` 0.0.1 (2024, sin mantenimiento): solo escucha teclas con la
    actividad en primer plano; no sirve con Waze delante.
- **Limitación conocida**: Android entrega los botones multimedia a la última sesión que
  reprodujo audio; con música sonando en otra app el clic puede ir a esa app.

## R8. Burbuja flotante

- **Decision**: capa Kotlin delgada (`WindowManager` con `TYPE_APPLICATION_OVERLAY`, una vista
  nativa redonda de 64 dp) en el mismo proceso, mostrada solo con canal abierto, permiso
  `SYSTEM_ALERT_WINDOW` concedido, la burbuja activada y Kyq en segundo plano. Toques:
  `bubble_down` / `bubble_up` por el mismo `EventChannel`; arrastrar más de 12 px mueve la
  burbuja y suelta el turno. Dart le envía el estado para el color. El permiso se pide con
  `permission_handler` (`Permission.systemAlertWindow`).
- **Rationale**: el proceso ya está en primer plano por el servicio ONLINE; una vista nativa no
  necesita un segundo motor Flutter.
- **Alternatives considered**: `flutter_overlay_window` (mantenido; 1.0.0 es la única versión
  1.x con ≥ 2 semanas). Crea un segundo motor Flutter en cada arranque de la app aunque no se
  use (memoria y batería, constitución VII), exige otro servicio en primer plano de tipo
  `specialUse` además del de ONLINE y, con arrastre activado, se traga el `ACTION_UP` tras un
  arrastre, lo que deja el turno "pulsado". Para un único botón redondo la vista nativa es más
  simple y predecible.

## R9. Un solo destino para el manos libres

- **Decision**: `HandsFreePtt` (en `kyq_ptt`) guarda una pila de controladores PTT abiertos: la
  pantalla del viaje y la consulta activa se adjuntan al abrirse y se sueltan al cerrarse; el
  botón y la burbuja actúan sobre el último. Con la pila vacía se desactiva la sesión multimedia y
  se oculta la burbuja (FR-013).
- **Rationale**: el botón y la burbuja usan exactamente el mismo `press`/`release` que el botón
  de pantalla (FR-016).

## R10. Coste medido

- **Decision**: el webhook de LiveKit atribuye los segundos de las salas `pre-{id}` al conductor
  de la consulta, igual que las `trip-{id}`; los eventos publicados cuentan en `Events`.
- **Rationale**: constitución VII.

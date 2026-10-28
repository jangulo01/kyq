# Research: SOS y consola de emergencias

## R1. Voz SOS

- **Decision**: sala LiveKit `sos-{alertId}` creada por la API al crear la alerta. La persona
  recibe un token con permiso de publicar micrófono desde el inicio (en emergencia no hay turno:
  se transmite continuo). Operadores: token sin publicar al entrar; al tomar la alerta la API les
  concede publicar (`UpdateParticipant`, como el turno de 001) y se lo retira al liberar. Los
  demás operadores escuchan.
- **Rationale**: reutiliza la integración LiveKit de 001 y el control de permisos fail-closed.
- **Alternatives**: llamada telefónica (sale de la plataforma y no se graba).

## R2. Ubicación a 1 Hz

- **Decision**: `POST /v1/sos/{alertId}/locations` con lotes (1–5 puntos) cada segundo; la API
  guarda los puntos y publica `sos.location` en `sos:{alertId}` (Centrifugo, solo operadores).
  Conductor: el servicio en primer plano existente sube la cadencia a 1 s. Pasajero: stream de
  `geolocator` con la pantalla del viaje abierta y servicio en primer plano ligero durante la
  alerta.
- **Rationale**: misma vía que la ubicación del conductor de 001; lotes toleran cortes.

## R3. Cola en tiempo real de la consola

- **Decision**: canal Centrifugo `ops:sos` (namespace `ops`, solo administradores con permiso de
  emergencias): `sos.created`, `sos.claimed`, `sos.released`, `sos.closed`, `sos.cancel_attempt`.
- **Rationale**: Centrifugo ya está; el autorizador de canales de 001 se amplía con el rol.

## R4. Grabación

- **Decision**: LiveKit Egress `RoomCompositeEgress` solo audio (OGG/Opus) hacia el bucket S3
  `kyq-sos`, iniciado al crear la sala y detenido al cerrar la alerta. Regla de ciclo de vida del
  bucket: borrar a los 90 días. Reproducción en la consola con URL firmada de 5 min.
- **Rationale**: graba en el servidor aunque el teléfono se apague (FR-018). Egress exige Redis.

## R5. Enlace compartido

- **Decision**: token aleatorio de 128 bits por enlace (`share_links`), ruta pública
  `GET /s/{token}` que sirve una página HTML embebida con MapLibre GL JS (versión fijada) y
  consulta `GET /v1/share/{token}` cada 3 s (posición, placa, nombre del conductor, estado). Sin
  teléfonos ni documentos. Expira 15 min tras terminar el viaje.
- **Rationale**: funciona en cualquier navegador sin cuenta (FR-014); sondeo simple, sin
  WebSocket público.

## R6. PIN y contactos

- **Decision**: PIN de 4 dígitos guardado con bcrypt; 5 intentos fallidos bloquean la cancelación
  hasta que el operador cierre. Contactos: hasta 3 por usuario, teléfono E.164 validado; SMS por
  la interfaz `SMSSender` de 002 con el enlace compartido.

## R7. Operadores

- **Decision**: permiso `emergency_operator` (booleano en usuarios admin) y `on_duty` con
  teléfono para la escalada SMS a los 60 s (barrido cada 10 s).

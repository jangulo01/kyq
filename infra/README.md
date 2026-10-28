# Infraestructura local

```bash
docker compose -f infra/docker-compose.yml up -d
```

| Servicio | Puerto | Uso |
|---|---|---|
| postgres | 5432 | PostgreSQL 17 + PostGIS (`kyq` / `kyq_dev`) |
| centrifugo | 8000 | Tiempo real; configuración en `centrifugo.json` |
| livekit | 7880, 7881, 7882/udp | Voz PTT y salas SOS; claves de desarrollo `devkey` / `secret` |
| redis | (interno) | Cola de LiveKit Egress (003); sin persistencia |
| egress | (interno) | LiveKit Egress: graba el audio de las salas `sos-*` en `kyq-sos` (003) |
| minio | 9000 (9001 local) | Objetos privados: fotos KYC (`kyq-kyc`) y grabaciones SOS (`kyq-sos`) |
| osrm | 5000 | Rutas, distancia y tiempo para tarifas y ETA |
| tiles | 8081 | Teselas PMTiles de la ciudad |

## Datos de la ciudad piloto

Los datos no se versionan (`infra/data/` está en `.gitignore`).

### OSRM

1. Descargar el extracto OSM de la región (por ejemplo desde Geofabrik) y recortarlo a la
   ciudad con `osmium extract` si hace falta. Guardarlo como `infra/data/osrm/city.osm.pbf`.
2. Preprocesar con el perfil de coche:

```bash
docker run --rm -t -v "$PWD/infra/data/osrm:/data" ghcr.io/project-osrm/osrm-backend:v5.27.1 osrm-extract -p /opt/car.lua /data/city.osm.pbf
docker run --rm -t -v "$PWD/infra/data/osrm:/data" ghcr.io/project-osrm/osrm-backend:v5.27.1 osrm-partition /data/city.osrm
docker run --rm -t -v "$PWD/infra/data/osrm:/data" ghcr.io/project-osrm/osrm-backend:v5.27.1 osrm-customize /data/city.osrm
```

3. Reiniciar el servicio `osrm`. Prueba:
   `curl "http://localhost:5000/route/v1/driving/-74.08,4.60;-74.05,4.65?overview=false"`.

Repetir cada mes para tener calles actualizadas.

### Teselas

Mapa base vectorial propio (sin Google ni coste por carga). `tiles/build.sh` deja en
`infra/data/tiles/`:

- `city.pmtiles`: extracto zoom 0–15 de las regiones de `tiles/regions.geojson` (Cali
  metropolitana y Bogotá, ~29 MB) desde el build diario de Protomaps
  (`https://build.protomaps.com/AAAAMMDD.pmtiles`, ver `build-metadata.protomaps.dev/builds.json`),
  con `pmtiles extract` de la imagen `protomaps/go-pmtiles`.
- `style.json`: estilo MapLibre generado con `@protomaps/basemaps` (tema claro, nombres en español)
  que apunta a `pmtiles://<base>/city.pmtiles`; MapLibre Native lee el archivo con peticiones Range.
- `fonts/` (Noto Sans, licencia OFL en `fonts/OFL.txt`) y `sprites/v4/light*` de
  `protomaps/basemaps-assets` (commit fijado en el script).

```bash
cd infra
TILES_BASE_URL=http://192.168.1.66:8081 sh tiles/build.sh 20261027   # sin fecha: build de ayer
docker compose --profile routing up -d tiles
curl -I http://localhost:8081/style.json
```

`TILES_BASE_URL` queda escrito en `style.json` (glifos, sprites y fuente), así que debe ser la URL
con la que el móvil llega al servicio. La atribución de OpenStreetMap va en la fuente del estilo y
se muestra en el botón (i) del mapa. Caddy (`tiles/Caddyfile`) sirve los archivos con CORS y
`Accept-Ranges`. En producción el mismo contenido se publica en Cloudflare R2.

La app de pasajero usa por defecto `http://<host de KYQ_API_URL>:8081/style.json`; se puede fijar
otro estilo con `--dart-define=KYQ_MAP_STYLE_URL=...`.

### Photon (buscador de direcciones, 010)

La API consulta Photon (`KYQ_GEOCODER_URL`, por defecto `http://photon:2322`) y descarta lo que
cae fuera de la caja de la ciudad (`KYQ_CITY_BBOX=minLng,minLat,maxLng,maxLat`; vacía, Bogotá:
`-74.25,4.45,-73.98,4.85`). Las búsquedas no salen de nuestra infraestructura.

1. Descargar en `infra/data/photon/` el jar de Photon y la base de datos del país **de la misma
   versión** (ver la página de versiones de komoot/photon y las descargas de GraphHopper):

```bash
mkdir -p infra/data/photon && cd infra/data/photon
curl -L -o photon.jar https://github.com/komoot/photon/releases/download/0.7.0/photon-0.7.0.jar
curl -L https://download1.graphhopper.com/public/extracts/by-country-code/co/photon-db-co-latest.tar.bz2 | tar -xj
```

   Debe quedar `infra/data/photon/photon.jar` y `infra/data/photon/photon_data/`.
2. `docker compose --profile routing up -d photon` (arranca en ~1 minuto). Prueba:
   `curl "http://localhost:2322/api?q=Andino&limit=3"`.
3. Desde la API: `GET /v1/places?q=Andino` con un token de pasajero. Sin Photon responde
   `503 places_unavailable` y la app deja marcar el punto en el mapa.

Repetir la descarga cada pocos meses para tener direcciones nuevas.

## Documentos KYC en MinIO (002)

- La API guarda las fotos de los documentos en el bucket privado `kyq-kyc` (job `minio-init`) y
  entrega URLs firmadas de corta duración. Credenciales en el `.env`: `KYQ_S3_ACCESS_KEY` y
  `KYQ_S3_SECRET_KEY` (`openssl rand -hex 16`), que son también el usuario y la clave raíz de MinIO.
- `KYQ_S3_PUBLIC_ENDPOINT` es la URL con la que el móvil y el panel llegan a MinIO para subir y ver
  las fotos (por defecto `http://KYQ_PUBLIC_HOST:9000`); dentro de Docker la API usa
  `http://minio:9000`. La consola de MinIO (9001) solo escucha en la máquina.
- En producción el mismo bucket va en Cloudflare R2: `KYQ_S3_ENDPOINT` y `KYQ_S3_PUBLIC_ENDPOINT`
  con la URL S3 de R2 y `KYQ_S3_REGION=auto`.

## Pagos con Bold (002 y 004)

Bold cobra la suscripción del conductor (002) y, si el conductor lo acepta, el viaje (004). Con
`KYQ_BOLD_ENV` vacío los pagos con Bold quedan desactivados (la API lo avisa al arrancar); el pago en
efectivo del viaje funciona igual.

| Variable | Valor |
|---|---|
| `KYQ_BOLD_ENV` | vacío (desactivado), `sandbox` o `production` |
| `KYQ_BOLD_IDENTITY_KEY` | llave de identidad (panel de Bold → Integraciones → Llaves de API); en `sandbox`, la de pruebas |
| `KYQ_BOLD_SECRET_KEY` | llave secreta; firma los webhooks en `production` (en `sandbox` Bold firma con llave vacía) |
| `KYQ_BOLD_API_URL` | opcional; por defecto `https://integrations.api.bold.co` |

Las llaves nunca se versionan: solo en `infra/.env` (`chmod 600`).

**Confirmación de pagos.** La API consulta a Bold cada 10 s los enlaces de pago abiertos de
suscripciones y viajes, así que en la VM de desarrollo (sin HTTPS público) los pagos se confirman
sin webhook. El webhook acelera la confirmación y es obligatorio en producción:

1. Publicar la API detrás de HTTPS con un dominio (por ejemplo Caddy o Cloudflare Tunnel delante del
   puerto 8080): el webhook necesita una URL pública con `https://`.
2. En el panel de Bold, en la configuración de webhooks de la integración, registrar
   `https://<dominio>/v1/billing/bold/webhook`. Es la misma URL para suscripciones (002) y pagos de
   viajes (004): la API reparte cada notificación según su referencia.
3. Con `KYQ_BOLD_ENV=production` la API comprueba la cabecera `x-bold-signature` (HMAC-SHA256 con
   `KYQ_BOLD_SECRET_KEY`); una firma inválida responde 401 y no cambia nada. Las notificaciones
   repetidas no abonan dos veces.
4. Prueba: pagar con una tarjeta de pruebas en `sandbox` y comprobar en el log de la API el webhook
   recibido y que la suscripción o el pago del viaje pasan a pagados.

En la app del pasajero el checkout de Bold se abre en una Custom Tab (Android) y la app vuelve a
consultar el pago al regresar.

## Operación del panel (009)

- **Soporte**: no necesita configuración. Los casos se abren desde "Ayuda" en las dos apps; las
  disputas de efectivo y los "no me pagó" de 004 crean su caso de pago solos. Un usuario
  suspendido entra solo a "Ayuda". El canal `admin:support` usa el namespace `admin` de Centrifugo
  que ya existe para la torre.
- **Megáfono**: usa el mismo LiveKit (salas `mega-{id}` de hasta 60 s, sin grabación).
- **Sesiones sin fallos** (Salud): `KYQ_SENTRY_API_TOKEN` (token de lectura con `org:read` y
  `project:read`), `KYQ_SENTRY_ORG` y `KYQ_SENTRY_PROJECTS=driver=ID,rider=ID,admin=ID` (ids de
  los proyectos de Sentry de cada app); `KYQ_SENTRY_API_URL` solo si no es `https://sentry.io`. Sin
  token, Salud muestra "no configurado".
- **Dominios espejo**: la API firma la lista con `KYQ_DOMAINS_SIGNING_KEY` (Ed25519). Pasos:

  ```bash
  cd backend
  go run ./cmd/domainsign -new-key                       # semilla para KYQ_DOMAINS_SIGNING_KEY
  KYQ_DOMAINS_SIGNING_KEY=… go run ./cmd/domainsign -print-public-key
  KYQ_DOMAINS_SIGNING_KEY=… go run ./cmd/domainsign \
    -api https://api.kyq.co -realtime wss://rt.kyq.co/connection/websocket \
    -api https://api2.kyq.co -realtime wss://rt2.kyq.co/connection/websocket
  ```

  La clave pública y la lista inicial firmada se pasan a las apps al compilar:
  `--dart-define=KYQ_DOMAINS_PUBLIC_KEY=…` y `--dart-define=KYQ_DOMAINS_BOOTSTRAP='{"payload":…}'`.
  Sin clave pública las apps usan solo `KYQ_API_URL`. Los dominios se administran en Panel →
  Dominios; las apps piden la lista al conectar y cada 10 minutos, y tras 3 fallos de red seguidos
  pasan al siguiente dominio activo sin cerrar la sesión. El tiempo real toma el dominio en uso al
  abrir la app. Cambiar la clave exige publicar nuevas versiones de las apps.

## Radio Kyq (011)

- **Buckets**: `kyq-radio` (mensajes de voz y fotos) y `kyq-radio-saved` (guardados). El job
  `minio-init-radio` los crea; la API les pone al arrancar la regla de ciclo de vida de 90 y 366
  días (`EnsureExpiry`). La retención real (7, 30 o 90 días) la aplica el barrido diario según
  Panel → Configuración de Radio.
- **Registro**: cada sala `radio-*` se crea con egress automático por pista (OGG/Opus) hacia
  `kyq-radio`, con las mismas credenciales S3 de la API; el webhook de LiveKit
  (`/v1/livekit/webhook`) marca cada mensaje como listo. `KYQ_RADIO_RECORDING=false` lo apaga.
- **Enlaces de invitación**: `KYQ_PUBLIC_BASE_URL/r/{code}` abre `kyq://radio/{code}` o lleva a
  la tienda (`KYQ_PLAY_DRIVER_URL`, `KYQ_PLAY_RIDER_URL`). Las cargas masivas envían SMS con el
  mismo proveedor de 002/003 (`KYQ_TWILIO_SMS_FROM`).

## SOS y consola de emergencias (003)

- **Grabación**: `egress` (LiveKit Egress, configuración en `egress.yaml`) recibe por Redis las
  órdenes de la API (`StartRoomCompositeEgress` solo audio, OGG/Opus) y sube
  `sos/{alertId}.ogg` al bucket `kyq-sos`. Las credenciales S3 le llegan por
  `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` (las de MinIO del `.env`). El job
  `minio-init-sos` crea el bucket y la API le pone al arrancar la regla de ciclo de vida que borra
  el audio a los 90 días (también válida en Cloudflare R2). Sin egress, poner
  `KYQ_SOS_RECORDING=false`: las alertas funcionan igual, sin grabación.
- **Redis** solo existe por Egress (desviación registrada en el plan de 003); `livekit.yaml` lo
  declara para que el servidor publique las peticiones de grabación.
- **Centrifugo**: namespaces `ops` (cola `ops:sos`) y `sos` (`sos:{alertId}`, ubicación a 1 Hz),
  solo para administradores con permiso de operador de emergencias.
- **Operadores**: la semilla deja al administrador de `KYQ_SEED_ADMIN_PHONE` como operador de
  emergencias de guardia (tabla `emergency_operators`). La guardia se cambia desde la consola; a
  los 60 s sin tomar una alerta se avisa por SMS a los de guardia (`KYQ_TWILIO_SMS_FROM`; vacío o
  con OTP de desarrollo, solo se registra en el log).
- **Viaje compartido**: la API sirve la página pública `GET /s/{token}` (MapLibre GL JS 4.7.1 y
  pmtiles 3.2.1 desde unpkg con SRI) y `GET /v1/share/{token}`. El mapa usa `KYQ_MAP_STYLE_URL`
  o el servicio `tiles` del mismo host (puerto 8081, perfil `routing`).

Comprobar tras `docker compose up -d`:

```bash
docker compose logs egress | tail          # "service ready" y conectado a Redis
docker compose run --rm minio-init-sos ls local/   # lista los buckets: kyq-kyc y kyq-sos
```

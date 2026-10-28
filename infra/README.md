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

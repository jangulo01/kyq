# Infraestructura local

```bash
docker compose -f infra/docker-compose.yml up -d
```

| Servicio | Puerto | Uso |
|---|---|---|
| postgres | 5432 | PostgreSQL 17 + PostGIS (`kyq` / `kyq_dev`) |
| centrifugo | 8000 | Tiempo real; configuración en `centrifugo.json` |
| livekit | 7880, 7881, 7882/udp | Voz PTT; claves de desarrollo `devkey` / `secret` |
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

Generar un PMTiles de la ciudad con el CLI `pmtiles extract` a partir de un build de Protomaps y
guardarlo como `infra/data/tiles/city.pmtiles`. En producción se publica en Cloudflare R2.

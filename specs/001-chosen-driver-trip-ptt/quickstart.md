# Quickstart: validar el MVP 001 de punta a punta

## Requisitos

- Flutter 3.44+, Melos 7, Go 1.24+, Docker, Android SDK
- Dos teléfonos Android 10+ (uno idealmente sin servicios de Google) en la misma red 4G o Wi-Fi
- Extracto OSM y PMTiles de la ciudad piloto en `infra/data/` (ver README de infra)

## Arranque

```bash
docker compose -f infra/docker-compose.yml up -d
cd backend && go run ./cmd/migrate up && go run ./cmd/api
```

```bash
melos run test
flutter run -d <telefono_conductor> apps/kyq_driver_app
flutter run -d <telefono_pasajero> apps/kyq_rider_app
```

Datos de arranque: desde Kyq Admin web, crear un conductor, registrar su suscripción, aprobar sus
tres documentos y definir la tabla de tarifas de la ciudad
([contracts/api.yaml](contracts/api.yaml), rutas `/v1/admin/*`).

## Escenarios

| # | Pasos | Resultado esperado | Requisitos |
|---|---|---|---|
| 1 | Pasajero escanea el QR del conductor | Conductor en "Mis Conductores Elegidos"; pasajero en la cartera del conductor | FR-005–007, SC-001 |
| 2 | Conductor se pone ONLINE | Pasajero lo ve "Libre" en < 5 s | FR-008, SC-002 |
| 3 | Pasajero pide viaje; conductor acepta con tarifa sugerida | Ambos ven ACCEPTED; botón PTT activo sin pasos extra | FR-009–013, FR-016 |
| 4 | Pasajero mantiene pulsado y habla con la app del conductor en segundo plano y Google Maps navegando | Voz suena en altavoz, la navegación baja volumen | FR-017–019, SC-005, SC-006 |
| 5 | Ambos pulsan a la vez | Solo uno transmite; el otro ve "canal ocupado" | FR-017 |
| 6 | Conductor marca llegada, inicio y fin | Estados iguales en ambas apps; resumen con comisión 0 | FR-013, FR-015, SC-007 |
| 7 | Esperar 15 min tras COMPLETED | Botón PTT desaparece; `ptt/token` responde 410 | FR-020 |
| 8 | Nueva oferta; conductor no responde | A los 25 s el pasajero recibe aviso | FR-011 |
| 9 | Conductor acepta con otra tarifa; pasajero no confirma | A los 30 s viaje cancelado sin cargo | FR-010a |
| 10 | Conductor propone negociar; pasajero acepta; intercambian 2 propuestas y aceptan | ACCEPTED con la tarifa acordada | FR-010c |
| 11 | Admin pone `paid_until` 73 h en el pasado; conductor intenta ONLINE | Bloqueado con motivo "suscripción suspendida" | FR-002 |
| 12 | Repetir 11 con un viaje en curso | El viaje continúa hasta COMPLETED | FR-003 |

## Medición

- Latencia de voz: grabar ambos teléfonos con un tercer dispositivo y medir del inicio de la
  palabra al sonido en el receptor, 20 muestras (SC-005).
- Tiempos de oferta y presencia: marcas de tiempo de los eventos `trip.offer` y
  `driver.presence` frente a la petición (SC-002, SC-004).

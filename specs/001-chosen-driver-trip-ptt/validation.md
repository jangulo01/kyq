# Validación: MVP Conductor Elegido + Viaje + PTT 1 a 1

Resultados de T079 y T080 ([quickstart.md](quickstart.md)). Entorno: backend y servicios en la VM
de desarrollo (192.168.1.66, Docker), apps debug en un Redmi Note 13 Pro+ 5G (HyperOS, con Google
Play Services) por Wi-Fi en la misma LAN.

## T080. Medición

### SC-004 y SC-002 (2026-10-27)

Script reproducible: [`infra/measure/latency.py`](../../infra/measure/latency.py). Cliente
Centrifugo real (protocolo JSON) para conductor y pasajero, 20 solicitudes seguidas; cada oferta
se rechaza para liberar al conductor. Latencia medida en el mismo reloj, desde el envío de la
petición HTTP hasta la llegada del evento por WebSocket.

| Criterio | Medido | Mediana | p95 | Máx. | Límite | Resultado |
|---|---|---|---|---|---|---|
| SC-004 oferta al conductor | `POST /v1/trips` → `trip.offer` | 36 ms | 49 ms | 120 ms | 3 s (p95) | Cumple |
| SC-002 conductor pasa a ocupado | `POST /v1/trips` → `driver.presence` busy | 36 ms | 49 ms | 121 ms | 5 s | Cumple |
| SC-002 conductor vuelve a libre | `POST .../reject` → `driver.presence` free | 27 ms | 40 ms | 44 ms | 5 s | Cumple |

Pendiente: repetir con los teléfonos en 4G fuera de la LAN y el backend en el servidor de
producción; la red móvil añadirá su latencia, pero el margen es de dos órdenes de magnitud.

### SC-005 (voz < 250 ms en 4G, p95)

**Sin medir.** Requiere dos teléfonos y un tercer dispositivo grabando ambos (quickstart). Con un
solo teléfono se comprobó el flujo (turno concedido, permiso de publicar en LiveKit, pista
publicada y retirada), no la latencia boca-oído.

Riesgo conocido: desde la revisión de seguridad el micrófono se publica al obtener el turno (no
al conectar), así que cada pulsación incluye negociar la pista con LiveKit además de
`POST /ptt/floor` (≈ 10 ms en la LAN). Esa negociación retrasa el inicio de la transmisión, no la
latencia de la voz ya en curso; hay que medir ambas. Si el arranque supera lo aceptable, la
alternativa es mantener la pista publicada y silenciada y que el backend la silencie en LiveKit
(`MutePublishedTrack`) cuando no se tiene el turno.

## T079. Teléfono sin Google Play Services (Huawei)

**Pendiente: no hay un Huawei disponible.** Lo previsto para ese teléfono:

- Ubicación: `geolocator` con `forceLocationManager` (R6), implementado en
  `apps/kyq_driver_app/lib/background/geolocator_source.dart`.
- Sin push (R4): no depende de FCM.
- Mapas: MapLibre con teselas propias (PMTiles), sin Google Maps SDK.

Escenarios a ejecutar: 2–7 de [quickstart.md](quickstart.md) con el conductor en el Huawei.

## Escenarios verificados en el Redmi

| # | Escenario | Resultado |
|---|---|---|
| 2 | Conductor ONLINE; el pasajero lo ve "Libre" | OK |
| 3 | Solicitud con tarifa sugerida (OSRM), aceptación, botón PTT activo sin pasos extra | OK |
| 4 | Pulsar y hablar | Parcial: turno, permiso y publicación de la pista verificados en LiveKit; voz no escuchada (un solo teléfono) |
| 5 | Ambos pulsan a la vez | Cubierto por pruebas del backend (409 y permiso de LiveKit); no se puede con un teléfono |
| 6 | Llegué, Iniciar, Finalizar; resumen con comisión 0 | OK |
| 7 | Cierre del canal | OK al cancelar: sala borrada, `ptt.closed`, botón oculto; el cierre a los 15 min está cubierto por pruebas |
| — | App reiniciada con viaje en curso | OK: aviso "Tienes un viaje en curso" en ambas apps (`GET /v1/trips/active`) |
| — | LiveKit reiniciado con la sala activa | OK: la app pide un token nuevo y vuelve a entrar |
| — | Minutos de voz por conductor (T077) | OK: 82 s de participante registrados tras cancelar un viaje |

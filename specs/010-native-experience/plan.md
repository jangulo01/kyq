# Implementation Plan: Experiencia nativa: cartera con notas y agenda, llegada automática, escaneo de documentos, direcciones y mapa

**Branch**: `010-native-experience` | **Date**: 2026-10-28 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/010-native-experience/spec.md`

## Summary

1. **Agenda**: módulo nuevo `reservations` con la reserva (pendiente → confirmada → cumplida, o
   rechazada, cancelada, vencida, perdida). Un barrido cada 10 s vence las no confirmadas a 15
   minutos, avisa 30 minutos antes y, a la hora, crea la solicitud nominal con
   `trips.Service.RequestWith` y la tarifa reservada (la oferta lleva `reservation: true`).
2. **Cartera**: ficha del cliente (`GET /v1/driver/clients/{passengerId}`) con viajes juntos,
   último viaje, origen y próximas reservas, y nota privada (`PUT …/note`) que viaja en
   `trip.offer` como `client_note` solo al conductor; se borra al quitar la afiliación.
3. **Llegada automática**: la ubicación del conductor trae `accuracy_m`; con un viaje aceptado,
   `trips.Service.ObserveArrival` guarda desde cuándo está a < 60 m (`trips.near_pickup_since`) y
   marca "llegó" tras 10 s seguidos con precisión ≤ 50 m.
4. **Escaneo**: ML Kit Document Scanner (`google_mlkit_document_scanner`) detecta bordes, recorta y
   endereza; sin Google Play Services, recorte manual de cuatro esquinas con `image`
   (`copyRectify`). Antes de subir, la varianza del laplaciano avisa de fotos borrosas.
5. **Direcciones**: `GET /v1/places?q=` hace de proxy a un geocodificador OpenStreetMap propio
   (Photon), limitado a la caja de la ciudad; la app guarda en el teléfono Casa, Trabajo y los 10
   destinos recientes.
6. **Mapa**: el seguimiento interpola la posición del conductor entre ubicaciones y lo orienta por
   rumbo; el inicio del pasajero muestra a sus Conductores Elegidos libres como pines dorados en el
   centro de su hexágono H3 de resolución 8 (`ChosenDriver.zone`).

## Technical Context

**Language/Version**: Dart 3.12 / Flutter 3.44 (apps); Go 1.26 (backend)

**Primary Dependencies**: las existentes (pgx, sqlc, goose, PostGIS, h3-go, Centrifugo, MapLibre).
Nuevas en las apps: `google_mlkit_document_scanner` (conductor), `image` (recorte manual y nitidez)
y `shared_preferences` (destinos del pasajero). Servicio nuevo opcional: Photon (geocodificador
OSM) en `infra/`.

**Storage**: PostgreSQL 17; migración `00015_native_experience.sql` ([data-model.md](data-model.md)).

**Testing**: unidad (máquina de estados de la reserva, geocerca, nitidez, recorte, interpolación,
destinos), integración con base real (reservas y barrido, notas, llegada automática, zona de los
Conductores Elegidos), contrato y cubit/widget.

**Target Platform**: Android 10+ (conductor y pasajero), navegador (panel).

**Project Type**: mobile + web admin + API (monorepo existente).

**Performance Goals**: oferta de la reserva < 5 s tras la hora (barrido de 10 s); sugerencias en
< 1 s (geocodificador local, caché de 10 min); interpolación a 60 fps de un solo punto.

**Constraints**: la nota nunca sale hacia el pasajero (SC-005); la zona del conductor nunca más
precisa que res. 8; los destinos guardados solo en el teléfono.

## Constitution Check

| Principio | Cumplimiento |
|---|---|
| I. Clean-room | Diseño propio a partir del SDD de Kyq. |
| II. Adoptar antes que construir | ML Kit para bordes, `image` para el recorte manual, Photon (OSM) para direcciones, H3 para la zona. |
| III. Flutter | Cambios en las apps y paquetes compartidos. |
| IV. Monolito modular Go | Módulos nuevos `reservations` y `places`; llegada en `trips`; notas en `drivers`; zona en `affiliations`. |
| V. Reglas como contrato | RN-KYQ-005 y RN-KYQ-007 (reserva solo con el Conductor Elegido y oferta nominal de 25 s), RN-KYQ-001 (sin cargo ni comisión). |
| VI. Pruebas | Según Technical Context. |
| VII. Coste medido | Geocodificador propio sin coste por consulta; sin rutas extra (la tarifa se cotiza una vez al reservar). |

Sin desviaciones.

## Project Structure

```text
specs/010-native-experience/
├── plan.md · research.md · data-model.md · quickstart.md · tasks.md
├── contracts/api.yaml      # vista de rutas nuevas (fusionadas en 001)
└── checklists/requirements.md

backend/
├── migrations/00015_native_experience.sql
├── internal/reservations/   # reservas, agenda, barrido
├── internal/places/         # proxy al geocodificador
├── internal/trips/          # tarifa reservada, llegada automática, nota en la oferta
├── internal/drivers/        # accuracy_m, ficha del cliente y nota
└── internal/affiliations/   # zona aproximada; borrar nota al quitar la afiliación
apps/kyq_rider_app/lib/reservations/   # reservar y mis reservas
apps/kyq_rider_app/lib/places/         # buscador y destinos guardados
apps/kyq_rider_app/lib/map/            # interpolación y pines dorados
apps/kyq_driver_app/lib/reservations/  # agenda
apps/kyq_driver_app/lib/onboarding/    # ficha del cliente, escaneo de documentos
infra/                                 # Photon
```

## Complexity Tracking

Sin violaciones que justificar.

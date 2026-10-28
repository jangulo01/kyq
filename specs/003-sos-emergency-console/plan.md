# Implementation Plan: Botón SOS, viaje compartido y consola de emergencias

**Branch**: `003-sos-emergency-console` | **Date**: 2026-10-27 | **Spec**: [spec.md](spec.md)

## Summary

Botón SOS (pulsación de 2 s) en las pantallas de viaje del pasajero y del conductor: crea una
alerta, envía la ubicación cada segundo y abre una sala LiveKit `sos-{alertId}` con los
operadores. Consola web de emergencias con cola en tiempo real (Centrifugo), mapa en vivo,
escucha/intervención por voz, notas y cierre. Enlace público del viaje en vivo servido por la
API. Contactos de emergencia avisados por SMS y PIN contra coacción. Grabación del audio SOS con
LiveKit Egress a S3 (MinIO/R2) durante 90 días.

## Technical Context

**Language/Version**: Dart 3.12 / Flutter 3.44; Go 1.26.

**Primary Dependencies**: las de 001–002. Nuevas: servicio **LiveKit Egress** (grabación de
audio a S3) y **Redis** (requisito de Egress); `golang.org/x/crypto/bcrypt` para el PIN;
`share_plus` en las apps; MapLibre GL JS (CDN fijado) en la página del enlace compartido.

**Storage**: PostgreSQL (tablas en [data-model.md](data-model.md)); grabaciones en el bucket
privado `kyq-sos` con regla de expiración de 90 días.

**Testing**: como 001–002; pruebas de integración del ciclo de alerta, tokens LiveKit de
operador/usuario, enlace compartido y privacidad.

**Target Platform**: Android (apps), navegador (consola y enlace compartido).

**Performance Goals**: alerta en consola < 5 s p95 (SC-001); ubicación < 3 s de retraso.

**Constraints**: la otra parte del viaje no se entera del SOS; el enlace no expone teléfonos;
solo operadores con permiso ven alertas y grabaciones.

**Scale/Scope**: piloto; decenas de alertas al mes, 1–3 operadores.

## Constitution Check

| Principio | Cumplimiento |
|---|---|
| I. Clean-room | Diseño propio. |
| II. Adoptar | LiveKit (sala y Egress) para voz y grabación; Centrifugo para la cola; MapLibre en la web. |
| III. Flutter | Botón SOS, contactos y PIN en las apps; consola en `kyq_admin_web`. La página del enlace compartido es HTML estático servido por la API (ver Complexity Tracking). |
| IV. Monolito Go | Módulo nuevo `safety`. |
| V. Reglas | RN-KYQ-015 con prueba de integración (alerta → ubicación 1 Hz → sala con operadores). |
| VI. Pruebas | Unidad, integración, widget (botón SOS, consola). |
| VII. Coste | Egress y Redis solo graban SOS; medidos en `driver_usage_daily` como voz. |

## Project Structure

```text
backend/internal/safety/     # alertas, ubicación, operadores, notas, enlace compartido, contactos, PIN, grabación
backend/migrations/00008_safety.sql
backend/web/share/           # página HTML del viaje compartido (embebida en el binario)
apps/kyq_driver_app/lib/safety/, apps/kyq_rider_app/lib/safety/   # botón SOS, contactos, PIN, compartir
packages/kyq_ui/lib/src/safety/                                  # SosButton y pantallas comunes
apps/kyq_admin_web/lib/emergencies/                              # consola
infra/                       # egress + redis, bucket kyq-sos con expiración 90 días
```

## Complexity Tracking

| Desviación | Por qué | Alternativa descartada |
|---|---|---|
| Redis (R13 de 001 lo excluía) | Lo exige LiveKit Egress para grabar el audio SOS (FR-018) | Grabar en el teléfono y subir: se pierde si el teléfono se apaga, que es justo el caso de emergencia |
| Página HTML del enlace compartido fuera de Flutter | Se abre en cualquier navegador sin instalar; una página de 1 archivo carga en < 1 s en 4G, Flutter web pesa varios MB | Flutter web (carga lenta para un contacto que solo quiere ver el mapa) |

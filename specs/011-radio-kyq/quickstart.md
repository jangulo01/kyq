# Quickstart: validar 011 en la VM

Requisitos: backend, Centrifugo, LiveKit, Egress, Redis y MinIO de la VM (README de `infra/`);
**dos teléfonos Android** con Kyq Conductor (Carlos y Jonathan) y un tercero o el mismo con Kyq
Pasajero (Ana); el panel en un navegador. El resultado de cada paso se registra en
`validation.md` (fecha, commit, teléfonos).

Variables nuevas del backend:

| Variable | Uso |
|---|---|
| `KYQ_S3_RADIO_BUCKET` | bucket de mensajes (`kyq-radio`, vence a 90 días) |
| `KYQ_S3_RADIO_SAVED_BUCKET` | bucket de guardados (`kyq-radio-saved`, vence a 366 días) |
| `KYQ_PLAY_DRIVER_URL`, `KYQ_PLAY_RIDER_URL` | tienda de cada app para la página `/r/{code}` |

## 1. Radio 1 a 1 (US1, US2)

1. Carlos abre Radio, acepta el aviso de registro y toca "Agregar contacto". Jonathan escanea el
   QR y acepta: ambos se ven en la lista, en verde y sin teléfono.
2. Con las dos pantallas bloqueadas, Carlos mantiene pulsado y habla 5 s: Jonathan lo oye en el
   acto. Jonathan responde. Mientras uno habla, el otro ve quién tiene el turno y oye el tono de
   ocupado si intenta.
3. Mide la latencia como en SC-005 de 001 (grabación de los dos teléfonos): p95 < 250 ms.
4. Jonathan activa el modo avión; Carlos envía 3 mensajes. Jonathan vuelve: ve "3 nuevos", los
   reproduce en cola, repite uno a 1,5x y 2x (tono igual) y guarda uno.
5. Pulsación de 0,3 s: no aparece en el historial.

## 2. Canales y cooperativa (US4, US7)

1. Jonathan crea "Taxistas Norte" con aprobación y comparte el QR; Carlos pide entrar y Jonathan
   lo aprueba y lo nombra moderador.
2. Con 3 miembros hablando por turnos, el turno es único; a los 60 s se corta solo.
3. Carlos silencia a un miembro (no puede hablar) y lo expulsa (sale y pierde el historial).
4. El canal de la cooperativa de 006 aparece en la lista; "Salir" no está disponible.
5. Con "Escuchar" encendido en la cooperativa, Taxistas Norte y Jonathan, dos mensajes a la vez
   se oyen uno tras otro, sin mezclarse; durante un viaje, la voz del viaje suena primero.

## 3. Clientes (US3)

1. Sin "Radio con mis clientes", Ana no ve a Carlos en Radio. Carlos la activa: Ana lo ve.
2. Ana le deja un mensaje y toca "Pedir viaje": abre la solicitud a Carlos.
3. Carlos silencia a Ana (su mensaje no suena) y la bloquea (Ana ve que no puede enviar).

## 4. Migración y configuración (US10, FR-040)

1. Desde un teléfono sin la app, abre el enlace de un canal: lleva a la tienda; tras instalar y
   registrarse, queda dentro del canal sin volver a abrir el enlace (< 3 min).
2. En el panel sube un CSV de 50 filas con 3 errores: los errores se ven antes de enviar;
   confirma; los estados cambian a enviada/aceptada; reenvía las fallidas.
3. En Configuración de Radio prueba las tres políticas con un conductor sin suscripción:
   prueba (habla y ve los días restantes), solo con suscripción (no entra), solo escucha (oye y
   no transmite). Cambia la retención: se ve el costo estimado y queda en la bitácora.
4. Permite pasajeros "Solo escucha" en canales: Jonathan admite a Ana como oyente.

## 5. Comodidad, emergencia y control (US5, US6, US8, US9, US11)

1. Carlos en Ocupado: la voz no suena y queda como nueva. Programa un horario de silencio que
   empieza en 2 minutos: cambia solo.
2. Jonathan envía una alerta con texto: suena y vibra en Ocupado hasta abrirla; la cuarta en 10
   min se rechaza.
3. Texto, foto (sin ubicación en los metadatos) y ubicación aparecen en el historial; la
   ubicación abre Waze.
4. Con Waze delante y la pantalla bloqueada, la voz suena bajando la navegación; Carlos responde
   con el botón Bluetooth y con la burbuja; abre el modo auto y cambia de conversación.
5. Sin viaje, Carlos mantiene pulsado Emergencia: la consola de 003 muestra "Sin viaje · desde
   Radio" con ubicación y voz; Taxistas Norte y la cooperativa reciben el aviso aun en Ocupado.
6. Ana reporta un mensaje; el administrador lo abre (solo ese mensaje), lo borra y suspende el
   canal; el acceso queda registrado. Economía unitaria muestra minutos y almacenamiento de Radio.

## 6. Usabilidad y piloto (SC-001, SC-007)

Prueba con 10 usuarios de la app walkie-talkie anterior sin explicación (phva.md §3) y piloto de
2 semanas con un grupo real; registra resultados y decisiones de phva.md §4 en `validation.md`.

# Quickstart: validar 010 en la VM

Requisitos: backend de la VM con la migración 00015; Photon para el buscador (ver
`infra/README.md`, sección 010); apps de conductor y pasajero en dos teléfonos Android.

| Variable | Uso |
|---|---|
| `KYQ_GEOCODER_URL` | URL de Photon (por ejemplo `http://photon:2322`); vacía, sin buscador |
| `KYQ_CITY_BBOX` | `minLng,minLat,maxLng,maxLat` de la ciudad; por defecto Bogotá |

## 1. Agenda (US1)

1. Pasajero → Conductor Elegido → "Reservar": recogida, destino y hora dentro de 1 hora. Ve la
   tarifa y la reserva "pendiente de confirmar".
2. Conductor → Agenda: la reserva aparece; la acepta. El pasajero la ve "confirmada".
3. A los 30 minutos antes ambos ven el recordatorio; a la hora, con el conductor ONLINE y libre,
   llega la oferta de 25 s con la tarifa reservada y la etiqueta "Reserva".
4. Otra reserva sin respuesta: 15 minutos antes se cancela y el pasajero recibe el aviso.

## 2. Notas (US2)

1. Conductor → Mis clientes → Ana: ve viajes juntos, último viaje, origen y reservas; escribe
   "Recoger en la portería 2".
2. Ana pide un viaje: la oferta muestra la nota. En la app de Ana no aparece en ninguna parte.

## 3. Llegada automática (US3)

1. Con un viaje aceptado, el conductor se detiene a menos de 60 m de la recogida 10 s: el viaje
   pasa a "llegó" sin tocar la pantalla y el pasajero recibe el aviso.
2. Pasar sin detenerse no cambia el estado.

## 4. Escaneo (US4)

1. Conductor → Documentos → licencia → "Escanear": la imagen subida es solo el documento,
   recortado y derecho.
2. Una foto movida muestra el aviso de borrosa. En un teléfono sin Google Play Services se
   ajustan las cuatro esquinas a mano.

## 5. Direcciones (US5)

1. En la solicitud, escribe "Andino" y elige la sugerencia: se calcula la tarifa.
2. Guarda "Casa"; en el siguiente pedido aparecen Casa y los recientes antes de escribir.

## 6. Mapa (US6)

1. En el seguimiento, el vehículo se desplaza sin saltos y gira con el rumbo.
2. En el inicio, un Conductor Elegido libre aparece como pin dorado en su zona; al ocuparse,
   desaparece del mapa.

Registra los resultados en `validation.md`.

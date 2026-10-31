# Quickstart: validar 009 en la VM

Requisitos: backend, Centrifugo y LiveKit de la VM (README de `infra/`); apps de conductor y
pasajero en dos teléfonos Android y el panel en un navegador.

Variables nuevas del backend:

| Variable | Uso |
|---|---|
| `KYQ_DOMAINS_SIGNING_KEY` | semilla Ed25519 en base64 (32 bytes) para firmar la lista de dominios |
| `KYQ_SENTRY_API_TOKEN`, `KYQ_SENTRY_ORG`, `KYQ_SENTRY_PROJECTS` | lectura de sesiones; `KYQ_SENTRY_PROJECTS=driver=ID,rider=ID,admin=ID` |
| `KYQ_SENTRY_API_URL` | opcional, por defecto `https://sentry.io` |

Para las apps: `go run ./cmd/domainsign -print-public-key` muestra la clave pública y
`go run ./cmd/domainsign -api https://… -realtime wss://… [-api … -realtime …]` la lista
inicial; se pasan con `--dart-define=KYQ_DOMAINS_PUBLIC_KEY=…` y
`--dart-define=KYQ_DOMAINS_BOOTSTRAP=…`.

## 1. Inspección (US1)

1. Pide un viaje y acéptalo. En la torre, haz clic en el punto naranja del conductor: se abre el
   detalle en < 2 s, sin teléfonos.
2. Mueve al conductor: la posición cambia en < 10 s.
3. Haz clic en el hexágono: aparece la lista de viajes activos.
4. Abre un SOS en el viaje: el detalle muestra el aviso y el acceso a la alerta.

## 2. Soporte (US2)

1. Pasajero → Ayuda → Nuevo caso → "Objeto olvidado", asocia el último viaje y envía.
2. Panel → Soporte: el caso aparece en "sin respuesta"; asígnatelo, responde y deja una nota
   interna. El pasajero ve la respuesta en < 10 s y no ve la nota.
3. Marca el caso como resuelto; el pasajero responde y el caso vuelve a "abierto".
4. Conductor marca "No recibí el efectivo" en un viaje pagado en efectivo: aparece un caso de
   pago para los dos. Resuélvelo como "pagado" desde el caso: en Pagos de viajes queda pagado.
5. Suspende al pasajero (007) e inicia sesión de nuevo: solo ve "Cuenta suspendida" y Ayuda.

## 3. Megáfono (US3)

1. Dos conductores ONLINE en hexágonos distintos. En la torre, selecciona el hexágono del
   primero y mantén pulsado "Megáfono": solo ese conductor oye el comunicado.
2. Repite con la app del conductor en segundo plano: se oye y al volver ve el aviso.
3. Habla más de 60 s: se corta. El registro muestra autor, zonas, duración y 1 destinatario.

## 4. Sesiones sin fallos (US4)

1. Sin variables de Sentry: Salud muestra "no configurado".
2. Con las variables: porcentajes por app en 24 h y 7 días; los menores de 99 % resaltados.

## 5. Dominios espejo (US5)

1. Panel → Dominios: añade un segundo dominio activo (otro nombre apuntando a la VM).
2. Bloquea el primero en el teléfono (por ejemplo, con una entrada falsa en el DNS del router):
   la app sigue funcionando en < 30 s sin cerrar sesión.
3. Intenta desactivar todos los dominios: se rechaza.

Registra los resultados en `validation.md`.

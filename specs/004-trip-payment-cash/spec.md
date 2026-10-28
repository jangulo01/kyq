# Feature Specification: Pago del viaje con Bold o en efectivo

**Feature Branch**: `004-trip-payment-cash`

**Created**: 2026-10-27

**Status**: Draft

**Input**: User description: "El sistema debe permitir pago en efectivo; en esta opción el pasajero debe reportar que pagó de esta forma. Hoy los viajes se pagan fuera de la app (001: 0 % de comisión, 100 % para el conductor, RN-KYQ-001). Esta fase añade el pago de la tarifa dentro del flujo: al terminar el viaje (o antes) el pasajero elige cómo pagar: (a) Bold (tarjeta, PSE, Nequi) con el mismo enlace de pago de Bold que ya se usa para la suscripción en 002, o (b) efectivo: el pasajero reporta 'Pagué en efectivo' en la app y el conductor confirma 'Recibí el efectivo' (o lo disputa); ambos reportes quedan registrados. El valor es la tarifa acordada. El dinero de Bold lo recauda la cuenta Bold de Kyq y se liquida 100 % al conductor (libro de liquidación por conductor; los giros los hace un administrador a mano y los marca como pagados; sin giros automáticos); Kyq mantiene 0 % de comisión; anulaciones mínimas; si el pasajero nunca reporta hay recordatorio y el conductor puede marcar 'no pagado', visible en el panel; el conductor elige qué medios acepta."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - El pasajero paga en efectivo y el conductor lo confirma (Priority: P1)

Al terminar el viaje, el pasajero ve la tarifa acordada y las formas de pago que acepta su
conductor. Le entrega el dinero en efectivo y toca "Pagué en efectivo". El conductor ve en su app
"El pasajero dice que pagó en efectivo" y toca "Recibí el efectivo"; el viaje queda pagado y
ambos lo ven. Si el conductor no recibió el dinero, toca "No recibí el efectivo" y el caso queda
en disputa para que lo revise un administrador.

**Why this priority**: es el requisito explícito del responsable de producto y el medio de pago
más usado por los pasajeros de Kyq; sin él no se puede saber si un viaje quedó pagado.

**Independent Test**: un viaje completado; el pasajero reporta efectivo, el conductor confirma y
ambas apps muestran "Pagado en efectivo"; en otro viaje el conductor disputa y el panel lo lista
como "En disputa".

**Acceptance Scenarios**:

1. **Given** un viaje recién completado con tarifa acordada de 18 000 COP y un conductor que
   acepta efectivo, **When** el pasajero abre el resumen, **Then** ve "Total: $ 18.000", "El
   100 % es para tu conductor" y los botones "Pagar con Bold" y "Pagué en efectivo".
2. **Given** ese resumen, **When** el pasajero toca "Pagué en efectivo" y confirma, **Then** el
   pago queda "Efectivo reportado: esperando confirmación del conductor" con la hora del reporte,
   y el conductor recibe el aviso en vivo.
3. **Given** un efectivo reportado, **When** el conductor toca "Recibí el efectivo", **Then** el
   pago queda "Pagado en efectivo" en las dos apps con la hora de la confirmación.
4. **Given** un efectivo reportado, **When** el conductor toca "No recibí el efectivo" y
   confirma, **Then** el pago queda "En disputa", el pasajero lo ve y el panel lo lista para
   revisión.
5. **Given** un viaje completado en el que el pasajero no reportó nada, **When** el conductor
   recibió el efectivo y toca "Recibí el efectivo", **Then** el pago queda pagado sin esperar el
   reporte del pasajero.
6. **Given** un conductor que no acepta efectivo, **When** el pasajero abre el resumen, **Then**
   no ve "Pagué en efectivo" y el backend rechaza ese reporte.

---

### User Story 2 - El pasajero paga con Bold y el dinero se liquida 100 % al conductor (Priority: P1)

El pasajero toca "Pagar con Bold" y paga la tarifa acordada con tarjeta, PSE o Nequi en el
checkout de Bold sin salir de la app. Cuando Bold confirma, el viaje queda pagado, el conductor lo
ve y el valor completo se abona en su libro de liquidación: Kyq lo recauda en su cuenta de Bold y
se lo gira al conductor, sin comisión.

**Why this priority**: muchos pasajeros no llevan efectivo; cobrar con el mismo Bold de la
suscripción no añade proveedores y mantiene el 0 % de comisión (RN-KYQ-001).

**Independent Test**: en el sandbox de Bold, el pasajero paga un viaje de 18 000 COP; el pago
queda aprobado, el conductor ve "Pagado con Bold" y su saldo por liquidar sube exactamente
18 000 COP con comisión 0.

**Acceptance Scenarios**:

1. **Given** un viaje completado y un conductor que acepta Bold, **When** el pasajero toca
   "Pagar con Bold", **Then** se abre el checkout de Bold con el valor exacto de la tarifa
   acordada, sin que el pasajero pueda cambiarlo.
2. **Given** un pago aprobado por Bold, **When** el pasajero vuelve a la app, **Then** ve
   "Pagado con Bold" en menos de 1 minuto y el conductor recibe un aviso "Pago recibido".
3. **Given** un pago aprobado de 18 000 COP, **When** se abona al conductor, **Then** su libro
   muestra un abono de 18 000 COP (100 %) y la comisión de Kyq es 0 (RN-KYQ-001).
4. **Given** un pago rechazado o un enlace que caduca sin pagar, **When** el pasajero vuelve,
   **Then** ve "El pago no se completó" y puede intentarlo otra vez o reportar efectivo.
5. **Given** que Bold notifica dos veces el mismo pago aprobado (webhook y consulta), **When** se
   procesan, **Then** el abono al conductor se registra una sola vez.
6. **Given** un pago por PSE "en proceso", **When** el pasajero intenta reportar efectivo,
   **Then** se le indica que espere el resultado de Bold.

---

### User Story 3 - Viajes sin pagar: recordatorio y "no pagado" (Priority: P1)

Si el pasajero cierra la app sin pagar ni reportar, recibe un recordatorio y, cada vez que abre
la app, ve "Tienes un viaje sin pagar" con acceso directo al pago. El conductor recibe un aviso
para confirmar si le pagaron; si no le pagaron, marca el viaje como "No pagado" y el caso queda
visible en el panel. El pasajero todavía puede pagarlo después.

**Why this priority**: sin cierre, el conductor pierde dinero sin evidencia y el administrador no
puede actuar con pasajeros que no pagan.

**Independent Test**: un viaje completado sin reporte; a los 10 minutos el pasajero recibe el
recordatorio y el conductor un aviso; el conductor marca "No pagado" y el panel lo lista; luego el
pasajero paga con Bold y el caso se cierra como pagado.

**Acceptance Scenarios**:

1. **Given** un viaje completado hace 10 minutos sin pago ni reporte, **When** corre el barrido,
   **Then** el pasajero recibe un recordatorio en vivo y el conductor un aviso "¿Te pagaron el
   viaje?", una sola vez cada uno.
2. **Given** un pasajero con un viaje sin pagar, **When** abre la app, **Then** ve un aviso en su
   pantalla principal con el valor y el conductor, que lo lleva al pago.
3. **Given** un viaje sin reporte, **When** el conductor toca "No me pagó", **Then** el pago
   queda "No pagado", el pasajero lo ve y el panel lo lista en "Incidencias".
4. **Given** un viaje marcado "No pagado", **When** el pasajero paga con Bold o reporta efectivo y
   el conductor lo confirma, **Then** el pago queda pagado y sale de las incidencias.

---

### User Story 4 - El conductor elige qué medios acepta (Priority: P2)

El conductor decide si acepta efectivo, Bold o ambos (por defecto ambos). El pasajero solo ve los
medios que acepta su conductor al momento de terminar el viaje.

**Why this priority**: algunos conductores no quieren manejar efectivo o prefieren no esperar el
giro de Kyq; no bloquea el cobro.

**Independent Test**: el conductor desactiva el efectivo; el siguiente viaje completado solo
ofrece Bold al pasajero.

**Acceptance Scenarios**:

1. **Given** un conductor nuevo, **When** abre "Pagos de viajes", **Then** ve efectivo y Bold
   activados.
2. **Given** un conductor, **When** intenta desactivar los dos medios, **Then** se le indica que
   debe aceptar al menos uno.
3. **Given** un viaje ya completado, **When** el conductor cambia sus medios, **Then** ese viaje
   conserva los medios que tenía al completarse.

---

### User Story 5 - Liquidación al conductor y panel (Priority: P2)

El administrador ve por conductor el saldo que Kyq le debe por pagos con Bold, el detalle de
abonos y giros, y registra cada giro hecho por fuera (transferencia) con su referencia; el saldo
baja y el conductor lo ve. También ve la lista de pagos de viajes por estado, resuelve disputas y
"no pagados" (pagado en efectivo o no pagado, con nota) y puede anular un pago de Bold
reembolsado en el panel de Bold.

**Why this priority**: es el control del dinero de terceros que Kyq recauda; sin él no hay
confianza del conductor, pero el cobro funciona sin el panel.

**Independent Test**: tras dos pagos con Bold (18 000 y 12 000 COP), el panel muestra 30 000 de
saldo; el admin registra un giro de 30 000 con referencia, el saldo queda en 0 y el conductor ve
el giro en su app.

**Acceptance Scenarios**:

1. **Given** conductores con abonos, **When** el administrador abre "Liquidaciones", **Then** ve
   por conductor: abonado, girado, saldo por girar y último giro; los que tienen saldo, primero.
2. **Given** un conductor con saldo de 30 000 COP, **When** el administrador registra un giro de
   30 000 con la referencia de la transferencia, **Then** el saldo queda en 0, el giro queda con
   quién y cuándo, y el conductor lo ve en su libro y recibe un aviso.
3. **Given** un saldo de 30 000, **When** el administrador intenta girar 40 000, **Then** se
   rechaza: no se gira más que el saldo.
4. **Given** un pago en disputa, **When** el administrador lo resuelve como "pagado en efectivo"
   con una nota, **Then** el pago queda pagado y la resolución queda auditada.
5. **Given** un pago con Bold aprobado que se reembolsó en Bold, **When** el administrador lo
   anula con motivo (o llega la anulación de Bold), **Then** el pago queda anulado y el libro del
   conductor registra el débito por el mismo valor.

---

### Edge Cases

- Viajes completados antes de esta fase: no tienen pago registrado; el resumen conserva el texto
  de 001 ("Págale directamente").
- Viaje cancelado: nunca genera pago.
- El pasajero abre el checkout de Bold, no paga y el enlace caduca (30 min): el pago vuelve a
  "pendiente" (o a "no pagado" si el conductor ya lo había marcado) y puede elegir otra vez.
- Bold aprueba tarde un enlace anterior cuando el pasajero ya había reportado efectivo: gana el
  pago confirmado por Bold (dinero verificable) y el reporte de efectivo queda registrado.
- Bold aprueba un segundo cobro del mismo viaje (dos enlaces pagados): el viaje sigue pagado una
  vez, el abono es uno y el pago queda marcado para que el administrador reembolse el sobrante
  en Bold.
- Bold confirma un valor o moneda distintos a la tarifa: no se abona al conductor; el pago queda
  "en revisión" para el administrador.
- Notificación sin firma válida o de una referencia desconocida: se rechaza o se ignora como en
  002.
- El conductor confirma efectivo de un pago en disputa (cambió de opinión): queda pagado.
- El conductor no puede marcar "No me pagó" mientras el pasajero tiene un pago con Bold en curso.
- El pasajero nunca abre la app: el viaje queda "pendiente" con recordatorio único; el conductor
  puede marcarlo "No pagado" en cualquier momento.
- Giro de un saldo en varias partes: cada giro baja el saldo; nunca puede quedar negativo por un
  giro (sí por una anulación posterior a un giro, que queda como saldo a favor de Kyq).
- Moneda: los pagos y saldos se llevan por moneda (hoy solo COP).

## Requirements *(mandatory)*

### Functional Requirements

**Pago del viaje**

- **FR-001**: Al completarse un viaje, el sistema MUST registrar su pago con el valor de la
  tarifa acordada, 100 % para el conductor y comisión 0 (RN-KYQ-001), y los medios que acepta
  el conductor en ese momento.
- **FR-002**: El pasajero MUST ver en el resumen del viaje el valor, el estado del pago y solo los
  medios que acepta su conductor (y Bold solo si está activo en Kyq).
- **FR-003**: El pasajero MUST poder pagar con Bold (tarjeta, PSE, Nequi, según lo que Bold
  ofrezca) sin salir de la app; el valor lo fija el servidor.
- **FR-004**: El pasajero MUST poder reportar "Pagué en efectivo"; el reporte queda registrado con
  fecha y hora y se avisa al conductor en vivo.
- **FR-005**: El conductor MUST poder confirmar "Recibí el efectivo" (con o sin reporte previo del
  pasajero) y, ante un reporte del pasajero, disputarlo con "No recibí el efectivo"; ambos actos
  quedan registrados con fecha y hora.
- **FR-006**: El conductor MUST poder marcar un viaje sin pagar ni reportar como "No pagado"; el
  pasajero puede pagarlo después con Bold o efectivo confirmado.
- **FR-007**: Ambas partes MUST ver siempre el mismo estado del pago: pendiente, pago con Bold en
  curso, efectivo reportado, pagado (con medio), no pagado, en disputa, en revisión o anulado.
- **FR-008**: Solo el pasajero del viaje puede pagar o reportar efectivo y solo su conductor puede
  confirmar, disputar o marcar no pagado; terceros no ven el pago.

**Bold y liquidación**

- **FR-009**: Un pago con Bold MUST confirmarse con Bold (consulta del enlace o webhook firmado)
  antes de marcarse pagado; un mismo pago MUST abonarse al conductor una sola vez.
- **FR-010**: Un cobro de Bold por valor o moneda distintos a la tarifa MUST NOT abonarse y MUST
  quedar en revisión.
- **FR-011**: Cada pago aprobado por Bold MUST abonar el 100 % del valor en el libro de
  liquidación del conductor; Kyq MUST NOT descontar comisión ni costos de la pasarela
  (RN-KYQ-001). El efectivo no pasa por el libro.
- **FR-012**: El administrador MUST poder registrar giros al conductor (valor, referencia, nota)
  que no superen el saldo; cada giro queda auditado y el conductor recibe un aviso.
- **FR-013**: El conductor MUST ver su saldo por girar, los abonos, débitos y giros de su libro.
- **FR-014**: El administrador MUST poder anular un pago con Bold con motivo (reembolso hecho en
  Bold); la anulación (manual o notificada por Bold) MUST registrar un débito igual al abono.

**Seguimiento**

- **FR-015**: A los 10 minutos de completado un viaje sin pago ni reporte, el sistema MUST enviar
  un recordatorio al pasajero y un aviso al conductor, una sola vez.
- **FR-016**: El pasajero MUST ver al abrir la app los viajes que tiene sin pagar con acceso
  directo al pago.
- **FR-017**: El panel MUST listar los pagos de viajes por estado y destacar las incidencias (no
  pagado, en disputa, en revisión); el administrador MUST poder resolver una disputa o un no
  pagado como "pagado en efectivo" o "no pagado", con nota auditada.

**Medios aceptados**

- **FR-018**: El conductor MUST poder elegir si acepta efectivo, Bold o ambos (al menos uno; por
  defecto ambos).

### Key Entities

- **Pago del viaje**: uno por viaje completado; valor, moneda, valor para el conductor (= valor),
  comisión (= 0), medios aceptados, estado, medio con que se pagó, enlace de Bold en curso,
  fechas de reporte, confirmación, disputa, no pagado y pago, recordatorio, notas de revisión,
  resolución y anulación con su autor.
- **Medios aceptados del conductor**: efectivo sí/no, Bold sí/no.
- **Movimiento del libro del conductor**: abono por pago con Bold, débito por anulación o giro;
  valor con signo, moneda, pago o giro de origen, autor y fecha.
- **Giro al conductor**: valor, moneda, referencia de la transferencia, nota, quién lo registró y
  cuándo.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: El pasajero completa el pago (Bold o reporte de efectivo) en menos de 1 minuto
  desde el resumen del viaje.
- **SC-002**: El 99 % de los pagos aprobados por Bold se ven como pagados en ambas apps en menos
  de 1 minuto.
- **SC-003**: Ningún pago se abona dos veces ni se abona un pago no confirmado por Bold (0 casos
  en pruebas y en la conciliación mensual con Bold).
- **SC-004**: La comisión de Kyq en los pagos de viaje es 0 en el 100 % de los casos y el libro
  de cada conductor cuadra: abonos − débitos − giros = saldo.
- **SC-005**: Al menos el 90 % de los viajes completados quedan con un estado final (pagado o
  incidencia) dentro de las 24 h siguientes.
- **SC-006**: El administrador registra un giro y ve el saldo actualizado en menos de 1 minuto.

## Assumptions

- **Recaudo y giro**: el dinero de los pagos con Bold entra a la cuenta Bold de Kyq (la misma de
  la suscripción). Kyq lo gira al conductor por fuera de la app (transferencia) y el
  administrador lo registra; no hay giros automáticos ni dispersión por API en esta fase.
- **0 % de comisión (RN-KYQ-001)**: el conductor recibe el 100 % de la tarifa; la comisión de
  Bold la asume Kyq como costo de plataforma (no se descuenta al conductor ni se cobra al
  pasajero).
- **Valor**: la tarifa acordada del viaje (sin propinas, peajes ni recargos en esta fase).
- **Momento del pago**: el pago se habilita al completar el viaje; pagar antes de terminar queda
  fuera de esta fase (la tarifa ya está acordada, pero el viaje aún puede cancelarse sin cargo).
- **Anulaciones mínimas**: solo pagos con Bold, por el administrador o por la notificación de
  anulación de Bold; el reembolso se hace en el panel de Bold. No hay devoluciones parciales.
- **Recordatorio**: uno solo, a los 10 minutos, en vivo para el pasajero (no hay push; ve además
  el aviso al abrir la app) y como aviso de la app para el conductor. Sin SMS al pasajero.
- **No pagado**: es la palabra del conductor; Kyq no cobra ni bloquea al pasajero en esta fase.
  El administrador ve los casos y decide fuera de la app (p. ej. quitar la afiliación).
- **Medios del conductor**: se toman al completarse el viaje; cambiar la preferencia no afecta
  viajes ya completados. Si Bold no está configurado en Kyq, solo se ofrece efectivo.
- **Transferencias entre personas** (Nequi o Daviplata directos al conductor) no se registran en
  la app: el conductor puede marcarlas como "Recibí el efectivo" si quiere cerrar el viaje, o
  dejarlas pendientes; el texto de la app habla de "efectivo".
- **Viajes anteriores** a esta fase no se migran: no tienen pago registrado.
- Android para las apps y web para el panel, como 002.

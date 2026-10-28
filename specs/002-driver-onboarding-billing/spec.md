# Feature Specification: Alta autónoma del conductor, validación documental y suscripción con Bold

**Feature Branch**: `002-driver-onboarding-billing`

**Created**: 2026-10-27

**Status**: Draft

**Input**: User description: "Alta autónoma del conductor con validación documental (KYC) y cobro de la suscripción mensual con la pasarela Bold (Colombia). El conductor se registra desde Kyq Conductor con su teléfono (OTP), completa perfil y vehículo, sube fotos de sus documentos (cédula, licencia de conducción, SOAT, revisión técnico-mecánica, tarjeta de propiedad) con fecha de vencimiento; el administrador los revisa en el Panel (aprobar/rechazar con motivo) y el sistema avisa antes del vencimiento y bloquea al vencer (RN-KYQ-002/003 ya existentes). La suscripción mensual (0 % de comisión por viaje, RN-KYQ-001) se paga con Bold (enlace de pago o checkout: tarjeta, PSE, Nequi); el webhook de Bold confirma el pago y extiende paid_until; recordatorios antes del vencimiento, periodo de gracia de 72 h y bloqueo como hoy. La app del conductor y el panel muestran en qué se gasta la suscripción (mapas, voz PTT, tiempo real) con los costos medidos por conductor (RN-KYQ-004, usando driver_usage_daily). Panel: cola de validación KYC, estado de suscripciones e historial de pagos. Android y web del panel; sin cooperativas."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - El conductor se registra solo y envía sus documentos (Priority: P1)

Un conductor descarga Kyq Conductor, entra con su teléfono y un código por SMS, completa su
nombre, los datos de su vehículo (placa, marca, modelo, color, año) y toma o sube fotos de sus
documentos con su fecha de vencimiento. Al enviarlos queda "en revisión" y ve en todo momento qué
documento falta, cuál está en revisión, aprobado o rechazado (con el motivo).

**Why this priority**: hoy cada conductor lo da de alta un administrador a mano; sin alta
autónoma no se puede crecer más allá de unos pocos conductores.

**Independent Test**: un teléfono nuevo se registra como conductor, sube los cinco documentos y
aparece en la cola del panel con estado "en revisión", sin intervención previa del administrador.

**Acceptance Scenarios**:

1. **Given** un teléfono sin cuenta, **When** elige "Soy conductor", verifica el código y
   completa perfil y vehículo, **Then** tiene una cuenta de conductor en estado "documentos
   pendientes" y ve la lista de documentos que debe enviar.
2. **Given** un conductor con documentos pendientes, **When** fotografía la licencia (frente y
   reverso) e indica su número y fecha de vencimiento, **Then** el documento queda "en revisión" y
   la foto se ve en su lista.
3. **Given** un conductor con los cinco documentos enviados, **When** abre la app, **Then** ve
   "En revisión: te avisaremos cuando un administrador apruebe tus documentos" y no puede ponerse
   ONLINE.
4. **Given** un documento rechazado con motivo "foto borrosa", **When** el conductor abre la app,
   **Then** ve el motivo y puede volver a enviar solo ese documento.
5. **Given** un teléfono ya registrado como pasajero, **When** intenta registrarse como conductor,
   **Then** se le indica que ese teléfono ya tiene una cuenta de pasajero y que use otro número.

---

### User Story 2 - El administrador valida documentos y el sistema vigila los vencimientos (Priority: P1)

El administrador ve en el panel una cola de conductores con documentos en revisión, ordenada por
antigüedad. Abre cada uno, ve las fotos junto a los datos declarados, y aprueba o rechaza cada
documento con un motivo. Cuando todos los obligatorios están aprobados y vigentes, el conductor
puede trabajar en cuanto pague su suscripción. Antes de que un documento venza, el conductor
recibe avisos; al vencer, deja de poder ponerse ONLINE hasta que envíe uno nuevo y se apruebe.

**Why this priority**: la seguridad de los pasajeros y el cumplimiento legal dependen de que
nadie trabaje con documentos falsos o vencidos (RN-KYQ-016).

**Independent Test**: un administrador aprueba cuatro documentos y rechaza uno; el conductor ve
el rechazo, reenvía, el administrador aprueba y el conductor queda "documentos al día".

**Acceptance Scenarios**:

1. **Given** tres conductores en revisión, **When** el administrador abre la cola, **Then** los
   ve ordenados del más antiguo al más reciente con cuántos documentos tiene cada uno por revisar.
2. **Given** un documento en revisión, **When** el administrador lo rechaza, **Then** debe elegir
   o escribir un motivo, y el conductor ve ese motivo en la app y recibe un aviso.
3. **Given** un conductor con todos los documentos aprobados y vigentes, **When** el
   administrador aprueba el último, **Then** el estado documental del conductor pasa a "al día".
4. **Given** un SOAT aprobado que vence en 15 días, **When** llega ese día, **Then** el conductor
   recibe un aviso en la app y otro a los 3 días del vencimiento.
5. **Given** un SOAT vencido, **When** el conductor intenta ponerse ONLINE, **Then** se bloquea
   con el motivo "SOAT vencido: envía el nuevo" (RN-KYQ-016); si estaba en un viaje, lo termina.
6. **Given** un conductor que envía el SOAT renovado antes de que venza el anterior, **When** el
   nuevo está en revisión, **Then** sigue trabajando con el anterior hasta su vencimiento.

---

### User Story 3 - El conductor paga su suscripción con Bold (Priority: P1)

El conductor ve el estado de su suscripción (activa hasta una fecha, en gracia o suspendida),
el precio del mes y un botón "Pagar". Paga con tarjeta, PSE o Nequi en la pantalla de pago de
Bold sin salir de la app. Cuando Bold confirma el pago, la suscripción se extiende un mes y el
conductor lo ve al instante, con su comprobante en el historial. Antes del vencimiento recibe
recordatorios; tras vencer tiene 72 horas de gracia y luego queda suspendido como hoy.

**Why this priority**: es el ingreso de Kyq (0 % de comisión por viaje, RN-KYQ-001); hoy cada
pago lo registra un administrador a mano.

**Independent Test**: en el entorno de pruebas de Bold, un conductor suspendido paga con una
tarjeta de prueba, la suscripción queda activa por un mes y puede ponerse ONLINE de inmediato.

**Acceptance Scenarios**:

1. **Given** un conductor con documentos al día y sin suscripción, **When** toca "Pagar" y Bold
   aprueba el pago, **Then** la suscripción queda activa hasta dentro de un mes y puede ponerse
   ONLINE sin más pasos.
2. **Given** una suscripción activa hasta el 30, **When** el conductor paga el día 25, **Then**
   queda activa hasta el 30 del mes siguiente (no pierde los días que le quedaban).
3. **Given** una suscripción vencida hace 5 días (suspendida), **When** paga, **Then** queda
   activa por un mes contado desde el pago.
4. **Given** un pago por PSE que Bold deja "pendiente", **When** el conductor vuelve a la app,
   **Then** ve "Pago en proceso" y la suscripción se extiende solo cuando Bold lo aprueba; si lo
   rechaza, ve "Pago rechazado" y puede intentarlo otra vez.
5. **Given** que Bold notifica dos veces el mismo pago aprobado, **When** se procesan las dos
   notificaciones, **Then** la suscripción se extiende una sola vez.
6. **Given** una suscripción que vence en 5 días, **When** llega ese día, **Then** el conductor
   recibe un recordatorio con el botón de pago; otro a 1 día; y otro al empezar la gracia.
7. **Given** un conductor, **When** abre "Mis pagos", **Then** ve cada pago con fecha, valor,
   medio, estado y el periodo que cubrió.

---

### User Story 4 - Transparencia: en qué se va la suscripción (Priority: P2)

El conductor ve cómo su suscripción financia la plataforma: cuánto costó en el mes el mapa, la
voz del walkie-talkie y el tiempo real que usó, medido con su propio uso, y qué parte cubre el
mantenimiento de Kyq. El administrador ve los mismos números agregados por conductor y el margen
de cada suscripción frente a su costo real.

**Why this priority**: RN-KYQ-004; refuerza la confianza en un modelo sin comisión, pero no
bloquea el alta ni el cobro.

**Independent Test**: con usos registrados de un conductor en el mes, su pantalla "Tu
suscripción" muestra el desglose por concepto y el panel muestra el mismo costo y el margen.

**Acceptance Scenarios**:

1. **Given** un conductor con 120 minutos de voz, 3 000 eventos en tiempo real y 200 rutas en el
   mes, **When** abre "Tu suscripción", **Then** ve el costo estimado de cada concepto según las
   tarifas vigentes y el total frente al precio pagado.
2. **Given** el panel, **When** el administrador abre "Costos por conductor" de un mes, **Then**
   ve por conductor: precio cobrado, costo medido por concepto y margen; y los conductores cuyo
   costo supera su precio, destacados.
3. **Given** que el administrador actualiza la tarifa de un concepto (p. ej. minuto de voz),
   **When** se calcula de nuevo el mes en curso, **Then** se usa la tarifa nueva desde su fecha
   de vigencia.

---

### User Story 5 - Panel de suscripciones y pagos (Priority: P2)

El administrador ve todas las suscripciones con su estado (activa, gracia, suspendida), filtra
por estado, ve el historial de pagos de cada conductor y puede registrar a mano un pago recibido
por otro medio (p. ej. efectivo en la oficina) o anular uno con motivo (p. ej. contracargo).

**Why this priority**: soporte y conciliación; el flujo normal ya lo cubre Bold.

**Independent Test**: el administrador filtra "en gracia", registra un pago en efectivo de uno de
ellos y el conductor pasa a "activa"; anula ese pago y vuelve al estado anterior.

**Acceptance Scenarios**:

1. **Given** 50 conductores, **When** el administrador filtra por "suspendida", **Then** ve solo
   los suspendidos con la fecha de vencimiento y el último pago.
2. **Given** un conductor en gracia, **When** el administrador registra un pago manual con medio y
   referencia, **Then** la suscripción se extiende igual que con Bold y queda auditado quién lo
   registró.
3. **Given** un pago aprobado, **When** el administrador lo anula con el motivo "contracargo",
   **Then** se resta el periodo que cubría y el conductor ve el cambio y el motivo.

---

### Edge Cases

- El conductor cierra la pantalla de pago antes de que Bold responda: al volver se consulta el
  estado del pago y se muestra "en proceso", "aprobado" o "rechazado".
- Bold notifica un pago por un valor distinto al precio vigente: no se extiende la suscripción,
  queda marcado para revisión del administrador.
- Llega una notificación que no viene de Bold o con firma inválida: se rechaza y se registra.
- Notificaciones fuera de orden (rechazado después de aprobado para el mismo pago): se aplica el
  estado final que Bold confirme al consultarlo, no el orden de llegada.
- El precio cambia mientras un pago está en proceso: se respeta el precio con el que se inició.
- El conductor cambia de vehículo: envía los documentos del vehículo nuevo; mientras se revisan
  sigue trabajando con el vehículo anterior aprobado.
- Foto ilegible, documento de otra persona o placa que no coincide: el administrador rechaza con
  motivo; tras 3 rechazos del mismo documento, se sugiere contactar a soporte.
- Documento sin vencimiento (cédula, tarjeta de propiedad): no genera avisos ni bloqueos por
  fecha.
- Vehículo nuevo exento de revisión técnico-mecánica: el administrador marca "no aplica hasta"
  una fecha, y desde esa fecha se exige.
- Un conductor dado de alta por un administrador (flujo actual) sigue funcionando y puede subir
  sus documentos desde la app igual que uno autónomo.
- Sin conexión al subir fotos: la subida se reintenta y el documento no pasa a "en revisión"
  hasta que todas sus fotos llegan.
- Pagos repetidos seguidos por error: cada pago aprobado extiende un mes; el administrador puede
  anular el sobrante.

## Requirements *(mandatory)*

### Functional Requirements

**Alta del conductor**

- **FR-001**: Una persona MUST poder crear su cuenta de conductor desde la app con su teléfono
  verificado por código, sin intervención de un administrador.
- **FR-002**: El conductor MUST completar nombre, placa, marca, modelo, color y año del vehículo
  antes de enviar documentos.
- **FR-003**: Un teléfono MUST tener un solo rol; si ya es pasajero o administrador, el alta como
  conductor se rechaza con un mensaje claro.
- **FR-004**: Un conductor sin documentos aprobados y vigentes ni suscripción activa o en gracia
  MUST NOT poder ponerse ONLINE ni recibir afiliaciones nuevas, y MUST ver qué le falta.

**Documentos (KYC)**

- **FR-005**: Los documentos obligatorios son: cédula, licencia de conducción, SOAT, revisión
  técnico-mecánica y tarjeta de propiedad del vehículo. Cada uno tiene número, fotos (frente y,
  si aplica, reverso) y, salvo cédula y tarjeta de propiedad, fecha de vencimiento.
- **FR-006**: Cada documento MUST tener estado: pendiente, en revisión, aprobado, rechazado (con
  motivo) o vencido; el conductor MUST ver el estado de cada uno.
- **FR-007**: El conductor MUST poder reenviar un documento rechazado o próximo a vencer sin
  afectar a los demás; el documento aprobado anterior sigue vigente hasta su fecha.
- **FR-008**: El administrador MUST tener una cola de revisión ordenada por antigüedad y poder
  aprobar o rechazar cada documento; rechazar exige un motivo (lista predefinida o texto).
- **FR-009**: El administrador MUST poder corregir la fecha de vencimiento o el número declarado
  al aprobar, y marcar la revisión técnico-mecánica como "no aplica hasta" una fecha.
- **FR-010**: El sistema MUST avisar al conductor 15 y 3 días antes del vencimiento de cada
  documento y el día que vence, y bloquear su paso a ONLINE al vencer (RN-KYQ-016) sin
  interrumpir un viaje en curso (RN-KYQ-003).
- **FR-011**: Las fotos de documentos MUST ser visibles solo para el propio conductor y los
  administradores; nunca para pasajeros.
- **FR-012**: Toda aprobación, rechazo o corrección MUST quedar registrada con quién y cuándo.

**Suscripción y pagos**

- **FR-013**: El precio mensual MUST configurarse por ciudad y moneda desde el panel, con fecha de
  vigencia; el conductor ve el precio que pagará antes de pagar.
- **FR-014**: El conductor MUST poder pagar la suscripción desde la app con Bold (tarjeta, PSE o
  Nequi, según lo que Bold ofrezca) sin salir de la app.
- **FR-015**: Un pago aprobado MUST extender la suscripción un mes contado desde el mayor entre el
  vencimiento actual y el momento del pago.
- **FR-016**: El sistema MUST confirmar cada pago con Bold (notificación verificada o consulta
  directa) antes de extender la suscripción; un mismo pago MUST extenderla una sola vez.
- **FR-017**: Un pago por un valor o moneda distintos al precio con el que se inició MUST NOT
  extender la suscripción y MUST quedar marcado para revisión.
- **FR-018**: El sistema MUST mantener la gracia de 72 horas tras el vencimiento y la suspensión
  posterior (RN-KYQ-002, RN-KYQ-003); pagar en gracia o suspendido reactiva al instante.
- **FR-019**: El sistema MUST recordar el pago 5 días y 1 día antes del vencimiento y al empezar la
  gracia, con acceso directo al pago.
- **FR-020**: El conductor MUST ver su historial de pagos: fecha, valor, medio, estado y periodo
  cubierto.
- **FR-021**: El administrador MUST poder registrar un pago manual (medio y referencia) y anular
  un pago con motivo; ambas acciones recalculan el vencimiento y quedan auditadas.
- **FR-022**: El panel MUST listar suscripciones por estado (activa, gracia, suspendida, sin
  pagar) con vencimiento y último pago, y el historial de pagos de cada conductor.
- **FR-023**: Kyq MUST NOT cobrar comisión por viaje en ningún caso (RN-KYQ-001); la suscripción
  es el único cobro al conductor.

**Transparencia de costos (RN-KYQ-004)**

- **FR-024**: El administrador MUST poder configurar, con fecha de vigencia, el costo unitario de
  cada concepto medido: minuto de voz, evento en tiempo real y petición de ruta; y un costo fijo
  mensual por conductor (mapa base, mantenimiento).
- **FR-025**: El conductor MUST ver, para el mes en curso y los anteriores, su uso y su costo
  estimado por concepto frente al precio de su suscripción.
- **FR-026**: El panel MUST mostrar por conductor y mes: precio cobrado, costo por concepto,
  costo total y margen, destacando los conductores con margen negativo.

**Avisos**

- **FR-027**: Los avisos de documentos y pagos MUST mostrarse en la app; además, los de
  vencimiento de suscripción y de documentos (3 días antes y el día del vencimiento) MUST
  enviarse por SMS, porque la app puede estar cerrada.

### Key Entities

- **Conductor**: persona con rol conductor; estado de alta (perfil incompleto, documentos
  pendientes, en revisión, al día) derivado de sus documentos.
- **Vehículo**: placa, marca, modelo, color, año; pertenece a un conductor; puede cambiar.
- **Documento del conductor**: tipo, número, fotos, fecha de vencimiento, estado, motivo de
  rechazo, revisor y fecha de revisión; versiones sucesivas del mismo tipo.
- **Precio de suscripción**: ciudad, moneda, valor mensual, vigente desde.
- **Pago**: conductor, valor, moneda, medio, estado (iniciado, en proceso, aprobado, rechazado,
  anulado), referencia de Bold o manual, periodo que cubre, quién lo registró o anuló.
- **Suscripción**: conductor y fecha hasta la que está pagada; estado derivado (activa, gracia,
  suspendida).
- **Tarifa de costo**: concepto, costo unitario, vigente desde.
- **Uso del conductor**: lo medido por día (voz, eventos, rutas), ya existente.
- **Aviso**: conductor, tipo, canal (app, SMS), fecha programada y enviada.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Un conductor completa el registro, el vehículo y el envío de los cinco documentos
  en menos de 10 minutos.
- **SC-002**: Un administrador revisa el expediente completo de un conductor en menos de 3
  minutos.
- **SC-003**: El 99 % de los pagos aprobados por Bold se reflejan en la suscripción del
  conductor en menos de 1 minuto.
- **SC-004**: Ningún conductor puede ponerse ONLINE con un documento vencido o sin aprobar, ni
  con la suscripción suspendida (0 casos en las pruebas y en la auditoría mensual).
- **SC-005**: Ningún pago se aplica dos veces ni se aplica un pago no confirmado por Bold.
- **SC-006**: Al menos el 80 % de los conductores renuevan antes de entrar en gracia tras los
  recordatorios.
- **SC-007**: El conductor entiende su desglose de costos: en una prueba con 5 conductores, al
  menos 4 explican correctamente qué financia su suscripción tras verlo.

## Assumptions

- Se paga un mes por pago; no hay débito automático ni planes por varios meses en esta fase.
- El precio es igual para todos los conductores de una ciudad; no hay descuentos ni cupones.
- Bold es la única pasarela; se usa su checkout o enlace de pago y su entorno de pruebas para
  validar. Kyq no guarda datos de tarjetas.
- Kyq no emite facturas electrónicas en esta fase; el comprobante es el de Bold más el historial
  de la app.
- No hay notificaciones push (como en el MVP); los avisos van en la app y, los críticos, por SMS.
- Las fotos de documentos se conservan mientras la cuenta esté activa y hasta 5 años después de
  cerrarla, por exigencias legales del transporte; luego se eliminan.
- La revisión es manual por un administrador; no hay verificación automática de identidad ni
  consulta a bases externas (RUNT, SIMIT) en esta fase.
- Los conductores dados de alta por el administrador en el MVP siguen igual y pueden usar todo lo
  nuevo.
- Solo Android para el conductor y web para el panel; sin cooperativas (fase 005).
- Los costos unitarios de infraestructura son estimaciones que el administrador ajusta; no se
  leen de las facturas de los proveedores.

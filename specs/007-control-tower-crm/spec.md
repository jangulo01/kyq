# Feature Specification: Torre de control H3, CRM y economía unitaria

**Feature Branch**: `007-control-tower-crm`

**Created**: 2026-10-27

**Status**: Draft

**Input**: User description: "Módulos del panel de administración del SDD: 1) Torre de Control
Geoespacial H3 en vivo: mapa con los conductores ONLINE (libres y ocupados) y los viajes activos
agregados en hexágonos H3, con demanda y oferta por hexágono. 2) Motor financiero de suscripciones
frente a infraestructura (economía unitaria): ingresos mensuales por suscripción frente al costo de
infraestructura medido por conductor y en total, sobre los costos por conductor que ya construyó
002 (tarifas de costo, uso diario y pagos), sin duplicarlos. 5) Analítica de fidelización (CRM) y
moderación: crecimiento de afiliaciones, viajes repetidos por pareja pasajero–conductor, abandono
de conductores elegidos, el SC-008 de 001 (% de pasajeros que afilian a un conductor y le vuelven
a pedir), y moderación básica: suspender y reactivar usuarios con motivo y auditoría. 6)
Observabilidad nativa (Healthline): página de salud de las dependencias (base de datos,
Centrifugo, LiveKit, OSRM, almacenamiento S3 y Bold) con latencias. Solo administradores, en el
panel web, con MapLibre y el estilo de teselas existente."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Torre de control en vivo (Priority: P1)

El administrador abre "Torre" en el panel y ve el mapa de la ciudad dividido en hexágonos. Cada
hexágono con actividad muestra cuántos conductores libres y ocupados hay, cuántos viajes activos
y cuántas solicitudes hubo en la última hora, coloreado según la relación entre demanda y oferta.
Los conductores ONLINE aparecen como puntos (libre / ocupado) y la vista se actualiza sola en
cuanto cambia algo, sin recargar la página. Puede cambiar el tamaño de los hexágonos y ver una
lista de las zonas con más presión.

**Why this priority**: es la herramienta diaria de operación: saber dónde hay conductores, dónde
se acumula demanda sin atender y si el servicio está funcionando en este momento.

**Independent Test**: con dos conductores ONLINE en zonas distintas (uno ocupado con un viaje) y
varias solicitudes recientes, el administrador ve los hexágonos y totales correctos; cuando uno de
los conductores se desconecta, la torre lo refleja en segundos sin intervención.

**Acceptance Scenarios**:

1. **Given** tres conductores ONLINE (dos libres, uno ocupado), **When** el administrador abre la
   torre, **Then** ve 3 conductores ONLINE en los totales, cada uno en su hexágono y con su color
   de estado.
2. **Given** cuatro solicitudes en la última hora con recogida en un mismo hexágono sin
   conductores libres, **When** abre la torre, **Then** ese hexágono aparece marcado como "sin
   oferta" y encabeza la lista de zonas con presión.
3. **Given** la torre abierta, **When** un conductor se pone OFFLINE o se mueve de hexágono,
   **Then** la torre se actualiza en menos de 10 segundos sin recargar.
4. **Given** un conductor ONLINE cuya última ubicación tiene más de 2 minutos, **When** se muestra,
   **Then** aparece marcado como "ubicación desactualizada" y se cuenta aparte.
5. **Given** un usuario sin rol de administrador, **When** intenta ver la torre o suscribirse a
   sus actualizaciones, **Then** se le niega el acceso.

---

### User Story 2 - Finanzas: suscripciones frente a infraestructura (Priority: P1)

El administrador abre "Finanzas" y ve, mes a mes, cuánto se cobró en suscripciones, cuánto costó
la infraestructura medida (voz, tiempo real, rutas y costo fijo por conductor), el margen total y
el porcentaje de margen, cuántos conductores estuvieron activos y cuántos pagaron, el costo por
conductor activo y el ingreso por conductor que paga. Desde ahí puede ir al detalle por conductor
que ya existe (002).

**Why this priority**: la constitución (VII) exige que la cuota fija cubra el costo real; sin el
agregado mensual no se sabe si el negocio es rentable ni hacia dónde va.

**Independent Test**: con pagos aprobados y uso medido en dos meses, los totales de cada mes
coinciden con la suma de las filas del detalle por conductor de ese mes.

**Acceptance Scenarios**:

1. **Given** dos conductores con pagos aprobados y uso medido en octubre, **When** el
   administrador abre Finanzas en octubre, **Then** ve ingresos = suma de pagos aprobados del mes,
   costo = suma de los costos por conductor del mes y margen = ingresos − costo.
2. **Given** los últimos 6 meses, **When** abre Finanzas, **Then** ve una fila por mes con la
   evolución, y los meses con margen negativo destacados.
3. **Given** un mes sin tarifas de costo configuradas, **When** lo consulta, **Then** el costo es 0
   y se le avisa de que faltan tarifas.
4. **Given** el detalle de costos por conductor de 002, **When** compara con Finanzas, **Then** la
   suma de las filas del mismo mes coincide con el total de Finanzas.

---

### User Story 3 - Fidelización (CRM) (Priority: P2)

El administrador abre "Fidelización" y elige un periodo. Ve cuántas afiliaciones nuevas y bajas
hubo, la serie semanal de afiliaciones activas, qué parte de las parejas pasajero–conductor
repitió viaje, el indicador SC-008 (porcentaje de afiliaciones en las que el pasajero pidió al
menos un viaje a ese conductor en sus primeros 30 días, con la meta del 80 %), y los conductores
elegidos que pierden afiliados o llevan 30 días sin viajes teniendo afiliados.

**Why this priority**: el diferencial de Kyq es el conductor elegido; hay que medir si la
fidelización funciona, pero no bloquea la operación diaria.

**Independent Test**: con afiliaciones y viajes sembrados de forma controlada, los indicadores
coinciden con los valores calculados a mano.

**Acceptance Scenarios**:

1. **Given** 5 afiliaciones de hace más de 30 días, en 4 de las cuales el pasajero pidió un viaje
   a ese conductor en los 30 días siguientes, **When** consulta el periodo, **Then** SC-008 = 80 %
   y se marca la meta como cumplida.
2. **Given** afiliaciones de hace menos de 30 días, **When** consulta, **Then** no cuentan en el
   SC-008 todavía y se informan como "en curso".
3. **Given** una pareja con 3 viajes completados y otra con 1 en el periodo, **When** consulta,
   **Then** ve 2 parejas, 1 repetida (50 %) y 2 viajes de media.
4. **Given** un conductor con afiliados y sin viajes completados en 30 días, **When** consulta,
   **Then** aparece en "conductores elegidos inactivos".

---

### User Story 4 - Moderación de usuarios (Priority: P2)

El administrador busca un usuario por nombre o teléfono, ve si está activo o suspendido, y lo
suspende o reactiva indicando siempre un motivo. Un usuario suspendido no puede volver a iniciar
sesión ni renovar la sesión; un conductor suspendido deja de estar ONLINE (si no está en un viaje)
y no puede volver a conectarse. Cada acción queda registrada con quién, cuándo y por qué.

**Why this priority**: se necesita poder actuar ante abusos o fraudes, pero es poco frecuente.

**Independent Test**: suspender a un pasajero y a un conductor, comprobar que no pueden renovar
sesión ni el conductor ponerse ONLINE, reactivarlos y ver las dos acciones en el historial.

**Acceptance Scenarios**:

1. **Given** un conductor ONLINE libre, **When** el administrador lo suspende con motivo,
   **Then** el conductor pasa a OFFLINE, sus sesiones se cierran y el historial muestra la acción.
2. **Given** un usuario suspendido, **When** intenta iniciar sesión o renovar la sesión, **Then**
   recibe "tu cuenta está suspendida" y no obtiene sesión.
3. **Given** un conductor suspendido, **When** intenta ponerse ONLINE con una sesión aún válida,
   **Then** se le rechaza por cuenta suspendida.
4. **Given** una suspensión sin motivo, **When** se envía, **Then** se rechaza.
5. **Given** un usuario suspendido, **When** el administrador lo reactiva con motivo, **Then**
   puede volver a iniciar sesión y la reactivación queda en el historial.
6. **Given** otro administrador, **When** se intenta suspenderlo, **Then** se rechaza.

---

### User Story 5 - Salud de la plataforma (Healthline) (Priority: P2)

El administrador abre "Salud" y ve el estado de cada dependencia (base de datos, tiempo real,
voz, rutas, almacenamiento de documentos y pasarela de pagos): disponible, caída o desactivada,
con la latencia medida y la hora de la comprobación, y un estado global. La página se refresca
sola.

**Why this priority**: permite diagnosticar en segundos por qué falla algo en la operación, sin
entrar a la máquina.

**Independent Test**: con una dependencia detenida, la página la muestra caída y el estado global
"degradado", y las demás con su latencia.

**Acceptance Scenarios**:

1. **Given** todas las dependencias activas, **When** abre Salud, **Then** todas aparecen
   disponibles con su latencia en milisegundos y el estado global es "operativo".
2. **Given** el servicio de rutas detenido, **When** abre Salud, **Then** rutas aparece "caída"
   con el motivo resumido y el estado global es "degradado".
3. **Given** los pagos con Bold desactivados en la configuración, **When** abre Salud, **Then**
   Bold aparece "desactivado", sin contar como fallo.
4. **Given** la base de datos caída, **Then** el estado global es "caído".
5. **Given** cualquier comprobación, **Then** ninguna respuesta muestra llaves, contraseñas ni
   URLs con credenciales.

### Edge Cases

- Conductores ONLINE sin ninguna ubicación aún: cuentan en los totales como "sin ubicación" y no se
  dibujan.
- Ubicaciones antiguas (> 2 min): se dibujan atenuadas y se cuentan como desactualizadas.
- Hexágonos que cruzan una arista del icosaedro o pentágonos: el contorno se dibuja igual (H3 lo
  resuelve); en Colombia y Perú no hay pentágonos.
- Mes sin pagos ni uso: ingresos y costos 0; porcentaje de margen "—" (sin división por cero).
- Afiliación eliminada y vuelta a crear: cuenta como afiliación nueva desde la fecha de la nueva
  (el MVP reescribe la fecha al reactivar).
- Suspender a alguien con un viaje en curso: el viaje sigue hasta terminar; no puede iniciar otro
  ni el conductor volver a ONLINE.
- Suspender a un usuario ya suspendido o reactivar a uno activo: se rechaza indicando el estado.
- Un administrador no puede suspenderse a sí mismo ni a otro administrador.
- Comprobación de salud que tarda: se corta a los 3 s y se informa como caída por tiempo.
- Periodo de fidelización mayor de un año o invertido: se rechaza.

## Requirements *(mandatory)*

### Functional Requirements

**Torre de control (módulo 1 del SDD)**

- **FR-001**: El sistema MUST agregar en hexágonos H3 de la resolución elegida (6 a 9; 8 por
  defecto) los conductores ONLINE libres y ocupados (por su última ubicación), los viajes activos
  (aceptado, en recogida o en curso; en la posición actual de su conductor o, si no se conoce, en
  la recogida) y las solicitudes de la última hora (por punto de recogida).
- **FR-002**: Por hexágono MUST mostrar: conductores libres, ocupados, viajes activos,
  solicitudes de la última hora, solicitudes no atendidas (oferta vencida, rechazada o negociación
  fallida) y un nivel de presión: sin demanda, equilibrado, alta (≥ 2 solicitudes por conductor
  libre) o sin oferta (solicitudes sin ningún conductor libre).
- **FR-003**: MUST mostrar totales: ONLINE, libres, ocupados, sin ubicación, con ubicación
  desactualizada (> 2 min), viajes activos, solicitudes y no atendidas de la última hora.
- **FR-004**: MUST dibujar los hexágonos y los conductores sobre el mapa base propio de Kyq, con
  la lista de hexágonos ordenada por presión.
- **FR-005**: La torre MUST actualizarse sola en menos de 10 s cuando cambie la presencia, la
  ubicación de un conductor o un viaje, sin recargar la página; y seguir funcionando (con
  actualización periódica) si el canal en vivo no está disponible.
- **FR-006**: Solo los administradores MUST poder consultar la torre y suscribirse a sus
  actualizaciones; las actualizaciones en vivo no llevan datos personales (solo un aviso de
  cambio).

**Finanzas (módulo 2 del SDD)**

- **FR-007**: El sistema MUST mostrar por mes (hasta 24 meses; 6 por defecto, terminando en el mes
  elegido): ingresos por suscripción (pagos aprobados cuyo periodo empieza en el mes), costo de
  infraestructura (suma de los costos por conductor de 002), margen, % de margen, conductores
  activos (con uso medido o pago en el mes), conductores que pagaron, conductores con margen
  negativo, costo por conductor activo, ingreso por conductor que paga y costo por concepto.
- **FR-008**: Los totales de un mes MUST coincidir con la suma del detalle por conductor de 002
  para ese mes (mismo cálculo, sin duplicarlo).
- **FR-009**: MUST indicar cuándo no hay tarifas de costo vigentes, porque el costo mostrado sería
  0.

**Fidelización (módulo 5 del SDD)**

- **FR-010**: Para un periodo (por defecto las últimas 12 semanas; máximo 366 días) MUST mostrar:
  afiliaciones activas hoy, nuevas y bajas en el periodo, saldo, tasa de abandono (bajas / (activas
  al inicio + nuevas)) y la serie semanal (nuevas, bajas, activas al cierre de la semana).
- **FR-011**: MUST mostrar las parejas pasajero–conductor con viajes completados en el periodo,
  cuántas repitieron (≥ 2 viajes), la tasa de repetición y los viajes por pareja.
- **FR-012**: MUST mostrar el SC-008 de 001: de las afiliaciones creadas en el periodo que ya
  cumplieron 30 días, el porcentaje en que el pasajero pidió al menos un viaje a ese conductor en
  esos 30 días; la meta (80 %), si se cumple, y cuántas afiliaciones siguen en curso.
- **FR-013**: MUST listar los conductores con más bajas de afiliados en el periodo y los
  conductores elegidos inactivos (con afiliados activos y sin viajes completados en los últimos 30
  días), con su número de afiliados y su último viaje.

**Moderación (módulo 5 del SDD)**

- **FR-014**: El administrador MUST poder buscar usuarios por nombre o teléfono y filtrar por rol
  y estado (activo, suspendido).
- **FR-015**: El administrador MUST poder suspender y reactivar a pasajeros y conductores con un
  motivo obligatorio (3 a 500 caracteres); no a administradores.
- **FR-016**: Suspender MUST cerrar las sesiones del usuario, impedir iniciar o renovar sesión,
  poner OFFLINE al conductor que no esté en un viaje e impedirle volver a ONLINE. Las sesiones de
  acceso ya emitidas caducan como máximo a los 15 minutos.
- **FR-017**: Cada suspensión y reactivación MUST quedar registrada (usuario, acción, motivo,
  administrador, fecha) y consultarse por usuario.

**Salud (módulo 6 del SDD)**

- **FR-018**: El sistema MUST comprobar en paralelo, con un límite de 3 s cada una, la base de
  datos, el tiempo real, la voz, las rutas, el almacenamiento de documentos y la pasarela de pagos,
  y devolver por cada una: estado (disponible, caída, desactivada), latencia y un detalle breve.
- **FR-019**: El estado global MUST ser "caído" si falla la base de datos, "degradado" si falla
  cualquier otra y "operativo" si no falla ninguna.
- **FR-020**: Las respuestas MUST NOT incluir secretos, credenciales ni direcciones internas con
  credenciales.

**Común**

- **FR-021**: Todas las pantallas y datos de este módulo MUST ser exclusivos del rol
  administrador.

### Key Entities

- **Instantánea de la torre**: momento, resolución, totales, hexágonos con sus contadores y
  conductores ONLINE con posición; se calcula al pedirla, no se guarda.
- **Hexágono**: índice H3, centro y contorno, contadores y nivel de presión.
- **Resumen financiero mensual**: mes, ingresos, costo, margen y conductores; derivado de pagos,
  uso diario y tarifas de 002.
- **Indicadores de fidelización**: derivados de afiliaciones y viajes.
- **Suspensión del usuario**: fecha y motivo vigentes en el usuario.
- **Acción de moderación**: usuario, suspender/reactivar, motivo, administrador y fecha.
- **Comprobación de salud**: dependencia, estado, latencia, detalle y hora; no se guarda.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Un cambio de presencia o ubicación de un conductor se ve en la torre en menos de
  10 s en el 95 % de los casos.
- **SC-002**: La torre se carga en menos de 2 s con 200 conductores ONLINE y 1 000 solicitudes en
  la última hora.
- **SC-003**: Los totales mensuales de Finanzas coinciden al centavo con la suma del detalle por
  conductor del mismo mes (0 diferencias en las pruebas).
- **SC-004**: Un administrador sabe en menos de 1 minuto si el último mes fue rentable y cuánto
  cuesta un conductor activo.
- **SC-005**: Un usuario suspendido no obtiene ninguna sesión nueva (0 casos en las pruebas) y su
  sesión vigente deja de servir en 15 minutos o menos.
- **SC-006**: El 100 % de las suspensiones y reactivaciones tienen motivo, autor y fecha.
- **SC-007**: La página de salud identifica la dependencia caída en menos de 5 s.
- **SC-008 de 001**: medible desde el panel sin consultas manuales a la base de datos.

## Assumptions

- Los hexágonos usan el sistema H3 (constitución II); resolución 8 por defecto (lado ~0,46 km),
  adecuada para barrios de Bogotá, Cali o Lima; el administrador puede elegir de 6 a 9.
- "Demanda" son las solicitudes de viaje (creadas en la última hora, por recogida) y "oferta" los
  conductores libres; en Kyq el pasajero pide a su conductor elegido, así que la presión por zona
  orienta dónde conviene que haya conductores, no un despacho automático.
- La actualización en vivo envía solo un aviso de "algo cambió" (como mucho uno cada 3 s) y el
  panel vuelve a pedir la instantánea; así el coste en eventos es acotado y no viajan datos
  personales por el canal. Además el panel actualiza cada 30 s (avanza la ventana de una hora y
  cubre los fallos del canal).
- La instantánea no se guarda: no hay histórico ni reproducción de la torre en esta fase.
- Finanzas reutiliza el cálculo de costos de 002 tal cual; los conductores cuentan desde el mes en
  que se crearon. Ingresos = pagos aprobados cuyo periodo cubierto empieza en el mes (criterio de
  002), en la moneda del precio vigente de la ciudad.
- Una sola ciudad y una sola moneda (como 002).
- SC-008 se mide por afiliación (pareja pasajero–conductor), y "pedir un viaje" es crear una
  solicitud a ese conductor, termine como termine.
- La moderación no notifica al usuario por SMS en esta fase; el usuario ve el mensaje al intentar
  entrar.
- Al suspender no se cancela el viaje en curso (la seguridad del pasajero en marcha prima); el
  administrador puede contactar a las partes por fuera.
- La salud se comprueba al abrir o refrescar la página; no hay alertas automáticas ni histórico
  (Sentry ya recoge los errores).
- Solo panel web; las apps de conductor y pasajero no cambian salvo los mensajes de cuenta
  suspendida que ya muestran como error de sesión.
- Fuera de alcance de esta fase (el SDD los cita en los mismos módulos): la inspección en un clic
  del detalle de cada viaje activo desde el mapa (la torre muestra conductores y viajes agregados),
  el megáfono PTT por zona y la consola SOS (fase 003), el centro de soporte y disputas, el
  porcentaje de sesiones sin fallos (lo da Sentry) y la conmutación de dominios espejo.
- "MRR" del SDD = ingresos por suscripción del mes en Finanzas (un mes por pago, precio único).

# Feature Specification: MVP Conductor Elegido + Viaje + PTT 1 a 1 (Android)

**Feature Branch**: `001-chosen-driver-trip-ptt`

**Created**: 2026-10-27

**Status**: Draft

**Input**: User description: "MVP Kyq en Android: el pasajero afilia a un conductor escaneando su QR y lo guarda como Conductor Elegido; ve en su pantalla principal si sus conductores elegidos están libres u ocupados (con tiempo estimado para liberarse); solicita un viaje directamente a su conductor elegido (oferta exclusiva 25 s, RN-KYQ-007); el conductor (con suscripción activa o en gracia y KYC vigente, RN-KYQ-002/003/016) acepta y el viaje sigue el ciclo ACCEPTED → ARRIVED → IN_PROGRESS → COMPLETED; al aceptar se abre automáticamente un canal walkie-talkie PTT 1 a 1 entre pasajero y conductor (RN-KYQ-009) que sigue abierto 15 minutos tras finalizar (RN-KYQ-014); en el conductor la voz entrante suena en manos libres bajando el volumen del GPS (RN-KYQ-011); liquidación 100 % para el conductor sin comisión (RN-KYQ-001). Fuera del MVP: cooperativas y delegación, bolsa zonal H3, pagos en app, iOS, panel admin más allá de lo mínimo, botones Bluetooth, burbuja flotante, historial de voz."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Afiliar un Conductor Elegido por QR (Priority: P1)

El conductor muestra su código QR personal (en la app o impreso en el vehículo). El pasajero lo
escanea con Kyq Pasajero y el conductor queda guardado en su lista "Mis Conductores Elegidos".
El conductor ve al pasajero en su cartera de clientes.

**Why this priority**: es el vínculo que diferencia a Kyq de una plataforma anónima; sin él no
existe el Conductor Elegido ni el resto del MVP.

**Independent Test**: un conductor registrado muestra su QR; un pasajero lo escanea y ambos ven
el vínculo en su app. Entrega valor por sí solo: el pasajero conserva a su conductor de
confianza.

**Acceptance Scenarios**:

1. **Given** un pasajero registrado y un conductor con perfil activo, **When** el pasajero
   escanea el QR del conductor, **Then** el conductor aparece en "Mis Conductores Elegidos" y el
   pasajero aparece en la cartera del conductor (RN-KYQ-005).
2. **Given** un pasajero que ya tiene a ese conductor como elegido, **When** escanea de nuevo su
   QR, **Then** no se crea un duplicado y se le informa que ya está afiliado.
3. **Given** un QR que no corresponde a un conductor Kyq válido, **When** el pasajero lo escanea,
   **Then** la app indica que el código no es válido y no crea ningún vínculo.
4. **Given** un pasajero con conductores elegidos, **When** elimina uno de su lista, **Then** deja
   de verlo en su pantalla principal y de poder pedirle viajes directos.

---

### User Story 2 - Ver disponibilidad de mis conductores y pedirles un viaje (Priority: P1)

En la pantalla principal el pasajero ve a sus conductores elegidos primero, cada uno como
"Libre" u "Ocupado" con el tiempo estimado para liberarse. Elige uno libre, indica origen y
destino, ve la tarifa y envía la solicitud. Solo ese conductor recibe la oferta durante 25
segundos. El conductor acepta y el viaje avanza por llegada, inicio y fin. El conductor recibe el
100 % de la tarifa.

**Why this priority**: es el núcleo del producto (despacho nominal y modelo 0 % comisión).

**Independent Test**: con un pasajero y un conductor vinculados, el pasajero pide un viaje, el
conductor lo acepta y lo completa; ambos ven el mismo estado en cada paso y el resumen final
muestra 0 de comisión.

**Acceptance Scenarios**:

1. **Given** un pasajero con conductores elegidos, **When** abre la app, **Then** ve primero a sus
   conductores elegidos con su estado (Libre / Ocupado + minutos estimados para liberarse)
   (RN-KYQ-006).
2. **Given** un conductor elegido Libre, **When** el pasajero confirma origen, destino y tarifa y
   solicita el viaje, **Then** solo ese conductor recibe la oferta y tiene 25 segundos para
   responder (RN-KYQ-007).
3. **Given** una oferta en curso, **When** el conductor la acepta antes de 25 s, **Then** el viaje
   pasa a ACCEPTED y ambas partes ven los datos del otro (nombre, vehículo, posición del
   conductor).
4. **Given** una oferta en curso, **When** el conductor la acepta cambiando la tarifa, **Then** el
   pasajero ve la nueva tarifa y el viaje pasa a ACCEPTED solo si la confirma en 30 s; si no,
   se cancela sin cargo.
5. **Given** una oferta en curso, **When** el conductor propone negociar y el pasajero acepta,
   **Then** ambos intercambian propuestas hasta que uno acepta (viaje ACCEPTED con esa tarifa)
   o se agota el tiempo (cancelado sin cargo); **When** el pasajero no acepta negociar, **Then**
   sigue vigente la tarifa sugerida.
6. **Given** una oferta en curso, **When** el conductor la rechaza o pasan 25 s sin respuesta,
   **Then** la solicitud se cierra y el pasajero recibe aviso para reintentar o elegir otro
   conductor elegido.
7. **Given** un viaje ACCEPTED, **When** el conductor marca llegada, inicio y fin, **Then** el
   estado avanza a ARRIVED, IN_PROGRESS y COMPLETED y el pasajero lo ve en su app.
8. **Given** un viaje COMPLETED, **When** se muestra el resumen, **Then** el conductor recibe el
   100 % de la tarifa acordada y la comisión de plataforma es 0 (RN-KYQ-001).
9. **Given** un conductor con suscripción suspendida o un documento obligatorio vencido,
   **When** intenta ponerse ONLINE, **Then** no puede y la app le indica el motivo
   (RN-KYQ-002, RN-KYQ-016); con suscripción en gracia sí puede (RN-KYQ-003).
10. **Given** un conductor con un viaje en curso cuya suscripción vence durante el viaje,
   **When** el viaje sigue, **Then** no se interrumpe y puede completarlo (RN-KYQ-003).

---

### User Story 3 - Walkie-talkie 1 a 1 durante el viaje (Priority: P2)

Al aceptarse el viaje se abre solo un canal de voz privado entre pasajero y conductor. Mientras
mantienen pulsado el botón hablan; al soltar, el otro oye el mensaje al instante. En el
conductor la voz suena por altavoz sin tocar la pantalla y baja el volumen del GPS mientras
dura. El canal sigue abierto 15 minutos después de terminar el viaje para objetos olvidados.

**Why this priority**: es el diferencial de comunicación sin llamadas ni números telefónicos,
pero el viaje funciona sin él.

**Independent Test**: con un viaje aceptado, el pasajero mantiene pulsado y habla; el conductor
lo oye sin tocar la pantalla y responde. 15 minutos tras COMPLETED el canal se cierra.

**Acceptance Scenarios**:

1. **Given** un viaje que pasa a ACCEPTED, **When** cualquiera de las dos apps lo muestra,
   **Then** el botón walkie-talkie está activo sin pasos adicionales (RN-KYQ-009).
2. **Given** el canal abierto, **When** una parte mantiene pulsado y habla, **Then** la otra oye
   la voz en menos de 1 segundo y nadie ve el número de teléfono del otro.
3. **Given** que ambas partes pulsan a la vez, **When** se produce el conflicto, **Then** solo una
   transmite y la otra recibe aviso de canal ocupado.
4. **Given** el conductor con la app en segundo plano o la pantalla apagada y una app de
   navegación hablando, **When** llega voz del pasajero, **Then** se reproduce por altavoz y la
   navegación baja su volumen mientras dura el mensaje (RN-KYQ-011).
5. **Given** un viaje COMPLETED, **When** pasan 15 minutos, **Then** el canal se cierra y ninguna
   de las partes puede seguir usándolo (RN-KYQ-014).
6. **Given** un viaje cancelado, **When** se cancela, **Then** el canal se cierra de inmediato.

---

### Edge Cases

- El conductor elegido pasa a Ocupado mientras el pasajero está creando la solicitud: la app lo
  avisa y no envía la oferta.
- El pasajero cierra la app o pierde conexión durante una negociación: si no responde en 30 s,
  la negociación termina y el viaje se cancela sin cargo.
- Dos pasajeros piden al mismo conductor casi a la vez: solo una oferta se presenta; la otra
  recibe "conductor ocupado".
- El pasajero cancela antes de que el conductor responda: la oferta desaparece del conductor.
- Cancelación tras ACCEPTED y antes de IN_PROGRESS por cualquiera de las partes: el viaje termina
  como cancelado, sin cargo, y el canal de voz se cierra.
- Pérdida de conexión de una parte durante el viaje: al reconectar ve el estado actual del
  viaje sin perder pasos; los mensajes de voz perdidos durante la desconexión no se reproducen.
- Red que bloquea el tráfico de voz en tiempo real: la voz sigue funcionando por una ruta
  alternativa, con más latencia.
- El pasajero niega el permiso de micrófono: puede escuchar pero no hablar, y se le indica cómo
  activarlo.
- El conductor niega permisos de ubicación o de ejecución en segundo plano: no puede ponerse
  ONLINE hasta concederlos.
- Teléfonos Huawei sin servicios de Google: notificaciones y ubicación funcionan igual.

## Requirements *(mandatory)*

### Functional Requirements

**Cuentas y acceso**

- **FR-001**: Pasajeros y conductores MUST registrarse e iniciar sesión con su número de teléfono
  verificado por código de un solo uso.
- **FR-002**: El sistema MUST permitir al conductor ponerse ONLINE solo si su suscripción está
  activa o en gracia y sus documentos obligatorios están vigentes (RN-KYQ-002, RN-KYQ-003,
  RN-KYQ-016), e indicar el motivo cuando lo bloquea.
- **FR-003**: El sistema MUST mantener la gracia de 72 horas tras el vencimiento de la
  suscripción y nunca interrumpir un viaje en curso por suscripción o documentos.
- **FR-004**: Un administrador MUST poder registrar el pago de la suscripción de un conductor,
  aprobar sus documentos y su fecha de vencimiento (panel mínimo).

**Conductor Elegido**

- **FR-005**: Cada conductor MUST tener un código QR personal, mostrable en la app y descargable
  para imprimir.
- **FR-006**: Los pasajeros MUST poder afiliar un conductor escaneando su QR, sin duplicados, y
  eliminarlo de su lista.
- **FR-007**: Cada afiliación MUST quedar en la cartera del conductor, que puede ver la lista de
  sus clientes afiliados (RN-KYQ-005).
- **FR-008**: La pantalla principal del pasajero MUST mostrar primero a sus conductores elegidos
  con su estado Libre, Ocupado (con minutos estimados para liberarse) o Desconectado,
  actualizado en vivo (RN-KYQ-006).

**Viaje**

- **FR-009**: El pasajero MUST poder indicar origen (por defecto su ubicación) y destino, ver la
  tarifa y solicitar el viaje a un conductor elegido Libre.
- **FR-010**: El sistema MUST sugerir la tarifa automáticamente según la distancia y el tiempo
  estimados de la ruta y la tabla de tarifas de la ciudad, y mostrarla al pasajero antes de
  solicitar (RN-KYQ-013).
- **FR-010a**: Al recibir la oferta, el conductor MUST poder aceptarla con la tarifa sugerida o
  con otra tarifa que él indique. Si la cambia, el pasajero MUST ver la nueva tarifa y
  confirmarla en 30 segundos; si la rechaza o no responde, el viaje se cancela sin cargo.
- **FR-010c**: Como alternativa a FR-010a, el conductor MUST poder proponer negociar la tarifa.
  La negociación solo empieza si el pasajero la acepta; si la rechaza, se mantiene la tarifa
  sugerida y el conductor decide si acepta el viaje con ella. Durante la negociación ambas partes
  se envían propuestas y contrapropuestas; cada propuesta se responde en 30 segundos y la
  negociación termina al aceptar una de ellas, al abandonarla cualquiera de las partes o a los
  3 minutos. Sin acuerdo, el viaje se cancela sin cargo. La oferta sigue reservada a ese
  conductor mientras dura la negociación.
- **FR-010b**: Un administrador MUST poder definir la tabla de tarifas de cada ciudad (tarifa
  base, precio por kilómetro, precio por minuto y tarifa mínima).
- **FR-011**: La oferta MUST enviarse en exclusiva al conductor elegido durante 25 segundos; si la
  rechaza o expira, la solicitud se cierra y se avisa al pasajero (RN-KYQ-007).
- **FR-012**: Un conductor MUST recibir como máximo una oferta a la vez y no recibir ofertas
  mientras tiene un viaje activo.
- **FR-013**: El viaje MUST seguir los estados ACCEPTED → ARRIVED → IN_PROGRESS → COMPLETED, con
  CANCELLED posible antes de IN_PROGRESS; ambas apps MUST mostrar siempre el mismo estado.
- **FR-014**: Tras aceptar, el pasajero MUST ver la posición del conductor acercándose y el
  conductor MUST poder abrir la ruta al punto de recogida y al destino en una app de navegación
  externa.
- **FR-015**: Al completar el viaje, el sistema MUST registrar la tarifa como 100 % para el
  conductor y comisión 0 (RN-KYQ-001), y mostrar el resumen a ambas partes. El cobro se hace
  fuera de la app.

**Walkie-talkie PTT**

- **FR-016**: Al pasar el viaje a ACCEPTED el sistema MUST abrir un canal de voz privado entre
  pasajero y conductor, accesible solo para ellos (RN-KYQ-009).
- **FR-017**: Los participantes MUST hablar manteniendo pulsado un botón; solo una persona
  transmite a la vez y la otra ve quién habla.
- **FR-018**: La voz entrante MUST reproducirse automáticamente, también con la app del conductor
  en segundo plano o la pantalla apagada.
- **FR-019**: En el conductor, la voz entrante MUST bajar el volumen de la navegación mientras
  suena (RN-KYQ-011).
- **FR-020**: El canal MUST cerrarse 15 minutos después de COMPLETED o inmediatamente al
  cancelar (RN-KYQ-014), y ninguna parte MUST ver el número de teléfono de la otra.
- **FR-021**: Los mensajes de voz MUST NOT grabarse ni almacenarse en el MVP.

**Plataforma**

- **FR-022**: Ambas apps MUST funcionar en Android 10 o superior, incluidos teléfonos sin
  servicios de Google.

### Key Entities

- **Conductor**: autónomo con perfil, vehículo, código QR, estado (Desconectado, Libre, Ocupado),
  suscripción y documentos.
- **Suscripción**: periodo pagado del conductor; estados activa, en gracia (72 h) o suspendida.
- **Documento obligatorio**: licencia, seguro obligatorio, documento del vehículo; con fecha de
  vencimiento y estado de aprobación.
- **Pasajero**: usuario con teléfono verificado y lista de conductores elegidos.
- **Afiliación**: vínculo pasajero ↔ conductor creado por QR; pertenece a la cartera del
  conductor.
- **Viaje**: solicitud nominal de un pasajero a un conductor elegido, con origen, destino,
  tarifa sugerida, tarifa acordada, estados y liquidación (100 % conductor, 0 comisión).
- **Tabla de tarifas**: valores por ciudad (base, por kilómetro, por minuto, mínima) usados para
  sugerir la tarifa.
- **Oferta**: propuesta de viaje enviada a un único conductor con vencimiento de 25 s.
- **Canal de voz del viaje**: canal privado de dos participantes ligado a un viaje, abierto desde
  ACCEPTED hasta 15 min después de COMPLETED.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Un pasajero afilia a un conductor por QR en menos de 15 segundos desde que abre el
  escáner.
- **SC-002**: El estado de un conductor elegido (Libre / Ocupado) se refleja en la app del
  pasajero en menos de 5 segundos tras cambiar.
- **SC-003**: Un pasajero solicita un viaje a su conductor elegido en menos de 30 segundos desde
  que abre la app.
- **SC-004**: El conductor recibe la oferta en menos de 3 segundos tras la solicitud en el 95 %
  de los casos.
- **SC-005**: La voz llega al otro participante en menos de 250 ms en 4G en el 95 % de los
  mensajes y en menos de 1 segundo en el peor caso aceptable.
- **SC-006**: El 95 % de los mensajes de voz al conductor se reproducen sin que toque el
  teléfono, también con la pantalla apagada.
- **SC-007**: El 100 % de los viajes completados registran 0 de comisión y 100 % para el
  conductor.
- **SC-008**: En una prueba piloto, al menos el 80 % de los pasajeros que afilian un conductor le
  piden al menos un viaje en sus primeros 30 días.

## Assumptions

- El MVP es solo Android; el pasajero no tiene versión web en esta fase.
- No hay pagos dentro de la app: el pasajero paga al conductor directamente y la suscripción la
  registra un administrador manualmente.
- El alta de conductores (perfil, vehículo, documentos) se completa con ayuda de un
  administrador; la carga de documentos desde la app no entra en el MVP.
- Sin cooperativas, delegación, bolsa zonal, pre-consulta PTT antes del viaje, botones
  Bluetooth, burbuja flotante, historial de voz ni iOS.
- El tiempo estimado para liberarse de un conductor ocupado se calcula con la ruta restante de
  su viaje actual.
- Un pasajero puede tener cualquier número de conductores elegidos; un conductor, cualquier
  número de afiliados.
- La navegación paso a paso la hace una app externa elegida por el conductor.
- Cancelar antes de IN_PROGRESS no tiene penalización en el MVP.
- La negociación es una práctica habitual entre conductores y clientes; por eso existe, pero
  siempre con consentimiento del pasajero. La tarifa sugerida sigue siendo la opción por defecto.
- El conductor puede subir o bajar la tarifa sin límite; el control lo ejerce el pasajero al
  confirmarla. La tarifa acordada no cambia durante el viaje aunque la ruta real varíe.
- El MVP arranca con una sola ciudad configurada.
- Se usará con red móvil 4G o mejor en zonas urbanas.

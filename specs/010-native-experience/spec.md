# Feature Specification: Experiencia nativa: cartera con notas y agenda, llegada automática, escaneo de documentos, direcciones y mapa

**Feature Branch**: `010-native-experience`

**Created**: 2026-10-28

**Status**: Draft

**Input**: User description: "Funciones del SDD aún sin construir en las apps: CRM del autónomo con
notas por pasajero y agenda de viajes (CHK-KYQ-03, `kyq_driver.loyalty_crm`); geocerca automática
de llegada a la recogida a menos de 60 m (CHK-DRV-09); subida de documentos KYC con detección y
recorte automático de bordes (CHK-DRV-08); buscador de direcciones con destinos frecuentes
(CHK-PAS-04); mapa del pasajero con movimiento suave del vehículo (CHK-PAS-02) y pines dorados de
los Conductores Elegidos (`kyq_rider.map_vector_gl`). Fuera: historial de voz (CHK-ZEL-14) y
fusión de sensores (CHK-DRV-06)."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Agenda: el pasajero reserva un viaje con su Conductor Elegido (Priority: P1)

El pasajero reserva un viaje para más tarde (de 30 minutos a 7 días) con uno de sus Conductores
Elegidos: elige recogida, destino, fecha y hora y ve la tarifa sugerida (con la preferencial de
008 si aplica). El conductor recibe la reserva y la acepta o la rechaza; la ve en su agenda. Ambos
reciben un recordatorio 30 minutos antes. A la hora, si el conductor está ONLINE, recibe la oferta
nominal exclusiva de 25 s como en 001 (Prioridad Oro); si no responde o no está disponible, el
pasajero recibe aviso y puede pedir a la cooperativa o a la bolsa. Cualquiera de los dos puede
cancelar la reserva hasta la hora sin cargo.

**Why this priority**: es la "agenda de viajes" del CRM del SDD y refuerza la relación directa
(RN-KYQ-005, RN-KYQ-007): el cliente frecuente asegura a su conductor.

**Independent Test**: el pasajero reserva para dentro de 1 hora; el conductor la acepta y la ve en
su agenda; 30 minutos antes ambos ven el recordatorio; a la hora el conductor ONLINE recibe la
oferta y el viaje sigue el ciclo normal.

**Acceptance Scenarios**:

1. **Given** un Conductor Elegido, **When** el pasajero reserva para dentro de 2 horas, **Then**
   el conductor recibe la reserva y el pasajero la ve "pendiente de confirmar".
2. **Given** una reserva pendiente, **When** el conductor la acepta, **Then** ambos la ven
   "confirmada" y aparece en la agenda del conductor ordenada por hora.
3. **Given** una reserva confirmada, **When** faltan 30 minutos, **Then** ambos reciben un
   recordatorio.
4. **Given** la hora de una reserva confirmada y el conductor ONLINE, **When** llega la hora,
   **Then** recibe la oferta nominal de 25 s con la tarifa reservada.
5. **Given** el conductor OFFLINE u ocupado a la hora, **When** llega la hora, **Then** el
   pasajero recibe aviso y puede pedir a la cooperativa o a la bolsa.
6. **Given** una reserva, **When** cualquiera la cancela antes de la hora, **Then** se cancela
   sin cargo y el otro recibe aviso.
7. **Given** una reserva sin respuesta del conductor 15 minutos antes de la hora, **When** llega
   ese momento, **Then** se cancela y se avisa al pasajero.

---

### User Story 2 - Notas privadas del conductor sobre sus clientes (Priority: P2)

En "Mis clientes", el conductor abre un cliente y ve cuántos viajes han hecho juntos, la fecha del
último, el origen de la afiliación (008) y sus próximas reservas; puede escribir notas privadas
("prefiere aire acondicionado", "recoger en la portería 2") que solo él ve. Cuando ese cliente le
pide un viaje, la oferta muestra la nota.

**Why this priority**: completa la cartera del SDD ("notas por pasajero"); ayuda a dar un servicio
personal.

**Independent Test**: el conductor escribe una nota para Ana; Ana le pide un viaje y la oferta
muestra la nota; el pasajero no la ve nunca.

**Acceptance Scenarios**:

1. **Given** un cliente, **When** el conductor guarda una nota, **Then** la ve en la ficha y en
   las ofertas de ese cliente.
2. **Given** una nota, **When** el pasajero usa su app, **Then** no la ve en ninguna parte.
3. **Given** un cliente que eliminó la afiliación, **When** el conductor busca su ficha, **Then**
   ya no aparece y la nota se borra.

---

### User Story 3 - Llegada automática a la recogida (Priority: P2)

Cuando el conductor con un viaje aceptado está a menos de 60 m del punto de recogida durante al
menos 10 segundos, el viaje pasa solo a "llegó" y el pasajero recibe el aviso, sin que el conductor
toque la pantalla (va conduciendo). El conductor puede seguir marcando "Llegué" a mano.

**Why this priority**: seguridad al volante (el conductor no manipula el teléfono) y avisos más
fiables.

**Independent Test**: con el viaje aceptado, se simula al conductor acercándose a 40 m de la
recogida y quedándose 10 s; el viaje pasa a "llegó" y el pasajero lo ve.

**Acceptance Scenarios**:

1. **Given** un viaje aceptado, **When** el conductor está a menos de 60 m durante 10 s, **Then**
   el viaje pasa a "llegó" y el pasajero recibe el aviso.
2. **Given** que pasa a menos de 60 m sin detenerse (menos de 10 s), **When** se aleja, **Then**
   no cambia el estado.
3. **Given** una ubicación con precisión peor que 50 m, **When** se evalúa, **Then** no cuenta
   para la llegada automática.
4. **Given** que el conductor ya marcó "Llegué", **When** entra en la zona, **Then** no se repite.

---

### User Story 4 - Escaneo de documentos con recorte automático (Priority: P2)

Al subir un documento (002), el conductor lo enfoca con la cámara y la app detecta los bordes del
documento, lo recorta, endereza la perspectiva y avisa si la foto está borrosa antes de subirla. En
teléfonos sin los servicios necesarios para la detección automática (por ejemplo, Huawei sin Google
Play Services) puede ajustar a mano las cuatro esquinas.

**Why this priority**: documentos más legibles, menos rechazos en la validación y menos
reenvíos.

**Independent Test**: el conductor fotografía su licencia sobre una mesa; la imagen subida
contiene solo el documento recortado y derecho; una foto movida se avisa como borrosa.

**Acceptance Scenarios**:

1. **Given** un documento sobre una superficie, **When** el conductor lo escanea, **Then** la
   imagen resultante contiene solo el documento, recortado y enderezado.
2. **Given** una foto borrosa, **When** se va a subir, **Then** se avisa y se ofrece repetir.
3. **Given** un teléfono sin detección automática, **When** escanea, **Then** puede ajustar las
   cuatro esquinas a mano.

---

### User Story 5 - Buscar direcciones y usar destinos frecuentes (Priority: P1)

Al pedir un viaje, el pasajero escribe una dirección o un lugar ("Calle 72 # 10", "Centro
Comercial Andino") y elige entre las sugerencias de su ciudad. La app recuerda sus destinos
recientes (los 10 últimos) y le deja guardar "Casa" y "Trabajo", que aparecen primero. Sigue
pudiendo marcar el punto en el mapa.

**Why this priority**: hoy solo se marca un punto en el mapa, lo que es lento y propenso a error;
es la forma habitual de pedir un viaje.

**Independent Test**: el pasajero escribe "Andino", elige la sugerencia y la tarifa se calcula; en
el siguiente pedido el destino aparece en recientes.

**Acceptance Scenarios**:

1. **Given** la pantalla de solicitud, **When** el pasajero escribe al menos 3 letras, **Then**
   ve sugerencias de su ciudad en menos de 1 s.
2. **Given** una sugerencia elegida, **When** se fija como destino, **Then** se calcula la tarifa
   como con el mapa.
3. **Given** viajes anteriores, **When** abre el buscador, **Then** ve "Casa", "Trabajo" y sus
   destinos recientes antes de escribir.
4. **Given** el buscador sin conexión o sin resultados, **When** busca, **Then** puede marcar el
   punto en el mapa.

---

### User Story 6 - Mapa del pasajero más claro (Priority: P3)

En el seguimiento del viaje, el vehículo del conductor se mueve de forma continua entre una
ubicación y la siguiente, girando según su rumbo, en lugar de saltar. En el inicio, el pasajero ve
un mapa con sus Conductores Elegidos libres como pines dorados en su zona aproximada (no su
posición exacta), además de la lista de 001.

**Why this priority**: mejora la percepción de calidad (SDD `kyq_rider.map_vector_gl`); no cambia
reglas.

**Independent Test**: con actualizaciones de ubicación cada 3 s, el vehículo se desplaza sin saltos;
en el inicio, un conductor libre aparece como pin dorado en su zona y desaparece al ocuparse.

**Acceptance Scenarios**:

1. **Given** un viaje en seguimiento, **When** llega una nueva ubicación, **Then** el vehículo se
   desplaza de forma continua hasta ella y orienta según el rumbo.
2. **Given** Conductores Elegidos libres, **When** el pasajero abre el inicio, **Then** los ve como
   pines dorados en su zona aproximada.
3. **Given** un Conductor Elegido ocupado o desconectado, **When** se muestra el mapa, **Then** no
   aparece como pin (sigue en la lista con su estado).

### Edge Cases

- Reserva para una hora en la que el pasajero ya tiene otro viaje activo: a la hora se le avisa y
  no se crea la oferta hasta que termine o cancele.
- El conductor deja de ser Conductor Elegido del pasajero (eliminado) con reservas pendientes: se
  cancelan con aviso.
- Dos reservas del mismo conductor a menos de 30 minutos: se permite reservar, pero el conductor
  ve el aviso de solape al aceptar.
- Conductor suspendido (007) con reservas: se cancelan con aviso al pasajero.
- Llegada automática con GPS saltando: solo cuentan ubicaciones con precisión ≤ 50 m.
- Llegada automática en un viaje de la bolsa o derivado: igual que en uno directo.
- Escaneo sin permiso de cámara: se explica y se ofrece elegir de la galería (como 002).
- Búsqueda de direcciones fuera de la ciudad configurada: no se sugieren.
- Zona aproximada de un Conductor Elegido: nunca más precisa que un hexágono de ~0,7 km².

## Requirements *(mandatory)*

### Functional Requirements

**Agenda y reservas**

- **FR-001**: El pasajero MUST poder reservar un viaje con uno de sus Conductores Elegidos para
  una hora entre 30 minutos y 7 días en el futuro, con recogida, destino y tarifa sugerida.
- **FR-002**: El conductor MUST poder aceptar o rechazar cada reserva y ver su agenda de reservas
  confirmadas y pendientes ordenada por hora.
- **FR-003**: Ambos MUST recibir un recordatorio 30 minutos antes de una reserva confirmada.
- **FR-004**: A la hora de una reserva confirmada, MUST crearse la solicitud nominal al conductor
  con la tarifa reservada y las reglas de 001 (25 s, RN-KYQ-007); si el conductor no está libre o
  no responde, el pasajero MUST recibir aviso y poder pedir por otra vía.
- **FR-005**: Cualquiera de las partes MUST poder cancelar la reserva antes de la hora, sin cargo;
  una reserva no confirmada 15 minutos antes de la hora MUST cancelarse sola.
- **FR-006**: Un pasajero MUST tener como máximo 3 reservas futuras activas.

**Cartera del conductor**

- **FR-007**: La ficha de un cliente MUST mostrar viajes completados juntos, fecha del último,
  origen de la afiliación y próximas reservas.
- **FR-008**: El conductor MUST poder escribir una nota privada por cliente (hasta 500
  caracteres) que se muestra en sus ofertas de ese cliente y que el pasajero MUST NOT ver nunca.
- **FR-009**: Si el pasajero elimina la afiliación, la nota MUST borrarse.

**Llegada automática**

- **FR-010**: Con un viaje aceptado, el viaje MUST pasar a "llegó" cuando el conductor está a
  menos de 60 m de la recogida durante 10 s seguidos, con ubicaciones de precisión ≤ 50 m.
- **FR-011**: El conductor MUST poder seguir marcando "Llegué" a mano; la llegada automática no
  se repite si ya llegó.

**Escaneo de documentos**

- **FR-012**: La captura de documentos MUST detectar los bordes, recortar y enderezar el
  documento y avisar de fotos borrosas antes de subir.
- **FR-013**: Sin detección automática disponible en el teléfono, el conductor MUST poder ajustar
  las cuatro esquinas a mano; la galería sigue disponible.

**Direcciones**

- **FR-014**: El pasajero MUST poder buscar direcciones y lugares de su ciudad y obtener
  sugerencias en menos de 1 s desde 3 caracteres.
- **FR-015**: La app MUST recordar los 10 destinos recientes y permitir guardar "Casa" y
  "Trabajo"; se guardan solo en el teléfono.
- **FR-016**: Marcar el punto en el mapa MUST seguir disponible.

**Mapa del pasajero**

- **FR-017**: En el seguimiento, el vehículo MUST moverse de forma continua entre ubicaciones y
  orientarse según el rumbo.
- **FR-018**: El inicio MUST mostrar los Conductores Elegidos libres como pines dorados en su
  zona aproximada (hexágono H3 de resolución 8), nunca en su posición exacta.

### Key Entities

- **Reserva**: pasajero, conductor, recogida, destino, hora, tarifa reservada, estado (pendiente,
  confirmada, rechazada, cancelada, cumplida, vencida), quién canceló, viaje creado.
- **Nota de cliente**: conductor, pasajero, texto, fecha de actualización.
- **Destino guardado** (solo en el teléfono): nombre (Casa, Trabajo o reciente), dirección y
  punto.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: El 95 % de las reservas confirmadas con el conductor ONLINE a la hora generan la
  oferta en menos de 5 s tras la hora reservada.
- **SC-002**: La llegada automática acierta: 0 llegadas marcadas a más de 100 m de la recogida en
  las pruebas, y el 90 % de las llegadas reales se detectan sin tocar la pantalla.
- **SC-003**: Los rechazos de documentos por ilegibilidad bajan un 50 % frente a 002.
- **SC-004**: El pasajero fija un destino por búsqueda en menos de 15 s en el 90 % de los casos.
- **SC-005**: Ninguna nota de conductor llega a la app del pasajero (0 casos en las pruebas).

## Assumptions

- **Reservas**: solo con Conductores Elegidos (la bolsa y la cooperativa son para viajes
  inmediatos); sin pago anticipado ni penalización por cancelar.
- **Recordatorios**: avisos en la app (en vivo o al abrirla), como en 002; sin SMS.
- **Detección de bordes**: se adopta un componente maduro (principio II); en teléfonos sin los
  servicios que necesita, recorte manual.
- **Direcciones**: un buscador de direcciones con datos de OpenStreetMap alojado por Kyq, como OSRM
  y las teselas (sin coste por consulta); limitado a la ciudad configurada.
- **Zona aproximada**: hexágono H3 de resolución 8 (~0,7 km²), coherente con la torre.
- **Fuera de esta etapa**: historial de voz y "repetir último audio" (CHK-ZEL-14; la voz no se
  guarda, decisión de 001) y fusión de sensores (CHK-DRV-06).
- Android para conductor y pasajero; iOS fuera de alcance (fase 2).

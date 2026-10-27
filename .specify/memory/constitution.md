<!--
Sync Impact Report
- Versión: plantilla sin rellenar → 1.0.0 (adopción inicial)
- Principios definidos: I. Clean-room; II. Adoptar antes que construir; III. Flutter en todos los
  clientes; IV. Backend monolito modular en Go; V. Reglas de negocio como contrato;
  VI. Pruebas y CI; VII. Simplicidad y coste medido
- Secciones añadidas: Restricciones de plataforma y rendimiento; Flujo de desarrollo
- Secciones eliminadas: ninguna
- TODO diferidos: ninguno
-->

# Kyq Constitution

Kyq es una plataforma de movilidad por suscripción SaaS mensual (0 % de comisión por viaje) para
conductores autónomos, con fidelización directa del pasajero y canal walkie-talkie (PTT) entre
pasajero y conductor.

## Core Principles

### I. Clean-room (NO NEGOCIABLE)

- Los APK de Uber y Zello y su análisis REA son solo referencia funcional: describen QUÉ hace el
  producto, nunca CÓMO se implementa en Kyq.
- Está prohibido copiar código descompilado, recursos (imágenes, sonidos, `assets/*`), formatos
  de protocolo propietarios, nombres de clases o marcas de terceros.
- Toda especificación de Kyq MUST redactarse en términos propios; las referencias a "clon" o
  "fusión exacta" de terceros no son válidas como requisito.

Razón: reduce el riesgo legal de propiedad intelectual y obliga a diseñar para Kyq.

### II. Adoptar antes que construir

- Capacidades resueltas por componentes maduros MUST usarlos: LiveKit para voz (WebRTC/Opus,
  cancelación de eco, supresión de ruido), Centrifugo para tiempo real, MapLibre + PMTiles para
  mapas, H3 para indexación geoespacial, Sentry para errores.
- Código C/C++ propio o protocolos de red propios MUST NOT introducirse sin una medición que
  demuestre que la alternativa adoptada no cumple el requisito.

Razón: el coste de mantenimiento domina sobre el coste de construcción.

### III. Flutter en todos los clientes

- Kyq Conductor, Kyq Pasajero y Kyq Admin (web) MUST construirse en Flutter dentro de un único
  monorepo gestionado con Melos, compartiendo modelos de dominio y clientes de red en paquetes.
- El código nativo se limita a capas delgadas en Kotlin (y Swift en fase 2) para servicios del
  sistema operativo: servicio en primer plano, botones físicos, superposición y PushToTalk.

Razón: un lenguaje y una base de código para tres productos.

### IV. Backend monolito modular en Go

- El backend MUST ser un único servicio Go organizado en módulos (auth, suscripciones, despacho,
  CRM, KYC, PTT, telemetría) sobre PostgreSQL + PostGIS, Redis y almacenamiento compatible S3.
- Un módulo SHALL extraerse a servicio independiente solo con evidencia de carga o de despliegue
  que lo justifique, documentada en el plan correspondiente.

Razón: menos piezas que operar con un equipo pequeño.

### V. Reglas de negocio como contrato

- Las reglas RN-KYQ-001 a RN-KYQ-016 son contrato del producto. Cada regla MUST tener al menos
  una prueba automatizada que falle si la regla se incumple.
- Cambiar una regla requiere actualizar la especificación, la prueba y esta trazabilidad en el
  mismo cambio.

Razón: el modelo de negocio (0 % comisión, suscripción, conductor elegido) es el diferencial.

### VI. Pruebas y CI

- Lógica de dominio: pruebas unitarias. UI crítica (viaje, PTT, pago): pruebas de widget.
  Contratos API cliente–servidor: pruebas de integración.
- Ningún cambio se integra en la rama principal sin CI en verde (análisis estático + pruebas).

Razón: tres apps y un backend comparten contratos; los fallos deben detectarse antes de llegar
al usuario.

### VII. Simplicidad y coste medido

- Aplicar YAGNI: no se construye infraestructura ni funcionalidad sin requisito vigente.
- El coste de infraestructura por conductor activo (voz, eventos, mapas, base de datos) MUST
  medirse y mostrarse en el panel de economía unitaria; toda decisión de arquitectura que lo
  aumente debe justificarse.

Razón: la cuota mensual fija debe cubrir el coste real de cada conductor.

## Restricciones de plataforma y rendimiento

- Orden de plataformas: 1) Android y web (admin y pasajero ligero); 2) iOS usando el framework
  PushToTalk de Apple; HarmonyOS NEXT queda fuera de alcance.
- Los builds Android MUST funcionar sin Google Play Services usando HMS Push y HMS Location
  como alternativa para dispositivos Huawei.
- Latencia de voz PTT extremo a extremo objetivo: < 250 ms en red 4G.
- Navegación paso a paso en el MVP mediante apps externas (Waze, Google Maps) con burbuja PTT.
- Documentación del proyecto en español.

## Flujo de desarrollo

- Cada funcionalidad sigue el ciclo Spec Kit: especificar → aclarar si hay ambigüedad →
  planificar → tareas → implementar.
- Todo plan MUST incluir una verificación contra esta constitución; las desviaciones se
  registran con su justificación.
- Las revisiones de código verifican cumplimiento de los principios I, II y V de forma explícita.

## Governance

- Esta constitución prevalece sobre cualquier otra práctica o documento del proyecto, incluido
  el SDD V2.0 cuando entren en conflicto.
- Enmiendas: propuesta escrita, aprobación del responsable de producto y plan de migración si
  afecta código existente.
- Versionado semántico: MAJOR para eliminar o redefinir principios; MINOR para añadir principios
  o secciones; PATCH para aclaraciones.
- Revisión de cumplimiento al cerrar cada funcionalidad y al menos una vez por trimestre.

**Version**: 1.0.0 | **Ratified**: 2026-10-27 | **Last Amended**: 2026-10-27

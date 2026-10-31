import 'package:flutter/widgets.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_realtime/kyq_realtime.dart';

import 'services.dart';

/// Lo que cada app pone para montar Radio. Las pantallas lo leen del contexto
/// (`RepositoryProvider<RadioDeps>`) junto con el [RadioCubit] de la app.
class RadioDeps {
  const RadioDeps({
    required this.api,
    required this.myUserId,
    required this.events,
    required this.newPlayer,
    this.location,
    this.photos = const PlatformRadioPhotoPicker(),
    this.isDriver = true,
    this.onEmergency,
    this.onRequestTrip,
    this.onShareLink,
    this.pickPoint,
  });

  final RadioApi api;
  final String myUserId;

  /// Eventos del canal `user:{id}`.
  final Stream<RealtimeEvent> events;

  /// Reproductor nuevo para cada conversación abierta.
  final MessagePlayer Function() newPlayer;
  final RadioLocation? location;
  final RadioPhotoPicker photos;

  /// Kyq Conductor: agregar contactos, crear canales y "Radio con mis clientes".
  final bool isDriver;

  /// Emergencia (FR-030): la app decide; con viaje en curso abre su SOS de 003. null la oculta.
  final Future<void> Function(BuildContext context, RadioConversation conversation)? onEmergency;

  /// Kyq Pasajero: "Pedir viaje" al conductor de la conversación (US3-6).
  final void Function(BuildContext context, RadioConversation conversation)? onRequestTrip;

  /// Compartir un enlace de invitación con el menú del sistema; null copia al portapapeles.
  final Future<void> Function(String text)? onShareLink;

  /// "Elegir un punto en el mapa" (FR-023) con el mapa de la app; null solo comparte la actual.
  final Future<RadioPoint?> Function(BuildContext context, RadioPoint? near)? pickPoint;
}

/// Rutas de Radio montadas en `/radio` de cada app.
abstract final class RadioRoutes {
  static const list = '/radio';
  static String conversation(String id) => '/radio/c/$id';
  static String invite(String code) => '/radio/invite/$code';
  static const newChannel = '/radio/channels/new';
  static String channel(String id) => '/radio/channels/$id';
  static const auto = '/radio/auto';
  static const settings = '/radio/settings';
}

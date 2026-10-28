import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ptt/kyq_ptt.dart';

import 'safety_page.dart';
import 'sos_cubit.dart';
import 'sos_widgets.dart';

/// Servicios de plataforma del kit de seguridad que pone cada app (GPS, menú de compartir,
/// marcador). Las pruebas pasan falsos.
class SafetyPlatform {
  const SafetyPlatform({
    required this.location,
    required this.share,
    required this.callEmergency,
    this.voice,
    this.mic,
  });

  /// GPS de la alerta: uno nuevo por alerta.
  final SosLocationSource Function() location;

  /// Abre el menú del sistema para compartir [text] (WhatsApp, SMS u otra app).
  final Future<void> Function(String text) share;

  /// Abre el marcador con el 123.
  final Future<void> Function() callEmergency;

  /// Sala de voz; null usa LiveKit.
  final VoiceRoom Function()? voice;
  final MicPermission? mic;

  /// Crea el [SosCubit] de un viaje y retoma una alerta abierta.
  SosCubit sosFor(SafetyApi api, String tripId) =>
      SosCubit(api: api, tripId: tripId, location: location(), voice: voice, mic: mic)..resume();
}

/// Estados en los que se comparte el viaje en vivo (FR-013).
const shareTripStatuses = {TripStatus.accepted, TripStatus.arrived, TripStatus.inProgress};

/// Seguridad de la pantalla del viaje: el SOS del [SosCubit] y el enlace compartido.
class TripSafety {
  const TripSafety({
    required this.api,
    required this.tripId,
    required this.sos,
    required this.platform,
    this.onSetupPin,
  });

  final SafetyApi api;
  final String tripId;
  final SosCubit sos;
  final SafetyPlatform platform;

  /// Abre la pantalla "Seguridad" para configurar el PIN tras una alerta sin él.
  final VoidCallback? onSetupPin;

  /// Botón "Compartir viaje" para la barra superior, o null fuera de los estados que lo permiten.
  Widget? shareAction(TripStatus status) =>
      shareTripStatuses.contains(status) ? ShareTripButton(api: api, tripId: tripId, share: platform.share) : null;
}

/// Pone el botón SOS sobre la pantalla del viaje y, con una alerta en curso, la sustituye por
/// [SosActiveView] (US1). Fuera de la ventana del SOS deja [child] tal cual.
class TripSafetyLayer extends StatelessWidget {
  const TripSafetyLayer({
    super.key,
    required this.safety,
    required this.status,
    required this.child,
    this.keepOpenWarning = false,
  });

  final TripSafety safety;
  final TripStatus status;
  final Widget child;

  /// Pasajero: la alerta solo se envía con la app abierta.
  final bool keepOpenWarning;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: safety.sos,
      child: BlocBuilder<SosCubit, SosState>(
        buildWhen: (a, b) => a.phase != b.phase,
        builder: (context, state) {
          if (state.phase != SosPhase.idle) {
            return SosActiveView(
              onCallEmergency: safety.platform.callEmergency,
              keepOpenWarning: keepOpenWarning,
              onSetupPin: safety.onSetupPin,
            );
          }
          if (!sosTripStatuses.contains(status)) return child;
          return Stack(
            children: [
              Positioned.fill(child: child),
              const Positioned(right: 16, bottom: 16, child: SosFab()),
            ],
          );
        },
      ),
    );
  }
}

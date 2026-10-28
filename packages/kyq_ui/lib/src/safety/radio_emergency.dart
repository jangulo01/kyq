import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';

import 'sos_widgets.dart';
import 'trip_safety.dart';

/// Botón Emergencia de Radio (011, FR-030): abre la pantalla del SOS de 003 (voz con el
/// operador, ubicación cada segundo y cancelar con PIN). [raise] llama a
/// `POST /v1/radio/conversations/{id}/emergency`: con viaje en curso es el SOS del viaje.
Future<void> openRadioEmergency(
  BuildContext context, {
  required SafetyApi api,
  required SafetyPlatform platform,
  required Future<RadioEmergency> Function(SosPoint? location) raise,
  VoidCallback? onSetupPin,
}) {
  Future<SosAlertSelf> raiseAlert(SosPoint? fix) async {
    final out = await raise(fix);
    final active = await api.activeSos();
    return active ??
        SosAlertSelf(id: out.alertId, tripId: out.tripId, status: SosStatus.open, createdAt: DateTime.now().toUtc());
  }

  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => platform.sosFromRadio(api, raiseAlert)..raise(),
        child: Scaffold(
          appBar: AppBar(title: const Text('Emergencia')),
          body: SosActiveView(onCallEmergency: () => platform.callEmergency(), onSetupPin: onSetupPin),
        ),
      ),
    ),
  );
}

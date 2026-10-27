import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';

import 'ptt_button.dart';
import 'ptt_controller.dart';

/// Estados del viaje con el canal de voz abierto (FR-016). Tras COMPLETED sigue abierto 15 min.
const pttTripStatuses = {TripStatus.accepted, TripStatus.arrived, TripStatus.inProgress, TripStatus.completed};

/// Barra con el [PttButton] para la pantalla del viaje (T074, T075).
///
/// Conecta la sala al ver el viaje en ACCEPTED o después y la cierra si se cancela. Se oculta
/// cuando el canal cierra: `ptt.closed`, `closes_at` vencido o token con 410.
class TripPttBar extends StatefulWidget {
  const TripPttBar({super.key, required this.controller, required this.status, this.remoteName = 'la otra parte'});

  final PttController controller;
  final TripStatus status;
  final String remoteName;

  @override
  State<TripPttBar> createState() => _TripPttBarState();
}

class _TripPttBarState extends State<TripPttBar> {
  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(TripPttBar old) {
    super.didUpdateWidget(old);
    if (old.status != widget.status || old.controller != widget.controller) _sync();
  }

  void _sync() {
    final controller = widget.controller;
    final status = widget.status;
    // Fuera del build: arrancar emite estados que reconstruyen el botón.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.isClosed) return;
      if (pttTripStatuses.contains(status)) {
        controller.start();
      } else if (status == TripStatus.cancelled) {
        controller.closeChannel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!pttTripStatuses.contains(widget.status)) return const SizedBox.shrink();
    return BlocBuilder<PttController, PttState>(
      bloc: widget.controller,
      buildWhen: (a, b) => (a.status == PttStatus.closed) != (b.status == PttStatus.closed),
      builder: (context, state) => state.status == PttStatus.closed
          ? const SizedBox.shrink()
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: PttButton(controller: widget.controller, remoteName: widget.remoteName),
              ),
            ),
    );
  }
}

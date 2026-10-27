import 'package:flutter/material.dart';
import 'package:kyq_api/kyq_api.dart';

/// Aviso "Tienes un viaje en curso" en la pantalla de inicio. Tras cerrar la app o perder la
/// sesión, es la forma de volver al viaje (edge case de reconexión de la spec).
///
/// Consulta al montarse, al volver la app a primer plano y cuando cambia [refreshKey].
class ActiveTripBanner extends StatefulWidget {
  const ActiveTripBanner({super.key, required this.load, required this.onOpen, this.refreshKey});

  final Future<Trip?> Function() load;
  final void Function(Trip trip) onOpen;
  final Object? refreshKey;

  @override
  State<ActiveTripBanner> createState() => _ActiveTripBannerState();
}

class _ActiveTripBannerState extends State<ActiveTripBanner> with WidgetsBindingObserver {
  Trip? _trip;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void didUpdateWidget(ActiveTripBanner old) {
    super.didUpdateWidget(old);
    if (old.refreshKey != widget.refreshKey) _refresh();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final trip = await widget.load();
      if (mounted) setState(() => _trip = trip);
    } on ApiException {
      // Sin red el aviso se queda como estaba; se reintenta al volver a primer plano.
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = _trip;
    if (trip == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.primaryContainer,
      child: ListTile(
        key: const Key('activeTrip.open'),
        leading: Icon(Icons.local_taxi, color: scheme.onPrimaryContainer),
        title: const Text('Tienes un viaje en curso'),
        subtitle: const Text('Toca para volver a él'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => widget.onOpen(trip),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';

import '../reservations/agenda_page.dart' show formatSlot;
import 'clients_page.dart' show sourceLabel;

/// Ficha de un cliente (010, US2): viajes juntos, último viaje, origen, próximas reservas y una
/// nota privada que solo ve el conductor y aparece en las ofertas de ese cliente.
class ClientCardPage extends StatefulWidget {
  const ClientCardPage({super.key, required this.passengerId});

  final String passengerId;

  @override
  State<ClientCardPage> createState() => _ClientCardPageState();
}

class _ClientCardPageState extends State<ClientCardPage> {
  final _note = TextEditingController();
  ClientCard? _card;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final card = await context.read<KyqApiClient>().clientCard(widget.passengerId);
      if (!mounted) return;
      setState(() {
        _card = card;
        _note.text = card.note ?? '';
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(
          () => _error = e.code == 'client_not_found'
              ? 'Este pasajero ya no está en tu cartera.'
              : 'No pudimos cargar la ficha.',
        );
      }
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final card = await context.read<KyqApiClient>().setClientNote(widget.passengerId, _note.text.trim());
      if (!mounted) return;
      setState(() => _card = card);
      messenger.showSnackBar(const SnackBar(content: Text('Nota guardada. Solo tú la ves.')));
    } on ApiException {
      messenger.showSnackBar(const SnackBar(content: Text('No pudimos guardar la nota.')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = _card;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(card?.displayName ?? 'Cliente')),
      body: card == null
          ? Center(child: _error != null ? Text(_error!) : const CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      key: const Key('client.trips'),
                      label: Text('${card.tripsTogether} viaje${card.tripsTogether == 1 ? '' : 's'} juntos'),
                    ),
                    if (card.lastTripAt case final last?) Chip(label: Text('Último: ${formatSlot(last)}')),
                    Chip(label: Text('Te guardó ${sourceLabel(card.source)}')),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Nota privada', style: theme.textTheme.titleMedium),
                const Text('La ves en las ofertas de este cliente. El pasajero nunca la ve.'),
                const SizedBox(height: 8),
                TextField(
                  key: const Key('client.note'),
                  controller: _note,
                  maxLength: 500,
                  minLines: 2,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: 'Ej.: prefiere aire acondicionado; recoger en la portería 2',
                    border: OutlineInputBorder(),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    key: const Key('client.saveNote'),
                    onPressed: _saving ? null : _save,
                    child: const Text('Guardar nota'),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Próximas reservas', style: theme.textTheme.titleMedium),
                if (card.upcomingReservations.isEmpty) const Text('Ninguna.'),
                for (final r in card.upcomingReservations)
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.event),
                    title: Text(formatSlot(r.scheduledAt)),
                    subtitle: Text(r.status == ReservationStatus.confirmed ? 'Confirmada' : 'Por confirmar'),
                  ),
              ],
            ),
    );
  }
}

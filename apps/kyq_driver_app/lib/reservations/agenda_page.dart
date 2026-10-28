import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ui/kyq_ui.dart';

import 'agenda_cubit.dart';

/// "28/10 14:00" en la hora del teléfono.
String formatSlot(DateTime d) {
  final l = d.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(l.day)}/${two(l.month)} ${two(l.hour)}:${two(l.minute)}';
}

/// Agenda del conductor (010 FR-002): pendientes por decidir y confirmadas, por hora.
class AgendaPage extends StatelessWidget {
  const AgendaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AgendaCubit>();
    return Scaffold(
      appBar: AppBar(title: const Text('Agenda')),
      body: BlocConsumer<AgendaCubit, AgendaState>(
        listenWhen: (a, b) => b.error != null && a.error != b.error,
        listener: (context, s) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.error!))),
        builder: (context, state) {
          if (state.loading && state.items.isEmpty) return const Center(child: CircularProgressIndicator());
          final pending = state.pending;
          final confirmed = state.confirmed;
          return RefreshIndicator(
            onRefresh: cubit.load,
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                if (pending.isEmpty && confirmed.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Sin reservas. Tus clientes pueden reservar contigo desde su app con hasta 7 días de anticipación.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (pending.isNotEmpty) ...[
                  Text('Por confirmar', style: Theme.of(context).textTheme.titleMedium),
                  for (final r in pending) _ReservationCard(r: r, busy: state.busyId == r.id, pending: true),
                  const SizedBox(height: 16),
                ],
                if (confirmed.isNotEmpty) ...[
                  Text('Confirmadas', style: Theme.of(context).textTheme.titleMedium),
                  for (final r in confirmed) _ReservationCard(r: r, busy: state.busyId == r.id),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ReservationCard extends StatelessWidget {
  const _ReservationCard({required this.r, required this.busy, this.pending = false});

  final Reservation r;
  final bool busy;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AgendaCubit>();
    final theme = Theme.of(context);
    return Card(
      key: ValueKey('agenda.${r.id}'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${formatSlot(r.scheduledAt)} · ${r.passenger.displayName}', style: theme.textTheme.titleMedium),
            if (r.dropoffLabel != null) Text('Hacia ${r.dropoffLabel}'),
            Text(
              '${(r.distanceM / 1000).toStringAsFixed(1).replaceAll('.', ',')} km · ${formatMoney(r.fareMinor, r.currency)}'
              '${r.preferentialDiscountPct > 0 ? ' (preferencial −${r.preferentialDiscountPct} %)' : ''}',
            ),
            if (r.overlaps)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Otra reserva a menos de 30 minutos',
                  key: ValueKey('agenda.overlap.${r.id}'),
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                if (pending) ...[
                  FilledButton(
                    key: ValueKey('agenda.accept.${r.id}'),
                    onPressed: busy ? null : () => cubit.accept(r),
                    child: const Text('Aceptar'),
                  ),
                  OutlinedButton(
                    key: ValueKey('agenda.reject.${r.id}'),
                    onPressed: busy ? null : () => cubit.reject(r),
                    child: const Text('Rechazar'),
                  ),
                ] else
                  TextButton(
                    key: ValueKey('agenda.cancel.${r.id}'),
                    onPressed: busy ? null : () => cubit.cancel(r),
                    child: const Text('Cancelar reserva'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

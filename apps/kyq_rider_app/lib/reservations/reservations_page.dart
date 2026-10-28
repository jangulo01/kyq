import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ui/kyq_ui.dart';

import 'booking_page.dart' show formatSlot;
import 'reservations_cubit.dart';

/// Ruta de "Mis reservas".
const reservationsLocation = '/reservations';

String reservationStatusLabel(Reservation r) => switch (r.status) {
  ReservationStatus.pending => 'Pendiente de confirmar',
  ReservationStatus.confirmed => 'Confirmada',
  ReservationStatus.rejected => 'Rechazada por el conductor',
  ReservationStatus.cancelled => r.cancelledByMe ? 'La cancelaste' : 'Cancelada',
  ReservationStatus.expired => 'Vencida sin confirmar',
  ReservationStatus.fulfilled => 'Viaje enviado al conductor',
  ReservationStatus.missed => 'El conductor no estaba disponible',
};

/// "Mis reservas" (010, US1): abiertas con cancelar y el historial reciente.
class ReservationsPage extends StatelessWidget {
  const ReservationsPage({super.key});

  Future<void> _confirmCancel(BuildContext context, Reservation r) async {
    final cubit = context.read<ReservationsCubit>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cancelar la reserva?'),
        content: Text('${formatSlot(r.scheduledAt)} con ${r.driver.displayName}. No tiene cargo.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Volver')),
          FilledButton(
            key: const Key('reservations.confirmCancel'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancelar reserva'),
          ),
        ],
      ),
    );
    if (ok == true) await cubit.cancel(r);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis reservas')),
      body: BlocConsumer<ReservationsCubit, ReservationsState>(
        listenWhen: (a, b) => (b.error != null && a.error != b.error) || (b.notice != null && a.notice != b.notice),
        listener: (context, s) {
          final text = s.error ?? s.notice!.message;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
        },
        builder: (context, state) {
          if (state.loading && state.items.isEmpty) return const Center(child: CircularProgressIndicator());
          if (state.items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No tienes reservas. Reserva con uno de tus Conductores Elegidos desde el inicio.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: context.read<ReservationsCubit>().load,
            child: ListView.separated(
              itemCount: state.items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final r = state.items[i];
                return ListTile(
                  key: ValueKey('reservations.${r.id}'),
                  leading: Icon(r.open ? Icons.event_available : Icons.event_busy),
                  title: Text('${formatSlot(r.scheduledAt)} · ${r.driver.displayName}'),
                  subtitle: Text(
                    [
                      reservationStatusLabel(r),
                      if (r.dropoffLabel != null) 'Hacia ${r.dropoffLabel}',
                      formatMoney(r.fareMinor, r.currency),
                    ].join(' · '),
                  ),
                  trailing: r.open
                      ? IconButton(
                          key: ValueKey('reservations.cancel.${r.id}'),
                          tooltip: 'Cancelar',
                          icon: const Icon(Icons.close),
                          onPressed: state.busyId == null ? () => _confirmCancel(context, r) : null,
                        )
                      : null,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

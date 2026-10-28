import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_ui/kyq_ui.dart';

import '../places/place_search_page.dart';
import 'booking_cubit.dart';

/// "28/10 14:00" en la hora del teléfono.
String formatSlot(DateTime d) {
  final l = d.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(l.day)}/${two(l.month)} ${two(l.hour)}:${two(l.minute)}';
}

/// Elige fecha y hora; las pruebas pasan una que no abre diálogos.
typedef DateTimePicker = Future<DateTime?> Function(BuildContext context, DateTime initial);

Future<DateTime?> materialDateTimePicker(BuildContext context, DateTime initial) async {
  final now = DateTime.now();
  final date = await showDatePicker(
    context: context,
    helpText: 'Día del viaje',
    initialDate: initial,
    firstDate: DateTime(now.year, now.month, now.day),
    lastDate: now.add(maxBookingLead),
  );
  if (date == null || !context.mounted) return null;
  final time = await showTimePicker(
    context: context,
    helpText: 'Hora de recogida',
    initialTime: TimeOfDay.fromDateTime(initial),
  );
  if (time == null) return null;
  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}

/// Ruta para reservar con un conductor.
String bookingLocation(String driverId, String driverName) =>
    Uri(path: '/book/$driverId', queryParameters: {'name': driverName}).toString();

/// Reservar un viaje (010, US1).
class BookingPage extends StatelessWidget {
  const BookingPage({super.key, this.pickDateTime = materialDateTimePicker});

  final DateTimePicker pickDateTime;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BookingCubit>();
    return Scaffold(
      appBar: AppBar(title: Text('Reservar con ${cubit.driverName}')),
      body: BlocConsumer<BookingCubit, BookingState>(
        listenWhen: (a, b) => (b.error != null && a.error != b.error) || (a.booked == null && b.booked != null),
        listener: (context, state) {
          final messenger = ScaffoldMessenger.of(context);
          if (state.booked != null) {
            messenger.showSnackBar(SnackBar(content: Text('Reserva enviada. ${cubit.driverName} debe confirmarla.')));
            Navigator.of(context).pop(true);
          } else {
            messenger.showSnackBar(SnackBar(content: Text(state.error!)));
          }
        },
        builder: (context, state) {
          final theme = Theme.of(context);
          final quote = state.quote;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ListTile(
                key: const Key('booking.pickup'),
                leading: const Icon(Icons.trip_origin),
                title: Text(state.pickupLabel ?? 'Recogida'),
                subtitle: state.pickup == null ? const Text('Toca para buscar la dirección') : null,
                onTap: () async {
                  final place = await showPlaceSearch(context, title: '¿Dónde te recogen?');
                  if (place != null) await cubit.setPickup(place);
                },
              ),
              ListTile(
                key: const Key('booking.dropoff'),
                leading: const Icon(Icons.place),
                title: Text(state.dropoffLabel ?? 'Destino'),
                subtitle: state.dropoff == null ? const Text('Toca para buscar el destino') : null,
                onTap: () async {
                  final place = await showPlaceSearch(context, title: '¿A dónde vas?');
                  if (place != null) await cubit.setDropoff(place);
                },
              ),
              ListTile(
                key: const Key('booking.when'),
                leading: const Icon(Icons.event),
                title: Text(state.scheduledAt == null ? 'Fecha y hora' : formatSlot(state.scheduledAt!)),
                subtitle: const Text('De 30 minutos a 7 días desde ahora'),
                onTap: () async {
                  final at = await pickDateTime(
                    context,
                    state.scheduledAt ?? DateTime.now().add(const Duration(hours: 1)),
                  );
                  if (at != null) cubit.setScheduledAt(at);
                },
              ),
              const SizedBox(height: 12),
              if (state.quoting)
                const Center(child: CircularProgressIndicator())
              else if (quote != null) ...[
                if (quote.preferentialDiscountPct > 0)
                  Text(
                    'Tarifa preferencial −${quote.preferentialDiscountPct} %',
                    style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary),
                  )
                else
                  Text('Tarifa sugerida', style: theme.textTheme.labelLarge),
                Text(
                  formatMoney(quote.suggestedFareMinor, quote.currency),
                  key: const Key('booking.fare'),
                  style: theme.textTheme.headlineMedium,
                ),
                const Text('Queda reservada con esta tarifa. Cancelar antes de la hora no tiene cargo.'),
              ],
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('booking.submit'),
                onPressed: state.canSubmit ? cubit.submit : null,
                child: state.submitting
                    ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Reservar'),
              ),
            ],
          );
        },
      ),
    );
  }
}

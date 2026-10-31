import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ui/kyq_ui.dart';

import 'trip_cubit.dart';

/// Resumen final con la tarifa acordada, 100 % para el conductor (RN-KYQ-001, FR-015).
///
/// Con [payment] (004), el pago del viaje reemplaza el aviso de pagar por fuera de la app.
class TripSummaryView extends StatelessWidget {
  const TripSummaryView({super.key, required this.trip, required this.driverName, this.payment});

  final Trip trip;
  final String driverName;
  final Widget? payment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fare = trip.agreedFareMinor ?? trip.suggestedFareMinor;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Icon(Icons.check_circle, size: 64, color: Colors.green),
        const SizedBox(height: 16),
        Text('Viaje completado', style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        Text('Tarifa acordada', style: theme.textTheme.labelLarge, textAlign: TextAlign.center),
        Text(
          formatMoney(fare, trip.currency),
          key: const Key('trip.summaryFare'),
          style: theme.textTheme.displaySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const Text('El 100 % es para tu conductor. Kyq no cobra comisión.', textAlign: TextAlign.center),
        const SizedBox(height: 8),
        payment ??
            Text(
              'Págale directamente a $driverName, en efectivo o por transferencia. La app no hace cobros.',
              textAlign: TextAlign.center,
            ),
        // 008: el conductor no era el suyo (bolsa zonal o compañero de cooperativa): puede guardarlo.
        if (trip.dispatch == TripDispatch.zonePool || trip.isDelegated) ...[
          const SizedBox(height: 24),
          _SaveDriver(driverName: driverName),
        ],
        const SizedBox(height: 32),
        FilledButton(onPressed: () => context.go('/'), child: const Text('Volver a mis conductores')),
      ],
    );
  }
}

class _SaveDriver extends StatefulWidget {
  const _SaveDriver({required this.driverName});

  final String driverName;

  @override
  State<_SaveDriver> createState() => _SaveDriverState();
}

class _SaveDriverState extends State<_SaveDriver> {
  bool _busy = false;
  String? _saved;

  Future<void> _save() async {
    setState(() => _busy = true);
    final (ok, message) = await context.read<TripCubit>().saveDriverAsChosen(widget.driverName);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok) _saved = message;
    });
    if (!ok) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final saved = _saved;
    if (saved != null) {
      return ListTile(key: const Key('trip.driverSaved'), leading: const Icon(Icons.star), title: Text(saved));
    }
    return OutlinedButton.icon(
      key: const Key('trip.saveDriver'),
      onPressed: _busy ? null : _save,
      icon: const Icon(Icons.star_border),
      label: Text('Guardar a ${widget.driverName} como Conductor Elegido'),
    );
  }
}

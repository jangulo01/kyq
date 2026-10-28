import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kyq_ui/kyq_ui.dart';

import 'trip_payments_cubits.dart';

/// Liquidaciones: lo que Kyq recaudó con Bold para cada conductor y lo que falta girarle
/// (004, T029, FR-012). Los que tienen saldo, primero.
class SettlementsPage extends StatelessWidget {
  const SettlementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SettlementsCubit>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liquidaciones a conductores'),
        actions: [IconButton(tooltip: 'Recargar', icon: const Icon(Icons.refresh), onPressed: cubit.load)],
      ),
      body: BlocConsumer<SettlementsCubit, SettlementsState>(
        listenWhen: (a, b) => b.error != null && a.error != b.error,
        listener: (context, state) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!))),
        builder: (context, state) {
          if (state.loading && state.rows.isEmpty) return const Center(child: CircularProgressIndicator());
          if (state.rows.isEmpty) return const Center(child: Text('Aún no hay pagos con Bold que liquidar.'));
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.loading) const LinearProgressIndicator(),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Kyq recauda en su cuenta de Bold y gira el 100 % a cada conductor, sin comisión. '
                  'Registra cada giro hecho por transferencia en el libro del conductor.',
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      showCheckboxColumn: false,
                      columns: const [
                        DataColumn(label: Text('Conductor')),
                        DataColumn(label: Text('Recaudado'), numeric: true),
                        DataColumn(label: Text('Anulado'), numeric: true),
                        DataColumn(label: Text('Girado'), numeric: true),
                        DataColumn(label: Text('Por girar'), numeric: true),
                        DataColumn(label: Text('Último giro')),
                      ],
                      rows: [
                        for (final r in state.rows)
                          DataRow(
                            key: ValueKey('settlements.row.${r.driverId}.${r.currency}'),
                            onSelectChanged: (_) =>
                                context.push('/trip-payments/settlements/drivers/${r.driverId}', extra: r.displayName),
                            cells: [
                              DataCell(Text([r.displayName, ?r.vehiclePlate].join(' · '))),
                              DataCell(Text(formatSignedMoney(r.creditedMinor, r.currency))),
                              DataCell(Text(formatSignedMoney(r.debitedMinor, r.currency))),
                              DataCell(Text(formatSignedMoney(r.paidOutMinor, r.currency))),
                              DataCell(
                                Text(
                                  formatSignedMoney(r.balanceMinor, r.currency),
                                  style: r.balanceMinor > 0 ? const TextStyle(fontWeight: FontWeight.bold) : null,
                                ),
                              ),
                              DataCell(Text(r.lastPayoutAt == null ? '—' : formatDate(r.lastPayoutAt!))),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

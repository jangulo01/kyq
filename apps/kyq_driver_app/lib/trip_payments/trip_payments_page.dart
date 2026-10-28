import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ui/kyq_ui.dart';

import 'trip_payment_card.dart';
import 'trip_payments_cubit.dart';

/// "Pagos de viajes" (004): qué medios acepta, cuánto le debe Kyq por pagos con Bold, el libro y
/// los pagos recientes con sus acciones.
class TripPaymentsPage extends StatelessWidget {
  const TripPaymentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TripPaymentsCubit>();
    return Scaffold(
      appBar: AppBar(title: const Text('Pagos de viajes')),
      body: BlocConsumer<TripPaymentsCubit, TripPaymentsState>(
        listenWhen: (a, b) => b.message != null && a.message != b.message,
        listener: (context, state) =>
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message!))),
        builder: (context, state) {
          final s = state.settlement;
          final m = state.methods;
          if (s == null && state.loading) return const Center(child: CircularProgressIndicator());
          return RefreshIndicator(
            onRefresh: cubit.load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (m != null) _MethodsCard(methods: m, busy: state.busy),
                const SizedBox(height: 8),
                _BalanceCard(balances: s?.balances ?? const []),
                const SizedBox(height: 16),
                Text('Pagos recientes', style: Theme.of(context).textTheme.titleMedium),
                if (s == null || s.payments.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('Aún no tienes viajes cobrados.'),
                  ),
                for (final p in s?.payments ?? const <TripPayment>[])
                  Card(
                    key: ValueKey('tripPayments.payment.${p.id}'),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '${formatDate(p.createdAt)} · ${p.passengerName} · ${formatMoney(p.amountMinor, p.currency)}',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: 4),
                          TripPaymentDetails(
                            payment: p,
                            busy: state.busy,
                            onAction: (action) => cubit.act(p.tripId, action),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (s != null && s.entries.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Movimientos con Kyq', style: Theme.of(context).textTheme.titleMedium),
                  for (final e in s.entries)
                    ListTile(
                      key: ValueKey('tripPayments.entry.${e.id}'),
                      contentPadding: EdgeInsets.zero,
                      title: Text(ledgerKindLabel(e.kind)),
                      subtitle: Text([formatDate(e.createdAt), ?e.reference].join(' · ')),
                      trailing: Text(formatSignedMoney(e.amountMinor, e.currency)),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MethodsCard extends StatelessWidget {
  const _MethodsCard({required this.methods, required this.busy});

  final PaymentMethods methods;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TripPaymentsCubit>();
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            key: const Key('tripPayments.cash'),
            title: const Text('Acepto efectivo'),
            subtitle: const Text('El pasajero te paga y tú confirmas que lo recibiste.'),
            value: methods.acceptsCash,
            onChanged: busy ? null : (v) => cubit.setMethods(cash: v, bold: methods.acceptsBold),
          ),
          SwitchListTile(
            key: const Key('tripPayments.bold'),
            title: const Text('Acepto Bold (tarjeta, PSE, Nequi)'),
            subtitle: Text(
              methods.boldAvailable
                  ? 'Kyq recibe el pago y te gira el 100 %, sin comisión.'
                  : 'Bold no está disponible en Kyq por ahora.',
            ),
            value: methods.acceptsBold,
            onChanged: busy ? null : (v) => cubit.setMethods(cash: methods.acceptsCash, bold: v),
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balances});

  final List<SettlementBalance> balances;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cop = balances.where((b) => b.currency == 'COP').firstOrNull ?? const SettlementBalance(currency: 'COP');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kyq te debe por pagos con Bold', style: theme.textTheme.labelLarge),
            Text(
              formatSignedMoney(cop.balanceMinor, cop.currency),
              key: const Key('tripPayments.balance'),
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Recibido con Bold: ${formatSignedMoney(cop.creditedMinor, cop.currency)} · '
              'Girado: ${formatSignedMoney(cop.paidOutMinor, cop.currency)}',
            ),
            const SizedBox(height: 4),
            Text(
              'Sin comisión: recibes el 100 % de cada viaje. Kyq te gira el saldo por transferencia.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

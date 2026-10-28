import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ui/kyq_ui.dart';

import 'costs_view.dart';
import 'subscription_cubit.dart';

/// "Mi suscripción" (T032): estado, precio, pagar con Bold, historial y costos (T036).
class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key, this.costsNow});

  /// Mes actual para la sección de costos, en pruebas.
  final DateTime? costsNow;

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Al cerrar la Custom Tab de Bold la app vuelve a primer plano: se pregunta ya por el pago.
    if (state == AppLifecycleState.resumed) context.read<SubscriptionCubit>().onResumed();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SubscriptionCubit>();
    return Scaffold(
      appBar: AppBar(title: const Text('Mi suscripción')),
      body: BlocConsumer<SubscriptionCubit, SubscriptionState>(
        listenWhen: (a, b) => b.message != null && a.message != b.message,
        listener: (context, state) =>
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message!))),
        builder: (context, state) {
          final view = state.view;
          if (view == null) {
            return state.loadFailed
                ? Center(
                    child: TextButton(onPressed: cubit.load, child: const Text('No pudimos cargar. Reintentar')),
                  )
                : const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: cubit.load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _StatusCard(view: view),
                if (state.outcome != null) _OutcomeCard(state: state),
                _PayCard(state: state),
                const SizedBox(height: 8),
                CostsView(now: widget.costsNow),
                const SizedBox(height: 8),
                _History(payments: view.payments),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.view});

  final SubscriptionView view;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final paidUntil = view.paidUntil;
    final graceUntil = view.graceUntil;
    final (icon, color, detail) = switch (view.status) {
      BillingStatus.active => (
        Icons.check_circle,
        Colors.green,
        paidUntil == null ? 'Puedes trabajar.' : 'Pagada hasta el ${formatDate(paidUntil)}.',
      ),
      BillingStatus.grace => (
        Icons.warning_amber,
        Colors.orange,
        graceUntil == null
            ? 'Venció. Paga para no quedar suspendido.'
            : 'Venció. Tienes hasta el ${formatDate(graceUntil)} para pagar sin quedar suspendido.',
      ),
      BillingStatus.suspended => (Icons.block, scheme.error, 'No recibes viajes. Paga para reactivarla al instante.'),
      BillingStatus.unpaid => (
        Icons.payments_outlined,
        scheme.primary,
        'Aún no has pagado. Paga tu primer mes para empezar a recibir viajes.',
      ),
    };
    return Card(
      child: ListTile(
        key: const Key('subscription.status'),
        leading: Icon(icon, color: color, size: 32),
        title: Text('Suscripción: ${billingStatusLabel(view.status).toLowerCase()}'),
        subtitle: Text(detail),
      ),
    );
  }
}

class _OutcomeCard extends StatelessWidget {
  const _OutcomeCard({required this.state});

  final SubscriptionState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final until = state.payment?.coversUntil;
    final (icon, color, title, detail) = switch (state.outcome!) {
      PaymentOutcome.processing => (
        Icons.hourglass_top,
        Colors.orange,
        'Pago en proceso',
        'Estamos esperando la confirmación de Bold. Puede tardar unos minutos con PSE.',
      ),
      PaymentOutcome.approved => (
        Icons.check_circle,
        Colors.green,
        'Pago aprobado',
        until == null ? 'Tu suscripción quedó activa.' : 'Tu suscripción quedó activa hasta el ${formatDate(until)}.',
      ),
      PaymentOutcome.rejected => (
        Icons.cancel,
        scheme.error,
        'Pago rechazado',
        'No se cobró nada. Puedes intentarlo otra vez.',
      ),
      PaymentOutcome.review => (
        Icons.manage_search,
        Colors.orange,
        'Pago en revisión',
        'Un administrador revisará tu pago antes de activarlo.',
      ),
    };
    return Card(
      child: ListTile(
        key: const Key('subscription.outcome'),
        leading: state.outcome == PaymentOutcome.processing
            ? const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(icon, color: color),
        title: Text(title),
        subtitle: Text(detail),
      ),
    );
  }
}

class _PayCard extends StatelessWidget {
  const _PayCard({required this.state});

  final SubscriptionState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SubscriptionCubit>();
    final price = state.view?.price;
    final inProgress = state.payment?.status.inProgress ?? false;
    final amount = price == null ? null : formatMoney(price.amountMinor, price.currency);
    final canPay = state.view?.canPay ?? false;
    // El backend dice si se puede pagar (documentos al día, precio definido y Bold activo).
    final why = canPay
        ? null
        : price == null
        ? 'El precio del mes aún no está definido.'
        : 'Podrás pagar cuando tus documentos estén aprobados.';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              amount == null ? 'Precio del mes no disponible' : 'Precio del mes: $amount',
              key: const Key('subscription.price'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            const Text(
              'Cada pago suma un mes desde tu vencimiento (o desde hoy si ya venció). Sin comisión por viaje.',
            ),
            const SizedBox(height: 12),
            if (inProgress)
              OutlinedButton(
                key: const Key('subscription.continue'),
                onPressed: state.paying ? null : cubit.continuePayment,
                child: const Text('Continuar el pago'),
              )
            else
              FilledButton(
                key: const Key('subscription.pay'),
                onPressed: state.paying || !canPay ? null : cubit.pay,
                child: state.paying
                    ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(state.outcome == PaymentOutcome.rejected ? 'Intentar otra vez' : 'Pagar ${amount ?? ''}'),
              ),
            if (why != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(why, key: const Key('subscription.cannotPay'), textAlign: TextAlign.center),
              ),
            const SizedBox(height: 4),
            Text(
              'Pagas con tarjeta, PSE o Nequi en la página segura de Bold.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _History extends StatelessWidget {
  const _History({required this.payments});

  final List<Payment> payments;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Mis pagos', style: Theme.of(context).textTheme.titleMedium),
          ),
          if (payments.isEmpty)
            const Padding(padding: EdgeInsets.fromLTRB(16, 0, 16, 16), child: Text('Aún no tienes pagos.')),
          for (final p in payments)
            ListTile(
              key: Key('payment.${p.id}'),
              title: Text('${formatMoney(p.amountMinor, p.currency)} · ${paymentStatusLabel(p.status)}'),
              subtitle: Text(
                [
                  '${formatDate(p.createdAt)} · ${paymentMethodLabel(p)}',
                  if (p.coversFrom != null && p.coversUntil != null)
                    'Cubre del ${formatDate(p.coversFrom!)} al ${formatDate(p.coversUntil!)}',
                  if (p.voidReason != null) 'Anulado: ${p.voidReason}',
                ].join('\n'),
              ),
              isThreeLine: p.coversUntil != null || p.voidReason != null,
            ),
        ],
      ),
    );
  }
}

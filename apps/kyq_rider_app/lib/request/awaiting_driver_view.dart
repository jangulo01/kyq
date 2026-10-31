import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ui/kyq_ui.dart';

import '../trip/countdown.dart';
import '../trip/trip_cubit.dart';

/// Espera de la respuesta del conductor: oferta exclusiva (FR-011), confirmación de una tarifa
/// distinta (FR-010a) y negociación (FR-010c). Siempre deja cancelar la solicitud.
class AwaitingDriverView extends StatelessWidget {
  const AwaitingDriverView({super.key, required this.trip, required this.driverName, this.busy = false});

  final Trip trip;
  final String driverName;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TripCubit>();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        switch (trip.status) {
          TripStatus.farePending => _FarePending(trip: trip, driverName: driverName, busy: busy),
          TripStatus.negotiationPending => _NegotiationPending(trip: trip, driverName: driverName, busy: busy),
          TripStatus.negotiating => NegotiationPanel(
            currency: trip.currency,
            suggestedMinor: trip.suggestedFareMinor,
            offer: switch (trip.openProposal) {
              final p? => NegotiationOffer(
                amountMinor: p.amountMinor,
                fromMe: p.proposedBy == ProposalParty.passenger,
                expiresAt: p.expiresAt,
              ),
              null => null,
            },
            negotiationEndsAt: trip.negotiationExpiresAt ?? DateTime.now().add(const Duration(minutes: 3)),
            busy: busy,
            onAccept: () => cubit.decideOpenProposal(accept: true),
            onPropose: cubit.propose,
            onAbandon: cubit.cancel,
          ),
          _ => _Requested(trip: trip, driverName: driverName),
        },
        const SizedBox(height: 24),
        TextButton(
          key: const Key('trip.cancelRequest'),
          onPressed: busy ? null : cubit.cancel,
          child: const Text('Cancelar solicitud'),
        ),
      ],
    );
  }
}

class _Requested extends StatelessWidget {
  const _Requested({required this.trip, required this.driverName});

  final Trip trip;
  final String driverName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expires = trip.offerExpiresAt;
    return Column(
      children: [
        if (trip.isDelegated) ...[
          Card(
            child: ListTile(
              key: const Key('trip.delegated'),
              leading: const Icon(Icons.groups),
              title: Text('Tu solicitud pasó a un compañero de ${trip.cooperativeName ?? 'la cooperativa'}'),
              subtitle: const Text('Tu conductor no podía atenderte ahora.'),
            ),
          ),
        ] else if (trip.dispatch == TripDispatch.zonePool)
          Card(
            child: ListTile(
              key: const Key('trip.zonePool'),
              leading: const Icon(Icons.near_me),
              title: const Text('Buscando un conductor cercano'),
              subtitle: const Text('Si no responde, tu solicitud pasa al siguiente conductor libre de la zona.'),
            ),
          )
        else if (trip.dispatch == TripDispatch.cooperative)
          Card(
            child: ListTile(
              key: const Key('trip.cooperativeDispatch'),
              leading: const Icon(Icons.groups),
              title: Text('Solicitud a ${trip.cooperativeName ?? 'la cooperativa'}'),
            ),
          ),
        const SizedBox(height: 24),
        const CircularProgressIndicator(),
        const SizedBox(height: 24),
        Text('Esperando a $driverName…', style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        if (expires != null)
          Countdown(
            until: expires,
            builder: (context, s) => Text('Tiene $s s para responder', key: const Key('trip.offerCountdown')),
          ),
        const SizedBox(height: 16),
        Text('Tarifa sugerida: ${formatMoney(trip.suggestedFareMinor, trip.currency)}'),
      ],
    );
  }
}

class _FarePending extends StatelessWidget {
  const _FarePending({required this.trip, required this.driverName, required this.busy});

  final Trip trip;
  final String driverName;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TripCubit>();
    final theme = Theme.of(context);
    final proposal = trip.openProposal;
    if (proposal == null) return const Center(child: CircularProgressIndicator());
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Tu conductor propone ${formatMoney(proposal.amountMinor, trip.currency)}',
              key: const Key('trip.fareProposal'),
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text('$driverName acepta el viaje con otra tarifa.'),
            Text('Sugerida: ${formatMoney(trip.suggestedFareMinor, trip.currency)}', style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            Countdown(
              until: proposal.expiresAt,
              builder: (context, s) => Text('Responde en $s s; si no, el viaje se cancela sin cargo.'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('trip.fareAccept'),
              onPressed: busy ? null : () => cubit.confirmFare(accept: true),
              child: const Text('Aceptar'),
            ),
            OutlinedButton(
              key: const Key('trip.fareReject'),
              onPressed: busy ? null : () => cubit.confirmFare(accept: false),
              child: const Text('Rechazar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NegotiationPending extends StatelessWidget {
  const _NegotiationPending({required this.trip, required this.driverName, required this.busy});

  final Trip trip;
  final String driverName;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TripCubit>();
    final theme = Theme.of(context);
    final expires = trip.negotiationExpiresAt;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Tu conductor quiere negociar la tarifa', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Si no quieres negociar, $driverName decide si acepta con la tarifa sugerida de '
              '${formatMoney(trip.suggestedFareMinor, trip.currency)}.',
            ),
            if (expires != null) ...[
              const SizedBox(height: 8),
              Countdown(until: expires, builder: (context, s) => Text('Responde en $s s')),
            ],
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('trip.negotiationAccept'),
              onPressed: busy ? null : () => cubit.respondNegotiation(accept: true),
              child: const Text('Aceptar negociar'),
            ),
            OutlinedButton(
              key: const Key('trip.negotiationDecline'),
              onPressed: busy ? null : () => cubit.respondNegotiation(accept: false),
              child: const Text('Mantener tarifa sugerida'),
            ),
          ],
        ),
      ),
    );
  }
}

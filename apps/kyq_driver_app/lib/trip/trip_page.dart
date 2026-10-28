import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ptt/kyq_ptt.dart';
import 'package:kyq_ui/kyq_ui.dart';

import '../presence/presence_cubit.dart';
import 'trip_active_view.dart';
import 'trip_cubit.dart';
import 'trip_pending_views.dart';
import 'trip_summary_page.dart';

/// Pantalla del viaje del conductor: negociación, recogida, viaje y resumen (T058–T060).
///
/// Con [ptt], el walkie-talkie queda abajo desde ACCEPTED hasta que cierra el canal (T074). Con
/// [safety], el botón SOS y "Compartir viaje" (003).
class TripPage extends StatelessWidget {
  const TripPage({super.key, this.ptt, this.safety});

  final PttController? ptt;
  final TripSafety? safety;

  static String title(TripStatus status) => switch (status) {
    TripStatus.requested => 'Oferta de viaje',
    TripStatus.farePending => 'Nueva tarifa enviada',
    TripStatus.negotiationPending || TripStatus.negotiating => 'Negociación',
    TripStatus.accepted => 'Ve a recoger al pasajero',
    TripStatus.arrived => 'Esperando al pasajero',
    TripStatus.inProgress => 'Viaje en curso',
    TripStatus.completed || TripStatus.cancelled => 'Resumen',
  };

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TripCubit, TripState>(
      builder: (context, state) {
        final trip = state.trip;
        return Scaffold(
          appBar: AppBar(
            title: Text(trip == null ? 'Viaje' : title(trip.status)),
            actions: [
              ?switch ((trip, safety)) {
                (final trip?, final safety?) => safety.shareAction(trip.status),
                _ => null,
              },
            ],
          ),
          body: switch ((trip, safety)) {
            (null, _) => Center(
              child: state.loading
                  ? const CircularProgressIndicator()
                  : Text(state.error ?? 'No pudimos cargar el viaje.'),
            ),
            (final trip?, final safety?) => TripSafetyLayer(
              safety: safety,
              status: trip.status,
              child: RefreshIndicator(onRefresh: context.read<TripCubit>().refresh, child: _body(context, trip, state)),
            ),
            (final trip?, null) => RefreshIndicator(
              onRefresh: context.read<TripCubit>().refresh,
              child: _body(context, trip, state),
            ),
          },
          bottomNavigationBar: switch ((trip, ptt)) {
            (final trip?, final ptt?) => TripPttBar(controller: ptt, status: trip.status, remoteName: 'el pasajero'),
            _ => null,
          },
        );
      },
    );
  }

  Widget _body(BuildContext context, Trip trip, TripState state) {
    final cubit = context.read<TripCubit>();
    final content = switch (trip.status) {
      TripStatus.requested => SuggestedFareBackView(trip: trip, busy: state.busy),
      TripStatus.farePending => WaitingView(
        title:
            'Esperando que el pasajero confirme '
            '${formatMoney(trip.openProposal?.amountMinor ?? trip.agreedFareMinor ?? trip.suggestedFareMinor, trip.currency)}',
        detail: 'Tiene 30 s para aceptar tu tarifa.',
        until: trip.openProposal?.expiresAt,
        onCancel: state.busy ? null : cubit.cancel,
      ),
      TripStatus.negotiationPending => WaitingView(
        title: 'Esperando al pasajero',
        detail: 'Le preguntamos si quiere negociar la tarifa.',
        until: trip.negotiationExpiresAt,
        onCancel: state.busy ? null : cubit.cancel,
      ),
      TripStatus.negotiating => NegotiationPanel(
        currency: trip.currency,
        suggestedMinor: trip.suggestedFareMinor,
        offer: switch (trip.openProposal) {
          final p? => NegotiationOffer(
            amountMinor: p.amountMinor,
            fromMe: p.proposedBy == ProposalParty.driver,
            expiresAt: p.expiresAt,
          ),
          null => null,
        },
        negotiationEndsAt: trip.negotiationExpiresAt ?? DateTime.now().add(const Duration(minutes: 3)),
        busy: state.busy,
        onAccept: cubit.acceptProposal,
        onPropose: cubit.propose,
        onAbandon: cubit.abandon,
      ),
      TripStatus.accepted ||
      TripStatus.arrived ||
      TripStatus.inProgress => TripActiveView(trip: trip, busy: state.busy),
      TripStatus.completed || TripStatus.cancelled => TripSummaryView(
        trip: trip,
        onDone: () {
          context.read<PresenceCubit>().load();
          context.go('/');
        },
      ),
    };
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (state.error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              state.error!,
              key: const Key('trip.error'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        content,
      ],
    );
  }
}

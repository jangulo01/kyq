import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_realtime/kyq_realtime.dart';

import '../trip/trip_texts.dart';
import 'offer.dart';

/// Estado de la oferta entrante (T057).
sealed class OfferState {
  const OfferState();
}

/// Sin oferta. [notice] explica por qué se cerró la anterior, si aplica.
final class OfferIdle extends OfferState {
  const OfferIdle({this.notice});

  final String? notice;
}

final class OfferShown extends OfferState {
  const OfferShown({required this.offer, required this.secondsLeft, this.busy = false, this.error});

  final Offer offer;
  final int secondsLeft;
  final bool busy;
  final String? error;

  OfferShown copyWith({int? secondsLeft, bool? busy, String? error}) =>
      OfferShown(offer: offer, secondsLeft: secondsLeft ?? this.secondsLeft, busy: busy ?? this.busy, error: error);
}

/// El conductor respondió y el viaje sigue en la pantalla del viaje. Dura hasta la próxima oferta.
final class OfferTaken extends OfferState {
  const OfferTaken(this.trip);

  final Trip trip;
}

/// Muestra cada `trip.offer` con su cuenta atrás de 25 s y envía la respuesta del conductor.
class OfferCubit extends Cubit<OfferState> {
  OfferCubit(
    this._api,
    Stream<RealtimeEvent> events, {
    DateTime Function()? now,
    this.tick = const Duration(seconds: 1),
  }) : _now = now ?? DateTime.now,
       super(const OfferIdle()) {
    _sub = events.listen(_onEvent);
  }

  final KyqApiClient _api;
  final DateTime Function() _now;
  final Duration tick;
  late final StreamSubscription<RealtimeEvent> _sub;
  Timer? _timer;

  void _onEvent(RealtimeEvent e) {
    switch (e) {
      case TripOffered():
        _show(Offer.fromEvent(e));
      case TripOfferClosed(:final tripId, :final reason):
        final s = state;
        if (s is OfferShown && s.offer.tripId == tripId) _close(offerClosedMessage(reason));
      default:
        break;
    }
  }

  void _show(Offer offer) {
    _timer?.cancel();
    final left = _secondsLeft(offer);
    if (left <= 0) return;
    emit(OfferShown(offer: offer, secondsLeft: left));
    _timer = Timer.periodic(tick, (_) => _onTick());
  }

  int _secondsLeft(Offer offer) {
    final ms = offer.expiresAt.difference(_now()).inMilliseconds;
    return ms <= 0 ? 0 : (ms / 1000).ceil();
  }

  void _onTick() {
    final s = state;
    if (s is! OfferShown) return _timer?.cancel();
    final left = _secondsLeft(s.offer);
    if (left <= 0) {
      _close('La oferta venció.');
    } else if (left != s.secondsLeft) {
      emit(s.copyWith(secondsLeft: left, error: s.error));
    }
  }

  void _close(String? notice) {
    _timer?.cancel();
    emit(OfferIdle(notice: notice));
  }

  /// Acepta con la tarifa sugerida.
  Future<void> accept() => _respond((id) => _api.acceptTrip(id));

  /// Acepta con otra tarifa en pesos; el pasajero tiene 30 s para confirmarla (FR-010a).
  Future<void> acceptWithFare(int pesos) async {
    if (pesos <= 0) {
      final s = state;
      if (s is OfferShown) emit(s.copyWith(error: 'Escribe una tarifa válida.'));
      return;
    }
    await _respond((id) => _api.acceptTrip(id, fareMinor: pesos * 100));
  }

  /// Propone negociar la tarifa (FR-010c).
  Future<void> requestNegotiation() => _respond((id) => _api.requestNegotiation(id));

  Future<void> reject() => _respond((id) => _api.rejectTrip(id), notice: 'Rechazaste el viaje.');

  /// Pasa la solicitud a un compañero libre de la cooperativa (RN-KYQ-008, FR-013).
  Future<void> delegate() => _respond((id) => _api.delegateTrip(id), notice: 'Pasaste la solicitud a tu cooperativa.');

  /// Sin [notice] el viaje pasa a la pantalla del viaje; con [notice] la oferta se cierra.
  Future<void> _respond(Future<Trip> Function(String tripId) action, {String? notice}) async {
    final s = state;
    if (s is! OfferShown || s.busy) return;
    emit(s.copyWith(busy: true));
    try {
      final trip = await action(s.offer.tripId);
      _timer?.cancel();
      emit(notice == null ? OfferTaken(trip) : OfferIdle(notice: notice));
    } on ApiException catch (e) {
      switch (e.code) {
        case 'expired':
          _close('La oferta venció.');
        case 'invalid_transition' || 'not_found':
          _close('Este viaje ya no está disponible.');
        case 'delegation_not_allowed':
          final current = state;
          if (current is OfferShown) {
            emit(current.copyWith(busy: false, error: 'Esta solicitud no se puede pasar a la cooperativa.'));
          }
        default:
          final current = state;
          if (current is OfferShown) emit(current.copyWith(busy: false, error: tripErrorMessage(e)));
      }
    }
  }

  @override
  Future<void> close() async {
    _timer?.cancel();
    await _sub.cancel();
    return super.close();
  }
}

/// Mensaje para `trip.offer_closed`; su `reason` es el `cancel_reason` del viaje.
String offerClosedMessage(String reason) => switch (reason) {
  'offer_expired' => 'La oferta venció.',
  'passenger' => 'El pasajero canceló la solicitud.',
  'delegated' => 'Pasaste la solicitud a tu cooperativa.',
  _ => cancelReasonMessage(reason),
};

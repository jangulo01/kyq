import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_realtime/kyq_realtime.dart';

import 'controller/radio_cubit.dart';
import 'deps.dart';
import 'referrer.dart';
import 'services.dart';

/// Radio Kyq montada en una app (011). El [RadioCubit] vive con la sesión, no con la pantalla:
/// la radio sigue escuchando con la app en segundo plano o en otra pantalla (phva.md §1.3).
class RadioMount {
  RadioMount({
    required this.api,
    required this.events,
    required this.factory,
    this.isDriver = true,
    this.onRequestTrip,
    required this.newPlayer,
    this.location,
    this.photos = const PlatformRadioPhotoPicker(),
    this.onShareLink,
    this.referrer = const NoRadioReferrer(),
    this.open,
    this.pickPoint,
  });

  final RadioApi api;

  /// Eventos del canal `user:{id}` del usuario.
  final Stream<RealtimeEvent> Function(String userId) events;
  final RadioCubitFactory factory;
  final bool isDriver;
  final void Function(BuildContext context, RadioConversation conversation)? onRequestTrip;
  final MessagePlayer Function() newPlayer;
  final RadioLocation? location;
  final RadioPhotoPicker photos;
  final Future<void> Function(String text)? onShareLink;

  /// Invitación de la instalación (Play Install Referrer, R9).
  final RadioReferrer referrer;

  /// Abre una ruta de Radio en la app (la invitación de la instalación o la conversación a la que
  /// llevó una invitación por teléfono al registrarse).
  final void Function(String location)? open;

  /// Punto en el mapa de la app (ver [RadioDeps.pickPoint]).
  final Future<RadioPoint?> Function(BuildContext context, RadioPoint? near)? pickPoint;

  /// Cubit y dependencias del usuario con sesión; null antes de conocerlo.
  final scope = ValueNotifier<({RadioCubit cubit, RadioDeps deps})?>(null);

  RadioCubit? get cubit => scope.value?.cubit;

  /// Arranca la radio del usuario [userId]; no hace nada si ya está arrancada para él. [applied]
  /// son las conversaciones a las que llevaron invitaciones por teléfono al verificar el OTP: se
  /// abre la primera; si no hay, la invitación con la que se instaló la app.
  void start(String userId, {List<String> applied = const []}) {
    if (scope.value?.deps.myUserId == userId) {
      if (applied.isNotEmpty) open?.call(RadioRoutes.conversation(applied.first));
      return;
    }
    unawaited(stop());
    // Al cerrar la sesión se cancela también la suscripción al canal del usuario.
    final stream = events(userId).asBroadcastStream(onCancel: (sub) => sub.cancel());
    final cubit = factory(api, userId, stream);
    scope.value = (
      cubit: cubit,
      deps: RadioDeps(
        api: api,
        myUserId: userId,
        events: stream,
        newPlayer: newPlayer,
        isDriver: isDriver,
        onRequestTrip: onRequestTrip,
        location: location,
        photos: photos,
        onShareLink: onShareLink,
        pickPoint: pickPoint,
      ),
    );
    unawaited(cubit.load());
    unawaited(_openPending(applied));
  }

  Future<void> _openPending(List<String> applied) async {
    final open = this.open;
    if (open == null) return;
    if (applied.isNotEmpty) {
      open(RadioRoutes.conversation(applied.first));
      return;
    }
    final code = await referrer.take();
    if (code != null) open(RadioRoutes.invite(code));
  }

  /// Apaga la radio al cerrar la sesión.
  Future<void> stop() async {
    final old = scope.value;
    scope.value = null;
    await old?.cubit.close();
  }

  /// [RadioScope] de las rutas `/radio`: espera a conocer al usuario.
  Widget wrap(BuildContext context, Widget page) => ValueListenableBuilder(
    valueListenable: scope,
    builder: (context, value, _) => value == null
        ? Scaffold(
            appBar: AppBar(title: const Text('Radio')),
            body: const Center(child: CircularProgressIndicator()),
          )
        : RepositoryProvider.value(
            value: value.deps,
            child: BlocProvider.value(value: value.cubit, child: page),
          ),
  );

  Future<void> dispose() async {
    await stop();
    scope.dispose();
  }
}

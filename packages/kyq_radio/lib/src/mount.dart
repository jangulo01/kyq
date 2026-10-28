import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_realtime/kyq_realtime.dart';

import 'controller/radio_cubit.dart';
import 'deps.dart';
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

  /// Cubit y dependencias del usuario con sesión; null antes de conocerlo.
  final scope = ValueNotifier<({RadioCubit cubit, RadioDeps deps})?>(null);

  RadioCubit? get cubit => scope.value?.cubit;

  /// Arranca la radio del usuario [userId]; no hace nada si ya está arrancada para él.
  void start(String userId) {
    if (scope.value?.deps.myUserId == userId) return;
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
      ),
    );
    unawaited(cubit.load());
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

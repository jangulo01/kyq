import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_radio/kyq_radio.dart';
import 'package:kyq_realtime/kyq_realtime.dart';

import '../background/location_reporter.dart';

/// Radio Kyq en Kyq Conductor (011). El [RadioCubit] vive con la sesión, no con la pantalla: la
/// radio sigue escuchando con la app en segundo plano o en otra pantalla (phva.md §1.3).
class RadioMount {
  RadioMount({
    required this.api,
    required this.events,
    required this.factory,
    required this.newPlayer,
    this.location,
    this.photos = const PlatformRadioPhotoPicker(),
    this.onShareLink,
  });

  final RadioApi api;
  final Stream<RealtimeEvent> events;
  final RadioCubitFactory factory;
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
    final cubit = factory(api, userId, events);
    scope.value = (
      cubit: cubit,
      deps: RadioDeps(
        api: api,
        myUserId: userId,
        events: events,
        newPlayer: newPlayer,
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

/// Ubicación de la radio con el GPS de la app (enviar ubicación, emergencia).
class PositionRadioLocation implements RadioLocation {
  const PositionRadioLocation(this.source);

  final PositionSource source;

  @override
  Future<RadioPoint?> current() async {
    final fix = await source.current();
    return fix == null ? null : (lat: fix.lat, lng: fix.lng);
  }
}

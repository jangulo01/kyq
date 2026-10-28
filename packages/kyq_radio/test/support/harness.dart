import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kyq_ptt/testing.dart';
import 'package:kyq_radio/kyq_radio.dart';
import 'package:kyq_radio/testing.dart';
import 'package:kyq_realtime/kyq_realtime.dart';

/// Radio montada en un router de prueba con API, salas, tonos y audio falsos.
class RadioHarness {
  RadioHarness(this.api, {this.myUserId = 'me'});

  final FakeRadioApi api;
  final String myUserId;
  final events = StreamController<RealtimeEvent>.broadcast();
  final player = FakeMessagePlayer();
  final tones = FakeTonePlayer();
  late RadioCubit cubit;

  Future<void> pump(WidgetTester tester, {String initial = '/radio'}) async {
    cubit = RadioCubit(
      api: api,
      myUserId: myUserId,
      events: events.stream,
      rooms: () => FakeListeningRoom(identity: myUserId),
      tones: tones,
      focus: FakeAudioFocus(),
      player: FakeMessagePlayer(),
    );
    addTearDown(events.close);
    addTearDown(cubit.close);
    final router = GoRouter(
      initialLocation: initial,
      routes: [
        GoRoute(path: '/', builder: (_, _) => const SizedBox(), routes: [radioRoute()]),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      RepositoryProvider(
        create: (_) => RadioDeps(api: api, myUserId: myUserId, events: events.stream, newPlayer: () => player),
        child: BlocProvider.value(
          value: cubit..load(),
          child: MaterialApp.router(routerConfig: router),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Cierra el cubit dentro de la prueba: sus temporizadores (latido) no deben quedar vivos.
  Future<void> done(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    cubit.cancelTimers();
  }
}

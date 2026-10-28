import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ptt/testing.dart';
import 'package:kyq_radio/kyq_radio.dart';
import 'package:kyq_radio/testing.dart';
import 'package:kyq_realtime/kyq_realtime.dart';
import 'package:kyq_rider_app/app/app.dart';
import 'package:kyq_ui/kyq_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../support/fakes.dart';

RadioCubit _fakeRadio(RadioApi api, String userId, Stream<RealtimeEvent> events) => RadioCubit(
  api: api,
  myUserId: userId,
  events: events,
  rooms: () => FakeListeningRoom(identity: userId),
  tones: FakeTonePlayer(),
  focus: FakeAudioFocus(),
  player: FakeMessagePlayer(),
);

void main() {
  testWidgets('Radio desde Conductores Elegidos: el conductor y "Pedir viaje" (T028)', (tester) async {
    final api = MockApi();
    when(
      () => api.currentSession(),
    ).thenAnswer((_) async => Tokens(accessToken: fakeAccessToken('p1'), refreshToken: 'r', role: UserRole.passenger));
    when(() => api.chosenDrivers()).thenAnswer((_) async => const []);
    final realtime = FakeRealtime();
    final radio = FakeRadioApi(
      conversations: [fakeContact('c1', title: 'Carlos').copyWith(kind: RadioConversationKind.client)],
    );
    final auth = AuthCubit(api, allowedRoles: {UserRole.passenger}, wrongRoleMessage: '')..start();
    await tester.pumpWidget(
      KyqRiderApp(
        api: api,
        auth: auth,
        realtime: realtime,
        location: FakeLocation(),
        radio: _fakeRadio,
        radioPlayer: FakeMessagePlayer.new,
        radioApi: radio,
        radioReferrer: const NoRadioReferrer(),
      ),
    );
    await tester.pumpAndSettle();
    expect(realtime.isSubscribed('user:p1'), isTrue, reason: 'la radio escucha con la sesión');

    await tester.tap(find.byKey(const Key('home.radio')));
    await tester.pumpAndSettle();
    expect(find.text('Carlos'), findsOneWidget);
    expect(find.byKey(const Key('radio.add')), findsNothing, reason: 'el pasajero no agrega contactos');

    await tester.tap(find.byKey(const Key('radio.conversation.c1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('radio.requestTrip')), findsOneWidget);
  });
}

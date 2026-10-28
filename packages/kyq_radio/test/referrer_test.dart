import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ptt/testing.dart';
import 'package:kyq_radio/kyq_radio.dart';
import 'package:kyq_radio/testing.dart';
import 'package:kyq_realtime/kyq_realtime.dart';

class _Referrer implements RadioReferrer {
  _Referrer(this.code);

  String? code;

  @override
  Future<String?> take() async {
    final c = code;
    code = null;
    return c;
  }
}

RadioCubit _cubit(RadioApi api, String userId, Stream<RealtimeEvent> events) => RadioCubit(
  api: api,
  myUserId: userId,
  events: events,
  rooms: () => FakeListeningRoom(identity: userId),
  tones: FakeTonePlayer(),
  focus: FakeAudioFocus(),
  player: FakeMessagePlayer(),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('código de la invitación en el referrer de Google Play (R9)', () {
    expect(radioReferrerCode('radio=ABCDEFGHIJ'), 'ABCDEFGHIJ');
    expect(radioReferrerCode('utm_source=google-play&radio=ABCDEFGHIJ'), 'ABCDEFGHIJ');
    expect(radioReferrerCode('radio%3DABCDEFGHIJ'), 'ABCDEFGHIJ');
    expect(radioReferrerCode('utm_source=google-play&utm_medium=organic'), isNull);
    expect(radioReferrerCode('radio=corto'), isNull);
    expect(radioReferrerCode(null), isNull);
  });

  test('al arrancar abre la invitación de la instalación una sola vez (SC-004)', () async {
    final opened = <String>[];
    final referrer = _Referrer('ABCDEFGHIJ');
    final mount = RadioMount(
      api: FakeRadioApi(me: fakeMe(radioOn: false)),
      events: (_) => const Stream.empty(),
      factory: _cubit,
      newPlayer: FakeMessagePlayer.new,
      referrer: referrer,
      open: opened.add,
    );
    mount.start('me');
    await pumpEventQueue();
    expect(opened, ['/radio/invite/ABCDEFGHIJ']);
    expect(mount.scope.value?.deps.myUserId, 'me');

    await mount.stop();
    mount.start('me');
    await pumpEventQueue();
    expect(opened, hasLength(1), reason: 'el referrer se usa una vez');
    await mount.dispose();
  });

  test('tras registrarse abre la conversación a la que llevó la invitación por teléfono', () async {
    final opened = <String>[];
    final mount = RadioMount(
      api: FakeRadioApi(me: fakeMe(radioOn: false)),
      events: (_) => const Stream.empty(),
      factory: _cubit,
      newPlayer: FakeMessagePlayer.new,
      referrer: _Referrer('ABCDEFGHIJ'),
      open: opened.add,
    );
    mount.start('me', applied: ['c9']);
    await pumpEventQueue();
    expect(opened, ['/radio/c/c9'], reason: 'la conversación gana al referrer');
    await mount.dispose();
  });
}

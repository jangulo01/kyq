/// Falsos del walkie-talkie para pruebas: ningún canal de plataforma ni red.
library;

import 'dart:async';

import 'package:kyq_api/kyq_api.dart';

import 'kyq_ptt.dart';

class FakePttApi implements PttApi {
  FakePttApi({PttCredentials? credentials, this.closed = false})
    : credentials = credentials ?? const PttCredentials(url: 'wss://voz.test', token: 'lk', room: 'trip-t1');

  PttCredentials credentials;

  /// El token responde 410.
  bool closed;

  /// Respuesta de `requestFloor`; por defecto concede 60 s.
  Future<DateTime> Function() onRequestFloor = () async => DateTime.now().add(const Duration(seconds: 60));
  int tokenCalls = 0;
  int floorRequests = 0;
  int floorReleases = 0;

  @override
  Future<PttCredentials> token() async {
    tokenCalls++;
    if (closed) throw const PttChannelClosed();
    return credentials;
  }

  @override
  Future<DateTime> requestFloor() {
    floorRequests++;
    return onRequestFloor();
  }

  @override
  Future<void> releaseFloor() async => floorReleases++;
}

class FakeVoiceRoom implements VoiceRoom {
  FakeVoiceRoom({this.identity = 'yo'});

  final String identity;
  final _events = StreamController<VoiceRoomEvent>.broadcast(sync: true);
  final sent = <Map<String, Object?>>[];
  final micChanges = <bool>[];
  bool connected = false;
  int connects = 0;

  bool get micEnabled => micChanges.isNotEmpty && micChanges.last;

  /// Simula un evento de la sala.
  void emit(VoiceRoomEvent e) => _events.add(e);

  @override
  Stream<VoiceRoomEvent> get events => _events.stream;

  @override
  String? get localIdentity => identity;

  @override
  Future<void> connect(String url, String token) async {
    connects++;
    connected = true;
  }

  @override
  Future<void> setMicrophoneEnabled(bool enabled) async => micChanges.add(enabled);

  @override
  Future<void> sendData(Map<String, Object?> message) async => sent.add(message);

  @override
  Future<void> disconnect() async => connected = false;
}

/// Sala de Radio falsa (011): anota si la voz entrante está encendida.
class FakeListeningRoom extends FakeVoiceRoom implements ListeningRoom {
  FakeListeningRoom({super.identity});

  final remoteAudio = <bool>[];

  bool get remoteAudioEnabled => remoteAudio.isEmpty || remoteAudio.last;

  @override
  Future<void> setRemoteAudioEnabled(bool enabled) async => remoteAudio.add(enabled);
}

class FakeAudioFocus implements AudioFocus {
  /// `prepare`, `duck` y `release` en orden.
  final log = <String>[];

  bool get ducked => log.lastWhere((e) => e != 'prepare', orElse: () => 'release') == 'duck';

  @override
  Future<void> prepare() async => log.add('prepare');

  @override
  Future<void> duck() async => log.add('duck');

  @override
  Future<void> release() async => log.add('release');
}

class FakeTonePlayer implements TonePlayer {
  final played = <PttTone>[];

  @override
  Future<void> play(PttTone tone) async => played.add(tone);

  @override
  Future<void> dispose() async {}
}

class FakeMicPermission implements MicPermission {
  FakeMicPermission({this.granted = true, this.onRequest = MicAccess.granted});

  bool granted;
  MicAccess onRequest;
  int requests = 0;
  int settingsOpened = 0;

  @override
  Future<bool> isGranted() async => granted;

  @override
  Future<MicAccess> request() async {
    requests++;
    granted = onRequest == MicAccess.granted;
    return onRequest;
  }

  @override
  Future<void> openSettings() async => settingsOpened++;
}

/// Juego de falsos con su controlador.
class FakePtt {
  FakePtt({FakePttApi? api, FakeVoiceRoom? room, FakeMicPermission? mic, Stream<Object?>? closeSignals})
    : api = api ?? FakePttApi(),
      room = room ?? FakeVoiceRoom(),
      mic = mic ?? FakeMicPermission() {
    controller = PttController(
      api: this.api,
      room: this.room,
      focus: focus,
      tones: tones,
      mic: this.mic,
      closeSignals: closeSignals,
    );
  }

  final FakePttApi api;
  final FakeVoiceRoom room;
  final FakeMicPermission mic;
  final focus = FakeAudioFocus();
  final tones = FakeTonePlayer();
  late final PttController controller;
}

/// [PttControllerFactory] para pruebas de apps. Guarda cada [FakePtt] creado en [created].
PttControllerFactory fakePttFactory(List<FakePtt> created, {FakePttApi Function()? api}) =>
    (KyqApiClient _, String _, Stream<Object?> closeSignals) {
      final ptt = FakePtt(api: api?.call(), closeSignals: closeSignals);
      created.add(ptt);
      return ptt.controller;
    };

/// [HandsFreePlatform] en memoria: registra lo que pide [HandsFreePtt] y permite simular
/// pulsaciones.
class FakeHandsFreePlatform implements HandsFreePlatform {
  final _signals = StreamController<HandsFreeSignal>.broadcast(sync: true);

  /// Últimas peticiones: `media:on`, `media:off`, `bubble:<look>`, `bubble:hide`.
  final log = <String>[];
  bool mediaActive = false;
  BubbleLook? bubble;

  void emit(HandsFreeSignal s) => _signals.add(s);

  @override
  Stream<HandsFreeSignal> get signals => _signals.stream;

  @override
  Future<void> setMediaButtonActive(bool active) async {
    mediaActive = active;
    log.add(active ? 'media:on' : 'media:off');
  }

  @override
  Future<void> showBubble(BubbleLook look) async {
    bubble = look;
    log.add('bubble:${look.name}');
  }

  @override
  Future<void> hideBubble() async {
    bubble = null;
    log.add('bubble:hide');
  }
}

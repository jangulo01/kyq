import 'dart:async';

import 'package:flutter/widgets.dart';

import 'ptt_controller.dart';

/// Pulsaciones que llegan de la capa nativa (RN-KYQ-012).
enum HandsFreeSignal {
  /// Botón multimedia (auricular, manos libres, volante) pulsado.
  buttonDown,

  /// Botón multimedia soltado. Muchos botones envían bajar y subir juntos al soltar.
  buttonUp,

  /// Burbuja flotante tocada.
  bubbleDown,

  /// Burbuja soltada o arrastrada (arrastrar también suelta el turno).
  bubbleUp,
}

/// Aspecto de la burbuja según el estado del walkie-talkie.
enum BubbleLook { connecting, idle, talking, remoteTalking, busy }

/// Destino de las pulsaciones cuando no hay canal de viaje ni consulta abiertos: la conversación
/// seleccionada de Radio Kyq (011, FR-028). El canal del viaje siempre gana.
abstract interface class HandsFreeRadio {
  /// Hay una conversación seleccionada y la radio está encendida.
  bool get ready;

  /// Pidiendo el turno o hablando.
  bool get speaking;

  BubbleLook get look;

  /// Cambió algo de lo anterior.
  Stream<void> get changes;

  Future<void> press();

  Future<void> release();
}

/// Capa nativa de Kyq Conductor: sesión multimedia y burbuja sobre otras apps.
abstract interface class HandsFreePlatform {
  Stream<HandsFreeSignal> get signals;

  /// Captura (o deja de capturar) los botones multimedia.
  Future<void> setMediaButtonActive(bool active);

  /// Muestra la burbuja con [look], o la actualiza si ya está visible.
  Future<void> showBubble(BubbleLook look);

  Future<void> hideBubble();
}

/// Botón físico y burbuja flotante del walkie-talkie (RN-KYQ-012, specs/005-ptt-extras).
///
/// Guarda una pila de canales abiertos (viaje, pre-consulta) y aplica las pulsaciones al último,
/// con el mismo `press`/`release` que el botón de la pantalla (FR-016). Botón multimedia: un clic
/// corto alterna hablar/soltar y una pulsación de [holdThreshold] o más habla mientras se
/// mantiene (FR-012). Sin canal abierto no captura el botón ni muestra la burbuja (FR-013); la
/// burbuja solo se ve con la app en segundo plano (FR-014).
class HandsFreePtt {
  HandsFreePtt(
    this._platform, {
    this.holdThreshold = const Duration(milliseconds: 500),
    bool mediaButton = true,
    bool bubble = false,
    DateTime Function()? clock,
  }) : _mediaButtonEnabled = mediaButton,
       _bubbleEnabled = bubble,
       _clock = clock ?? DateTime.now {
    _signals = _platform.signals.listen(_onSignal, onError: (Object e) => debugPrint('Manos libres: $e'));
  }

  final HandsFreePlatform _platform;
  final DateTime Function() _clock;

  /// Desde esta duración la pulsación del botón cuenta como "mantener".
  final Duration holdThreshold;

  late final StreamSubscription<HandsFreeSignal> _signals;
  final _stack = <PttController>[];
  final _subs = <PttController, StreamSubscription<PttState>>{};
  Object? _lastTarget;
  HandsFreeRadio? _radio;
  StreamSubscription<void>? _radioSub;
  bool _mediaButtonEnabled;
  bool _bubbleEnabled;
  bool _foreground = true;
  bool _mediaActive = false;
  BubbleLook? _shownLook;

  DateTime? _downAt;
  bool _latched = false;
  bool _swallowUp = false;

  /// Canal al que van las pulsaciones, o null.
  PttController? get target {
    for (final c in _stack.reversed) {
      // Un canal sin conectar todavía (viaje sin aceptar) no captura el botón.
      if (!c.isClosed && c.state.status != PttStatus.closed && c.state.status != PttStatus.inactive) return c;
    }
    return null;
  }

  bool get mediaButtonEnabled => _mediaButtonEnabled;

  bool get bubbleEnabled => _bubbleEnabled;

  /// Un canal abierto (pantalla del viaje o consulta activa) recibe las pulsaciones.
  void attach(PttController controller) {
    _stack
      ..remove(controller)
      ..add(controller);
    _subs[controller] ??= controller.stream.listen(
      (_) => _sync(),
      // El controlador se cerró (pantalla del viaje cerrada): pasa al siguiente canal.
      onDone: () => scheduleMicrotask(() => detach(controller)),
    );
    _sync();
  }

  void detach(PttController controller) {
    unawaited(_subs.remove(controller)?.cancel());
    if (!_stack.remove(controller)) return;
    _sync();
  }

  /// La radio recibe las pulsaciones mientras no haya canal abierto (011, FR-028).
  void setRadio(HandsFreeRadio? radio) {
    unawaited(_radioSub?.cancel());
    _radio = radio;
    _radioSub = radio?.changes.listen((_) => _sync());
    _sync();
  }

  /// La radio, si hoy es ella quien recibe las pulsaciones.
  HandsFreeRadio? get _radioTarget => target == null && (_radio?.ready ?? false) ? _radio : null;

  /// Preferencias del conductor (FR-015). [bubble] además exige el permiso de superposición.
  void configure({bool? mediaButton, bool? bubble}) {
    _mediaButtonEnabled = mediaButton ?? _mediaButtonEnabled;
    _bubbleEnabled = bubble ?? _bubbleEnabled;
    _sync();
  }

  /// La app pasó a primer plano (sin burbuja) o a segundo plano (con burbuja).
  void setForeground(bool foreground) {
    _foreground = foreground;
    _sync();
  }

  void _resetButton() {
    _downAt = null;
    _latched = false;
    _swallowUp = false;
  }

  void _onSignal(HandsFreeSignal signal) {
    final t = target;
    final r = _radioTarget;
    if (t == null && r == null) return;
    Future<void> press() => t != null ? t.press() : r!.press();
    Future<void> release() => t != null ? t.release() : r!.release();
    switch (signal) {
      case HandsFreeSignal.buttonDown:
        if (!_mediaButtonEnabled) return;
        final speaking = t != null
            ? t.state.status == PttStatus.talking || t.state.status == PttStatus.requesting
            : r!.speaking;
        if (_latched && speaking) {
          // Segundo clic: soltar. Se ignora el "subir" de este mismo clic.
          _latched = false;
          _swallowUp = true;
          unawaited(release());
          return;
        }
        _latched = false;
        _swallowUp = false;
        _downAt = _clock();
        unawaited(press());
      case HandsFreeSignal.buttonUp:
        if (_swallowUp) {
          _swallowUp = false;
          return;
        }
        final downAt = _downAt;
        if (downAt == null) return;
        _downAt = null;
        if (_clock().difference(downAt) >= holdThreshold) {
          unawaited(release());
        } else {
          // Clic corto: sigue hablando hasta el siguiente clic o hasta que caduque el turno.
          _latched = true;
        }
      case HandsFreeSignal.bubbleDown:
        _resetButton();
        unawaited(press());
      case HandsFreeSignal.bubbleUp:
        unawaited(release());
    }
  }

  static BubbleLook lookFor(PttStatus status) => switch (status) {
    PttStatus.talking || PttStatus.requesting => BubbleLook.talking,
    PttStatus.remoteTalking => BubbleLook.remoteTalking,
    PttStatus.busy => BubbleLook.busy,
    PttStatus.idle || PttStatus.micDenied || PttStatus.error => BubbleLook.idle,
    _ => BubbleLook.connecting,
  };

  void _sync() {
    final t = target;
    final r = _radioTarget;
    final current = t ?? r;
    if (current != _lastTarget) {
      _lastTarget = current;
      _resetButton();
    }
    final media = current != null && _mediaButtonEnabled;
    if (media != _mediaActive) {
      _mediaActive = media;
      _call(() => _platform.setMediaButtonActive(media));
    }
    final look = current == null || !_bubbleEnabled || _foreground
        ? null
        : t != null
        ? lookFor(t.state.status)
        : r!.look;
    if (look == _shownLook) return;
    _shownLook = look;
    _call(() => look == null ? _platform.hideBubble() : _platform.showBubble(look));
  }

  void _call(Future<void> Function() op) {
    unawaited(op().catchError((Object e) => debugPrint('Manos libres: $e')));
  }

  Future<void> dispose() async {
    await _radioSub?.cancel();
    _radio = null;
    _stack.clear();
    for (final sub in _subs.values) {
      await sub.cancel();
    }
    _subs.clear();
    await _signals.cancel();
    if (_mediaActive) await _platform.setMediaButtonActive(false);
    if (_shownLook != null) await _platform.hideBubble();
  }
}

/// Adjunta [controller] a [handsFree] mientras el widget está montado (pantalla del viaje).
class HandsFreeAttachment extends StatefulWidget {
  const HandsFreeAttachment({super.key, required this.handsFree, required this.controller, required this.child});

  final HandsFreePtt handsFree;
  final PttController controller;
  final Widget child;

  @override
  State<HandsFreeAttachment> createState() => _HandsFreeAttachmentState();
}

class _HandsFreeAttachmentState extends State<HandsFreeAttachment> {
  @override
  void initState() {
    super.initState();
    widget.handsFree.attach(widget.controller);
  }

  @override
  void didUpdateWidget(HandsFreeAttachment old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller || old.handsFree != widget.handsFree) {
      old.handsFree.detach(old.controller);
      widget.handsFree.attach(widget.controller);
    }
  }

  @override
  void dispose() {
    widget.handsFree.detach(widget.controller);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

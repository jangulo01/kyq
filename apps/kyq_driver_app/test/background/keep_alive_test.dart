import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_driver_app/background/foreground_service.dart';

class _Host implements ForegroundHost {
  final shown = <String>[];
  final buttonsCtl = StreamController<String>.broadcast();

  @override
  Future<void> show({required bool online, required bool radio}) async => shown.add('online=$online radio=$radio');

  @override
  Future<void> hide() async => shown.add('oculto');

  @override
  Stream<String> get buttons => buttonsCtl.stream;
}

void main() {
  test('ONLINE y Radio encendida comparten un aviso que dice cuáles siguen (FR-026)', () async {
    final host = _Host();
    final keep = KeepAlive(host);
    await keep.online.start();
    await keep.setRadioOn(true);
    await keep.online.stop();
    await keep.setRadioOn(true); // sin cambios
    await keep.setRadioOn(false);
    expect(host.shown, ['online=true radio=false', 'online=true radio=true', 'online=false radio=true', 'oculto']);
  });

  test('"Apagar radio" en el aviso llega como pedido de apagar', () async {
    final host = _Host();
    final keep = KeepAlive(host);
    final got = <void>[];
    final sub = keep.turnOffRequests.listen(got.add);
    host.buttonsCtl
      ..add('otro')
      ..add(radioOffButton);
    await pumpEventQueue();
    expect(got, hasLength(1));
    await sub.cancel();
  });
}

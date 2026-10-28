import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_ptt/kyq_ptt.dart';

// 009: el megáfono espera mientras hay voz en algún canal (FR-015).
void main() {
  test('ocupado mientras algún canal tiene voz', () {
    final a = PttActivity();
    var notices = 0;
    a.addListener(() => notices++);
    final trip = Object(), group = Object();
    a.report(trip, busy: true);
    a.report(group, busy: true);
    a.report(trip, busy: false);
    expect(a.busy, isTrue);
    a.report(group, busy: false);
    expect(a.busy, isFalse);
    a.report(group, busy: false);
    expect(notices, 4, reason: 'solo avisa cuando cambia');
  });
}

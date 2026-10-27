import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_admin_web/app/bootstrap.dart';
import 'package:kyq_ui/kyq_ui.dart';

void main() {
  test('sin KYQ_SENTRY_DSN no se inicializa Sentry y la app arranca igual', () async {
    expect(sentryConfig.enabled, isFalse);
    var ran = false;
    await runBootstrapped(() => ran = true);
    expect(ran, isTrue);
    expect(isSentryEnabled, isFalse);
  });
}

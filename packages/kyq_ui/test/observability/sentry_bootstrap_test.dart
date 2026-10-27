import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_ui/kyq_ui.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void main() {
  test('sin dart-define el DSN está vacío y el entorno es dev', () {
    const config = KyqSentryConfig.fromEnvironment(appId: 'com.kyq.test');
    expect(config.dsn, isEmpty);
    expect(config.environment, 'dev');
    expect(config.enabled, isFalse);
  });

  test('DSN vacío o en blanco: ejecuta la app sin inicializar Sentry', () async {
    for (final dsn in ['', '   ']) {
      var ran = 0;
      await runWithSentry(KyqSentryConfig(appId: 'com.kyq.test', dsn: dsn), () => ran++);
      expect(ran, 1);
      expect(Sentry.isEnabled, isFalse);
    }
    // Sin Sentry, fijar el usuario no hace nada.
    await setSentryUserId('2b0c9a5e-4f3d-4d8e-9c1a-0f6b7e8d9a10');
    expect(Sentry.isEnabled, isFalse);
  });

  test('configureSentryOptions: sin PII, con entorno, release y filtros', () async {
    final options = SentryFlutterOptions();
    configureSentryOptions(
      options,
      const KyqSentryConfig(appId: 'com.kyq.driver', dsn: ' https://k@o1.ingest.sentry.io/1 ', environment: 'staging'),
      release: sentryRelease('com.kyq.driver', '0.1.0', '1'),
    );
    expect(options.dsn, 'https://k@o1.ingest.sentry.io/1');
    expect(options.environment, 'staging');
    expect(options.release, 'com.kyq.driver@0.1.0+1');
    expect(options.sendDefaultPii, isFalse);
    expect(options.attachScreenshot, isFalse);
    expect(options.maxRequestBodySize, MaxRequestBodySize.never);

    final event = await options.beforeSend!(
      SentryEvent(
        user: SentryUser(id: 'x', ipAddress: '1.2.3.4'),
        message: SentryMessage('+573001234567'),
      ),
      Hint(),
    );
    expect(event!.user, isNull);
    expect(event.message!.formatted, '[phone]');
    expect(options.beforeBreadcrumb!(Breadcrumb(message: '3001234567'), Hint())!.message, '[phone]');
  });

  test('sentryRelease sin número de build', () {
    expect(sentryRelease('com.kyq.rider', '1.2.0', ''), 'com.kyq.rider@1.2.0');
  });
}

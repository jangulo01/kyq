import 'dart:async';

import 'package:kyq_ui/kyq_ui.dart';

/// Sentry de esta app: DSN por `--dart-define=KYQ_SENTRY_DSN=...`; sin DSN no se inicializa.
const sentryConfig = KyqSentryConfig.fromEnvironment(appId: 'com.kyq.rider');

/// Ejecuta [appRunner] bajo Sentry (si está configurado) con los datos personales filtrados.
Future<void> runBootstrapped(FutureOr<void> Function() appRunner) => runWithSentry(sentryConfig, appRunner);

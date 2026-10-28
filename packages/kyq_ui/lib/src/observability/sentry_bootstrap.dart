import 'dart:async';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'pii_scrubber.dart';

/// Configuración de Sentry de una app. DSN y entorno llegan por `--dart-define`.
class KyqSentryConfig {
  const KyqSentryConfig({required this.appId, this.dsn = '', this.environment = 'dev'});

  /// Lee `KYQ_SENTRY_DSN` (vacío por defecto: Sentry apagado) y `KYQ_ENV` (por defecto 'dev').
  const KyqSentryConfig.fromEnvironment({required this.appId})
    : dsn = const String.fromEnvironment('KYQ_SENTRY_DSN'),
      environment = const String.fromEnvironment('KYQ_ENV', defaultValue: 'dev');

  /// Identificador de la app (applicationId de Android), base del `release`.
  final String appId;
  final String dsn;
  final String environment;

  bool get enabled => dsn.trim().isNotEmpty;
}

/// `release` de Sentry: `<appId>@<versión>+<build>`.
String sentryRelease(String appId, String version, String buildNumber) =>
    buildNumber.isEmpty ? '$appId@$version' : '$appId@$version+$buildNumber';

/// Aplica a [options] la configuración de Kyq: sin PII por defecto, sin capturas y con los filtros.
void configureSentryOptions(SentryFlutterOptions options, KyqSentryConfig config, {String? release}) {
  options
    ..dsn = config.dsn.trim()
    ..environment = config.environment
    ..release = release
    ..sendDefaultPii = false
    ..attachScreenshot = false
    ..maxRequestBodySize = MaxRequestBodySize.never
    ..beforeSend = ((event, hint) => scrubEvent(event))
    ..beforeBreadcrumb = ((crumb, hint) => scrubBreadcrumb(crumb));
}

/// Arranca la app con Sentry si hay DSN; sin DSN ejecuta [appRunner] tal cual, sin tocar la red.
///
/// Llamar después de `WidgetsFlutterBinding.ensureInitialized()`.
Future<void> runWithSentry(KyqSentryConfig config, FutureOr<void> Function() appRunner) async {
  if (!config.enabled) {
    await appRunner();
    return;
  }
  String? release;
  try {
    final info = await PackageInfo.fromPlatform();
    release = sentryRelease(config.appId, info.version, info.buildNumber);
  } on Object {
    release = null;
  }
  await SentryFlutter.init(
    (options) => configureSentryOptions(options, config, release: release),
    appRunner: appRunner,
  );
}

/// Asocia los errores al usuario solo por su id (UUID); `null` lo quita.
Future<void> setSentryUserId(String? userId) async {
  if (!Sentry.isEnabled) return;
  await Sentry.configureScope((scope) => scope.setUser(scrubUser(userId == null ? null : SentryUser(id: userId))));
}

/// Si Sentry quedó inicializado (falso sin DSN).
bool get isSentryEnabled => Sentry.isEnabled;

import 'package:flutter/material.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ui/kyq_ui.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';
import 'background/foreground_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  PlatformForegroundHost.configure();
  runBootstrapped(() async {
    final domains = await loadDomains(
      fallback: const KyqDomain(apiUrl: apiBaseUrl, realtimeUrl: realtimeUrl),
    );
    final deps = bootstrap(domains: domains);
    runApp(KyqDriverApp(api: deps.api, auth: deps.auth, services: deps.services));
  });
}

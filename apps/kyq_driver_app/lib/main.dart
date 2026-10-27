import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';
import 'background/foreground_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ForegroundOnlineService.configure();
  runBootstrapped(() {
    final deps = bootstrap();
    runApp(KyqDriverApp(api: deps.api, auth: deps.auth, services: deps.services));
  });
}

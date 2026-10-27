import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runBootstrapped(() {
    final deps = bootstrap();
    runApp(KyqRiderApp(api: deps.api, auth: deps.auth, realtime: deps.realtime));
  });
}

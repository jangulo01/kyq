import 'package:flutter/material.dart';

import 'app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final deps = bootstrap();
  runApp(KyqDriverApp(api: deps.api, auth: deps.auth));
}

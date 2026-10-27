import 'package:flutter/material.dart';

void main() {
  runApp(const KyqAdminApp());
}

class KyqAdminApp extends StatelessWidget {
  const KyqAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kyq Admin',
      theme: ThemeData(colorSchemeSeed: const Color(0xFF6A1B9A)),
      home: const Scaffold(
        body: Center(child: Text('Kyq Admin')),
      ),
    );
  }
}

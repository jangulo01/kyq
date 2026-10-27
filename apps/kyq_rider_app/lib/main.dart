import 'package:flutter/material.dart';

void main() {
  runApp(const KyqRiderApp());
}

class KyqRiderApp extends StatelessWidget {
  const KyqRiderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kyq Pasajero',
      theme: ThemeData(colorSchemeSeed: const Color(0xFF6A1B9A)),
      home: const Scaffold(
        body: Center(child: Text('Kyq Pasajero')),
      ),
    );
  }
}

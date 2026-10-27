import 'package:flutter/material.dart';

void main() {
  runApp(const KyqDriverApp());
}

class KyqDriverApp extends StatelessWidget {
  const KyqDriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kyq Conductor',
      theme: ThemeData(colorSchemeSeed: const Color(0xFF6A1B9A)),
      home: const Scaffold(
        body: Center(child: Text('Kyq Conductor')),
      ),
    );
  }
}

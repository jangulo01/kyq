import 'dart:async';

import 'package:flutter/material.dart';

/// Segundos que faltan hasta [until], actualizados cada segundo.
class CountdownText extends StatefulWidget {
  const CountdownText({super.key, required this.until, this.style, this.now});

  final DateTime until;
  final TextStyle? style;

  /// Reloj inyectable para pruebas.
  final DateTime Function()? now;

  @override
  State<CountdownText> createState() => _CountdownTextState();
}

class _CountdownTextState extends State<CountdownText> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final left = widget.until.difference((widget.now ?? DateTime.now)()).inSeconds.clamp(0, 9999);
    return Text('$left s', style: widget.style);
  }
}

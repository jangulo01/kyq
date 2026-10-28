import 'dart:async';

import 'package:flutter/material.dart';

/// Texto que se repinta cada segundo con los segundos que faltan para [until].
class Countdown extends StatefulWidget {
  const Countdown({super.key, required this.until, required this.builder, this.now});

  final DateTime until;
  final Widget Function(BuildContext context, int secondsLeft) builder;

  /// Reloj inyectable para pruebas.
  final DateTime Function()? now;

  @override
  State<Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<Countdown> {
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
    return widget.builder(context, left);
  }
}

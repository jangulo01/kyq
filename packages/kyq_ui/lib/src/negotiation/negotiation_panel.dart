import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Formatea unidades mínimas de moneda: 1 470 000 centavos COP → "$ 14.700".
String formatMoney(int minorUnits, String currency) {
  final units = minorUnits ~/ 100;
  final digits = units.toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write('.');
    buf.write(digits[i]);
  }
  return currency == 'COP' || currency == 'PEN' ? '\$ $buf' : '$buf $currency';
}

/// Propuesta abierta tal como la ve una de las partes.
class NegotiationOffer {
  const NegotiationOffer({required this.amountMinor, required this.fromMe, required this.expiresAt});

  final int amountMinor;

  /// true si la hizo quien mira la pantalla: entonces solo puede esperar o contraproponer.
  final bool fromMe;
  final DateTime expiresAt;
}

/// Panel de negociación de tarifa (FR-010c), igual para conductor y pasajero.
///
/// Muestra la propuesta actual con su cuenta atrás de 30 s y el límite total de 3 min, y deja
/// aceptar, contraproponer o abandonar.
class NegotiationPanel extends StatefulWidget {
  const NegotiationPanel({
    super.key,
    required this.currency,
    required this.suggestedMinor,
    required this.offer,
    required this.negotiationEndsAt,
    required this.onAccept,
    required this.onPropose,
    required this.onAbandon,
    this.busy = false,
    this.now,
  });

  final String currency;
  final int suggestedMinor;
  final NegotiationOffer? offer;
  final DateTime negotiationEndsAt;
  final VoidCallback onAccept;
  final ValueChanged<int> onPropose;
  final VoidCallback onAbandon;
  final bool busy;

  /// Reloj inyectable para pruebas.
  final DateTime Function()? now;

  @override
  State<NegotiationPanel> createState() => _NegotiationPanelState();
}

class _NegotiationPanelState extends State<NegotiationPanel> {
  final _amount = TextEditingController();
  Timer? _ticker;

  DateTime _now() => (widget.now ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _amount.dispose();
    super.dispose();
  }

  int _secondsLeft(DateTime t) => t.difference(_now()).inSeconds.clamp(0, 9999);

  void _propose() {
    final pesos = int.tryParse(_amount.text.replaceAll(RegExp(r'\D'), ''));
    if (pesos == null || pesos <= 0) return;
    widget.onPropose(pesos * 100);
    _amount.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final offer = widget.offer;
    final total = _secondsLeft(widget.negotiationEndsAt);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text('Negociando la tarifa', style: theme.textTheme.titleMedium)),
                Text('${total ~/ 60}:${(total % 60).toString().padLeft(2, '0')}', key: const Key('negotiation.total')),
              ],
            ),
            Text('Sugerida: ${formatMoney(widget.suggestedMinor, widget.currency)}', style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),
            if (offer == null)
              const Text('Aún no hay propuestas. Haz la primera.')
            else ...[
              Text(offer.fromMe ? 'Tu propuesta' : 'Te proponen', style: theme.textTheme.labelLarge),
              Text(
                formatMoney(offer.amountMinor, widget.currency),
                key: const Key('negotiation.amount'),
                style: theme.textTheme.headlineMedium,
              ),
              Text(
                offer.fromMe
                    ? 'Esperando respuesta · ${_secondsLeft(offer.expiresAt)} s'
                    : 'Responde en ${_secondsLeft(offer.expiresAt)} s',
              ),
              if (!offer.fromMe) ...[
                const SizedBox(height: 12),
                FilledButton(
                  key: const Key('negotiation.accept'),
                  onPressed: widget.busy ? null : widget.onAccept,
                  child: Text('Aceptar ${formatMoney(offer.amountMinor, widget.currency)}'),
                ),
              ],
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('negotiation.input'),
                    controller: _amount,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: 'Tu precio', prefixText: '\$ '),
                    onSubmitted: (_) => _propose(),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  key: const Key('negotiation.propose'),
                  onPressed: widget.busy ? null : _propose,
                  child: Text(offer == null ? 'Proponer' : 'Contraproponer'),
                ),
              ],
            ),
            TextButton(
              key: const Key('negotiation.abandon'),
              onPressed: widget.busy ? null : widget.onAbandon,
              child: const Text('Abandonar negociación'),
            ),
          ],
        ),
      ),
    );
  }
}

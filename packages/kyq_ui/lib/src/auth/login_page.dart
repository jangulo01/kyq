import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'auth_cubit.dart';

/// Pantalla de login por OTP: teléfono → código (→ nombre si es un registro nuevo).
class LoginPage extends StatelessWidget {
  const LoginPage({super.key, required this.title, this.countryCode = '+57'});

  final String title;

  /// Prefijo internacional que se antepone al número local.
  final String countryCode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(title, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
                  const SizedBox(height: 32),
                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, state) => switch (state) {
                      AuthCodeSent() => _CodeStep(state: state),
                      AuthSignedOut() => _PhoneStep(state: state, countryCode: countryCode),
                      _ => const Center(child: CircularProgressIndicator()),
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhoneStep extends StatefulWidget {
  const _PhoneStep({required this.state, required this.countryCode});

  final AuthSignedOut state;
  final String countryCode;

  @override
  State<_PhoneStep> createState() => _PhoneStepState();
}

class _PhoneStepState extends State<_PhoneStep> {
  final _phone = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  void _submit() {
    final digits = _phone.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return;
    context.read<AuthCubit>().requestCode('${widget.countryCode}$digits');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('login.phone'),
          controller: _phone,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]'))],
          decoration: InputDecoration(labelText: 'Tu número de celular', prefixText: '${widget.countryCode} '),
          onSubmitted: (_) => _submit(),
        ),
        if (widget.state.error != null) _ErrorText(widget.state.error!),
        const SizedBox(height: 16),
        FilledButton(
          key: const Key('login.sendCode'),
          onPressed: widget.state.busy ? null : _submit,
          child: widget.state.busy ? const _ButtonSpinner() : const Text('Enviarme un código'),
        ),
      ],
    );
  }
}

class _CodeStep extends StatefulWidget {
  const _CodeStep({required this.state});

  final AuthCodeSent state;

  @override
  State<_CodeStep> createState() => _CodeStepState();
}

class _CodeStepState extends State<_CodeStep> {
  final _code = TextEditingController();
  final _name = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    if (_code.text.length != 6) return;
    context.read<AuthCubit>().verify(_code.text, displayName: widget.state.needsName ? _name.text : null);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Te enviamos un código por SMS al ${state.phone}.'),
        const SizedBox(height: 16),
        TextField(
          key: const Key('login.code'),
          controller: _code,
          keyboardType: TextInputType.number,
          maxLength: 6,
          autofillHints: const [AutofillHints.oneTimeCode],
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(labelText: 'Código de 6 dígitos', counterText: ''),
          onSubmitted: (_) => _submit(),
        ),
        if (state.needsName) ...[
          const SizedBox(height: 16),
          Text('Es tu primera vez en Kyq. ¿Cómo te llamas?', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          TextField(
            key: const Key('login.name'),
            controller: _name,
            textCapitalization: TextCapitalization.words,
            maxLength: 60,
            decoration: const InputDecoration(labelText: 'Tu nombre', counterText: ''),
            onSubmitted: (_) => _submit(),
          ),
        ],
        if (state.error != null) _ErrorText(state.error!),
        const SizedBox(height: 16),
        FilledButton(
          key: const Key('login.verify'),
          onPressed: state.busy ? null : _submit,
          child: state.busy ? const _ButtonSpinner() : const Text('Entrar'),
        ),
        TextButton(
          onPressed: state.busy ? null : context.read<AuthCubit>().changePhone,
          child: const Text('Cambiar número'),
        ),
      ],
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Text(message, style: TextStyle(color: Theme.of(context).colorScheme.error)),
  );
}

class _ButtonSpinner extends StatelessWidget {
  const _ButtonSpinner();

  @override
  Widget build(BuildContext context) =>
      const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2));
}

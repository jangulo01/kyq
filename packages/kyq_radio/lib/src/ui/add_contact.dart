import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../controller/radio_cubit.dart';
import '../deps.dart';

final _codePattern = RegExp(r'(?:/r/|radio/)([0-9A-Za-z]{10})(?:[/?#]|$)');
final _bareCode = RegExp(r'^[0-9A-Za-z]{10}$');

/// Código de una invitación desde un enlace (`https://…/r/{code}`, `kyq://radio/{code}`) o el
/// código solo; null si no es de Radio Kyq.
String? radioInviteCode(String raw) {
  final t = raw.trim();
  if (_bareCode.hasMatch(t)) return t;
  return _codePattern.firstMatch(t)?.group(1);
}

/// Menú del botón "Agregar" (US1, US4): QR propio, escanear, teléfono, enlace y canal.
Future<void> showRadioAddMenu(BuildContext context) async {
  final choice = await showModalBottomSheet<String>(
    context: context,
    builder: (context) => SafeArea(
      child: Wrap(
        children: [
          ListTile(
            key: const Key('radio.add.qr'),
            leading: const Icon(Icons.qr_code_2),
            title: const Text('Mostrar mi QR'),
            subtitle: const Text('Tu compañero lo escanea y queda en tus contactos'),
            onTap: () => Navigator.pop(context, 'qr'),
          ),
          ListTile(
            key: const Key('radio.add.scan'),
            leading: const Icon(Icons.qr_code_scanner),
            title: const Text('Escanear un QR'),
            onTap: () => Navigator.pop(context, 'scan'),
          ),
          ListTile(
            key: const Key('radio.add.phone'),
            leading: const Icon(Icons.sms_outlined),
            title: const Text('Invitar por teléfono'),
            onTap: () => Navigator.pop(context, 'phone'),
          ),
          ListTile(
            key: const Key('radio.add.link'),
            leading: const Icon(Icons.link),
            title: const Text('Tengo un enlace de invitación'),
            onTap: () => Navigator.pop(context, 'link'),
          ),
          ListTile(
            key: const Key('radio.add.channel'),
            leading: const Icon(Icons.group_add_outlined),
            title: const Text('Crear canal'),
            onTap: () => Navigator.pop(context, 'channel'),
          ),
        ],
      ),
    ),
  );
  if (!context.mounted || choice == null) return;
  switch (choice) {
    case 'qr':
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => _MyQrPage(deps: context.read<RadioDeps>())));
    case 'scan':
      final code = await Navigator.of(context).push<String>(MaterialPageRoute(builder: (_) => const _ScanPage()));
      if (code != null && context.mounted) await context.push(RadioRoutes.invite(code));
    case 'phone':
      await _invitePhone(context);
    case 'link':
      await _pasteLink(context);
    case 'channel':
      await context.push(RadioRoutes.newChannel);
  }
}

Future<void> _invitePhone(BuildContext context) async {
  final ctl = TextEditingController();
  final deps = context.read<RadioDeps>();
  final phone = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Invitar por teléfono'),
      content: TextField(
        key: const Key('radio.invite.phone'),
        controller: ctl,
        keyboardType: TextInputType.phone,
        decoration: const InputDecoration(labelText: 'Celular', hintText: '300 123 4567'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          key: const Key('radio.invite.send'),
          onPressed: () => Navigator.pop(context, ctl.text),
          child: const Text('Enviar invitación'),
        ),
      ],
    ),
  );
  if (phone == null || phone.trim().isEmpty || !context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  try {
    await deps.api.inviteRadioContact(phoneE164: phone.trim());
    // Igual exista o no la cuenta: Kyq no lo revela (FR-002).
    messenger.showSnackBar(const SnackBar(content: Text('Le enviamos un SMS con tu invitación.')));
  } on ApiException catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text(e.code == 'invalid_radio_request' ? 'Revisa el número.' : radioErrorText(e))),
    );
  }
}

/// Sin Google Play (Huawei) la invitación también entra pegando el enlace (R9).
Future<void> _pasteLink(BuildContext context) async {
  final clip = await Clipboard.getData(Clipboard.kTextPlain);
  if (!context.mounted) return;
  final ctl = TextEditingController(text: radioInviteCode(clip?.text ?? '') == null ? '' : clip!.text);
  final raw = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Enlace de invitación'),
      content: TextField(
        key: const Key('radio.invite.link'),
        controller: ctl,
        decoration: const InputDecoration(hintText: 'Pega el enlace que te enviaron'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(context, ctl.text), child: const Text('Abrir')),
      ],
    ),
  );
  if (raw == null || !context.mounted) return;
  final code = radioInviteCode(raw);
  if (code == null) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ese enlace no es de Radio Kyq.')));
    return;
  }
  await context.push(RadioRoutes.invite(code));
}

class _MyQrPage extends StatefulWidget {
  const _MyQrPage({required this.deps});

  final RadioDeps deps;

  @override
  State<_MyQrPage> createState() => _MyQrPageState();
}

class _MyQrPageState extends State<_MyQrPage> {
  late final Future<RadioInvite?> _invite = widget.deps.api.inviteRadioContact();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi QR de Radio')),
      body: FutureBuilder<RadioInvite?>(
        future: _invite,
        builder: (context, snap) {
          if (snap.hasError) {
            final e = snap.error;
            return Center(child: Text(e is ApiException ? radioErrorText(e) : 'No pudimos crear la invitación.'));
          }
          final inv = snap.data;
          if (inv == null) return const Center(child: CircularProgressIndicator());
          return InviteShareView(
            invite: inv,
            deps: widget.deps,
            hint: 'Tu compañero escanea este código con Kyq Conductor.',
          );
        },
      ),
    );
  }
}

/// QR y enlace de una invitación, con compartir (FR-032).
class InviteShareView extends StatelessWidget {
  const InviteShareView({super.key, required this.invite, required this.deps, required this.hint});

  final RadioInvite invite;
  final RadioDeps deps;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: QrImageView(key: const Key('radio.qr'), data: invite.url, size: 240),
          ),
        ),
        const SizedBox(height: 16),
        Text(hint, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        SelectableText(invite.url, textAlign: TextAlign.center, key: const Key('radio.qr.link')),
        const SizedBox(height: 16),
        FilledButton.icon(
          key: const Key('radio.qr.share'),
          onPressed: () async {
            final text = 'Únete a mi Radio en Kyq: ${invite.url}';
            final share = deps.onShareLink;
            if (share != null) {
              await share(text);
              return;
            }
            await Clipboard.setData(ClipboardData(text: invite.url));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enlace copiado.')));
            }
          },
          icon: const Icon(Icons.share),
          label: const Text('Compartir enlace'),
        ),
        const SizedBox(height: 8),
        Text('Vence en 14 días.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _ScanPage extends StatefulWidget {
  const _ScanPage();

  @override
  State<_ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<_ScanPage> {
  final _camera = MobileScannerController(formats: const [BarcodeFormat.qrCode]);
  bool _done = false;

  @override
  void dispose() {
    _camera.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escanear QR de Radio')),
      body: MobileScanner(
        controller: _camera,
        onDetect: (capture) {
          if (_done) return;
          final code = radioInviteCode(capture.barcodes.firstOrNull?.rawValue ?? '');
          if (code == null) return;
          _done = true;
          Navigator.pop(context, code);
        },
      ),
    );
  }
}

/// Invitación abierta por enlace profundo, QR o enlace pegado (FR-032): quién invita y a qué, y
/// el botón para aceptar o pedir entrar.
class InviteAcceptPage extends StatefulWidget {
  const InviteAcceptPage({super.key, required this.code});

  final String code;

  @override
  State<InviteAcceptPage> createState() => _InviteAcceptPageState();
}

class _InviteAcceptPageState extends State<InviteAcceptPage> {
  late final Future<RadioInvitePreview> _preview = context.read<RadioDeps>().api.radioInvitePreview(widget.code);
  bool _busy = false;
  String? _error;

  Future<void> _accept() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final deps = context.read<RadioDeps>();
    final radio = context.read<RadioCubit>();
    try {
      final res = await deps.api.acceptRadioInvite(widget.code);
      await radio.load();
      if (!mounted) return;
      if (res.pending) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Solicitud enviada. Un moderador debe aprobarla.')));
        context.go(RadioRoutes.list);
        return;
      }
      context.go(RadioRoutes.conversation(res.conversation.id));
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = radioErrorText(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invitación de Radio')),
      body: FutureBuilder<RadioInvitePreview>(
        future: _preview,
        builder: (context, snap) {
          if (snap.hasError) {
            final e = snap.error;
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  e is ApiException ? radioErrorText(e) : 'No pudimos abrir la invitación.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final p = snap.data;
          if (p == null) return const Center(child: CircularProgressIndicator());
          final channel = p.kind == 'channel';
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(channel ? Icons.groups : Icons.person_add_alt_1, size: 64),
                const SizedBox(height: 16),
                Text(
                  channel
                      ? '${p.inviterName} te invita al canal «${p.channelName ?? ''}»'
                      : '${p.inviterName} quiere agregarte a su Radio',
                  key: const Key('radio.invite.title'),
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (_error != null) Text(_error!, key: const Key('radio.invite.error'), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  key: const Key('radio.invite.accept'),
                  onPressed: _busy ? null : _accept,
                  child: Text(channel ? 'Entrar al canal' : 'Aceptar contacto'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

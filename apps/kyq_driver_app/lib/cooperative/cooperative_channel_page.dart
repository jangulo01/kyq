import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ptt/kyq_ptt.dart';

/// Canal walkie-talkie de grupo de la cooperativa (006, FR-022–FR-024): conecta al abrir, un
/// solo turno para todo el grupo y muestra qué compañero habla.
class CooperativeChannelPage extends StatefulWidget {
  const CooperativeChannelPage({super.key, required this.controller, this.members = const []});

  final PttController controller;

  /// Compañeros, para poner nombre a quien habla.
  final List<CooperativeMember> members;

  @override
  State<CooperativeChannelPage> createState() => _CooperativeChannelPageState();
}

class _CooperativeChannelPageState extends State<CooperativeChannelPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.controller.isClosed) widget.controller.start();
    });
  }

  String _speaker(String? id) {
    for (final m in widget.members) {
      if (m.driverId == id) return m.displayName;
    }
    return 'un compañero';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Canal de la cooperativa')),
      body: BlocBuilder<PttController, PttState>(
        bloc: widget.controller,
        builder: (context, state) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.status == PttStatus.closed)
                const Text(
                  'Ya no tienes acceso a este canal: no perteneces a una cooperativa activa.',
                  key: Key('coopChannel.closed'),
                  textAlign: TextAlign.center,
                )
              else ...[
                const Text(
                  'Todos los compañeros conectados te oyen. Solo habla uno a la vez.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                PttButton(controller: widget.controller, remoteName: _speaker(state.speakerId)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

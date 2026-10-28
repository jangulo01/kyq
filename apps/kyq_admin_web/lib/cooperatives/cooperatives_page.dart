import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kyq_api/kyq_api.dart';

import 'cooperatives_cubits.dart';

/// Cooperativas con sus miembros y solicitudes pendientes, y alta de una nueva (006, FR-001,
/// FR-002). Junto a la validación de documentos forma el centro de validación del panel.
class CooperativesPage extends StatelessWidget {
  const CooperativesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CooperativesCubit>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cooperativas'),
        actions: [IconButton(tooltip: 'Recargar', icon: const Icon(Icons.refresh), onPressed: cubit.load)],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('coops.create'),
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => BlocProvider.value(value: cubit, child: const _CreateDialog()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Nueva cooperativa'),
      ),
      body: BlocBuilder<CooperativesCubit, CooperativesState>(
        builder: (context, state) {
          if (state.loading && state.cooperatives.isEmpty) return const Center(child: CircularProgressIndicator());
          if (state.error != null && state.cooperatives.isEmpty) return Center(child: Text(state.error!));
          if (state.cooperatives.isEmpty) return const Center(child: Text('Aún no hay cooperativas.'));
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.cooperatives.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final c = state.cooperatives[i];
              final suspended = c.status == CooperativeStatus.suspended;
              return ListTile(
                key: Key('coops.${c.id}'),
                leading: Icon(Icons.groups, color: suspended ? Colors.grey : null),
                title: Text(c.name),
                subtitle: Text(
                  [
                    c.cityCode,
                    if (c.nit != null) 'NIT ${c.nit}',
                    '${c.membersCount} ${c.membersCount == 1 ? 'miembro' : 'miembros'}',
                    if (suspended) 'Suspendida',
                  ].join(' · '),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (c.pendingCount > 0)
                      Chip(
                        key: Key('coops.${c.id}.pending'),
                        label: Text('${c.pendingCount} ${c.pendingCount == 1 ? 'solicitud' : 'solicitudes'}'),
                      ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () async {
                  await context.push('/cooperatives/${c.id}');
                  await cubit.load();
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _CreateDialog extends StatefulWidget {
  const _CreateDialog();

  @override
  State<_CreateDialog> createState() => _CreateDialogState();
}

class _CreateDialogState extends State<_CreateDialog> {
  final _name = TextEditingController();
  final _city = TextEditingController(text: 'bogota');
  final _nit = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    _nit.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().length < 3) {
      setState(() => _error = 'El nombre debe tener al menos 3 caracteres.');
      return;
    }
    setState(() => _saving = true);
    final error = await context.read<CooperativesCubit>().create(
      name: _name.text,
      cityCode: _city.text,
      nit: _nit.text,
    );
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context);
    } else {
      setState(() {
        _saving = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Nueva cooperativa'),
    content: SizedBox(
      width: 400,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('coops.form.name'),
            controller: _name,
            decoration: const InputDecoration(labelText: 'Nombre'),
          ),
          TextField(
            key: const Key('coops.form.city'),
            controller: _city,
            decoration: const InputDecoration(labelText: 'Ciudad (código)'),
          ),
          TextField(
            key: const Key('coops.form.nit'),
            controller: _nit,
            decoration: const InputDecoration(labelText: 'NIT (opcional)'),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
      FilledButton(key: const Key('coops.form.save'), onPressed: _saving ? null : _save, child: const Text('Crear')),
    ],
  );
}

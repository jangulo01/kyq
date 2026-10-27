import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ui/kyq_ui.dart';

import 'drivers_cubit.dart';

const _docLabels = {
  DocType.license: 'Licencia',
  DocType.mandatoryInsurance: 'Seguro obligatorio',
  DocType.vehicleRegistration: 'Tarjeta del vehículo',
};

const _blockLabels = {'subscription_suspended': 'Suscripción suspendida', 'kyc_expired': 'Documentos'};

String _date(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class DriversPage extends StatelessWidget {
  const DriversPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conductores'),
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/fares'),
            icon: const Icon(Icons.payments),
            label: const Text('Tarifas'),
          ),
          IconButton(
            tooltip: 'Recargar',
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<DriversCubit>().load(),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthCubit>().signOut(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Nuevo conductor'),
      ),
      body: BlocConsumer<DriversCubit, DriversState>(
        listenWhen: (a, b) => b.error != null && a.error != b.error,
        listener: (context, state) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!))),
        builder: (context, state) {
          if (state.loading && state.drivers.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.drivers.isEmpty) {
            return const Center(child: Text('Aún no hay conductores. Crea el primero.'));
          }
          return Column(
            children: [
              if (state.loading) const LinearProgressIndicator(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Conductor')),
                        DataColumn(label: Text('Vehículo')),
                        DataColumn(label: Text('Suscripción')),
                        DataColumn(label: Text('Documentos')),
                        DataColumn(label: Text('Puede trabajar')),
                        DataColumn(label: Text('Acciones')),
                      ],
                      rows: [for (final d in state.drivers) _row(context, d)],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  DataRow _row(BuildContext context, AdminDriver d) {
    final docs = {for (final doc in d.documents) doc.docType: doc};
    return DataRow(
      cells: [
        DataCell(Text('${d.displayName}\n${d.phoneE164}')),
        DataCell(Text('${d.vehiclePlate}\n${d.vehicleDescription}')),
        DataCell(
          Text(
            '${switch (d.subscriptionStatus) {
              SubscriptionStatus.active => 'Activa',
              SubscriptionStatus.gracePeriod => 'En gracia',
              SubscriptionStatus.suspended => 'Suspendida',
            }}${d.paidUntil == null ? '' : '\nhasta ${_date(d.paidUntil!.toLocal())}'}',
          ),
        ),
        DataCell(
          Wrap(
            spacing: 4,
            children: [
              for (final type in DocType.values)
                Chip(
                  visualDensity: VisualDensity.compact,
                  avatar: Icon(docs[type]?.approved == true ? Icons.check_circle : Icons.pending, size: 16),
                  label: Text('${_docLabels[type]}${docs[type] == null ? '' : ' · ${docs[type]!.expiresAt}'}'),
                ),
            ],
          ),
        ),
        DataCell(
          d.canGoOnline ? const Icon(Icons.check, color: Colors.green) : Text(_blockLabels[d.blockReason] ?? 'No'),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(onPressed: () => _pickPaidThrough(context, d), child: const Text('Registrar pago')),
              TextButton(onPressed: () => _showDocumentDialog(context, d), child: const Text('Documentos')),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickPaidThrough(BuildContext context, AdminDriver d) async {
    final cubit = context.read<DriversCubit>();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      helpText: 'Pagado hasta',
      initialDate: (d.paidUntil?.toLocal().isAfter(now) ?? false)
          ? d.paidUntil!.toLocal().add(const Duration(days: 30))
          : now.add(const Duration(days: 30)),
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (picked != null) await cubit.setPaidThrough(d.driverId, picked);
  }

  Future<void> _showDocumentDialog(BuildContext context, AdminDriver d) => showDialog<void>(
    context: context,
    builder: (_) => BlocProvider.value(
      value: context.read<DriversCubit>(),
      child: _DocumentDialog(driver: d),
    ),
  );

  Future<void> _showCreateDialog(BuildContext context) => showDialog<void>(
    context: context,
    builder: (_) => BlocProvider.value(value: context.read<DriversCubit>(), child: const _CreateDriverDialog()),
  );
}

class _CreateDriverDialog extends StatefulWidget {
  const _CreateDriverDialog();

  @override
  State<_CreateDriverDialog> createState() => _CreateDriverDialogState();
}

class _CreateDriverDialogState extends State<_CreateDriverDialog> {
  final _form = GlobalKey<FormState>();
  final _phone = TextEditingController(text: '+57');
  final _name = TextEditingController();
  final _plate = TextEditingController();
  final _vehicle = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_phone, _name, _plate, _vehicle]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final ok = await context.read<DriversCubit>().create(
      phoneE164: _phone.text.trim(),
      displayName: _name.text.trim(),
      vehiclePlate: _plate.text.trim(),
      vehicleDescription: _vehicle.text.trim(),
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String? required(String? v) => (v == null || v.trim().isEmpty) ? 'Obligatorio' : null;
    return AlertDialog(
      title: const Text('Nuevo conductor'),
      scrollable: true,
      content: SizedBox(
        width: 400,
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _phone,
                decoration: const InputDecoration(labelText: 'Teléfono (+57...)'),
                validator: (v) =>
                    RegExp(r'^\+[1-9][0-9]{6,14}$').hasMatch(v?.trim() ?? '') ? null : 'Formato +57XXXXXXXXXX',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _plate,
                decoration: const InputDecoration(labelText: 'Placa'),
                validator: required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _vehicle,
                decoration: const InputDecoration(labelText: 'Vehículo (marca, modelo, color)'),
                validator: required,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(onPressed: _saving ? null : _save, child: const Text('Crear')),
      ],
    );
  }
}

class _DocumentDialog extends StatefulWidget {
  const _DocumentDialog({required this.driver});

  final AdminDriver driver;

  @override
  State<_DocumentDialog> createState() => _DocumentDialogState();
}

class _DocumentDialogState extends State<_DocumentDialog> {
  DocType _type = DocType.license;
  DateTime? _expiresAt;
  bool _approved = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  void _loadExisting() {
    final existing = widget.driver.documents.where((d) => d.docType == _type).firstOrNull;
    _expiresAt = existing == null ? null : DateTime.parse(existing.expiresAt);
    _approved = existing?.approved ?? true;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      helpText: 'Vence el',
      initialDate: _expiresAt ?? now.add(const Duration(days: 365)),
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 10)),
    );
    if (picked != null) setState(() => _expiresAt = picked);
  }

  Future<void> _save() async {
    final expires = _expiresAt;
    if (expires == null) return;
    setState(() => _saving = true);
    final ok = await context.read<DriversCubit>().setDocument(
      widget.driver.driverId,
      _type,
      expiresAt: expires,
      approved: _approved,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Documentos de ${widget.driver.displayName}'),
      scrollable: true,
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<DocType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Documento'),
              items: [for (final t in DocType.values) DropdownMenuItem(value: t, child: Text(_docLabels[t]!))],
              onChanged: (t) => setState(() {
                _type = t!;
                _loadExisting();
              }),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.event),
              label: Text(_expiresAt == null ? 'Elegir fecha de vencimiento' : 'Vence el ${_date(_expiresAt!)}'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Revisado y aprobado'),
              value: _approved,
              onChanged: (v) => setState(() => _approved = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(onPressed: _saving || _expiresAt == null ? null : _save, child: const Text('Guardar')),
      ],
    );
  }
}

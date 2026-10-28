import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ui/kyq_ui.dart';

import 'drivers_cubit.dart';

const _blockLabels = {'subscription_suspended': 'Suscripción suspendida', 'kyc_expired': 'Documentos'};

String _date(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Secciones del panel (T023, T037, T040 de 002; T029 de 004; T032 de 007; 009), en la barra superior
/// de la lista de conductores.
const adminSections = [
  (path: '/tower', label: 'Torre', icon: Icons.hexagon_outlined),
  (path: '/finance', label: 'Finanzas', icon: Icons.account_balance_outlined),
  (path: '/crm', label: 'Fidelización', icon: Icons.favorite_border),
  (path: '/users', label: 'Usuarios', icon: Icons.manage_accounts_outlined),
  (path: '/health', label: 'Salud', icon: Icons.monitor_heart_outlined),
  (path: '/emergencies', label: 'Emergencias', icon: Icons.sos),
  (path: '/support', label: 'Soporte', icon: Icons.support_agent),
  (path: '/kyc', label: 'Validación', icon: Icons.fact_check_outlined),
  (path: '/cooperatives', label: 'Cooperativas', icon: Icons.groups),
  (path: '/radio', label: 'Radio', icon: Icons.settings_input_antenna),
  (path: '/billing', label: 'Suscripciones', icon: Icons.receipt_long_outlined),
  (path: '/trip-payments', label: 'Pagos de viajes', icon: Icons.account_balance_wallet_outlined),
  (path: '/costs', label: 'Costos', icon: Icons.query_stats),
  (path: '/fares', label: 'Tarifas', icon: Icons.payments),
  (path: '/domains', label: 'Dominios', icon: Icons.dns_outlined),
];

class DriversPage extends StatelessWidget {
  const DriversPage({super.key});

  @override
  Widget build(BuildContext context) {
    // En ventanas anchas las secciones van en una franja bajo la barra (desplazable si no caben);
    // en las estrechas, en un menú.
    final wide = MediaQuery.sizeOf(context).width >= 1000;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conductores'),
        bottom: wide
            ? PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        for (final s in adminSections)
                          TextButton.icon(
                            key: Key('nav${s.path}'),
                            onPressed: () => context.go(s.path),
                            icon: Icon(s.icon),
                            label: Text(s.label),
                          ),
                      ],
                    ),
                  ),
                ),
              )
            : null,
        actions: [
          if (!wide)
            PopupMenuButton<String>(
              key: const Key('nav.menu'),
              tooltip: 'Secciones',
              icon: const Icon(Icons.menu),
              onSelected: context.go,
              itemBuilder: (_) => [
                for (final s in adminSections)
                  PopupMenuItem(
                    key: Key('nav${s.path}'),
                    value: s.path,
                    child: ListTile(leading: Icon(s.icon), title: Text(s.label)),
                  ),
              ],
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
                  label: Text(
                    '${docTypeLabel(type)}${docs[type]?.expiresAt == null ? '' : ' · ${docs[type]!.expiresAt}'}',
                  ),
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
              // 002: los pagos y documentos se gestionan en sus pantallas, con historial y auditoría.
              TextButton(
                onPressed: () => context.push('/billing/drivers/${d.driverId}', extra: d.displayName),
                child: const Text('Pagos'),
              ),
              TextButton(onPressed: () => context.push('/kyc/drivers/${d.driverId}'), child: const Text('Documentos')),
            ],
          ),
        ),
      ],
    );
  }

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

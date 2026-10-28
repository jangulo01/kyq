import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ui/kyq_ui.dart';

String _message(ApiException e) => switch (e.code) {
  'network' => 'Sin conexión con el servidor.',
  _ => e.message.isEmpty ? 'Algo salió mal (${e.code}).' : e.message,
};

const roleLabels = {UserRole.passenger: 'Pasajero', UserRole.driver: 'Conductor', UserRole.admin: 'Administrador'};

class UsersState {
  const UsersState({
    this.query = '',
    this.role,
    this.suspended,
    this.users = const [],
    this.loading = false,
    this.error,
    this.notice,
  });

  final String query;
  final UserRole? role;

  /// null: todos; true: suspendidos; false: activos.
  final bool? suspended;
  final List<ModeratedUser> users;
  final bool loading;
  final String? error;

  /// Confirmación de la última acción.
  final String? notice;

  UsersState copyWith({
    String? query,
    UserRole? Function()? role,
    bool? Function()? suspended,
    List<ModeratedUser>? users,
    bool loading = false,
    String? error,
    String? notice,
  }) => UsersState(
    query: query ?? this.query,
    role: role != null ? role() : this.role,
    suspended: suspended != null ? suspended() : this.suspended,
    users: users ?? this.users,
    loading: loading,
    error: error,
    notice: notice,
  );
}

/// Moderación de usuarios (T028, FR-014–FR-017).
class UsersCubit extends Cubit<UsersState> {
  UsersCubit(this._api) : super(const UsersState());

  final KyqApiClient _api;

  Future<void> search({String? query, UserRole? Function()? role, bool? Function()? suspended}) async {
    final next = state.copyWith(query: query, role: role, suspended: suspended, loading: true);
    emit(next);
    try {
      final users = await _api.adminUsers(query: next.query, role: next.role, suspended: next.suspended);
      emit(next.copyWith(users: users));
    } on ApiException catch (e) {
      emit(next.copyWith(error: _message(e)));
    }
  }

  /// Suspende o reactiva con [reason]. Devuelve false y deja el error en el estado si falla.
  Future<bool> moderate(ModeratedUser user, {required bool suspend, required String reason}) async {
    try {
      final updated = suspend
          ? await _api.adminSuspendUser(user.userId, reason)
          : await _api.adminReactivateUser(user.userId, reason);
      emit(
        state.copyWith(
          users: [for (final u in state.users) u.userId == updated.userId ? updated : u],
          notice: suspend ? '${updated.displayName} quedó suspendido.' : '${updated.displayName} fue reactivado.',
        ),
      );
      return true;
    } on ApiException catch (e) {
      emit(state.copyWith(error: _message(e)));
      return false;
    }
  }

  Future<List<ModerationAction>> history(String userId) => _api.adminModerationHistory(userId);
}

/// Usuarios: búsqueda, filtros, suspender/reactivar con motivo e historial.
class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<UsersCubit>();
    return Scaffold(
      appBar: AppBar(title: const Text('Usuarios y moderación')),
      body: BlocConsumer<UsersCubit, UsersState>(
        listenWhen: (a, b) => (b.error != null && a.error != b.error) || (b.notice != null && a.notice != b.notice),
        listener: (context, state) =>
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error ?? state.notice!))),
        builder: (context, state) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 320,
                    child: TextField(
                      key: const Key('users.query'),
                      controller: _query,
                      maxLength: 60,
                      decoration: const InputDecoration(
                        labelText: 'Nombre o teléfono',
                        prefixIcon: Icon(Icons.search),
                        counterText: '',
                      ),
                      onSubmitted: (v) => cubit.search(query: v),
                    ),
                  ),
                  DropdownButton<UserRole?>(
                    key: const Key('users.role'),
                    value: state.role,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todos los roles')),
                      for (final e in roleLabels.entries) DropdownMenuItem(value: e.key, child: Text(e.value)),
                    ],
                    onChanged: (r) => cubit.search(query: _query.text, role: () => r),
                  ),
                  SegmentedButton<bool?>(
                    key: const Key('users.status'),
                    segments: const [
                      ButtonSegment(value: null, label: Text('Todos')),
                      ButtonSegment(value: false, label: Text('Activos')),
                      ButtonSegment(value: true, label: Text('Suspendidos')),
                    ],
                    selected: {state.suspended},
                    showSelectedIcon: false,
                    onSelectionChanged: (s) => cubit.search(query: _query.text, suspended: () => s.first),
                  ),
                  FilledButton.icon(
                    key: const Key('users.search'),
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                    onPressed: () => cubit.search(query: _query.text),
                    icon: const Icon(Icons.search),
                    label: const Text('Buscar'),
                  ),
                ],
              ),
            ),
            if (state.loading) const LinearProgressIndicator(),
            Expanded(
              child: state.users.isEmpty
                  ? Center(child: Text(state.loading ? '' : 'Sin resultados. Busca por nombre o teléfono.'))
                  : ListView.separated(
                      itemCount: state.users.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) => _UserTile(user: state.users[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({required this.user});

  final ModeratedUser user;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final canModerate = user.role != UserRole.admin;
    return ListTile(
      key: ValueKey('users.row.${user.userId}'),
      leading: Icon(user.suspended ? Icons.block : Icons.person, color: user.suspended ? scheme.error : null),
      title: Text('${user.displayName} · ${roleLabels[user.role]}'),
      subtitle: Text(
        user.suspended
            ? '${user.phoneE164} · suspendido el ${formatDate(user.suspendedAt!)}: ${user.suspensionReason}'
            : '${user.phoneE164} · desde el ${formatDate(user.createdAt)}',
      ),
      trailing: Wrap(
        spacing: 8,
        children: [
          TextButton(
            key: Key('users.history.${user.userId}'),
            onPressed: () => _showHistory(context, user),
            child: const Text('Historial'),
          ),
          if (canModerate)
            user.suspended
                ? OutlinedButton(
                    key: Key('users.reactivate.${user.userId}'),
                    onPressed: () => _moderate(context, user, suspend: false),
                    child: const Text('Reactivar'),
                  )
                : OutlinedButton(
                    key: Key('users.suspend.${user.userId}'),
                    style: OutlinedButton.styleFrom(foregroundColor: scheme.error),
                    onPressed: () => _moderate(context, user, suspend: true),
                    child: const Text('Suspender'),
                  ),
        ],
      ),
    );
  }

  Future<void> _moderate(BuildContext context, ModeratedUser user, {required bool suspend}) async {
    final cubit = context.read<UsersCubit>();
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => _ReasonDialog(user: user, suspend: suspend),
    );
    if (reason == null) return;
    await cubit.moderate(user, suspend: suspend, reason: reason);
  }

  Future<void> _showHistory(BuildContext context, ModeratedUser user) async {
    final cubit = context.read<UsersCubit>();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Historial de ${user.displayName}'),
        content: SizedBox(
          width: 480,
          child: FutureBuilder<List<ModerationAction>>(
            future: cubit.history(user.userId),
            builder: (context, snap) {
              if (snap.hasError) return const Text('No se pudo cargar el historial.');
              if (!snap.hasData) return const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()));
              final actions = snap.data!;
              if (actions.isEmpty) return const Text('Sin acciones de moderación.');
              return ListView(
                shrinkWrap: true,
                children: [
                  for (final a in actions)
                    ListTile(
                      key: ValueKey('users.action.${a.id}'),
                      leading: Icon(a.action == ModerationKind.suspend ? Icons.block : Icons.check_circle_outline),
                      title: Text(a.action == ModerationKind.suspend ? 'Suspendido' : 'Reactivado'),
                      subtitle: Text('${formatDate(a.createdAt)} · ${a.actorName}: ${a.reason}'),
                    ),
                ],
              );
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))],
      ),
    );
  }
}

/// Pide el motivo (3 a 500 caracteres) antes de suspender o reactivar.
class _ReasonDialog extends StatefulWidget {
  const _ReasonDialog({required this.user, required this.suspend});

  final ModeratedUser user;
  final bool suspend;

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  bool get _valid => _reason.text.trim().length >= 3;

  @override
  Widget build(BuildContext context) {
    final suspend = widget.suspend;
    return AlertDialog(
      title: Text(suspend ? 'Suspender a ${widget.user.displayName}' : 'Reactivar a ${widget.user.displayName}'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (suspend)
              Text(
                widget.user.role == UserRole.driver
                    ? 'Se cerrarán sus sesiones y quedará OFFLINE (si está en un viaje, podrá terminarlo).'
                    : 'Se cerrarán sus sesiones y no podrá volver a entrar.',
              ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('users.reason'),
              controller: _reason,
              autofocus: true,
              maxLength: 500,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Motivo (obligatorio)'),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          key: const Key('users.confirm'),
          style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
          onPressed: _valid ? () => Navigator.pop(context, _reason.text.trim()) : null,
          child: Text(suspend ? 'Suspender' : 'Reactivar'),
        ),
      ],
    );
  }
}

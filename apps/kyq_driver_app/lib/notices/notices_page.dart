import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ui/kyq_ui.dart';

import 'notices_cubit.dart';

/// Pantalla a la que lleva cada tipo de aviso.
String? noticeRoute(String kind) {
  if (kind.startsWith('doc_')) return '/onboarding/documents';
  if (kind.startsWith('sub_') || kind.startsWith('payment_')) return '/subscription';
  return null;
}

IconData _icon(String kind) {
  if (kind.startsWith('doc_')) return Icons.description_outlined;
  if (kind.startsWith('sub_') || kind.startsWith('payment_')) return Icons.payments_outlined;
  return Icons.notifications_outlined;
}

/// Avisos del conductor, recientes primero (T024).
class NoticesPage extends StatelessWidget {
  const NoticesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<NoticesCubit>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Avisos'),
        actions: [
          BlocSelector<NoticesCubit, NoticesState, int>(
            selector: (s) => s.unread,
            builder: (context, unread) => unread == 0
                ? const SizedBox.shrink()
                : TextButton(onPressed: cubit.markAllRead, child: const Text('Marcar leídos')),
          ),
        ],
      ),
      body: BlocBuilder<NoticesCubit, NoticesState>(
        builder: (context, state) {
          if (state.notices.isEmpty) {
            return state.loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: cubit.load,
                    child: ListView(
                      padding: const EdgeInsets.all(32),
                      children: const [Text('No tienes avisos.', textAlign: TextAlign.center)],
                    ),
                  );
          }
          return RefreshIndicator(
            onRefresh: cubit.load,
            child: ListView.separated(
              itemCount: state.notices.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) => _NoticeTile(notice: state.notices[i]),
            ),
          );
        },
      ),
    );
  }
}

class _NoticeTile extends StatelessWidget {
  const _NoticeTile({required this.notice});

  final Notice notice;

  @override
  Widget build(BuildContext context) {
    final unread = notice.readAt == null;
    final route = noticeRoute(notice.kind);
    return ListTile(
      key: Key('notice.${notice.id}'),
      leading: Badge(isLabelVisible: unread, smallSize: 10, child: Icon(_icon(notice.kind))),
      title: Text(notice.title, style: unread ? const TextStyle(fontWeight: FontWeight.bold) : null),
      subtitle: Text([if (notice.body.isNotEmpty) notice.body, formatDate(notice.createdAt)].join('\n')),
      isThreeLine: notice.body.isNotEmpty,
      onTap: () {
        context.read<NoticesCubit>().markRead(notice.id);
        if (route != null) context.push(route);
      },
    );
  }
}

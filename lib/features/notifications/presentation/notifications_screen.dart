import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hanpay_mobil/core/network/api_exception.dart';
import 'package:hanpay_mobil/features/notifications/data/notification_repository.dart';
import 'package:hanpay_mobil/shared/models/notification_model.dart';
import 'package:hanpay_mobil/shared/widgets/async_views.dart';
import 'package:intl/intl.dart';

final notificationsListProvider = FutureProvider.autoDispose<List<AppNotificationDto>>((ref) {
  return ref.watch(notificationRepositoryProvider).list(pageSize: 100);
});

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationsListProvider);
    final dateFmt = DateFormat('dd.MM.yyyy HH:mm');

    return async.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(notificationsListProvider),
      ),
      data: (items) => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(notificationsListProvider);
          ref.invalidate(unreadNotificationCountProvider);
        },
        child: items.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('Bildirim yok.')),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final n = items[index];
                  return Card(
                    color: n.isRead ? null : Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.25),
                    child: ListTile(
                      title: Text(n.title.isNotEmpty ? n.title : n.eventKey),
                      subtitle: Text('${n.message}\n${dateFmt.format(n.createdAt.toLocal())}'),
                      isThreeLine: true,
                      trailing: n.isRead ? null : const Icon(Icons.circle, size: 10, color: Colors.blue),
                      onTap: () async {
                        if (!n.isRead) {
                          try {
                            await ref.read(notificationRepositoryProvider).markRead(n.id);
                            ref.invalidate(notificationsListProvider);
                            ref.invalidate(unreadNotificationCountProvider);
                          } on ApiException catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                            }
                          }
                        }
                        if (n.link != null && n.link!.isNotEmpty && context.mounted) {
                          final link = n.link!;
                          if (link.startsWith('/')) {
                            context.go(link);
                          }
                        }
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hanpay_mobil/features/agent/data/agent_repository.dart';
import 'package:hanpay_mobil/shared/widgets/async_views.dart';

final agentUsersProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(agentRepositoryProvider).getUsers();
});

class AgentUsersScreen extends ConsumerWidget {
  const AgentUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(agentUsersProvider);
    return async.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(agentUsersProvider)),
      data: (users) {
        if (users.isEmpty) return const Center(child: Text('Kullanıcı bulunamadı.'));
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(agentUsersProvider),
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: users.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final u = users[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text(u.fullName.isNotEmpty ? u.fullName[0] : '?')),
                  title: Text(u.fullName),
                  subtitle: Text('${u.email}\n${u.role}'),
                  isThreeLine: true,
                  trailing: Icon(
                    u.isActive ? Icons.check_circle_outline : Icons.block,
                    color: u.isActive ? Colors.green : Colors.grey,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

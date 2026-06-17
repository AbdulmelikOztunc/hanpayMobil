import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hanpay_mobil/core/i18n/translator_ext.dart';
import 'package:hanpay_mobil/core/theme/app_colors.dart';

class AdminOperationsHubScreen extends ConsumerWidget {
  const AdminOperationsHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final shortcuts = [
      _Shortcut(
        titleKey: 'nav_requests',
        subtitleKey: 'mobile_admin_ops_requests_desc',
        icon: Icons.inbox_outlined,
        path: '/admin/requests',
      ),
      _Shortcut(
        titleKey: 'nav_transfers',
        subtitleKey: 'mobile_admin_ops_transfers_desc',
        icon: Icons.swap_horiz,
        path: '/admin/transfers',
      ),
      _Shortcut(
        titleKey: 'nav_users',
        subtitleKey: 'mobile_admin_ops_users_desc',
        icon: Icons.people_outline,
        path: '/admin/users',
      ),
      _Shortcut(
        titleKey: 'nav_agents',
        subtitleKey: 'mobile_admin_ops_agents_desc',
        icon: Icons.storefront_outlined,
        path: '/admin/agents',
      ),
      _Shortcut(
        titleKey: 'nav_distributors',
        subtitleKey: 'mobile_admin_ops_distributors_desc',
        icon: Icons.business_outlined,
        path: '/admin/distributors',
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(ref.tw('nav_group_operations'), style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          ref.tw('mobile_admin_ops_intro'),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        for (final item in shortcuts) ...[
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.lightPrimary.withValues(alpha: 0.12),
                foregroundColor: AppColors.lightPrimary,
                child: Icon(item.icon),
              ),
              title: Text(ref.tw(item.titleKey)),
              subtitle: Text(ref.tw(item.subtitleKey)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go(item.path),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _Shortcut {
  const _Shortcut({
    required this.titleKey,
    required this.subtitleKey,
    required this.icon,
    required this.path,
  });

  final String titleKey;
  final String subtitleKey;
  final IconData icon;
  final String path;
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hanpay_mobil/features/auth/presentation/auth_controller.dart';
import 'package:hanpay_mobil/shared/models/role.dart';

class _NavItem {
  const _NavItem({required this.icon, required this.label, required this.path});
  final IconData icon;
  final String label;
  final String path;
}

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child, required this.role});

  final Widget child;
  final AppRole role;

  List<_NavItem> _items() {
    if (role.isAgent) {
      return const [
        _NavItem(icon: Icons.dashboard_outlined, label: 'Dashboard', path: '/agent/dashboard'),
        _NavItem(icon: Icons.swap_horiz, label: 'Havaleler', path: '/agent/transfers'),
        _NavItem(icon: Icons.person_outline, label: 'Profil', path: '/profile'),
      ];
    }
    if (role.isDistributor) {
      return const [
        _NavItem(icon: Icons.dashboard_outlined, label: 'Dashboard', path: '/distributor/dashboard'),
        _NavItem(icon: Icons.inbox_outlined, label: 'Havaleler', path: '/distributor/transfers'),
        _NavItem(icon: Icons.person_outline, label: 'Profil', path: '/profile'),
      ];
    }
    return const [
      _NavItem(icon: Icons.dashboard_outlined, label: 'Dashboard', path: '/admin/dashboard'),
      _NavItem(icon: Icons.person_outline, label: 'Profil', path: '/profile'),
    ];
  }

  int _selectedIndex(BuildContext context, List<_NavItem> items) {
    final path = GoRouterState.of(context).uri.path;
    for (var i = items.length - 1; i >= 0; i--) {
      if (path.startsWith(items[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).session;
    final items = _items();
    final index = _selectedIndex(context, items);

    return Scaffold(
      appBar: AppBar(
        title: const Text('HANPAY'),
        actions: [
          if (session != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Text(session.fullName, style: Theme.of(context).textTheme.bodySmall),
              ),
            ),
          IconButton(
            tooltip: 'Çıkış',
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => context.go(items[i].path),
        destinations: [
          for (final item in items)
            NavigationDestination(icon: Icon(item.icon), label: item.label),
        ],
      ),
    );
  }
}

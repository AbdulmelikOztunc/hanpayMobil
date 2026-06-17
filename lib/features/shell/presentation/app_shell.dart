import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hanpay_mobil/core/i18n/translator_ext.dart';
import 'package:hanpay_mobil/core/navigation/app_nav_config.dart';
import 'package:hanpay_mobil/core/theme/app_colors.dart';
import 'package:hanpay_mobil/features/auth/presentation/auth_controller.dart';
import 'package:hanpay_mobil/shared/models/role.dart';
import 'package:hanpay_mobil/shared/widgets/brand_logo.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child, required this.role});

  final Widget child;
  final AppRole role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).session;
    final permissions = session?.permissions ?? const <String>[];
    final bottomItems = bottomNavItems(role, permissions);
    final drawerGroups = drawerNavGroups(role, permissions);
    final path = GoRouterState.of(context).uri.path;
    final index = selectedBottomIndex(path, bottomItems);
    final pageTitleKey = titleKeyForPath(path, role, permissions);

    return Scaffold(
      appBar: AppBar(
        leading: drawerGroups.isEmpty
            ? null
            : Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BrandLogo(height: 28, compact: true),
            if (pageTitleKey != null)
              Text(
                ref.tw(pageTitleKey),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
          ],
        ),
      ),
      drawer: drawerGroups.isEmpty
          ? null
          : Drawer(
              child: SafeArea(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    if (session != null)
                      UserAccountsDrawerHeader(
                        margin: EdgeInsets.zero,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.lightPrimary.withValues(alpha: 0.12),
                              AppColors.payBlue.withValues(alpha: 0.08),
                            ],
                          ),
                        ),
                        currentAccountPicture: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: Text(
                            session.fullName.isNotEmpty
                                ? session.fullName.characters.first.toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        accountName: Text(session.fullName),
                        accountEmail: Text(session.email),
                      ),
                    for (final group in drawerGroups) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          ref.tw(group.titleKey),
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: AppColors.lightPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      for (final item in group.items)
                        ListTile(
                          leading: Icon(item.icon),
                          title: Text(ref.tw(item.titleKey)),
                          selected: isNavItemActive(path, item),
                          onTap: () {
                            Navigator.of(context).pop();
                            context.go(item.path);
                          },
                        ),
                      const Divider(height: 1),
                    ],
                  ],
                ),
              ),
            ),
      body: child,
      floatingActionButton: role.isAgent && path.startsWith('/agent/transfers')
          ? FloatingActionButton.extended(
              onPressed: () => context.go('/agent/transfers/create'),
              icon: const Icon(Icons.add),
              label: Text(ref.tw('nav_create_transfer')),
              backgroundColor: AppColors.lightPrimary,
              foregroundColor: Colors.white,
            )
          : null,
      bottomNavigationBar: bottomItems.isEmpty
          ? null
          : NavigationBar(
              selectedIndex: index.clamp(0, bottomItems.length - 1),
              onDestinationSelected: (i) => context.go(bottomItems[i].path),
              destinations: [
                for (final item in bottomItems)
                  NavigationDestination(
                    icon: Icon(item.icon),
                    label: ref.tw(item.titleKey),
                  ),
              ],
            ),
    );
  }
}

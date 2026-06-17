import 'package:flutter/material.dart';
import 'package:hanpay_mobil/shared/models/role.dart';

enum NavPlacement { bottom, drawer }

class AppNavItem {
  const AppNavItem({
    required this.titleKey,
    required this.path,
    required this.icon,
    this.placement = NavPlacement.bottom,
    this.roles,
    this.permissions,
    this.activePrefix = false,
  });

  final String titleKey;
  final String path;
  final IconData icon;
  final NavPlacement placement;
  final List<AppRole>? roles;
  final List<String>? permissions;
  final bool activePrefix;
}

class AppNavGroup {
  const AppNavGroup({
    required this.titleKey,
    required this.items,
  });

  final String titleKey;
  final List<AppNavItem> items;
}

bool _permissionVisible(
  List<String>? required,
  List<String> userPermissions,
  AppRole role,
) {
  if (required == null || required.isEmpty) return true;
  if (required.any(userPermissions.contains)) return true;
  if (userPermissions.isEmpty) {
    return required.any((p) {
      if (p == 'distributor.primPackage.read') {
        return role == AppRole.admin || role == AppRole.assistantAdmin;
      }
      if (p == 'distributor.primPackage.manage') return role == AppRole.admin;
      if (p == 'distributor.read') {
        return role == AppRole.distributorManager || role == AppRole.distributorUser;
      }
      return false;
    });
  }
  return false;
}

bool _itemVisible(AppNavItem item, AppRole role, List<String> permissions) {
  if (item.roles != null && !item.roles!.contains(role)) return false;
  return _permissionVisible(item.permissions, permissions, role);
}

List<AppNavItem> filterNavItems(
  List<AppNavItem> items,
  AppRole role,
  List<String> permissions,
) {
  return items.where((i) => _itemVisible(i, role, permissions)).toList();
}

List<AppNavGroup> filterNavGroups(
  List<AppNavGroup> groups,
  AppRole role,
  List<String> permissions,
) {
  return groups
      .map((group) {
        final visible = filterNavItems(group.items, role, permissions);
        if (visible.isEmpty) return null;
        return AppNavGroup(titleKey: group.titleKey, items: visible);
      })
      .whereType<AppNavGroup>()
      .toList();
}

List<AppNavItem> bottomNavItems(AppRole role, List<String> permissions) {
  return filterNavItems(_allItems(role), role, permissions)
      .where((i) => i.placement == NavPlacement.bottom)
      .toList();
}

List<AppNavGroup> drawerNavGroups(AppRole role, List<String> permissions) {
  return filterNavGroups(_drawerGroups(role), role, permissions);
}

List<AppNavItem> _allItems(AppRole role) {
  return [
    ...bottomItemsFor(role),
    ..._drawerGroups(role).expand((g) => g.items),
  ];
}

List<AppNavItem> bottomItemsFor(AppRole role) {
  if (role.isAgent) {
    return const [
      AppNavItem(
        titleKey: 'nav_dashboard',
        path: '/agent/dashboard',
        icon: Icons.dashboard_outlined,
      ),
      AppNavItem(
        titleKey: 'nav_transfer_history',
        path: '/agent/transfers',
        icon: Icons.swap_horiz,
        activePrefix: true,
      ),
      AppNavItem(
        titleKey: 'nav_agent_balance',
        path: '/agent/balance',
        icon: Icons.account_balance_wallet_outlined,
      ),
      AppNavItem(
        titleKey: 'layout_my_profile',
        path: '/profile',
        icon: Icons.person_outline,
      ),
    ];
  }
  if (role.isDistributor) {
    return const [
      AppNavItem(
        titleKey: 'nav_dashboard',
        path: '/distributor/dashboard',
        icon: Icons.dashboard_outlined,
      ),
      AppNavItem(
        titleKey: 'nav_incoming_transfers',
        path: '/distributor/transfers',
        icon: Icons.inbox_outlined,
        activePrefix: true,
      ),
      AppNavItem(
        titleKey: 'nav_paid_transfers',
        path: '/distributor/history',
        icon: Icons.history,
        activePrefix: true,
      ),
      AppNavItem(
        titleKey: 'layout_my_profile',
        path: '/profile',
        icon: Icons.person_outline,
      ),
    ];
  }
  if (role.isAdmin) {
    return const [
      AppNavItem(
        titleKey: 'nav_admin_dashboard',
        path: '/admin/dashboard',
        icon: Icons.dashboard_outlined,
      ),
      AppNavItem(
        titleKey: 'nav_group_operations',
        path: '/admin/operations',
        icon: Icons.work_outline,
      ),
      AppNavItem(
        titleKey: 'layout_my_profile',
        path: '/profile',
        icon: Icons.person_outline,
      ),
    ];
  }
  return const [];
}

List<AppNavGroup> _drawerGroups(AppRole role) {
  if (role.isAgent) {
    return const [
      AppNavGroup(
        titleKey: 'nav_transfers_group',
        items: [
          AppNavItem(
            titleKey: 'nav_create_transfer',
            path: '/agent/transfers/create',
            icon: Icons.add_circle_outline,
            placement: NavPlacement.drawer,
          ),
        ],
      ),
      AppNavGroup(
        titleKey: 'nav_group_account_team',
        items: [
          AppNavItem(
            titleKey: 'nav_agent_users',
            path: '/agent/users',
            icon: Icons.group_outlined,
            placement: NavPlacement.drawer,
            roles: [AppRole.agentManager],
          ),
        ],
      ),
      AppNavGroup(
        titleKey: 'nav_group_insights',
        items: [
          AppNavItem(
            titleKey: 'nav_monthly_transfer_volume',
            path: '/agent/insights/monthly-transfer-volume',
            icon: Icons.bar_chart_outlined,
            placement: NavPlacement.drawer,
          ),
          AppNavItem(
            titleKey: 'nav_insights_statistics',
            path: '/agent/insights/statistics',
            icon: Icons.pie_chart_outline,
            placement: NavPlacement.drawer,
          ),
          AppNavItem(
            titleKey: 'nav_transfer_report',
            path: '/agent/reports/transfers',
            icon: Icons.description_outlined,
            placement: NavPlacement.drawer,
          ),
        ],
      ),
    ];
  }
  if (role.isDistributor) {
    return const [
      AppNavGroup(
        titleKey: 'nav_group_account_dist',
        items: [
          AppNavItem(
            titleKey: 'nav_distributor_balance',
            path: '/distributor/balance',
            icon: Icons.account_balance_wallet_outlined,
            placement: NavPlacement.drawer,
          ),
          AppNavItem(
            titleKey: 'nav_distributor_prims',
            path: '/distributor/prims',
            icon: Icons.card_giftcard_outlined,
            placement: NavPlacement.drawer,
            permissions: ['distributor.read'],
          ),
          AppNavItem(
            titleKey: 'admin_dist_detail_tab_users',
            path: '/distributor/users',
            icon: Icons.group_outlined,
            placement: NavPlacement.drawer,
            roles: [AppRole.distributorManager],
          ),
        ],
      ),
      AppNavGroup(
        titleKey: 'nav_group_insights',
        items: [
          AppNavItem(
            titleKey: 'nav_monthly_transfer_volume',
            path: '/distributor/insights/monthly-transfer-volume',
            icon: Icons.bar_chart_outlined,
            placement: NavPlacement.drawer,
          ),
          AppNavItem(
            titleKey: 'nav_insights_statistics',
            path: '/distributor/insights/statistics',
            icon: Icons.pie_chart_outline,
            placement: NavPlacement.drawer,
          ),
          AppNavItem(
            titleKey: 'nav_transfer_report',
            path: '/distributor/reports/transfers',
            icon: Icons.description_outlined,
            placement: NavPlacement.drawer,
          ),
        ],
      ),
    ];
  }
  if (role.isAdmin) {
    return const [
      AppNavGroup(
        titleKey: 'nav_group_partners',
        items: [
          AppNavItem(
            titleKey: 'nav_agents',
            path: '/admin/agents',
            icon: Icons.storefront_outlined,
            placement: NavPlacement.drawer,
            activePrefix: true,
          ),
          AppNavItem(
            titleKey: 'nav_distributors',
            path: '/admin/distributors',
            icon: Icons.business_outlined,
            placement: NavPlacement.drawer,
            activePrefix: true,
          ),
          AppNavItem(
            titleKey: 'nav_prim_packages',
            path: '/admin/prim-packages',
            icon: Icons.inventory_2_outlined,
            placement: NavPlacement.drawer,
            permissions: ['distributor.primPackage.read'],
          ),
          AppNavItem(
            titleKey: 'nav_states',
            path: '/admin/states',
            icon: Icons.map_outlined,
            placement: NavPlacement.drawer,
          ),
        ],
      ),
      AppNavGroup(
        titleKey: 'nav_group_operations',
        items: [
          AppNavItem(
            titleKey: 'nav_users',
            path: '/admin/users',
            icon: Icons.people_outline,
            placement: NavPlacement.drawer,
            activePrefix: true,
          ),
          AppNavItem(
            titleKey: 'nav_transfers',
            path: '/admin/transfers',
            icon: Icons.swap_horiz,
            placement: NavPlacement.drawer,
            activePrefix: true,
          ),
          AppNavItem(
            titleKey: 'nav_requests',
            path: '/admin/requests',
            icon: Icons.inbox_outlined,
            placement: NavPlacement.drawer,
          ),
          AppNavItem(
            titleKey: 'nav_prim_records',
            path: '/admin/prim-records',
            icon: Icons.list_alt_outlined,
            placement: NavPlacement.drawer,
            permissions: ['distributor.primPackage.read'],
          ),
        ],
      ),
      AppNavGroup(
        titleKey: 'nav_central_cashbox',
        items: [
          AppNavItem(
            titleKey: 'central_cashbox_title',
            path: '/admin/central-cashbox',
            icon: Icons.account_balance_outlined,
            placement: NavPlacement.drawer,
            roles: [AppRole.admin],
          ),
          AppNavItem(
            titleKey: 'nav_cashbox',
            path: '/admin/cashbox',
            icon: Icons.wallet_outlined,
            placement: NavPlacement.drawer,
          ),
        ],
      ),
      AppNavGroup(
        titleKey: 'nav_group_insights',
        items: [
          AppNavItem(
            titleKey: 'nav_monthly_transfer_volume',
            path: '/admin/insights/monthly-transfer-volume',
            icon: Icons.bar_chart_outlined,
            placement: NavPlacement.drawer,
          ),
          AppNavItem(
            titleKey: 'nav_insights_statistics',
            path: '/admin/insights/statistics',
            icon: Icons.pie_chart_outline,
            placement: NavPlacement.drawer,
          ),
          AppNavItem(
            titleKey: 'nav_system_reports',
            path: '/admin/reports',
            icon: Icons.assessment_outlined,
            placement: NavPlacement.drawer,
          ),
        ],
      ),
      AppNavGroup(
        titleKey: 'nav_group_access',
        items: [
          AppNavItem(
            titleKey: 'nav_roles_permissions',
            path: '/admin/roles',
            icon: Icons.shield_outlined,
            placement: NavPlacement.drawer,
          ),
        ],
      ),
      AppNavGroup(
        titleKey: 'nav_admin_settings',
        items: [
          AppNavItem(
            titleKey: 'nav_admin_settings',
            path: '/admin/settings',
            icon: Icons.settings_outlined,
            placement: NavPlacement.drawer,
          ),
        ],
      ),
    ];
  }
  return const [];
}

String? titleKeyForPath(String path, AppRole role, List<String> permissions) {
  for (final item in _allItems(role)) {
    if (!_itemVisible(item, role, permissions)) continue;
    if (item.activePrefix ? path.startsWith(item.path) : path == item.path) {
      return item.titleKey;
    }
  }
  for (final group in _drawerGroups(role)) {
    for (final item in group.items) {
      if (!_itemVisible(item, role, permissions)) continue;
      if (item.activePrefix ? path.startsWith(item.path) : path == item.path) {
        return item.titleKey;
      }
    }
  }
  return null;
}

int selectedBottomIndex(String path, List<AppNavItem> items) {
  for (var i = items.length - 1; i >= 0; i--) {
    final item = items[i];
    final matches = item.activePrefix ? path.startsWith(item.path) : path == item.path;
    if (matches) return i;
  }
  return 0;
}

bool isNavItemActive(String path, AppNavItem item) {
  return item.activePrefix ? path.startsWith(item.path) : path == item.path;
}

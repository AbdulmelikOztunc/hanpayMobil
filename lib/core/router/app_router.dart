import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hanpay_mobil/features/auth/presentation/auth_controller.dart';
import 'package:hanpay_mobil/features/auth/presentation/login_screen.dart';
import 'package:hanpay_mobil/features/admin/presentation/admin_operations_hub_screen.dart';
import 'package:hanpay_mobil/features/dashboard/presentation/admin_dashboard_screen.dart';
import 'package:hanpay_mobil/features/dashboard/presentation/agent_dashboard_screen.dart';
import 'package:hanpay_mobil/features/dashboard/presentation/distributor_dashboard_screen.dart';
import 'package:hanpay_mobil/features/profile/presentation/profile_screen.dart';
import 'package:hanpay_mobil/features/shell/presentation/app_shell.dart';
import 'package:hanpay_mobil/features/transfers/presentation/agent_transfer_detail_screen.dart';
import 'package:hanpay_mobil/features/transfers/presentation/agent_transfer_list_screen.dart';
import 'package:hanpay_mobil/features/transfers/presentation/distributor_transfer_detail_screen.dart';
import 'package:hanpay_mobil/features/transfers/presentation/distributor_transfers_screen.dart';
import 'package:hanpay_mobil/shared/models/role.dart';
import 'package:hanpay_mobil/shared/widgets/coming_soon_screen.dart';

final _routerRefreshProvider = Provider<ValueNotifier<int>>((ref) {
  final notifier = ValueNotifier(0);
  ref.listen(authControllerProvider, (_, _) => notifier.value++);
  ref.onDispose(notifier.dispose);
  return notifier;
});

Widget _shell(Ref ref, Widget child) =>
    AppShell(role: ref.read(authControllerProvider).session!.role, child: child);

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(_routerRefreshProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      if (auth.isBootstrapping) return null;

      final loggedIn = auth.isAuthenticated;
      final path = state.uri.path;
      final onLogin = path == '/login';

      if (!loggedIn) {
        return onLogin ? null : '/login';
      }

      final role = auth.session!.role;
      final home = postLoginPath(role);

      if (onLogin) return home;

      if (path.startsWith('/agent') && !role.isAgent) return home;
      if (path.startsWith('/distributor') && !role.isDistributor) return home;
      if (path.startsWith('/admin') && !role.isAdmin) return home;

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),

      // Agent
      GoRoute(
        path: '/agent/dashboard',
        builder: (_, _) => _shell(ref, const AgentDashboardScreen()),
      ),
      GoRoute(
        path: '/agent/transfers',
        builder: (_, _) => _shell(ref, const AgentTransferListScreen()),
        routes: [
          GoRoute(
            path: 'create',
            builder: (_, _) =>
                _shell(ref, const ComingSoonScreen(titleKey: 'nav_create_transfer')),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return AgentTransferDetailScreen(id: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/agent/balance',
        builder: (_, _) => _shell(ref, const ComingSoonScreen(titleKey: 'nav_agent_balance')),
      ),
      GoRoute(
        path: '/agent/users',
        builder: (_, _) => _shell(ref, const ComingSoonScreen(titleKey: 'nav_agent_users')),
      ),
      GoRoute(
        path: '/agent/insights/monthly-transfer-volume',
        builder: (_, _) =>
            _shell(ref, const ComingSoonScreen(titleKey: 'nav_monthly_transfer_volume')),
      ),
      GoRoute(
        path: '/agent/insights/statistics',
        builder: (_, _) =>
            _shell(ref, const ComingSoonScreen(titleKey: 'nav_insights_statistics')),
      ),
      GoRoute(
        path: '/agent/reports/transfers',
        builder: (_, _) => _shell(ref, const ComingSoonScreen(titleKey: 'nav_transfer_report')),
      ),

      // Distributor
      GoRoute(
        path: '/distributor/dashboard',
        builder: (_, _) => _shell(ref, const DistributorDashboardScreen()),
      ),
      GoRoute(
        path: '/distributor/transfers',
        builder: (_, _) => _shell(ref, const DistributorTransfersScreen()),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return DistributorTransferDetailScreen(id: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/distributor/history',
        builder: (_, _) => _shell(ref, const ComingSoonScreen(titleKey: 'nav_paid_transfers')),
      ),
      GoRoute(
        path: '/distributor/balance',
        builder: (_, _) =>
            _shell(ref, const ComingSoonScreen(titleKey: 'nav_distributor_balance')),
      ),
      GoRoute(
        path: '/distributor/prims',
        builder: (_, _) =>
            _shell(ref, const ComingSoonScreen(titleKey: 'nav_distributor_prims')),
      ),
      GoRoute(
        path: '/distributor/users',
        builder: (_, _) =>
            _shell(ref, const ComingSoonScreen(titleKey: 'admin_dist_detail_tab_users')),
      ),
      GoRoute(
        path: '/distributor/insights/monthly-transfer-volume',
        builder: (_, _) =>
            _shell(ref, const ComingSoonScreen(titleKey: 'nav_monthly_transfer_volume')),
      ),
      GoRoute(
        path: '/distributor/insights/statistics',
        builder: (_, _) =>
            _shell(ref, const ComingSoonScreen(titleKey: 'nav_insights_statistics')),
      ),
      GoRoute(
        path: '/distributor/reports/transfers',
        builder: (_, _) => _shell(ref, const ComingSoonScreen(titleKey: 'nav_transfer_report')),
      ),

      // Admin
      GoRoute(
        path: '/admin/dashboard',
        builder: (_, _) => _shell(ref, const AdminDashboardScreen()),
      ),
      GoRoute(
        path: '/admin/operations',
        builder: (_, _) => _shell(ref, const AdminOperationsHubScreen()),
      ),
      GoRoute(
        path: '/admin/agents',
        builder: (_, _) => _shell(ref, const ComingSoonScreen(titleKey: 'nav_agents')),
      ),
      GoRoute(
        path: '/admin/distributors',
        builder: (_, _) => _shell(ref, const ComingSoonScreen(titleKey: 'nav_distributors')),
      ),
      GoRoute(
        path: '/admin/users',
        builder: (_, _) => _shell(ref, const ComingSoonScreen(titleKey: 'nav_users')),
      ),
      GoRoute(
        path: '/admin/transfers',
        builder: (_, _) => _shell(ref, const ComingSoonScreen(titleKey: 'nav_transfers')),
      ),
      GoRoute(
        path: '/admin/requests',
        builder: (_, _) => _shell(ref, const ComingSoonScreen(titleKey: 'nav_requests')),
      ),
      GoRoute(
        path: '/admin/states',
        builder: (_, _) => _shell(ref, const ComingSoonScreen(titleKey: 'nav_states')),
      ),
      GoRoute(
        path: '/admin/prim-packages',
        builder: (_, _) => _shell(ref, const ComingSoonScreen(titleKey: 'nav_prim_packages')),
      ),
      GoRoute(
        path: '/admin/prim-records',
        builder: (_, _) => _shell(ref, const ComingSoonScreen(titleKey: 'nav_prim_records')),
      ),
      GoRoute(
        path: '/admin/central-cashbox',
        builder: (_, _) =>
            _shell(ref, const ComingSoonScreen(titleKey: 'central_cashbox_title')),
      ),
      GoRoute(
        path: '/admin/cashbox',
        builder: (_, _) => _shell(ref, const ComingSoonScreen(titleKey: 'nav_cashbox')),
      ),
      GoRoute(
        path: '/admin/insights/monthly-transfer-volume',
        builder: (_, _) =>
            _shell(ref, const ComingSoonScreen(titleKey: 'nav_monthly_transfer_volume')),
      ),
      GoRoute(
        path: '/admin/insights/statistics',
        builder: (_, _) =>
            _shell(ref, const ComingSoonScreen(titleKey: 'nav_insights_statistics')),
      ),
      GoRoute(
        path: '/admin/reports',
        builder: (_, _) => _shell(ref, const ComingSoonScreen(titleKey: 'nav_system_reports')),
      ),
      GoRoute(
        path: '/admin/roles',
        builder: (_, _) =>
            _shell(ref, const ComingSoonScreen(titleKey: 'nav_roles_permissions')),
      ),
      GoRoute(
        path: '/admin/settings',
        builder: (_, _) => _shell(ref, const ComingSoonScreen(titleKey: 'nav_admin_settings')),
      ),

      GoRoute(
        path: '/profile',
        builder: (_, _) => _shell(ref, const ProfileScreen()),
      ),
    ],
  );
});

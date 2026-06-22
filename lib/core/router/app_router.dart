import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hanpay_mobil/features/admin/presentation/admin_operations_hub_screen.dart';
import 'package:hanpay_mobil/features/admin/presentation/admin_screens.dart';
import 'package:hanpay_mobil/features/admin/presentation/admin_partner_detail_screens.dart';
import 'package:hanpay_mobil/features/admin/presentation/admin_prim_screens.dart';
import 'package:hanpay_mobil/features/admin/presentation/admin_user_detail_screen.dart';
import 'package:hanpay_mobil/features/agent/presentation/agent_balance_screen.dart';
import 'package:hanpay_mobil/features/agent/presentation/agent_users_screen.dart';
import 'package:hanpay_mobil/features/agent/presentation/transfer_form_screens.dart';
import 'package:hanpay_mobil/features/auth/presentation/auth_controller.dart';
import 'package:hanpay_mobil/features/auth/presentation/login_screen.dart';
import 'package:hanpay_mobil/features/dashboard/presentation/admin_dashboard_screen.dart';
import 'package:hanpay_mobil/features/dashboard/presentation/agent_dashboard_screen.dart';
import 'package:hanpay_mobil/features/dashboard/presentation/distributor_dashboard_screen.dart';
import 'package:hanpay_mobil/features/distributor/presentation/distributor_account_screens.dart';
import 'package:hanpay_mobil/features/distributor/presentation/distributor_history_screen.dart';
import 'package:hanpay_mobil/features/profile/presentation/profile_screen.dart';
import 'package:hanpay_mobil/features/shell/presentation/app_shell.dart';
import 'package:hanpay_mobil/features/transfers/presentation/agent_transfer_detail_screen.dart';
import 'package:hanpay_mobil/features/transfers/presentation/agent_transfer_list_screen.dart';
import 'package:hanpay_mobil/features/transfers/presentation/distributor_transfer_detail_screen.dart';
import 'package:hanpay_mobil/features/transfers/presentation/distributor_transfers_screen.dart';
import 'package:hanpay_mobil/shared/models/role.dart';
import 'package:hanpay_mobil/features/insights/presentation/insights_screens.dart';
import 'package:hanpay_mobil/features/notifications/presentation/notifications_screen.dart';
import 'package:hanpay_mobil/features/auth/presentation/forgot_password_screen.dart';

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
      final onForgot = path == '/forgot-password';

      if (!loggedIn) return (onLogin || onForgot) ? null : '/login';

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
      GoRoute(path: '/forgot-password', builder: (_, _) => const ForgotPasswordScreen()),
      GoRoute(path: '/notifications', builder: (_, _) => _shell(ref, const NotificationsScreen())),

      // Agent
      GoRoute(path: '/agent/dashboard', builder: (_, _) => _shell(ref, const AgentDashboardScreen())),
      GoRoute(
        path: '/agent/transfers',
        builder: (_, _) => _shell(ref, const AgentTransferListScreen()),
        routes: [
          GoRoute(path: 'create', builder: (_, _) => _shell(ref, const CreateTransferScreen())),
          GoRoute(
            path: ':id/edit',
            builder: (_, state) => _shell(
              ref,
              EditTransferScreen(transferId: int.parse(state.pathParameters['id']!)),
            ),
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
      GoRoute(path: '/agent/balance', builder: (_, _) => _shell(ref, const AgentBalanceScreen())),
      GoRoute(path: '/agent/users', builder: (_, _) => _shell(ref, const AgentUsersScreen())),
      GoRoute(
        path: '/agent/insights/monthly-transfer-volume',
        builder: (_, _) => _shell(ref, const MonthlyTransferVolumeScreen()),
      ),
      GoRoute(
        path: '/agent/insights/statistics',
        builder: (_, _) => _shell(ref, const PaymentDistributionScreen()),
      ),
      GoRoute(
        path: '/agent/reports/transfers',
        builder: (_, _) => _shell(ref, const TransferReportScreen()),
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
      GoRoute(path: '/distributor/history', builder: (_, _) => _shell(ref, const DistributorHistoryScreen())),
      GoRoute(path: '/distributor/balance', builder: (_, _) => _shell(ref, const DistributorBalanceScreen())),
      GoRoute(path: '/distributor/prims', builder: (_, _) => _shell(ref, const DistributorPrimsScreen())),
      GoRoute(path: '/distributor/users', builder: (_, _) => _shell(ref, const DistributorUsersScreen())),
      GoRoute(
        path: '/distributor/insights/monthly-transfer-volume',
        builder: (_, _) => _shell(ref, const MonthlyTransferVolumeScreen()),
      ),
      GoRoute(
        path: '/distributor/insights/statistics',
        builder: (_, _) => _shell(ref, const PaymentDistributionScreen()),
      ),
      GoRoute(
        path: '/distributor/reports/transfers',
        builder: (_, _) => _shell(ref, const TransferReportScreen()),
      ),

      // Admin
      GoRoute(path: '/admin/dashboard', builder: (_, _) => _shell(ref, const AdminDashboardScreen())),
      GoRoute(path: '/admin/operations', builder: (_, _) => _shell(ref, const AdminOperationsHubScreen())),
      GoRoute(path: '/admin/requests', builder: (_, _) => _shell(ref, const AdminRequestsScreen())),
      GoRoute(path: '/admin/transfers', builder: (_, _) => _shell(ref, const AdminTransfersScreen())),
      GoRoute(
        path: '/admin/agents',
        builder: (_, _) => _shell(ref, const AdminAgentsScreen()),
        routes: [
          GoRoute(
            path: ':id',
            builder: (_, state) => AdminAgentDetailScreen(id: int.parse(state.pathParameters['id']!)),
          ),
        ],
      ),
      GoRoute(
        path: '/admin/distributors',
        builder: (_, _) => _shell(ref, const AdminDistributorsScreen()),
        routes: [
          GoRoute(
            path: ':id',
            builder: (_, state) => AdminDistributorDetailScreen(id: int.parse(state.pathParameters['id']!)),
          ),
        ],
      ),
      GoRoute(path: '/admin/users', builder: (_, _) => _shell(ref, const AdminUsersScreen()), routes: [
        GoRoute(
          path: ':id',
          builder: (_, state) => AdminUserDetailScreen(id: int.parse(state.pathParameters['id']!)),
        ),
      ]),
      GoRoute(path: '/admin/states', builder: (_, _) => _shell(ref, const AdminStatesScreen())),
      GoRoute(path: '/admin/prim-packages', builder: (_, _) => _shell(ref, const AdminPrimPackagesScreen())),
      GoRoute(path: '/admin/prim-records', builder: (_, _) => _shell(ref, const AdminPrimRecordsScreen())),
      GoRoute(path: '/admin/central-cashbox', builder: (_, _) => _shell(ref, const AdminCentralCashboxScreen())),
      GoRoute(path: '/admin/cashbox', builder: (_, _) => _shell(ref, const AdminCashboxScreen())),
      GoRoute(
        path: '/admin/insights/monthly-transfer-volume',
        builder: (_, _) => _shell(ref, const MonthlyTransferVolumeScreen()),
      ),
      GoRoute(
        path: '/admin/insights/statistics',
        builder: (_, _) => _shell(ref, const PaymentDistributionScreen()),
      ),
      GoRoute(
        path: '/admin/reports',
        builder: (_, _) => _shell(ref, const TransferReportScreen(showAdminFilters: true)),
      ),
      GoRoute(path: '/admin/roles', builder: (_, _) => _shell(ref, const AdminRolesScreen())),
      GoRoute(path: '/admin/settings', builder: (_, _) => _shell(ref, const AdminSettingsScreen())),

      GoRoute(path: '/profile', builder: (_, _) => _shell(ref, const ProfileScreen())),
    ],
  );
});

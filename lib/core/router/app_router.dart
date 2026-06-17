import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hanpay_mobil/features/auth/presentation/auth_controller.dart';
import 'package:hanpay_mobil/features/auth/presentation/login_screen.dart';
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

final _routerRefreshProvider = Provider<ValueNotifier<int>>((ref) {
  final notifier = ValueNotifier(0);
  ref.listen(authControllerProvider, (_, _) => notifier.value++);
  ref.onDispose(notifier.dispose);
  return notifier;
});

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(_routerRefreshProvider);

  AppRole currentRole() => ref.read(authControllerProvider).session!.role;

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
      GoRoute(
        path: '/agent/dashboard',
        builder: (_, _) => AppShell(role: currentRole(), child: const AgentDashboardScreen()),
      ),
      GoRoute(
        path: '/agent/transfers',
        builder: (_, _) => AppShell(role: currentRole(), child: const AgentTransferListScreen()),
        routes: [
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
        path: '/distributor/dashboard',
        builder: (_, _) =>
            AppShell(role: currentRole(), child: const DistributorDashboardScreen()),
      ),
      GoRoute(
        path: '/distributor/transfers',
        builder: (_, _) =>
            AppShell(role: currentRole(), child: const DistributorTransfersScreen()),
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
        path: '/admin/dashboard',
        builder: (_, _) => AppShell(role: currentRole(), child: const AdminDashboardScreen()),
      ),
      GoRoute(
        path: '/profile',
        builder: (_, _) => AppShell(role: currentRole(), child: const ProfileScreen()),
      ),
    ],
  );
});

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/cart/presentation/cart_screen.dart';
import '../../features/checkout/presentation/checkout_screen.dart';
import '../../features/menu/presentation/menu_screen.dart';
import '../../features/orders/presentation/order_tracking_screen.dart';
import '../../features/staff/application/staff_auth_controller.dart';
import '../../features/staff/domain/staff_user.dart';
import '../../features/staff/presentation/admin_branch_screen.dart';
import '../../features/staff/presentation/admin_dashboard_screen.dart';
import '../../features/staff/presentation/shift_close_screen.dart';
import '../../features/staff/presentation/staff_dashboard_screen.dart';
import '../../features/staff/presentation/staff_login_screen.dart';
import '../../features/subscription/presentation/subscription_screen.dart';
import 'client_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final location = state.matchedLocation;

      // Las rutas de la estación de tienda (empleado) son independientes
      // del login del cliente.
      if (location.startsWith('/staff')) return null;

      final loggedIn = ref.read(authControllerProvider) != null;
      final loggingIn = location == '/login';
      if (!loggedIn) return loggingIn ? null : '/login';
      if (loggingIn) return '/menu';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),

      // --- Cliente: pestañas con barra inferior ---
      StatefulShellRoute.indexedStack(
        builder: (_, __, navigationShell) =>
            ClientShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/menu', builder: (_, __) => const MenuScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/cart', builder: (_, __) => const CartScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/order',
                builder: (_, __) => const OrderTrackingScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/subscription',
                builder: (_, __) => const SubscriptionScreen(),
              ),
            ],
          ),
        ],
      ),

      // Checkout va por encima del shell (pantalla completa, sin barra).
      GoRoute(
        path: '/checkout',
        builder: (_, __) => const CheckoutScreen(),
      ),

      // --- Estación de tienda (empleado) ---
      GoRoute(
        path: '/staff',
        builder: (_, __) => const StaffGate(),
      ),
      GoRoute(
        path: '/staff/close',
        builder: (_, __) => const ShiftCloseScreen(),
      ),
      GoRoute(
        path: '/staff/branch/:id',
        builder: (_, state) =>
            AdminBranchScreen(branchId: state.pathParameters['id']!),
      ),
    ],
  );
});

/// Enruta la estación de tienda según el rol: sin sesión → login;
/// administrador → dashboard multi-sucursal; empleado → cola de su sucursal.
class StaffGate extends ConsumerWidget {
  const StaffGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staff = ref.watch(staffAuthControllerProvider);
    if (staff == null) return const StaffLoginScreen();
    return staff.role == StaffRole.admin
        ? const AdminDashboardScreen()
        : const StaffDashboardScreen();
  }
}

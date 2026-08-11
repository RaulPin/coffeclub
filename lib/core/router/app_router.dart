import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/cart/presentation/cart_screen.dart';
import '../../features/checkout/presentation/checkout_screen.dart';
import '../../features/menu/presentation/menu_screen.dart';
import '../../features/orders/presentation/order_tracking_screen.dart';
import '../../features/staff/application/shift_controller.dart';
import '../../features/staff/presentation/shift_close_screen.dart';
import '../../features/staff/presentation/staff_dashboard_screen.dart';
import '../../features/staff/presentation/staff_login_screen.dart';
import '../../features/subscription/presentation/subscription_screen.dart';

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
      GoRoute(
        path: '/menu',
        builder: (_, __) => const MenuScreen(),
      ),
      GoRoute(
        path: '/subscription',
        builder: (_, __) => const SubscriptionScreen(),
      ),
      GoRoute(
        path: '/cart',
        builder: (_, __) => const CartScreen(),
      ),
      GoRoute(
        path: '/checkout',
        builder: (_, __) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/order',
        builder: (_, __) => const OrderTrackingScreen(),
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
    ],
  );
});

/// Decide qué mostrar en la estación de tienda: si hay turno abierto muestra
/// el panel de pedidos, si no, la pantalla de inicio de turno.
class StaffGate extends ConsumerWidget {
  const StaffGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shift = ref.watch(shiftControllerProvider);
    return shift == null
        ? const StaffLoginScreen()
        : const StaffDashboardScreen();
  }
}

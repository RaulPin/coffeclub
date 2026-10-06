import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../auth/application/auth_controller.dart';
import 'cart_controller.dart';

/// Desglose de precio del carrito según el modelo de negocio de Barra:
/// el cliente paga el subtotal de productos + una cuota de servicio fija
/// (que se elimina para socios Barra+). Aparte, Barra cobra una comisión a la
/// cafetería sobre el subtotal (no la ve el cliente).
class CartPricing {
  const CartPricing({
    required this.subtotalCents,
    required this.serviceFeeCents,
    required this.totalCents,
    required this.isMember,
    required this.commissionCents,
    required this.cafeNetCents,
  });

  /// Subtotal de productos.
  final int subtotalCents;

  /// Cuota de servicio que paga el cliente (0 si es socio o carrito vacío).
  final int serviceFeeCents;

  /// Total que paga el cliente (subtotal + cuota de servicio).
  final int totalCents;

  /// Si el cliente es socio Barra+ (sin cuota de servicio).
  final bool isMember;

  /// Comisión de Barra a la cafetería (sobre el subtotal).
  final int commissionCents;

  /// Lo que recibe la cafetería (subtotal − comisión).
  final int cafeNetCents;
}

final cartPricingProvider = Provider<CartPricing>((ref) {
  final items = ref.watch(cartControllerProvider);
  final user = ref.watch(authControllerProvider);

  final subtotal = items.fold<int>(0, (sum, item) => sum + item.subtotalCents);
  final isMember = user?.isSubscriber ?? false;

  // Socios no pagan cuota de servicio; tampoco si el carrito está vacío.
  final fee = (subtotal == 0 || isMember) ? 0 : AppConfig.serviceFeeCents;

  final commission = (subtotal * AppConfig.platformCommissionRate).round();

  return CartPricing(
    subtotalCents: subtotal,
    serviceFeeCents: fee,
    totalCents: subtotal + fee,
    isMember: isMember,
    commissionCents: commission,
    cafeNetCents: subtotal - commission,
  );
});

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
    required this.paymentCostCents,
    required this.platformNetCents,
  });

  /// Subtotal de productos.
  final int subtotalCents;

  /// Cuota de servicio que paga el cliente (reducida para socios, 0 si el
  /// carrito está vacío).
  final int serviceFeeCents;

  /// Total que paga el cliente (subtotal + cuota de servicio).
  final int totalCents;

  /// Si el cliente es socio Barra+ (cuota de servicio reducida).
  final bool isMember;

  /// Comisión de Barra a la cafetería (sobre el subtotal).
  final int commissionCents;

  /// Lo que recibe la cafetería (subtotal − comisión).
  final int cafeNetCents;

  /// Costo estimado de procesar el cobro con Mercado Pago (uso interno).
  final int paymentCostCents;

  /// Ganancia neta estimada de Barra por este pedido:
  /// comisión + cuota de servicio − costo de procesamiento.
  final int platformNetCents;
}

final cartPricingProvider = Provider<CartPricing>((ref) {
  final items = ref.watch(cartControllerProvider);
  final user = ref.watch(authControllerProvider);

  final subtotal = items.fold<int>(0, (sum, item) => sum + item.subtotalCents);
  final isMember = user?.isSubscriber ?? false;

  // Cuota de servicio: reducida para socios, completa para no socios, 0 si el
  // carrito está vacío.
  final int fee;
  if (subtotal == 0) {
    fee = 0;
  } else if (isMember) {
    fee = AppConfig.memberServiceFeeCents;
  } else {
    fee = AppConfig.serviceFeeCents;
  }

  final commission = (subtotal * AppConfig.platformCommissionRate).round();
  final total = subtotal + fee;

  // Margen de Barra: lo que cobra (comisión + cuota) menos el costo de
  // procesar el pago en Mercado Pago.
  final paymentCost =
      subtotal == 0 ? 0 : AppConfig.paymentProcessingCost(total);
  final platformNet = commission + fee - paymentCost;

  return CartPricing(
    subtotalCents: subtotal,
    serviceFeeCents: fee,
    totalCents: total,
    isMember: isMember,
    commissionCents: commission,
    cafeNetCents: subtotal - commission,
    paymentCostCents: paymentCost,
    platformNetCents: platformNet,
  );
});

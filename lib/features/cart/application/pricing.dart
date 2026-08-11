import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../auth/application/auth_controller.dart';
import '../../subscription/application/daily_perk.dart';
import 'cart_controller.dart';

/// Desglose de precio del carrito, incluyendo el beneficio de socio.
class CartPricing {
  const CartPricing({
    required this.subtotalCents,
    required this.perkDiscountCents,
    required this.totalCents,
    required this.perkApplied,
  });

  final int subtotalCents;

  /// Descuento aplicado por el beneficio (1 Americano a $1).
  final int perkDiscountCents;
  final int totalCents;

  /// `true` si en este carrito se está aplicando el beneficio del Americano.
  final bool perkApplied;
}

/// Calcula el total aplicando el beneficio de socio: si el usuario es socio,
/// aún no usó su beneficio hoy y el carrito incluye un producto elegible
/// (Americano), UNA unidad se cobra a $1.
final cartPricingProvider = Provider<CartPricing>((ref) {
  final items = ref.watch(cartControllerProvider);
  final user = ref.watch(authControllerProvider);
  final perkAvailable = ref.watch(perkAvailableTodayProvider);

  final subtotal = items.fold<int>(0, (sum, item) => sum + item.subtotalCents);

  final eligible = items
      .where((item) => item.product.eligibleForDailyPerk)
      .fold<int?>(null, (found, item) => found ?? item.product.priceCents);

  final isSubscriber = user?.isSubscriber ?? false;

  var discount = 0;
  if (isSubscriber && perkAvailable && eligible != null) {
    final raw = eligible - AppConfig.socioCoffeePriceCents;
    discount = raw < 0 ? 0 : raw;
  }

  return CartPricing(
    subtotalCents: subtotal,
    perkDiscountCents: discount,
    totalCents: subtotal - discount,
    perkApplied: discount > 0,
  );
});

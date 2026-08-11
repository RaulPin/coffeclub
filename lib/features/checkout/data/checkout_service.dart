import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../cart/domain/cart_item.dart';
import '../../orders/data/orders_repository.dart';
import 'stripe_checkout_service.dart';

/// Resultado de colocar un pedido.
class PlaceOrderResult {
  const PlaceOrderResult({required this.success, this.orderId, this.error});
  final bool success;
  final String? orderId;
  final String? error;
}

/// Cobra el carrito y crea la orden. Devuelve el id de la orden para seguirla.
///
/// - Mock: simula el pago y crea la orden localmente.
/// - Real: crea un PaymentIntent en el servidor (Cloud Function, que recalcula
///   el total y valida el beneficio de socio), muestra el Payment Sheet de
///   Stripe y la orden queda registrada por el servidor.
abstract interface class CheckoutService {
  Future<PlaceOrderResult> placeOrder({
    required List<CartItem> items,
    required int amountCents,
    required String userId,
  });
}

/// Implementación de demo: aprueba el pago y crea la orden en el repositorio.
class MockCheckoutService implements CheckoutService {
  MockCheckoutService(this._orders);

  final OrdersRepository _orders;

  @override
  Future<PlaceOrderResult> placeOrder({
    required List<CartItem> items,
    required int amountCents,
    required String userId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 800)); // "pago"
    final orderId = await _orders.create(items, amountCents, userId);
    return PlaceOrderResult(success: true, orderId: orderId);
  }
}

final checkoutServiceProvider = Provider<CheckoutService>((ref) {
  if (AppConfig.useMockBackend) {
    return MockCheckoutService(ref.watch(ordersRepositoryProvider));
  }
  return StripeCheckoutService();
});

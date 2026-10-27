import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../cart/domain/cart_item.dart';
import '../../orders/data/orders_repository.dart';
import '../../orders/domain/order.dart';
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
    required String branchId,
    PaymentMethod paymentMethod = PaymentMethod.payAtCounter,
  });
}

/// Implementación de demo: crea la orden SIN pagar, simula la aprobación del
/// pago (como haría el webhook de Mercado Pago) y la confirma. Así el flujo
/// "prepagado" es idéntico al real: la cafetería solo la ve una vez pagada.
class MockCheckoutService implements CheckoutService {
  MockCheckoutService(this._orders);

  final OrdersRepository _orders;

  @override
  Future<PlaceOrderResult> placeOrder({
    required List<CartItem> items,
    required int amountCents,
    required String userId,
    required String branchId,
    PaymentMethod paymentMethod = PaymentMethod.payAtCounter,
  }) async {
    // 1) Se crea el pedido pendiente de pago (aún invisible para la cafetería).
    final orderId = await _orders.create(
      items,
      amountCents,
      userId,
      branchId,
      paymentMethod: paymentMethod,
    );
    // 2) Se simula la pasarela de Mercado Pago.
    await Future<void>.delayed(const Duration(milliseconds: 900));
    // 3) Pago aprobado → se confirma; ahora entra a la cola de la cafetería.
    await _orders.markPaid(orderId);
    return PlaceOrderResult(success: true, orderId: orderId);
  }
}

final checkoutServiceProvider = Provider<CheckoutService>((ref) {
  if (AppConfig.useMockBackend) {
    return MockCheckoutService(ref.watch(ordersRepositoryProvider));
  }
  return StripeCheckoutService();
});

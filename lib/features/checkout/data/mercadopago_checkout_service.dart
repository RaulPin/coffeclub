import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../cart/domain/cart_item.dart';
import '../../orders/domain/order.dart';
import 'checkout_service.dart';

/// Checkout real con Mercado Pago. El flujo seguro:
///   1. Llama a la Cloud Function `createOrderPayment` con los productos
///      (id + cantidad). El SERVIDOR recalcula el total, crea el pedido SIN
///      pagar y genera el cobro con la comisión de Barra retenida (split).
///   2. Abre el checkout de Mercado Pago (`init_point`).
///   3. El webhook marca el pedido como pagado; la cafetería lo ve recién
///      entonces, y el seguimiento del cliente se actualiza solo.
///
/// El cliente NUNCA calcula montos ni conoce llaves secretas.
class MercadoPagoCheckoutService implements CheckoutService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  @override
  Future<PlaceOrderResult> placeOrder({
    required List<CartItem> items,
    required int amountCents, // ignorado: el servidor es la fuente de verdad
    required String userId, // se toma del token de auth en el servidor
    required String branchId,
    PaymentMethod paymentMethod = PaymentMethod.mercadoPago,
  }) async {
    try {
      final res = await _functions.httpsCallable('createOrderPayment').call({
        'branchId': branchId,
        'items': [
          for (final item in items)
            {'productId': item.product.id, 'quantity': item.quantity},
        ],
      });

      final data = Map<String, dynamic>.from(res.data as Map);
      final orderId = data['orderId'] as String?;
      final initPoint = data['initPoint'] as String?;
      if (orderId == null || initPoint == null) {
        return const PlaceOrderResult(
          success: false,
          error: 'No se pudo iniciar el cobro.',
        );
      }

      // Abre el checkout de Mercado Pago.
      final ok = await launchUrl(
        Uri.parse(initPoint),
        mode: LaunchMode.externalApplication,
      );
      if (!ok) {
        return const PlaceOrderResult(
          success: false,
          error: 'No se pudo abrir Mercado Pago.',
        );
      }

      // El pedido queda creado (sin pagar); el webhook lo confirmará.
      return PlaceOrderResult(success: true, orderId: orderId);
    } on FirebaseFunctionsException catch (e) {
      return PlaceOrderResult(
          success: false, error: e.message ?? 'Error al cobrar.');
    } catch (e) {
      return PlaceOrderResult(success: false, error: e.toString());
    }
  }
}

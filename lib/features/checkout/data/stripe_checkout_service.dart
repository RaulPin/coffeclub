import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import '../../../core/config/app_config.dart';
import '../../cart/domain/cart_item.dart';
import 'checkout_service.dart';

/// Pago real con Stripe. El flujo seguro:
///   1. Llama a la Cloud Function `createPaymentIntent` con los productos
///      (id + cantidad). El SERVIDOR recalcula el total, valida el beneficio
///      de socio (1 Americano/día) y crea la orden + el PaymentIntent.
///   2. Muestra el Payment Sheet de Stripe con el `clientSecret`.
///   3. Al confirmarse, la orden queda registrada (el webhook la marca pagada).
///
/// El cliente NUNCA calcula montos ni conoce la secret key.
class StripeCheckoutService implements CheckoutService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  @override
  Future<PlaceOrderResult> placeOrder({
    required List<CartItem> items,
    required int amountCents, // ignorado: el servidor es la fuente de verdad
    required String userId, // se toma del token de auth en el servidor
    required String branchId,
  }) async {
    try {
      final response =
          await _functions.httpsCallable('createPaymentIntent').call({
        'branchId': branchId,
        'items': [
          for (final item in items)
            {'productId': item.product.id, 'quantity': item.quantity},
        ],
      });

      final data = Map<String, dynamic>.from(response.data as Map);
      final clientSecret = data['clientSecret'] as String;
      final orderId = data['orderId'] as String;

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: AppConfig.appName,
        ),
      );
      await Stripe.instance.presentPaymentSheet();

      return PlaceOrderResult(success: true, orderId: orderId);
    } on StripeException catch (e) {
      return PlaceOrderResult(
          success: false, error: e.error.localizedMessage ?? 'Pago cancelado');
    } catch (e) {
      return PlaceOrderResult(success: false, error: e.toString());
    }
  }
}

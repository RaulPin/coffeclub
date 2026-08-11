import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import '../../../core/config/app_config.dart';

/// Resultado de un intento de pago/suscripción.
class PaymentResult {
  const PaymentResult({required this.success, this.reference, this.error});
  final bool success;
  final String? reference;
  final String? error;
}

/// Servicio de suscripción de socio (membresía recurrente).
abstract interface class PaymentService {
  /// Inicia la suscripción recurrente de socio.
  Future<PaymentResult> startSubscription();
}

/// Implementación de demo: siempre aprueba.
class MockPaymentService implements PaymentService {
  @override
  Future<PaymentResult> startSubscription() async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    return const PaymentResult(success: true, reference: 'mock_sub');
  }
}

/// Suscripción real con Stripe Billing.
///   1. Cloud Function `createSubscription` crea el Customer + Subscription y
///      devuelve el `clientSecret` del primer pago.
///   2. Se muestra el Payment Sheet para cobrar/guardar el método de pago.
///   3. El webhook marca al usuario como socio (`isSubscriber = true`).
class StripePaymentService implements PaymentService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  @override
  Future<PaymentResult> startSubscription() async {
    try {
      final response =
          await _functions.httpsCallable('createSubscription').call();
      final data = Map<String, dynamic>.from(response.data as Map);
      final clientSecret = data['clientSecret'] as String;

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: AppConfig.appName,
        ),
      );
      await Stripe.instance.presentPaymentSheet();

      return const PaymentResult(success: true);
    } on StripeException catch (e) {
      return PaymentResult(
          success: false, error: e.error.localizedMessage ?? 'Pago cancelado');
    } catch (e) {
      return PaymentResult(success: false, error: e.toString());
    }
  }
}

final paymentServiceProvider = Provider<PaymentService>((ref) {
  if (AppConfig.useMockBackend) return MockPaymentService();
  return StripePaymentService();
});

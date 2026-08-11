import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Resultado de un intento de pago.
class PaymentResult {
  const PaymentResult({required this.success, this.reference, this.error});
  final bool success;
  final String? reference;
  final String? error;
}

/// Contrato de pagos. La implementación real usa Stripe.
abstract interface class PaymentService {
  /// Cobra un monto único (en centavos).
  Future<PaymentResult> chargeOnce(int amountCents);

  /// Inicia una suscripción recurrente de socio.
  Future<PaymentResult> startSubscription();
}

/// Implementación de ejemplo: siempre aprueba.
class MockPaymentService implements PaymentService {
  @override
  Future<PaymentResult> chargeOnce(int amountCents) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    return PaymentResult(
        success: true, reference: 'mock_${DateTime.now().millisecondsSinceEpoch}');
  }

  @override
  Future<PaymentResult> startSubscription() async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    return const PaymentResult(success: true, reference: 'mock_sub');
  }
}

// ---------------------------------------------------------------------------
// TODO(stripe): Implementación real.
// El flujo seguro es:
//   1. App pide a una Cloud Function crear un PaymentIntent (monto en servidor).
//   2. La función devuelve el `clientSecret`.
//   3. App confirma el pago con flutter_stripe (Payment Sheet).
// Nunca calcules montos ni uses la secret key en el cliente.
// ---------------------------------------------------------------------------

final paymentServiceProvider = Provider<PaymentService>((ref) {
  return MockPaymentService();
});

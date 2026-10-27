import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Puente con el backend de pagos (Cloud Functions / Mercado Pago).
class CafePaymentsService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// [CAFÉ] Pide al backend la URL de autorización de Mercado Pago para que el
  /// dueño conecte su cuenta. Requiere que las Cloud Functions estén
  /// desplegadas.
  Future<String> connectUrl(String cafeId) async {
    final res = await _functions
        .httpsCallable('mpConnectUrl')
        .call(<String, dynamic>{'cafeId': cafeId});
    final data = Map<String, dynamic>.from(res.data as Map);
    final url = data['url'] as String?;
    if (url == null || url.isEmpty) {
      throw Exception('El backend no devolvió una URL de conexión.');
    }
    return url;
  }
}

final cafePaymentsServiceProvider =
    Provider<CafePaymentsService>((ref) => CafePaymentsService());

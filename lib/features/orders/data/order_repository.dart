import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/lockers/locker_service.dart';
import '../../../services/lockers/mock_locker_service.dart';
import '../../cart/domain/cart_item.dart';
import '../domain/order.dart';

/// Provee la implementación del servicio de casilleros.
final lockerServiceProvider = Provider<LockerService>((ref) {
  return MockLockerService();
});

/// Controlador del pedido activo. Crea el pedido tras el pago, le asigna un
/// casillero y simula el avance de estado (en producción esto lo hace el
/// backend y llega por Firestore/FCM).
class ActiveOrderController extends StateNotifier<CoffeeOrder?> {
  ActiveOrderController(this._lockers) : super(null);

  final LockerService _lockers;

  Future<CoffeeOrder> createOrder(List<CartItem> items, int totalCents) async {
    final now = DateTime.now();
    final id = 'ord_${now.millisecondsSinceEpoch}';
    final assignment = await _lockers.assignLocker(id);

    final order = CoffeeOrder(
      id: id,
      items: List.of(items),
      totalCents: totalCents,
      status: OrderStatus.preparing,
      createdAt: now,
      estimatedReadyAt: now.add(const Duration(minutes: 5)),
      lockerNumber: assignment.lockerNumber,
      lockerPin: assignment.pin,
    );
    state = order;
    _simulateProgress();
    return order;
  }

  /// Simula el paso a "listo". En producción, escucha cambios de Firestore.
  void _simulateProgress() {
    Future<void>.delayed(const Duration(seconds: 8), () {
      final current = state;
      if (current != null && current.status == OrderStatus.preparing) {
        state = current.copyWith(status: OrderStatus.ready);
      }
    });
  }

  Future<void> openLocker() async {
    final order = state;
    if (order?.lockerNumber == null) return;
    await _lockers.openLocker(order!.lockerNumber!);
    state = order.copyWith(status: OrderStatus.pickedUp);
    await _lockers.releaseLocker(order.lockerNumber!);
  }

  void clear() => state = null;
}

final activeOrderProvider =
    StateNotifierProvider<ActiveOrderController, CoffeeOrder?>((ref) {
  return ActiveOrderController(ref.watch(lockerServiceProvider));
});

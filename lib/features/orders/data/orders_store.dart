import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/lockers/locker_service.dart';
import '../../../services/lockers/mock_locker_service.dart';
import '../../cart/domain/cart_item.dart';
import '../domain/order.dart';

/// Provee la implementación del servicio de casilleros.
final lockerServiceProvider = Provider<LockerService>((ref) {
  return MockLockerService();
});

/// Store central de órdenes, compartido por la app del CLIENTE (crea y sigue
/// sus órdenes) y la app del EMPLEADO (procesa y coloca en el casillero).
///
/// En producción esto es la colección `orders/` de Firestore: ambos extremos
/// leen/escriben la misma fuente y reciben cambios en tiempo real. Aquí lo
/// simulamos en memoria, pero la interfaz pública es la misma.
class OrdersStore extends StateNotifier<List<CoffeeOrder>> {
  OrdersStore(this._lockers) : super([]);

  final LockerService _lockers;

  /// [CLIENTE] Crea una orden tras el pago. Queda en cola (`pending`) sin
  /// casillero; el empleado la tomará desde el otro extremo.
  String create(List<CartItem> items, int totalCents, String userId) {
    final now = DateTime.now();
    final order = CoffeeOrder(
      id: 'ord_${now.millisecondsSinceEpoch}',
      items: List.of(items),
      totalCents: totalCents,
      status: OrderStatus.pending,
      createdAt: now,
      estimatedReadyAt: now.add(const Duration(minutes: 5)),
      userId: userId,
    );
    state = [...state, order];
    return order.id;
  }

  /// [EMPLEADO] Empieza a preparar la orden.
  void startPreparing(String orderId) =>
      _update(orderId, (o) => o.copyWith(status: OrderStatus.preparing));

  /// [EMPLEADO] Marca la orden lista y la coloca en un casillero disponible.
  Future<void> markReady(String orderId) async {
    final assignment = await _lockers.assignLocker(orderId);
    _update(
      orderId,
      (o) => o.copyWith(
        status: OrderStatus.ready,
        lockerNumber: assignment.lockerNumber,
        lockerPin: assignment.pin,
      ),
    );
  }

  /// [CLIENTE] Abre el casillero y confirma la recogida.
  Future<void> pickUp(String orderId) async {
    final order = _byId(orderId);
    if (order?.lockerNumber != null) {
      await _lockers.openLocker(order!.lockerNumber!);
      await _lockers.releaseLocker(order.lockerNumber!);
    }
    _update(orderId, (o) => o.copyWith(status: OrderStatus.pickedUp));
  }

  CoffeeOrder? _byId(String id) {
    for (final o in state) {
      if (o.id == id) return o;
    }
    return null;
  }

  void _update(String id, CoffeeOrder Function(CoffeeOrder) transform) {
    state = [
      for (final o in state) if (o.id == id) transform(o) else o,
    ];
  }
}

final ordersStoreProvider =
    StateNotifierProvider<OrdersStore, List<CoffeeOrder>>((ref) {
  return OrdersStore(ref.watch(lockerServiceProvider));
});

/// [CLIENTE] Id de la orden activa del usuario actual.
final activeOrderIdProvider = StateProvider<String?>((ref) => null);

/// [CLIENTE] Orden activa derivada del store (reactiva a cambios del empleado).
final activeOrderProvider = Provider<CoffeeOrder?>((ref) {
  final id = ref.watch(activeOrderIdProvider);
  if (id == null) return null;
  final orders = ref.watch(ordersStoreProvider);
  for (final o in orders) {
    if (o.id == id) return o;
  }
  return null;
});

/// [EMPLEADO] Cola de órdenes en curso (no recogidas), más recientes primero.
final orderQueueProvider = Provider<List<CoffeeOrder>>((ref) {
  final orders = ref.watch(ordersStoreProvider);
  final active = orders
      .where((o) => o.status != OrderStatus.pickedUp)
      .toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  return active;
});

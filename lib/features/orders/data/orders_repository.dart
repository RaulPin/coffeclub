import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../services/lockers/locker_service.dart';
import '../../../services/lockers/mock_locker_service.dart';
import '../../cart/domain/cart_item.dart';
import '../domain/order.dart';
import 'firestore_orders_repository.dart';

/// Provee la implementación del servicio de casilleros.
final lockerServiceProvider = Provider<LockerService>((ref) {
  return MockLockerService();
});

/// Contrato de acceso a órdenes, compartido por la app CLIENTE y la app
/// EMPLEADO. Ambos extremos observan los mismos streams (en producción son
/// `snapshots()` de Firestore) y escriben con los mismos métodos.
abstract interface class OrdersRepository {
  /// Todas las órdenes (para reportes/turnos).
  Stream<List<CoffeeOrder>> watchAll();

  /// Órdenes en curso (no recogidas), para la cola del empleado.
  Stream<List<CoffeeOrder>> watchActive();

  /// Una orden específica, para el seguimiento del cliente.
  Stream<CoffeeOrder?> watchOrder(String orderId);

  /// [CLIENTE] Crea una orden pagada; queda en cola (`pending`).
  Future<String> create(
      List<CartItem> items, int totalCents, String userId, String branchId);

  /// [EMPLEADO] Empieza a preparar.
  Future<void> startPreparing(String orderId);

  /// [EMPLEADO] Marca lista y asigna un casillero disponible.
  Future<void> markReady(String orderId);

  /// [CLIENTE] Abre el casillero y confirma la recogida.
  Future<void> pickUp(String orderId);
}

/// Implementación en memoria para el demo (simula la colección `orders/`).
/// Emite por streams igual que Firestore, así la UI es idéntica en ambos modos.
class MockOrdersRepository implements OrdersRepository {
  MockOrdersRepository(this._lockers);

  final LockerService _lockers;
  final StreamController<List<CoffeeOrder>> _controller =
      StreamController<List<CoffeeOrder>>.broadcast();
  List<CoffeeOrder> _orders = [];

  void dispose() => _controller.close();

  void _emit() => _controller.add(List.unmodifiable(_orders));

  Stream<List<CoffeeOrder>> _all() async* {
    yield List.unmodifiable(_orders); // valor actual para nuevos oyentes
    yield* _controller.stream;
  }

  @override
  Stream<List<CoffeeOrder>> watchAll() => _all();

  @override
  Stream<List<CoffeeOrder>> watchActive() => _all().map((orders) {
        final active =
            orders.where((o) => o.status != OrderStatus.pickedUp).toList()
              ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
        return active;
      });

  @override
  Stream<CoffeeOrder?> watchOrder(String orderId) => _all().map((orders) {
        for (final o in orders) {
          if (o.id == orderId) return o;
        }
        return null;
      });

  @override
  Future<String> create(List<CartItem> items, int totalCents, String userId,
      String branchId) async {
    final now = DateTime.now();
    final order = CoffeeOrder(
      id: 'ord_${now.millisecondsSinceEpoch}',
      items: List.of(items),
      totalCents: totalCents,
      status: OrderStatus.pending,
      createdAt: now,
      estimatedReadyAt: now.add(const Duration(minutes: 5)),
      userId: userId,
      branchId: branchId,
    );
    _orders = [..._orders, order];
    _emit();
    return order.id;
  }

  @override
  Future<void> startPreparing(String orderId) async {
    _update(orderId, (o) => o.copyWith(status: OrderStatus.preparing));
  }

  @override
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

  @override
  Future<void> pickUp(String orderId) async {
    final order = _byId(orderId);
    if (order?.lockerNumber != null) {
      await _lockers.openLocker(order!.lockerNumber!);
      await _lockers.releaseLocker(order.lockerNumber!);
    }
    _update(orderId, (o) => o.copyWith(status: OrderStatus.pickedUp));
  }

  CoffeeOrder? _byId(String id) {
    for (final o in _orders) {
      if (o.id == id) return o;
    }
    return null;
  }

  void _update(String id, CoffeeOrder Function(CoffeeOrder) transform) {
    _orders = [
      for (final o in _orders) if (o.id == id) transform(o) else o,
    ];
    _emit();
  }
}

/// Selecciona la implementación según el modo (mock vs Firestore).
final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  final lockers = ref.watch(lockerServiceProvider);
  if (AppConfig.useMockBackend) {
    final repo = MockOrdersRepository(lockers);
    ref.onDispose(repo.dispose);
    return repo;
  }
  return FirestoreOrdersRepository(lockers);
});

/// [CLIENTE] Id de la orden activa del usuario actual.
final activeOrderIdProvider = StateProvider<String?>((ref) => null);

/// [CLIENTE] Orden activa (reactiva a cambios que hace el empleado).
final activeOrderProvider = StreamProvider<CoffeeOrder?>((ref) {
  final id = ref.watch(activeOrderIdProvider);
  if (id == null) return Stream.value(null);
  return ref.watch(ordersRepositoryProvider).watchOrder(id);
});

/// [EMPLEADO] Cola de órdenes en curso.
final orderQueueProvider = StreamProvider<List<CoffeeOrder>>((ref) {
  return ref.watch(ordersRepositoryProvider).watchActive();
});

/// Todas las órdenes (para el cierre de caja / reportes).
final allOrdersProvider = StreamProvider<List<CoffeeOrder>>((ref) {
  return ref.watch(ordersRepositoryProvider).watchAll();
});

/// [EMPLEADO] Cola de órdenes activas de UNA sucursal.
final branchQueueProvider =
    Provider.family<List<CoffeeOrder>, String>((ref, branchId) {
  final List<CoffeeOrder> queue =
      ref.watch(orderQueueProvider).valueOrNull ?? const [];
  return queue.where((o) => o.branchId == branchId).toList();
});

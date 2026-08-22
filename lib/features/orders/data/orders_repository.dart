import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../services/lockers/locker_service.dart';
import '../../../services/lockers/mock_locker_service.dart';
import '../../cart/domain/cart_item.dart';
import '../../menu/domain/product.dart';
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
  MockOrdersRepository(this._lockers) {
    _orders = _demoSeed();
  }

  final LockerService _lockers;
  final StreamController<List<CoffeeOrder>> _controller =
      StreamController<List<CoffeeOrder>>.broadcast();
  late List<CoffeeOrder> _orders;

  /// Línea de carrito rápida para los pedidos de ejemplo.
  static CartItem _item(
    String id,
    String name,
    int cents,
    String category, [
    int qty = 1,
  ]) =>
      CartItem(
        product: Product(
          id: id,
          name: name,
          description: '',
          priceCents: cents,
          category: category,
        ),
        quantity: qty,
      );

  /// Pedidos de ejemplo para que el panel de staff se vea poblado en el demo.
  /// (Solo en modo mock; en producción la cola arranca vacía y se llena con
  /// órdenes reales.)
  static List<CoffeeOrder> _demoSeed() {
    final now = DateTime.now();
    CoffeeOrder mk({
      required String id,
      required List<CartItem> items,
      required OrderStatus status,
      required String branchId,
      required int minutesAgo,
      int? lockerNumber,
      String? lockerPin,
    }) {
      final createdAt = now.subtract(Duration(minutes: minutesAgo));
      return CoffeeOrder(
        id: id,
        items: items,
        totalCents: items.fold(0, (s, i) => s + i.subtotalCents),
        status: status,
        createdAt: createdAt,
        estimatedReadyAt: createdAt.add(const Duration(minutes: 5)),
        userId: 'demo',
        branchId: branchId,
        lockerNumber: lockerNumber,
        lockerPin: lockerPin,
      );
    }

    return [
      // --- Condesa: cola activa para el empleado de esa sucursal ---
      mk(
        id: 'CC-4829',
        branchId: 'condesa',
        status: OrderStatus.pending,
        minutesAgo: 2,
        items: [
          _item('americano', 'Americano', 4000, 'Café'),
          _item('postre-galleta', 'Sándwich de Galleta', 3900, 'Postre'),
        ],
      ),
      mk(
        id: 'CC-4830',
        branchId: 'condesa',
        status: OrderStatus.preparing,
        minutesAgo: 5,
        items: [_item('latte', 'Latte', 5000, 'Café')],
      ),
      mk(
        id: 'CC-4831',
        branchId: 'condesa',
        status: OrderStatus.ready,
        minutesAgo: 9,
        lockerNumber: 3,
        lockerPin: '4417',
        items: [
          _item('cold-brew', 'Cold Brew', 5500, 'Café'),
          _item('pizza-doble-pepperoni', 'Doble Pepperoni', 13000, 'Pizza'),
        ],
      ),
      // --- Roma Norte ---
      mk(
        id: 'CC-4832',
        branchId: 'roma',
        status: OrderStatus.preparing,
        minutesAgo: 7,
        items: [_item('espresso', 'Espresso', 3500, 'Café', 2)],
      ),
      mk(
        id: 'CC-4833',
        branchId: 'roma',
        status: OrderStatus.ready,
        minutesAgo: 14,
        lockerNumber: 7,
        lockerPin: '6630',
        items: [_item('americano', 'Americano', 4000, 'Café')],
      ),
      // --- Polanco ---
      mk(
        id: 'CC-4834',
        branchId: 'polanco',
        status: OrderStatus.pending,
        minutesAgo: 3,
        items: [_item('pizza-doble-pepperoni', 'Doble Pepperoni', 13000, 'Pizza')],
      ),
      // --- Condesa: uno ya recogido (para ventas del día) ---
      mk(
        id: 'CC-4828',
        branchId: 'condesa',
        status: OrderStatus.pickedUp,
        minutesAgo: 35,
        lockerNumber: 5,
        lockerPin: '1128',
        items: [
          _item('latte', 'Latte', 5000, 'Café'),
          _item('postre-galleta', 'Sándwich de Galleta', 3900, 'Postre'),
        ],
      ),
    ];
  }

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

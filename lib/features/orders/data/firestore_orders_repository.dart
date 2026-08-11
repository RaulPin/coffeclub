import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../../services/lockers/locker_service.dart';
import '../../cart/domain/cart_item.dart';
import '../../menu/domain/product.dart';
import '../domain/order.dart';
import 'orders_repository.dart';

/// Implementación real sobre Cloud Firestore.
///
/// - Lecturas: `snapshots()` en tiempo real (los dos extremos ven lo mismo).
/// - Escrituras sensibles (asignar casillero, abrir casillero): vía Cloud
///   Functions para transaccionalidad y para no exponer credenciales del
///   hardware en el cliente.
///
/// > Nota: en el flujo endurecido de producción, la ORDEN la crea el webhook
/// > de Stripe tras confirmarse el pago (ver `StripeCheckoutService` y las
/// > Cloud Functions). Aquí `create` queda disponible para pruebas directas.
class FirestoreOrdersRepository implements OrdersRepository {
  FirestoreOrdersRepository(this._lockers);

  // ignore: unused_field
  final LockerService _lockers;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _db.collection('orders');

  static const _activeStatuses = ['pending', 'preparing', 'ready'];

  @override
  Stream<List<CoffeeOrder>> watchAll() => _orders
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(_fromDoc).whereType<CoffeeOrder>().toList());

  @override
  Stream<List<CoffeeOrder>> watchActive() => _orders
      .where('status', whereIn: _activeStatuses)
      .orderBy('createdAt')
      .snapshots()
      .map((snap) => snap.docs.map(_fromDoc).whereType<CoffeeOrder>().toList());

  @override
  Stream<CoffeeOrder?> watchOrder(String orderId) =>
      _orders.doc(orderId).snapshots().map((doc) => _fromDoc(doc));

  @override
  Future<String> create(
      List<CartItem> items, int totalCents, String userId) async {
    final now = DateTime.now();
    final doc = await _orders.add({
      'userId': userId,
      'items': items.map(_itemToMap).toList(),
      'totalCents': totalCents,
      'status': 'pending',
      'createdAt': Timestamp.fromDate(now),
      'estimatedReadyAt':
          Timestamp.fromDate(now.add(const Duration(minutes: 5))),
      'lockerNumber': null,
    });
    return doc.id;
  }

  @override
  Future<void> startPreparing(String orderId) =>
      _orders.doc(orderId).update({'status': 'preparing'});

  @override
  Future<void> markReady(String orderId) async {
    // La Cloud Function asigna un casillero libre de forma transaccional.
    await _functions.httpsCallable('markOrderReady').call({'orderId': orderId});
  }

  @override
  Future<void> pickUp(String orderId) async {
    // La Cloud Function ordena al hardware abrir el casillero.
    await _functions.httpsCallable('openLocker').call({'orderId': orderId});
  }

  // --- Mapeo Firestore <-> dominio ---

  Map<String, dynamic> _itemToMap(CartItem item) => {
        'productId': item.product.id,
        'name': item.product.name,
        'priceCents': item.product.priceCents,
        'quantity': item.quantity,
      };

  CoffeeOrder? _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) return null;
    final status = _statusFromString(data['status'] as String?);
    if (status == null) return null; // p.ej. awaiting_payment: ignorar

    final rawItems = (data['items'] as List<dynamic>? ?? []);
    final items = rawItems.map((raw) {
      final m = raw as Map<String, dynamic>;
      return CartItem(
        product: Product(
          id: m['productId'] as String? ?? '',
          name: m['name'] as String? ?? '',
          description: '',
          priceCents: (m['priceCents'] as num?)?.toInt() ?? 0,
          category: '',
        ),
        quantity: (m['quantity'] as num?)?.toInt() ?? 1,
      );
    }).toList();

    return CoffeeOrder(
      id: doc.id,
      items: items,
      totalCents: (data['totalCents'] as num?)?.toInt() ?? 0,
      status: status,
      createdAt: _toDate(data['createdAt']) ?? DateTime.now(),
      estimatedReadyAt: _toDate(data['estimatedReadyAt']) ?? DateTime.now(),
      userId: data['userId'] as String? ?? '',
      lockerNumber: (data['lockerNumber'] as num?)?.toInt(),
      lockerPin: data['lockerPin'] as String?,
    );
  }

  DateTime? _toDate(dynamic value) =>
      value is Timestamp ? value.toDate() : null;

  OrderStatus? _statusFromString(String? value) => switch (value) {
        'pending' => OrderStatus.pending,
        'preparing' => OrderStatus.preparing,
        'ready' => OrderStatus.ready,
        'pickedUp' => OrderStatus.pickedUp,
        _ => null,
      };
}

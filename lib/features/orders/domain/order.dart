import '../../cart/domain/cart_item.dart';

/// Estados por los que pasa un pedido.
enum OrderStatus {
  pending, // pago confirmado, en cola
  preparing, // en preparación
  ready, // listo en el casillero
  pickedUp, // recogido por el socio
}

extension OrderStatusLabel on OrderStatus {
  String get label => switch (this) {
        OrderStatus.pending => 'En cola',
        OrderStatus.preparing => 'Preparando',
        OrderStatus.ready => 'Listo para recoger',
        OrderStatus.pickedUp => 'Recogido',
      };
}

/// Pedido realizado por un socio.
class CoffeeOrder {
  const CoffeeOrder({
    required this.id,
    required this.items,
    required this.totalCents,
    required this.status,
    required this.createdAt,
    required this.estimatedReadyAt,
    required this.userId,
    this.lockerNumber,
    this.lockerPin,
  });

  final String id;
  final List<CartItem> items;
  final int totalCents;
  final OrderStatus status;
  final DateTime createdAt;

  /// Id del socio que hizo el pedido.
  final String userId;

  /// Momento estimado en que el pedido estará listo (para el contador).
  final DateTime estimatedReadyAt;

  /// Número de casillero asignado (1..12). Null hasta que se asigna.
  final int? lockerNumber;

  /// PIN/código para abrir el casillero (si el hardware lo requiere).
  final String? lockerPin;

  double get total => totalCents / 100;

  CoffeeOrder copyWith({
    OrderStatus? status,
    int? lockerNumber,
    String? lockerPin,
  }) =>
      CoffeeOrder(
        id: id,
        items: items,
        totalCents: totalCents,
        status: status ?? this.status,
        createdAt: createdAt,
        estimatedReadyAt: estimatedReadyAt,
        userId: userId,
        lockerNumber: lockerNumber ?? this.lockerNumber,
        lockerPin: lockerPin ?? this.lockerPin,
      );
}

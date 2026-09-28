import '../../cart/domain/cart_item.dart';

/// Estados por los que pasa un pedido.
enum OrderStatus {
  pending, // pago confirmado, en cola
  preparing, // en preparación
  ready, // listo para recoger en la barra
  pickedUp, // recogido por el cliente
}

extension OrderStatusLabel on OrderStatus {
  String get label => switch (this) {
        OrderStatus.pending => 'En cola',
        OrderStatus.preparing => 'Preparando',
        OrderStatus.ready => 'Listo para recoger',
        OrderStatus.pickedUp => 'Recogido',
      };
}

/// Pedido realizado por un cliente en una cafetería.
class CoffeeOrder {
  const CoffeeOrder({
    required this.id,
    required this.items,
    required this.totalCents,
    required this.status,
    required this.createdAt,
    required this.estimatedReadyAt,
    required this.userId,
    required this.branchId,
    required this.pickupCode,
  });

  final String id;
  final List<CartItem> items;
  final int totalCents;
  final OrderStatus status;
  final DateTime createdAt;

  /// Id del cliente que hizo el pedido.
  final String userId;

  /// Cafetería donde se prepara y recoge el pedido.
  final String branchId;

  /// Momento estimado en que el pedido estará listo (para el contador).
  final DateTime estimatedReadyAt;

  /// Código de recogida que el cliente muestra en la barra para recibir su
  /// pedido (p. ej. "K4T9").
  final String pickupCode;

  double get total => totalCents / 100;

  CoffeeOrder copyWith({OrderStatus? status}) => CoffeeOrder(
        id: id,
        items: items,
        totalCents: totalCents,
        status: status ?? this.status,
        createdAt: createdAt,
        estimatedReadyAt: estimatedReadyAt,
        userId: userId,
        branchId: branchId,
        pickupCode: pickupCode,
      );
}

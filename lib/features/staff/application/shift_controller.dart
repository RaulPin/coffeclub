import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../orders/data/orders_repository.dart';
import '../../orders/domain/order.dart';
import '../domain/shift.dart';

/// Maneja el turno abierto del empleado. En producción vive en `shifts/` de
/// Firestore para que cualquier tablet retome el turno correcto.
class ShiftController extends StateNotifier<Shift?> {
  ShiftController(this._ref) : super(null);

  final Ref _ref;

  /// El empleado inicia sesión y abre su turno.
  void startShift(String employeeName) {
    final now = DateTime.now();
    state = Shift(
      id: 'shift_${now.millisecondsSinceEpoch}',
      employeeName: employeeName,
      startedAt: now,
    );
  }

  /// Genera el cierre de caja del turno actual y lo cierra.
  /// El siguiente empleado abrirá un turno nuevo.
  ShiftReport? closeShift() {
    final shift = state;
    if (shift == null) return null;

    final closedAt = DateTime.now();
    final List<CoffeeOrder> orders =
        _ref.read(allOrdersProvider).valueOrNull ?? const [];

    // Órdenes creadas durante el turno (fuente de verdad: el store/Firestore).
    final duringShift = orders.where((o) =>
        !o.createdAt.isBefore(shift.startedAt) &&
        !o.createdAt.isAfter(closedAt));

    final total = duringShift.fold<int>(0, (sum, o) => sum + o.totalCents);

    final report = ShiftReport(
      shift: shift.close(closedAt),
      ordersCount: duringShift.length,
      totalSalesCents: total,
    );

    state = null; // turno cerrado
    return report;
  }
}

final shiftControllerProvider =
    StateNotifierProvider<ShiftController, Shift?>((ref) {
  return ShiftController(ref);
});

/// Órdenes pendientes de recoger que siguen ocupando un casillero al cierre.
final unfinishedOrdersProvider = Provider<List<CoffeeOrder>>((ref) {
  final List<CoffeeOrder> orders =
      ref.watch(allOrdersProvider).valueOrNull ?? const [];
  return orders.where((o) => o.status == OrderStatus.ready).toList();
});

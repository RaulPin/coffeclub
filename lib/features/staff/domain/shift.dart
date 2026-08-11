/// Turno de trabajo de un empleado en la tienda.
class Shift {
  const Shift({
    required this.id,
    required this.employeeName,
    required this.startedAt,
    this.endedAt,
  });

  final String id;
  final String employeeName;
  final DateTime startedAt;

  /// Null mientras el turno sigue abierto.
  final DateTime? endedAt;

  bool get isOpen => endedAt == null;

  Shift close(DateTime at) => Shift(
        id: id,
        employeeName: employeeName,
        startedAt: startedAt,
        endedAt: at,
      );
}

/// Reporte de cierre de caja generado al terminar el turno.
class ShiftReport {
  const ShiftReport({
    required this.shift,
    required this.ordersCount,
    required this.totalSalesCents,
  });

  final Shift shift;

  /// Número de órdenes atendidas durante el turno.
  final int ordersCount;

  /// Ventas totales del turno (en centavos).
  final int totalSalesCents;
}

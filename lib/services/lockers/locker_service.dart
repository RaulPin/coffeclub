/// Contrato agnóstico del hardware para controlar los casilleros de recogida.
///
/// La app y el backend hablan SIEMPRE con esta interfaz. Cuando definas el
/// hardware (proveedor con API, o electrónica propia por MQTT/HTTP) solo
/// tendrás que crear una implementación nueva de `LockerService` sin tocar
/// el resto de la app.
///
/// Recomendación: en producción, la apertura del casillero se dispara desde
/// una Cloud Function (backend) — nunca directamente desde el cliente— para
/// no exponer credenciales del hardware. Esta interfaz modela ambos casos.
abstract interface class LockerService {
  /// Reserva y asigna un casillero libre para un pedido.
  /// Devuelve el número de casillero asignado (1..N).
  Future<LockerAssignment> assignLocker(String orderId);

  /// Solicita la apertura del casillero (típicamente cuando el socio llega).
  Future<void> openLocker(int lockerNumber);

  /// Marca el casillero como libre tras la recogida.
  Future<void> releaseLocker(int lockerNumber);
}

/// Resultado de asignar un casillero.
class LockerAssignment {
  const LockerAssignment({required this.lockerNumber, this.pin});

  final int lockerNumber;

  /// Código para abrir, si el hardware usa PIN en lugar de apertura remota.
  final String? pin;
}

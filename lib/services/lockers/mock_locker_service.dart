import 'dart:math';

import '../../core/config/app_config.dart';
import 'locker_service.dart';

/// Implementación de ejemplo para desarrollo: asigna casilleros al azar
/// y simula la apertura. Sustitúyela por la integración real del hardware.
class MockLockerService implements LockerService {
  final _random = Random();
  final Set<int> _occupied = {};

  @override
  Future<LockerAssignment> assignLocker(String orderId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final free = [
      for (var i = 1; i <= AppConfig.lockerCount; i++)
        if (!_occupied.contains(i)) i,
    ];
    final locker = free.isEmpty
        ? _random.nextInt(AppConfig.lockerCount) + 1
        : free[_random.nextInt(free.length)];
    _occupied.add(locker);
    final pin = (1000 + _random.nextInt(9000)).toString();
    return LockerAssignment(lockerNumber: locker, pin: pin);
  }

  @override
  Future<void> openLocker(int lockerNumber) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    // En producción: llamar a la Cloud Function que abre el casillero.
  }

  @override
  Future<void> releaseLocker(int lockerNumber) async {
    _occupied.remove(lockerNumber);
  }
}

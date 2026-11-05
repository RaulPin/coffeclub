import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Un miembro del personal de una cafetería.
class CafeEmployee {
  const CafeEmployee({
    required this.uid,
    required this.name,
    required this.email,
    required this.isOwner,
  });

  final String uid;
  final String name;
  final String email;
  final bool isOwner;
}

/// Gestión de empleados de una cafetería (la crea/borra el dueño).
/// Las cuentas se crean en el backend (Admin SDK) para NO cerrar la sesión
/// del dueño.
class EmployeeService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createEmployee({
    required String cafeId,
    required String name,
    required String email,
    required String password,
  }) async {
    await _functions.httpsCallable('createEmployee').call(<String, dynamic>{
      'cafeId': cafeId,
      'name': name,
      'email': email,
      'password': password,
    });
  }

  Future<void> deleteEmployee({
    required String cafeId,
    required String employeeUid,
  }) async {
    await _functions.httpsCallable('deleteEmployee').call(<String, dynamic>{
      'cafeId': cafeId,
      'employeeUid': employeeUid,
    });
  }

  /// Personal de la cafetería, dueño primero.
  Stream<List<CafeEmployee>> watchEmployees(String cafeId) => _db
      .collection('staff')
      .where('branchId', isEqualTo: cafeId)
      .snapshots()
      .map((snap) {
        final list = snap.docs.map((d) {
          final m = d.data();
          return CafeEmployee(
            uid: d.id,
            name: m['name'] as String? ?? '',
            email: m['email'] as String? ?? '',
            isOwner: m['ownsCafe'] == true,
          );
        }).toList()
          ..sort((a, b) {
            if (a.isOwner != b.isOwner) return a.isOwner ? -1 : 1;
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });
        return list;
      });
}

final employeeServiceProvider =
    Provider<EmployeeService>((ref) => EmployeeService());

final cafeEmployeesProvider =
    StreamProvider.family<List<CafeEmployee>, String>((ref, cafeId) {
  return ref.watch(employeeServiceProvider).watchEmployees(cafeId);
});

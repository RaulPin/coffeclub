import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/staff_user.dart';
import 'staff_auth_repository.dart';

/// Autenticación real del personal con Firebase Auth (correo/contraseña).
///
/// El rol y la sucursal se leen del documento `staff/{uid}`:
///   { name, role: 'employee' | 'admin', branchId }
/// Las cuentas del personal las crea el administrador (no hay auto-registro).
class FirebaseStaffAuthRepository implements StaffAuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  StaffUser? get currentUser => null; // se resuelve al iniciar sesión

  @override
  Future<StaffUser> signIn(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = cred.user!.uid;

    final snap = await _db.collection('staff').doc(uid).get();
    final data = snap.data();
    if (data == null) {
      await _auth.signOut();
      throw Exception('Esta cuenta no tiene acceso al panel de tienda.');
    }

    return StaffUser(
      id: uid,
      name: data['name'] as String? ?? cred.user!.email ?? '',
      email: cred.user!.email ?? '',
      role: (data['role'] as String?) == 'admin'
          ? StaffRole.admin
          : StaffRole.employee,
      branchId: data['branchId'] as String?,
    );
  }

  @override
  Future<void> signOut() => _auth.signOut();
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/config/app_config.dart';
import '../domain/staff_user.dart';
import 'staff_auth_repository.dart';

/// Autenticación real del personal con Firebase Auth (correo/contraseña o
/// Google).
///
/// El rol y la sucursal se leen del documento `staff/{uid}`:
///   { name, role: 'employee' | 'admin', branchId }
/// Además, cualquier correo en `AppConfig.adminEmails` entra como admin.
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
    return _resolveStaff(cred.user!);
  }

  @override
  Future<StaffUser> signInWithGoogle() async {
    final UserCredential cred;
    if (kIsWeb) {
      cred = await _auth.signInWithPopup(GoogleAuthProvider());
    } else {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        throw FirebaseAuthException(
          code: 'canceled',
          message: 'Inicio de sesión cancelado.',
        );
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      cred = await _auth.signInWithCredential(credential);
    }
    return _resolveStaff(cred.user!);
  }

  @override
  Future<void> signOut() async {
    if (!kIsWeb) await GoogleSignIn().signOut();
    await _auth.signOut();
  }

  /// Decide el rol tras autenticar: admin por correo, o empleado según su
  /// documento `staff/{uid}`. Si no tiene acceso, cierra sesión y lanza.
  Future<StaffUser> _resolveStaff(User user) async {
    final uid = user.uid;
    final email = user.email ?? '';

    // Administrador general designado por correo (no requiere sucursal).
    if (AppConfig.isAdminEmail(email)) {
      final name = user.displayName ?? 'Administrador';
      await _db.collection('staff').doc(uid).set({
        'name': name,
        'email': email,
        'role': 'admin',
      }, SetOptions(merge: true));
      return StaffUser(
        id: uid,
        name: name,
        email: email,
        role: StaffRole.admin,
      );
    }

    final snap = await _db.collection('staff').doc(uid).get();
    final data = snap.data();
    if (data == null) {
      await signOut();
      throw Exception('Esta cuenta no tiene acceso al panel de tienda.');
    }

    return StaffUser(
      id: uid,
      name: data['name'] as String? ?? email,
      email: email,
      role: (data['role'] as String?) == 'admin'
          ? StaffRole.admin
          : StaffRole.employee,
      branchId: data['branchId'] as String?,
    );
  }
}

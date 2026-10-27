import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../staff/domain/staff_user.dart';

/// Datos que una cafetería captura al registrarse en Barra.
class CafeRegistration {
  const CafeRegistration({
    required this.cafeName,
    required this.address,
    required this.tagline,
    required this.ownerName,
    required this.email,
    required this.password,
    this.imageUrl = '',
    this.lat,
    this.lng,
  });

  final String cafeName;
  final String address;
  final String tagline;
  final String ownerName;
  final String email;
  final String password;

  /// URL de la foto/logo de la cafetería (opcional).
  final String imageUrl;

  /// Ubicación elegida en el mapa (opcional). Si falta, el café no se dibuja
  /// como pin pero sí aparece en la lista.
  final double? lat;
  final double? lng;
}

/// Alta de cafeterías en el marketplace (self-service).
abstract interface class CafeRegistrationRepository {
  /// Crea la cuenta de la cafetería y su ficha. Devuelve al dueño ya como
  /// usuario del personal (rol empleado, dueño de su propia sucursal).
  Future<StaffUser> registerCafe(CafeRegistration data);
}

/// Implementación real: crea el usuario en Firebase Auth y escribe la ficha de
/// la cafetería (`cafes/{cafeId}`) y el acceso del dueño (`staff/{uid}`).
class FirebaseCafeRegistrationRepository implements CafeRegistrationRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Future<StaffUser> registerCafe(CafeRegistration data) async {
    // 1) Cuenta de acceso del dueño.
    final cred = await _auth.createUserWithEmailAndPassword(
      email: data.email.trim(),
      password: data.password,
    );
    final uid = cred.user!.uid;
    await cred.user!.updateDisplayName(data.ownerName.trim());

    // 2) Ficha de la cafetería + acceso del dueño, en una sola escritura.
    final cafeRef = _db.collection('cafes').doc();
    final cafeId = cafeRef.id;

    final batch = _db.batch();
    batch.set(cafeRef, {
      'name': data.cafeName.trim(),
      'address': data.address.trim(),
      'tagline': data.tagline.trim(),
      'imageUrl': data.imageUrl.trim().isEmpty ? null : data.imageUrl.trim(),
      'etaMinutes': 5,
      'rating': 5.0,
      'lat': data.lat,
      'lng': data.lng,
      'ownerUid': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(_db.collection('staff').doc(uid), {
      'name': data.ownerName.trim(),
      'email': data.email.trim(),
      'role': 'employee',
      'branchId': cafeId,
      'ownsCafe': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();

    return StaffUser(
      id: uid,
      name: data.ownerName.trim(),
      email: data.email.trim(),
      role: StaffRole.employee,
      branchId: cafeId,
    );
  }
}

/// Implementación de demo: no persiste, solo simula el alta.
class MockCafeRegistrationRepository implements CafeRegistrationRepository {
  @override
  Future<StaffUser> registerCafe(CafeRegistration data) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return StaffUser(
      id: 'demo_owner',
      name: data.ownerName,
      email: data.email,
      role: StaffRole.employee,
      branchId: 'demo_cafe',
    );
  }
}

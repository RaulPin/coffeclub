import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/app_user.dart';
import 'auth_repository.dart';

/// Autenticación real con Firebase Auth (correo y contraseña).
/// El perfil (nombre, estado de socio) vive en `users/{uid}` de Firestore.
class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  @override
  AppUser? currentUser() {
    final u = _auth.currentUser;
    if (u == null) return null;
    return AppUser(
      id: u.uid,
      name: u.displayName ?? (u.email?.split('@').first ?? ''),
      email: u.email ?? '',
      photoUrl: u.photoURL,
    );
  }

  @override
  Stream<AppUser?> authState() =>
      _auth.authStateChanges().asyncMap((u) async {
        if (u == null) return null;
        return _loadProfile(u);
      });

  @override
  Future<AppUser> signIn(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return _loadProfile(cred.user!);
  }

  @override
  Future<AppUser> register(String name, String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = cred.user!;
    await user.updateDisplayName(name.trim());
    await _users.doc(user.uid).set({
      'name': name.trim(),
      'email': email.trim(),
      'isSubscriber': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return AppUser(
      id: user.uid,
      name: name.trim(),
      email: email.trim(),
    );
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> markSubscriber(String userId) =>
      _users.doc(userId).set({'isSubscriber': true}, SetOptions(merge: true));

  /// Carga el perfil de Firestore (crea el doc si falta, p. ej. cuentas viejas).
  Future<AppUser> _loadProfile(User user) async {
    final ref = _users.doc(user.uid);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'name': user.displayName ?? '',
        'email': user.email ?? '',
        'isSubscriber': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    final data = snap.data() ?? const {};
    return AppUser(
      id: user.uid,
      name: user.displayName ??
          (data['name'] as String?) ??
          (user.email?.split('@').first ?? ''),
      email: user.email ?? (data['email'] as String? ?? ''),
      photoUrl: user.photoURL,
      isSubscriber: (data['isSubscriber'] as bool?) ?? false,
    );
  }
}

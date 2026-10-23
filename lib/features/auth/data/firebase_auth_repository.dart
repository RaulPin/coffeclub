import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

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
  Future<AppUser> signInWithGoogle() async {
    final UserCredential cred;
    if (kIsWeb) {
      // En web, Firebase abre un popup de Google directamente.
      cred = await _auth.signInWithPopup(GoogleAuthProvider());
    } else {
      // En móvil, el plugin nativo obtiene las credenciales de Google.
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
    return _loadProfile(cred.user!);
  }

  @override
  Future<void> signOut() async {
    if (!kIsWeb) {
      // Cierra también la sesión del plugin de Google en móvil.
      await GoogleSignIn().signOut();
    }
    await _auth.signOut();
  }

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

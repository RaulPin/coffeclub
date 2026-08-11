import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../domain/app_user.dart';
import 'auth_repository.dart';

/// Autenticación real con Firebase Auth + proveedores sociales.
/// El estado de socio (`isSubscriber`) se lee del documento `users/{uid}`.
class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  AppUser? get currentUser {
    final user = _auth.currentUser;
    return user == null ? null : _mapBasic(user);
  }

  @override
  Future<AppUser> signInWith(SocialProvider provider) async {
    final credential = switch (provider) {
      SocialProvider.google => await _googleCredential(),
      SocialProvider.apple => await _appleCredential(),
      SocialProvider.facebook => await _facebookCredential(),
    };

    final result = await _auth.signInWithCredential(credential);
    final user = result.user!;
    await _ensureUserDoc(user);
    return _mapWithSubscription(user);
  }

  @override
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      GoogleSignIn().signOut(),
      FacebookAuth.instance.logOut(),
    ]);
  }

  // --- Proveedores sociales ---

  Future<OAuthCredential> _googleCredential() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) throw Exception('Inicio con Google cancelado');
    final googleAuth = await googleUser.authentication;
    return GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
  }

  Future<OAuthCredential> _appleCredential() async {
    final apple = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );
    return OAuthProvider('apple.com').credential(
      idToken: apple.identityToken,
      accessToken: apple.authorizationCode,
    );
  }

  Future<OAuthCredential> _facebookCredential() async {
    final result = await FacebookAuth.instance.login();
    if (result.status != LoginStatus.success || result.accessToken == null) {
      throw Exception('Inicio con Facebook cancelado');
    }
    return FacebookAuthProvider.credential(result.accessToken!.tokenString);
  }

  // --- Firestore users/{uid} ---

  Future<void> _ensureUserDoc(User user) async {
    final ref = _db.collection('users').doc(user.uid);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'name': user.displayName ?? '',
        'email': user.email ?? '',
        'photoUrl': user.photoURL,
        'isSubscriber': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  AppUser _mapBasic(User user) => AppUser(
        id: user.uid,
        name: user.displayName ?? '',
        email: user.email ?? '',
        photoUrl: user.photoURL,
      );

  Future<AppUser> _mapWithSubscription(User user) async {
    final snap = await _db.collection('users').doc(user.uid).get();
    final isSubscriber = (snap.data()?['isSubscriber'] as bool?) ?? false;
    return AppUser(
      id: user.uid,
      name: user.displayName ?? snap.data()?['name'] as String? ?? '',
      email: user.email ?? '',
      photoUrl: user.photoURL,
      isSubscriber: isSubscriber,
    );
  }
}

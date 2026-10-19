import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../data/auth_repository.dart';
import '../data/firebase_auth_repository.dart';
import '../domain/app_user.dart';

/// Provee la implementación de `AuthRepository` según el modo.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (AppConfig.useFirebaseAuth) return FirebaseAuthRepository();
  return MockAuthRepository();
});

/// Estado de la sesión del cliente: null = no autenticado.
class AuthController extends StateNotifier<AppUser?> {
  AuthController(this._repository) : super(_repository.currentUser()) {
    // Mantiene el estado sincronizado con la sesión (login/logout, perfil).
    _sub = _repository.authState().listen((user) => state = user);
  }

  final AuthRepository _repository;
  late final StreamSubscription<AppUser?> _sub;

  Future<void> signIn(String email, String password) async {
    state = await _repository.signIn(email, password);
  }

  Future<void> register(String name, String email, String password) async {
    state = await _repository.register(name, email, password);
  }

  Future<void> signOut() async {
    await _repository.signOut();
    state = null;
  }

  /// Marca al usuario como socio Barra+ tras contratar la membresía.
  Future<void> markAsSubscriber() async {
    final user = state;
    if (user == null) return;
    await _repository.markSubscriber(user.id);
    state = user.copyWith(isSubscriber: true);
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AppUser?>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});

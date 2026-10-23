import 'dart:async';

import '../domain/app_user.dart';

/// Contrato de autenticación de clientes (correo y contraseña). La app usa
/// esta interfaz; la implementación (mock o Firebase) se inyecta vía Riverpod.
abstract interface class AuthRepository {
  /// Usuario actual de forma síncrona (null si no hay sesión). Disponible al
  /// arrancar para que el router decida la pantalla inicial.
  AppUser? currentUser();

  /// Cambios de sesión (login/logout) con el perfil ya cargado.
  Stream<AppUser?> authState();

  /// Inicia sesión con correo y contraseña.
  Future<AppUser> signIn(String email, String password);

  /// Crea una cuenta nueva y su perfil.
  Future<AppUser> register(String name, String email, String password);

  /// Inicia sesión con Google. Lanza si el usuario cancela el flujo.
  Future<AppUser> signInWithGoogle();

  /// Cierra la sesión.
  Future<void> signOut();

  /// Marca al usuario como socio Barra+.
  Future<void> markSubscriber(String userId);
}

/// Implementación de ejemplo para desarrollo sin backend.
class MockAuthRepository implements AuthRepository {
  AppUser? _user;
  final StreamController<AppUser?> _ctrl =
      StreamController<AppUser?>.broadcast();

  @override
  AppUser? currentUser() => _user;

  @override
  Stream<AppUser?> authState() => _ctrl.stream;

  @override
  Future<AppUser> signIn(String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _user = AppUser(
      id: 'demo-user',
      name: email.split('@').first,
      email: email,
    );
    _ctrl.add(_user);
    return _user!;
  }

  @override
  Future<AppUser> register(String name, String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _user = AppUser(id: 'demo-user', name: name, email: email);
    _ctrl.add(_user);
    return _user!;
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _user = const AppUser(
      id: 'demo-google',
      name: 'Usuario Google',
      email: 'demo@gmail.com',
    );
    _ctrl.add(_user);
    return _user!;
  }

  @override
  Future<void> signOut() async {
    _user = null;
    _ctrl.add(null);
  }

  @override
  Future<void> markSubscriber(String userId) async {
    _user = _user?.copyWith(isSubscriber: true);
    _ctrl.add(_user);
  }
}

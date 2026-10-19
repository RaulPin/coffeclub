import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../application/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;
    final name = _name.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Escribe un correo válido.');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'La contraseña debe tener al menos 6 caracteres.');
      return;
    }
    if (_register && name.isEmpty) {
      setState(() => _error = 'Escribe tu nombre.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = ref.read(authControllerProvider.notifier);
      if (_register) {
        await auth.register(name, email, password);
      } else {
        await auth.signIn(email, password);
      }
      if (mounted) context.go('/cafes');
    } on FirebaseAuthException catch (e) {
      setState(() {
        _loading = false;
        _error = _message(e.code);
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _error = 'No pudimos continuar. Inténtalo de nuevo.';
      });
    }
  }

  String _message(String code) => switch (code) {
        'invalid-email' => 'El correo no es válido.',
        'user-not-found' ||
        'wrong-password' ||
        'invalid-credential' =>
          'Correo o contraseña incorrectos.',
        'email-already-in-use' => 'Ese correo ya tiene una cuenta.',
        'weak-password' => 'La contraseña es muy débil (mínimo 6 caracteres).',
        'operation-not-allowed' =>
          'Habilita Correo/contraseña en Firebase → Authentication.',
        'network-request-failed' => 'Sin conexión. Revisa tu internet.',
        _ => 'No pudimos continuar. Inténtalo de nuevo.',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                    child: const Icon(Icons.local_cafe_outlined,
                        color: Colors.white, size: 36),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                const Text(
                  'Barra',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _register
                      ? 'Crea tu cuenta para pedir'
                      : 'Tu café, sin fila.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted, fontSize: 15),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                if (_register) ...[
                  _field(_name, 'Nombre', TextInputType.name),
                  const SizedBox(height: AppSpacing.md),
                ],
                _field(_email, 'Correo', TextInputType.emailAddress),
                const SizedBox(height: AppSpacing.md),
                _field(_password, 'Contraseña', TextInputType.text,
                    obscure: true, onSubmit: _submit),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(_error!,
                      style: const TextStyle(color: Color(0xFFC0392B))),
                ],
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  height: AppRadius.buttonHeight,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.4, color: Colors.white),
                          )
                        : Text(_register ? 'Crear cuenta' : 'Iniciar sesión'),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextButton(
                  onPressed: _loading
                      ? null
                      : () => setState(() {
                            _register = !_register;
                            _error = null;
                          }),
                  child: Text(
                    _register
                        ? '¿Ya tienes cuenta? Inicia sesión'
                        : '¿No tienes cuenta? Crear una',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: () => context.go('/staff'),
                  child: const Text(
                    'Acceso empleados · estación de tienda',
                    style: TextStyle(color: AppColors.muted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    TextInputType keyboard, {
    bool obscure = false,
    VoidCallback? onSubmit,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      obscureText: obscure,
      autocorrect: false,
      enableSuggestions: !obscure,
      textInputAction:
          onSubmit != null ? TextInputAction.done : TextInputAction.next,
      onSubmitted: onSubmit == null ? null : (_) => onSubmit(),
      decoration: InputDecoration(hintText: label),
    );
  }
}

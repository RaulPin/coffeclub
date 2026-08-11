import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../data/auth_repository.dart';
import '../application/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _loading = false;

  Future<void> _signIn(SocialProvider provider) async {
    setState(() => _loading = true);
    await ref.read(authControllerProvider.notifier).signIn(provider);
    if (mounted) context.go('/menu');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text(
                AppConfig.appName.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'BIENVENIDO SOCIO.',
                textAlign: TextAlign.center,
                style: TextStyle(letterSpacing: 3, color: Color(0xFF6B6B6B)),
              ),
              const Spacer(),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else ...[
                _SocialButton(
                  label: 'Continuar con Google',
                  icon: Icons.g_mobiledata,
                  onTap: () => _signIn(SocialProvider.google),
                ),
                const SizedBox(height: 12),
                _SocialButton(
                  label: 'Continuar con Apple',
                  icon: Icons.apple,
                  onTap: () => _signIn(SocialProvider.apple),
                ),
                const SizedBox(height: 12),
                _SocialButton(
                  label: 'Continuar con Facebook',
                  icon: Icons.facebook,
                  onTap: () => _signIn(SocialProvider.facebook),
                ),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

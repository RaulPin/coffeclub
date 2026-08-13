import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../application/staff_auth_controller.dart';
import '../application/shift_controller.dart';
import '../domain/staff_user.dart';

/// Login del personal (empleado o administrador) por usuario y contraseña.
class StaffLoginScreen extends ConsumerStatefulWidget {
  const StaffLoginScreen({super.key});

  @override
  ConsumerState<StaffLoginScreen> createState() => _StaffLoginScreenState();
}

class _StaffLoginScreenState extends ConsumerState<StaffLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await ref.read(staffAuthControllerProvider.notifier).signIn(
            _emailController.text,
            _passwordController.text,
          );
      // El empleado abre turno en su sucursal; el admin va a su dashboard.
      if (user.role == StaffRole.employee && user.branchId != null) {
        ref
            .read(shiftControllerProvider.notifier)
            .startShift(user.name, user.branchId!);
      }
      if (mounted) context.go('/staff');
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Usuario o contraseña incorrectos';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ESTACIÓN DE TIENDA'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            const Text(
              'Acceso de personal',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ingresa con tu usuario y contraseña.',
              style: TextStyle(color: Color(0xFF6B6B6B)),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Usuario (correo)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              onSubmitted: (_) => _signIn(),
              decoration: const InputDecoration(
                labelText: 'Contraseña',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton(
                onPressed: _signIn,
                child: const Text('Iniciar sesión'),
              ),
            const Spacer(),
            if (AppConfig.useMockBackend) const _DemoHint(),
          ],
        ),
      ),
    );
  }
}

/// Pista con las cuentas de prueba (solo modo demo).
class _DemoHint extends StatelessWidget {
  const _DemoHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EEE9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cuentas de prueba (demo):',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          SizedBox(height: 4),
          Text('condesa@theclubcoffe.mx / 1234  → empleado',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B6B6B))),
          Text('roma@theclubcoffe.mx / 1234  → empleado',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B6B6B))),
          Text('admin@theclubcoffe.mx / admin  → administrador',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B6B6B))),
        ],
      ),
    );
  }
}

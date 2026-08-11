import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/shift_controller.dart';

/// Pantalla donde el empleado del turno inicia sesión y abre su turno.
class StaffLoginScreen extends ConsumerStatefulWidget {
  const StaffLoginScreen({super.key});

  @override
  ConsumerState<StaffLoginScreen> createState() => _StaffLoginScreenState();
}

class _StaffLoginScreenState extends ConsumerState<StaffLoginScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _start() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    ref.read(shiftControllerProvider.notifier).startShift(name);
    context.go('/staff');
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
              'Iniciar turno',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ingresa tu nombre para comenzar a recibir pedidos.',
              style: TextStyle(color: Color(0xFF6B6B6B)),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _start(),
              decoration: const InputDecoration(
                labelText: 'Nombre del empleado',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _start,
              child: const Text('Iniciar turno'),
            ),
          ],
        ),
      ),
    );
  }
}

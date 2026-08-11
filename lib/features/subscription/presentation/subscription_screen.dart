import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/application/auth_controller.dart';
import '../../checkout/data/payment_service.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  bool _loading = false;

  Future<void> _subscribe() async {
    setState(() => _loading = true);
    final result =
        await ref.read(paymentServiceProvider).startSubscription();
    if (!mounted) return;
    if (result.success) {
      ref.read(authControllerProvider.notifier).markAsSubscriber();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Bienvenido, socio!')),
      );
      context.pop();
    } else {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${result.error ?? 'desconocido'}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MEMBRESÍA')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            const Text(
              'Socio The Club Coffe',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            const Text(
              'Accede a 1 café Americano al día por solo \$1. Disponible 24/7.',
              style: TextStyle(color: Color(0xFF6B6B6B), fontSize: 16),
            ),
            const SizedBox(height: 24),
            ...const [
              _Benefit('1 Americano al día por \$1'),
              _Benefit('Acceso 24/7 a la sucursal'),
              _Benefit('Pedidos y recogida sin filas'),
              _Benefit('Cancela cuando quieras'),
            ],
            const Spacer(),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton(
                onPressed: _subscribe,
                child: const Text('Suscribirme'),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }
}

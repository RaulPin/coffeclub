import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/money.dart';
import '../../cart/application/cart_controller.dart';
import '../../orders/data/order_repository.dart';
import '../data/payment_service.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool _loading = false;

  Future<void> _pay() async {
    setState(() => _loading = true);
    final items = ref.read(cartControllerProvider);
    final total = ref.read(cartTotalProvider);

    final result = await ref.read(paymentServiceProvider).chargeOnce(total);
    if (!mounted) return;

    if (!result.success) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pago rechazado: ${result.error ?? ''}')),
      );
      return;
    }

    // Pago OK -> crear pedido y asignar casillero.
    await ref
        .read(activeOrderProvider.notifier)
        .createOrder(items, total);
    ref.read(cartControllerProvider.notifier).clear();

    if (mounted) context.go('/order');
  }

  @override
  Widget build(BuildContext context) {
    final total = ref.watch(cartTotalProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('PAGO')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            const Text('Método de pago',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.credit_card),
                title: const Text('Tarjeta •••• 4242'),
                subtitle: const Text('Pago con Stripe (demo)'),
                trailing: const Icon(Icons.check_circle, color: Colors.green),
                onTap: () {},
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total a pagar', style: TextStyle(fontSize: 16)),
                Text(formatCents(total),
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton(
                onPressed: total == 0 ? null : _pay,
                child: Text('Pagar ${formatCents(total)}'),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

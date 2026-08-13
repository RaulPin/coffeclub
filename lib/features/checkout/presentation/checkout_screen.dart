import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/money.dart';
import '../../auth/application/auth_controller.dart';
import '../../branches/data/branch_repository.dart';
import '../../cart/application/cart_controller.dart';
import '../../cart/application/pricing.dart';
import '../../orders/data/orders_repository.dart';
import '../../subscription/application/daily_perk.dart';
import '../data/checkout_service.dart';

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
    final pricing = ref.read(cartPricingProvider);
    final userId = ref.read(authControllerProvider)?.id ?? 'demo-user';
    final branchId = ref.read(selectedBranchIdProvider) ??
        ref.read(branchesProvider).valueOrNull?.first.id ??
        'condesa';

    final result = await ref.read(checkoutServiceProvider).placeOrder(
          items: items,
          amountCents: pricing.totalCents,
          userId: userId,
          branchId: branchId,
        );
    if (!mounted) return;

    if (!result.success || result.orderId == null) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pago no completado: ${result.error ?? ''}')),
      );
      return;
    }

    // Si se usó el beneficio del Americano, márcalo consumido por hoy.
    // (En producción, esto lo confirma el servidor al registrar la orden.)
    if (pricing.perkApplied) {
      ref.read(lastPerkRedemptionProvider.notifier).state = DateTime.now();
    }

    ref.read(activeOrderIdProvider.notifier).state = result.orderId;
    ref.read(cartControllerProvider.notifier).clear();

    if (mounted) context.go('/order');
  }

  @override
  Widget build(BuildContext context) {
    final pricing = ref.watch(cartPricingProvider);
    final total = pricing.totalCents;

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
            if (pricing.perkApplied) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Beneficio socio (1 Americano)',
                      style: TextStyle(color: Colors.green.shade700)),
                  Text('-${formatCents(pricing.perkDiscountCents)}',
                      style: TextStyle(color: Colors.green.shade700)),
                ],
              ),
              const SizedBox(height: 8),
            ],
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/money.dart';
import '../application/cart_controller.dart';
import '../application/pricing.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(cartControllerProvider);
    final pricing = ref.watch(cartPricingProvider);
    final cart = ref.read(cartControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('TU PEDIDO')),
      body: items.isEmpty
          ? const Center(child: Text('Tu carrito está vacío'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final item = items[i];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.product.name),
                  subtitle: Text(formatCents(item.product.priceCents)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => cart.remove(item.product),
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text('${item.quantity}',
                          style:
                              const TextStyle(fontWeight: FontWeight.w600)),
                      IconButton(
                        onPressed: () => cart.add(item.product),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                );
              },
            ),
      bottomNavigationBar: items.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (pricing.perkApplied) ...[
                      _Line(
                        label: 'Subtotal',
                        value: formatCents(pricing.subtotalCents),
                        muted: true,
                      ),
                      const SizedBox(height: 4),
                      _Line(
                        label: 'Beneficio socio (1 Americano)',
                        value: '-${formatCents(pricing.perkDiscountCents)}',
                        highlight: true,
                      ),
                      const SizedBox(height: 8),
                    ],
                    _Line(
                      label: 'Total',
                      value: formatCents(pricing.totalCents),
                      bold: true,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => context.push('/checkout'),
                      child: const Text('Ir a pagar'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.label,
    required this.value,
    this.bold = false,
    this.muted = false,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool bold;
  final bool muted;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final color = highlight
        ? Colors.green.shade700
        : (muted ? const Color(0xFF6B6B6B) : Colors.black);
    final style = TextStyle(
      fontSize: bold ? 18 : 15,
      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
      color: color,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style),
      ],
    );
  }
}

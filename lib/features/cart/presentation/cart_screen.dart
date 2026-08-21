import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/money.dart';
import '../application/cart_controller.dart';
import '../application/pricing.dart';
import '../domain/cart_item.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(cartControllerProvider);
    final pricing = ref.watch(cartPricingProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mi carrito')),
      body: items.isEmpty
          ? const _EmptyCart()
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.lg,
                AppSpacing.screen,
                AppSpacing.xxl,
              ),
              children: [
                const _SectionLabel('Tus artículos'),
                const SizedBox(height: AppSpacing.md),
                for (final item in items) ...[
                  _CartCard(item: item),
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
            ),
      bottomNavigationBar:
          items.isEmpty ? null : _SummaryBar(pricing: pricing),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 2,
        color: AppColors.muted,
      ),
    );
  }
}

class _CartCard extends ConsumerWidget {
  const _CartCard({required this.item});
  final CartItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.read(cartControllerProvider.notifier);
    final icon = switch (item.product.category) {
      'Pizza' => Icons.local_pizza_outlined,
      'Postre' => Icons.icecream_outlined,
      _ => Icons.local_cafe_outlined,
    };

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppColors.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 92,
              color: AppColors.paper,
              alignment: Alignment.center,
              child: Icon(icon, size: 32, color: AppColors.faint),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.product.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                formatMxn(item.product.priceCents),
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => cart.removeLine(item.product),
                          child: const Icon(Icons.delete_outline,
                              size: 20, color: AppColors.faint),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _QtyStepper(
                          quantity: item.quantity,
                          onMinus: () => cart.remove(item.product),
                          onPlus: () => cart.add(item.product),
                        ),
                        Text(
                          formatMxn(item.subtotalCents),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  const _QtyStepper({
    required this.quantity,
    required this.onMinus,
    required this.onPlus,
  });

  final int quantity;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _stepButton(Icons.remove, onMinus, enabled: quantity > 1),
          SizedBox(
            width: 28,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
          _stepButton(Icons.add, onPlus, enabled: true),
        ],
      ),
    );
  }

  Widget _stepButton(IconData icon, VoidCallback onTap, {required bool enabled}) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: SizedBox(
        width: 32,
        height: 32,
        child: Icon(
          icon,
          size: 16,
          color: enabled ? AppColors.ink : AppColors.faint,
        ),
      ),
    );
  }
}

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({required this.pricing});
  final CartPricing pricing;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.screen),
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (pricing.perkApplied) ...[
              _Line(
                label: 'Subtotal',
                value: formatMxn(pricing.subtotalCents),
                muted: true,
              ),
              const SizedBox(height: AppSpacing.sm),
              _Line(
                label: 'Beneficio socio (1 Americano)',
                value: '−${formatMxn(pricing.perkDiscountCents)}',
                color: AppColors.success,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            _Line(
              label: 'Casillero',
              value: 'Gratis',
              muted: true,
              valueColor: AppColors.success,
              valueBold: true,
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(),
            const SizedBox(height: AppSpacing.md),
            _Line(
              label: 'Total',
              value: formatMxn(pricing.totalCents),
              bold: true,
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline,
                      size: 18, color: AppColors.muted),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          height: 1.3,
                        ),
                        children: [
                          TextSpan(text: 'Recoge con '),
                          TextSpan(
                            text: 'PIN en tu casillero',
                            style: TextStyle(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(text: ' sin hacer fila.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _PayButton(total: pricing.totalCents),
          ],
        ),
      ),
    );
  }
}

class _PayButton extends StatelessWidget {
  const _PayButton({required this.total});
  final int total;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppRadius.buttonHeight,
      child: ElevatedButton(
        onPressed: () => context.push('/checkout'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.lock_outline, size: 18, color: Colors.white),
                SizedBox(width: AppSpacing.sm),
                Text('Confirmar y pagar'),
              ],
            ),
            Text(formatMxn(total)),
          ],
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
    this.color,
    this.valueColor,
    this.valueBold = false,
  });

  final String label;
  final String value;
  final bool bold;
  final bool muted;
  final Color? color;
  final Color? valueColor;
  final bool valueBold;

  @override
  Widget build(BuildContext context) {
    final baseColor =
        color ?? (muted ? AppColors.muted : AppColors.ink);
    final labelStyle = TextStyle(
      fontSize: bold ? 18 : 14,
      fontWeight: bold ? FontWeight.w900 : FontWeight.w500,
      color: baseColor,
      letterSpacing: bold ? -0.3 : 0,
    );
    final valueStyle = labelStyle.copyWith(
      color: valueColor ?? baseColor,
      fontWeight: valueBold || bold
          ? (bold ? FontWeight.w900 : FontWeight.w800)
          : labelStyle.fontWeight,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(child: Text(label, style: labelStyle)),
        Text(value, style: valueStyle),
      ],
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.sheet),
                boxShadow: AppColors.cardShadow,
              ),
              child: const Icon(Icons.shopping_bag_outlined,
                  size: 32, color: AppColors.muted),
            ),
            const SizedBox(height: AppSpacing.xl),
            const Text(
              'Carrito vacío',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Ve al menú y agrega tus favoritos.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: () => context.go('/menu'),
                child: const Text('Ver menú'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

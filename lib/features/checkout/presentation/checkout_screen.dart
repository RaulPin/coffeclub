import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
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
    final branches = ref.watch(branchesProvider).valueOrNull ?? const [];
    final selectedId = ref.watch(selectedBranchIdProvider);
    String? branchName;
    if (branches.isNotEmpty) {
      final match = branches.where((b) => b.id == selectedId);
      branchName = match.isNotEmpty ? match.first.name : branches.first.name;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Pago')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.lg,
          AppSpacing.screen,
          AppSpacing.xxl,
        ),
        children: [
          const _SectionLabel('Recoger en'),
          const SizedBox(height: AppSpacing.md),
          _InfoRow(
            icon: Icons.location_on_outlined,
            title: branchName ?? 'Sucursal',
            subtitle: 'Recogida en casillero con PIN',
          ),
          const SizedBox(height: AppSpacing.xl),
          const _SectionLabel('Método de pago'),
          const SizedBox(height: AppSpacing.md),
          _InfoRow(
            icon: Icons.credit_card,
            title: 'Tarjeta •••• 4242',
            subtitle: 'Pago con Stripe (demo)',
            trailing: const Icon(Icons.check_circle,
                color: AppColors.success, size: 22),
          ),
          const SizedBox(height: AppSpacing.xl),
          const _SectionLabel('Resumen'),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              boxShadow: AppColors.cardShadow,
            ),
            child: Column(
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
                  const SizedBox(height: AppSpacing.md),
                  const Divider(),
                  const SizedBox(height: AppSpacing.md),
                ],
                _Line(
                  label: 'Total a pagar',
                  value: formatMxn(total),
                  bold: true,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screen),
          child: SizedBox(
            height: AppRadius.buttonHeight,
            child: ElevatedButton(
              onPressed: total == 0 || _loading ? null : _pay,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.lock_outline,
                                size: 18, color: Colors.white),
                            SizedBox(width: AppSpacing.sm),
                            Text('Pagar'),
                          ],
                        ),
                        Text(formatMxn(total)),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            child: Icon(icon, size: 20, color: AppColors.ink),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
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
  });

  final String label;
  final String value;
  final bool bold;
  final bool muted;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? (muted ? AppColors.muted : AppColors.ink);
    final style = TextStyle(
      fontSize: bold ? 18 : 14,
      fontWeight: bold ? FontWeight.w900 : FontWeight.w500,
      color: c,
      letterSpacing: bold ? -0.3 : 0,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(child: Text(label, style: style)),
        Text(value, style: style),
      ],
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

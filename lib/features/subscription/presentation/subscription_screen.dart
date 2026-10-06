import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/money.dart';
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
    final result = await ref.read(paymentServiceProvider).startSubscription();
    if (!mounted) return;
    if (result.success) {
      ref.read(authControllerProvider.notifier).markAsSubscriber();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Bienvenido a Barra+!')),
      );
    } else {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${result.error ?? 'desconocido'}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider);
    final isMember = user?.isSubscriber ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Barra+')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.sm,
          AppSpacing.screen,
          AppSpacing.xxl,
        ),
        children: [
          _ClubCard(isMember: isMember, memberName: user?.name ?? 'Socio'),
          const SizedBox(height: AppSpacing.xl),
          _SectionLabel(isMember ? 'Tus beneficios' : 'Beneficios Barra+'),
          const SizedBox(height: AppSpacing.md),
          const _BenefitsGrid(),
          const SizedBox(height: AppSpacing.xl),
          if (!isMember)
            _JoinCta(loading: _loading, onJoin: _subscribe)
          else
            const _MemberCta(),
        ],
      ),
    );
  }
}

// ─── Club card ──────────────────────────────────────────────────────────────

class _ClubCard extends StatelessWidget {
  const _ClubCard({required this.isMember, required this.memberName});
  final bool isMember;
  final String memberName;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(AppRadius.sheet),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                      child: const Icon(Icons.bolt,
                          size: 18, color: Colors.white),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'BARRA+',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                if (!isMember) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        formatMxn(AppConfig.membershipMonthlyCents)
                            .replaceAll(' MXN', ''),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                      Text(
                        ' / mes',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Sin cuota de servicio en todos tus pedidos, '
                    'en cualquier cafetería.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        const Text(
                          'Socio activo',
                          style: TextStyle(
                            color: Color(0xFF5DD68E),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    memberName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tu membresía Barra+ está activa · \$29 / mes',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Benefits ───────────────────────────────────────────────────────────────

class _BenefitsGrid extends StatelessWidget {
  const _BenefitsGrid();

  static const _benefits = [
    (Icons.payments_outlined, 'Sin cuota de servicio', 'Ahorras \$10 por pedido'),
    (Icons.storefront_outlined, 'En todos los cafés', 'Aplica en toda Barra'),
    (Icons.bolt_outlined, 'Sin fila', 'Pide antes y recoge en barra'),
    (Icons.event_repeat_outlined, 'Sin permanencia', 'Cancela cuando quieras'),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.5,
      children: [
        for (final (icon, title, desc) in _benefits)
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              boxShadow: AppColors.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 22, color: AppColors.ink),
                const Spacer(),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ─── CTAs ───────────────────────────────────────────────────────────────────

class _JoinCta extends StatelessWidget {
  const _JoinCta({required this.loading, required this.onJoin});
  final bool loading;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: AppRadius.buttonHeight,
          child: ElevatedButton(
            onPressed: loading ? null : onJoin,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            ),
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Unirme a Barra+'),
                      Text('\$29 / mes'),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const Text(
          'Sin permanencia · cancela cuando quieras',
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      ],
    );
  }
}

class _MemberCta extends StatelessWidget {
  const _MemberCta();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppRadius.buttonHeight,
      child: ElevatedButton.icon(
        onPressed: () => context.go('/cafes'),
        icon: const Icon(Icons.storefront_outlined, size: 18),
        label: const Text('Explorar cafeterías'),
      ),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../auth/application/auth_controller.dart';
import '../../checkout/data/payment_service.dart';
import '../application/daily_perk.dart';

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
        const SnackBar(content: Text('¡Bienvenido al Club!')),
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
    final isSubscriber = user?.isSubscriber ?? false;
    final perkAvailable = ref.watch(perkAvailableTodayProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Club Coffe')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.sm,
          AppSpacing.screen,
          AppSpacing.xxl,
        ),
        children: [
          _ClubCard(
            isSubscriber: isSubscriber,
            perkAvailable: perkAvailable,
            memberName: user?.name ?? 'Socio',
          ),
          const SizedBox(height: AppSpacing.xl),
          _SectionLabel(isSubscriber ? 'Tus beneficios' : 'Beneficios del Club'),
          const SizedBox(height: AppSpacing.md),
          const _BenefitsGrid(),
          const SizedBox(height: AppSpacing.xl),
          if (!isSubscriber)
            _JoinCta(loading: _loading, onJoin: _subscribe)
          else
            _MemberCta(perkAvailable: perkAvailable),
        ],
      ),
    );
  }
}

// ─── Club card ──────────────────────────────────────────────────────────────

class _ClubCard extends StatelessWidget {
  const _ClubCard({
    required this.isSubscriber,
    required this.perkAvailable,
    required this.memberName,
  });

  final bool isSubscriber;
  final bool perkAvailable;
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
                      child: const Icon(Icons.local_cafe_outlined,
                          size: 18, color: Colors.white),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'THE CLUB COFFE',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                if (!isSubscriber) ...[
                  Text(
                    'MEMBRESÍA CLUB',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      const Text(
                        '\$365',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                      Text(
                        ' / año',
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
                    'Un café al día por \$1 — todos los días del año.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),
                ] else ...[
                  _StatusPill(available: perkAvailable),
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
                    'Membresía anual · \$1 por día',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: perkAvailable
                          ? AppColors.success.withValues(alpha: 0.18)
                          : Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(AppRadius.button),
                      border: Border.all(
                        color: perkAvailable
                            ? AppColors.success.withValues(alpha: 0.35)
                            : Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          perkAvailable
                              ? '¡Disponible hoy!'
                              : 'Beneficio usado',
                          style: TextStyle(
                            color: perkAvailable
                                ? const Color(0xFF5DD68E)
                                : Colors.white.withValues(alpha: 0.5),
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          perkAvailable
                              ? 'Tu Americano por \$1 MXN'
                              : 'Vuelve mañana por tu Americano',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 13,
                          ),
                        ),
                      ],
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

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.available});
  final bool available;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: available
            ? AppColors.success.withValues(alpha: 0.25)
            : Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: available
                  ? AppColors.success
                  : Colors.white.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Socio activo',
            style: TextStyle(
              color: available
                  ? const Color(0xFF5DD68E)
                  : Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
              fontWeight: FontWeight.w700,
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
    (Icons.local_cafe_outlined, '1 café al día', 'Americano por \$1 cada día'),
    (Icons.bolt_outlined, 'Sin fila', 'Recoge directo en tu casillero'),
    (Icons.lock_outline, 'Recogida con PIN', 'Acceso seguro 24/7'),
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
                      Text('Unirme al Club'),
                      Text('\$365 / año'),
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
  const _MemberCta({required this.perkAvailable});
  final bool perkAvailable;

  @override
  Widget build(BuildContext context) {
    if (perkAvailable) {
      return SizedBox(
        height: AppRadius.buttonHeight,
        child: ElevatedButton(
          onPressed: () => context.go('/menu'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.local_cafe_outlined,
                      size: 18, color: Colors.white),
                  SizedBox(width: AppSpacing.sm),
                  Text('Pedir mi Americano'),
                ],
              ),
              Text('\$1 MXN'),
            ],
          ),
        ),
      );
    }
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
            child: const Icon(Icons.check_circle_outline,
                color: AppColors.muted),
          ),
          const SizedBox(width: AppSpacing.lg),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Beneficio canjeado hoy',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                SizedBox(height: 2),
                Text(
                  'Vuelve mañana por tu Americano de \$1.',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
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

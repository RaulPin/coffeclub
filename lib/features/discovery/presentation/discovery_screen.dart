import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../auth/application/auth_controller.dart';
import '../../branches/data/branch_repository.dart';
import '../../branches/domain/branch.dart';

/// Descubrimiento: lista de cafeterías del marketplace. El cliente elige una
/// y entra a su menú.
class DiscoveryScreen extends ConsumerWidget {
  const DiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchesAsync = ref.watch(branchesProvider);
    final user = ref.watch(authControllerProvider);
    final firstName = (user?.name ?? '').split(' ').first;

    return Scaffold(
      appBar: AppBar(title: const Text('Barra')),
      body: branchesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('No pudimos cargar las cafeterías: $e'),
        ),
        data: (branches) => ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.lg,
            AppSpacing.screen,
            AppSpacing.xxl,
          ),
          children: [
            Text(
              firstName.isEmpty ? 'Hola 👋' : 'Hola, $firstName 👋',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              '¿Dónde quieres tu café hoy?',
              style: TextStyle(color: AppColors.muted, fontSize: 14),
            ),
            const SizedBox(height: AppSpacing.xl),
            const Text(
              'CAFETERÍAS CERCA',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final cafe in branches) ...[
              _CafeCard(
                cafe: cafe,
                onTap: () {
                  ref.read(selectedBranchIdProvider.notifier).state = cafe.id;
                  context.push('/cafe');
                },
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ],
        ),
      ),
    );
  }
}

class _CafeCard extends StatelessWidget {
  const _CafeCard({required this.cafe, required this.onTap});
  final Branch cafe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: AppColors.cardShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 130,
              width: double.infinity,
              child: cafe.imageUrl != null
                  ? Image.network(
                      cafe.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          cafe.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      const Icon(Icons.star_rounded,
                          size: 16, color: Color(0xFFF6C445)),
                      const SizedBox(width: 3),
                      Text(
                        cafe.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  if (cafe.tagline.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      cafe.tagline,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      const Icon(Icons.schedule,
                          size: 14, color: AppColors.muted),
                      const SizedBox(width: 4),
                      Text(
                        '~${cafe.etaMinutes} min',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      const Icon(Icons.location_on_outlined,
                          size: 14, color: AppColors.muted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          cafe.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: AppColors.paper,
        alignment: Alignment.center,
        child: const Icon(Icons.storefront_outlined,
            size: 40, color: AppColors.faint),
      );
}

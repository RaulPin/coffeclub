import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../auth/application/auth_controller.dart';
import '../../branches/data/branch_repository.dart';
import '../../branches/domain/branch.dart';
import 'cafe_map.dart';

/// Descubrimiento: lista de cafeterías del marketplace. El cliente elige una
/// y entra a su menú. Puede alternar entre vista de lista y mapa.
class DiscoveryScreen extends ConsumerStatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  ConsumerState<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends ConsumerState<DiscoveryScreen> {
  bool _mapView = false;

  void _openCafe(Branch cafe) {
    ref.read(selectedBranchIdProvider.notifier).state = cafe.id;
    context.push('/cafe');
  }

  @override
  Widget build(BuildContext context) {
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
        data: (branches) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.lg,
                AppSpacing.screen,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: AppSpacing.lg),
                  _ViewToggle(
                    mapView: _mapView,
                    onChanged: (v) => setState(() => _mapView = v),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
            Expanded(
              child: _mapView
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screen,
                        0,
                        AppSpacing.screen,
                        AppSpacing.lg,
                      ),
                      child: CafeMap(branches: branches, onOpen: _openCafe),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screen,
                        0,
                        AppSpacing.screen,
                        AppSpacing.xxl,
                      ),
                      children: [
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
                          _CafeCard(cafe: cafe, onTap: () => _openCafe(cafe)),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Interruptor segmentado Lista / Mapa.
class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.mapView, required this.onChanged});
  final bool mapView;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Row(
        children: [
          _segment('Lista', Icons.view_list_rounded, !mapView, () => onChanged(false)),
          _segment('Mapa', Icons.map_outlined, mapView, () => onChanged(true)),
        ],
      ),
    );
  }

  Widget _segment(String label, IconData icon, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.button - 2),
            boxShadow: active ? AppColors.cardShadow : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16, color: active ? AppColors.ink : AppColors.muted),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: active ? AppColors.ink : AppColors.muted,
                ),
              ),
            ],
          ),
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

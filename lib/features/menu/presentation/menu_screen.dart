import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/money.dart';
import '../../auth/application/auth_controller.dart';
import '../../branches/data/branch_repository.dart';
import '../../branches/domain/branch.dart';
import '../../cart/application/cart_controller.dart';
import '../../subscription/application/daily_perk.dart';
import '../application/cafe_menu_controller.dart';
import '../domain/product.dart';

/// Categoría seleccionada en el filtro del menú. `null` = "Todos".
final _menuFilterProvider = StateProvider.autoDispose<String?>((ref) => null);

/// Menú de una cafetería (la seleccionada en descubrimiento).
class CafeMenuScreen extends ConsumerWidget {
  const CafeMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branches = ref.watch(branchesProvider).valueOrNull ?? const [];
    final selectedId = ref.watch(selectedBranchIdProvider);
    final matches = branches.where((b) => b.id == selectedId).toList();
    final cafe = matches.isNotEmpty
        ? matches.first
        : (branches.isNotEmpty ? branches.first : null);

    if (cafe == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final products = ref.watch(cafeClientMenuProvider(cafe.id));
    final user = ref.watch(authControllerProvider);
    final cartCount = ref.watch(cartControllerProvider).fold<int>(
          0,
          (sum, item) => sum + item.quantity,
        );
    final filter = ref.watch(_menuFilterProvider);

    final categories = <String>[
      for (final c in const ['Café', 'Pizza', 'Postre'])
        if (products.any((p) => p.category == c)) c,
    ];
    final visible = filter == null
        ? products
        : products.where((p) => p.category == filter).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(cafe.name),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: _CartButton(count: cartCount),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.lg,
          AppSpacing.screen,
          AppSpacing.xxl,
        ),
        children: [
          _CafeHeader(cafe: cafe),
          const SizedBox(height: AppSpacing.lg),
          if (user != null && !user.isSubscriber) ...[
            _SubscriptionBanner(onTap: () => context.push('/subscription')),
            const SizedBox(height: AppSpacing.lg),
          ],
          _FilterChips(
            categories: categories,
            selected: filter,
            onSelected: (c) =>
                ref.read(_menuFilterProvider.notifier).state = c,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (visible.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(
                child: Text('Esta cafetería aún no tiene productos aquí.',
                    style: TextStyle(color: AppColors.muted)),
              ),
            )
          else
            for (final product in visible) ...[
              _ProductCard(product: product),
              const SizedBox(height: AppSpacing.md),
            ],
        ],
      ),
    );
  }
}

// ─── Café header ────────────────────────────────────────────────────────────

class _CafeHeader extends StatelessWidget {
  const _CafeHeader({required this.cafe});
  final Branch cafe;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.sheet),
        color: AppColors.ink,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (cafe.imageUrl != null)
            Image.network(
              cafe.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.15),
                  Colors.black.withValues(alpha: 0.75),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  cafe.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                if (cafe.tagline.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    cafe.tagline,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 15, color: Color(0xFFF6C445)),
                    const SizedBox(width: 3),
                    Text(
                      cafe.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Icon(Icons.schedule,
                        size: 14, color: Colors.white.withValues(alpha: 0.8)),
                    const SizedBox(width: 3),
                    Text(
                      '~${cafe.etaMinutes} min',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── App bar cart button ────────────────────────────────────────────────────

class _CartButton extends StatelessWidget {
  const _CartButton({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/cart'),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(color: AppColors.border),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.shopping_bag_outlined, size: 20),
            if (count > 0)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 16,
                  height: 16,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.ink,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Subscription banner ────────────────────────────────────────────────────

class _SubscriptionBanner extends StatelessWidget {
  const _SubscriptionBanner({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.ink,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Únete al Club',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const Text(
                      '1 café al día por \$1',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '\$365 al año · cancela cuando quieras',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                child: const Icon(Icons.arrow_forward,
                    color: Colors.white, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Filter chips ───────────────────────────────────────────────────────────

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final options = <String?>[null, ...categories];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, i) {
          final value = options[i];
          final active = value == selected;
          return GestureDetector(
            onTap: () => onSelected(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? AppColors.ink : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: active ? AppColors.ink : AppColors.border,
                ),
              ),
              child: Text(
                value ?? 'Todos',
                style: TextStyle(
                  color: active ? Colors.white : AppColors.muted,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Product card ───────────────────────────────────────────────────────────

class _ProductCard extends ConsumerWidget {
  const _ProductCard({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider);
    final perkAvailable = ref.watch(perkAvailableTodayProvider);
    final isSubscriber = user?.isSubscriber ?? false;
    final showPerk = product.eligibleForDailyPerk;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppColors.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              _ProductImage(product: product),
              if (showPerk)
                Positioned(
                  top: AppSpacing.md,
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  child: _PerkBadge(
                    isSubscriber: isSubscriber,
                    available: perkAvailable,
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  product.description,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formatMxn(product.priceCents),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    _AddButton(product: product),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.product});
  final Product product;

  IconData get _categoryIcon => switch (product.category) {
        'Pizza' => Icons.local_pizza_outlined,
        'Postre' => Icons.icecream_outlined,
        _ => Icons.local_cafe_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final url = product.imageUrl;
    return SizedBox(
      height: 150,
      width: double.infinity,
      child: url != null && url.isNotEmpty
          ? Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(),
            )
          : _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.paper,
      alignment: Alignment.center,
      child: Icon(_categoryIcon, size: 44, color: AppColors.faint),
    );
  }
}

class _PerkBadge extends StatelessWidget {
  const _PerkBadge({required this.isSubscriber, required this.available});
  final bool isSubscriber;
  final bool available;

  @override
  Widget build(BuildContext context) {
    final usedToday = isSubscriber && !available;
    final bg = usedToday ? AppColors.success : AppColors.ink;
    final text = isSubscriber
        ? (available ? 'Tu Americano por \$1 hoy' : 'Beneficio de hoy usado')
        : '1 café al día por \$1 — socio';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            usedToday ? Icons.check_circle_outline : Icons.star_rounded,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddButton extends ConsumerWidget {
  const _AddButton({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        ref.read(cartControllerProvider.notifier).add(product);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('${product.name} agregado'),
              duration: const Duration(milliseconds: 800),
            ),
          );
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 20),
      ),
    );
  }
}

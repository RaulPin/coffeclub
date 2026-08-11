import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/money.dart';
import '../../auth/application/auth_controller.dart';
import '../../cart/application/cart_controller.dart';
import '../data/menu_repository.dart';
import '../domain/product.dart';

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menu = ref.watch(menuByCategoryProvider);
    final user = ref.watch(authControllerProvider);
    final cartCount = ref.watch(cartControllerProvider).fold<int>(
          0,
          (sum, item) => sum + item.quantity,
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('MENÚ'),
        actions: [
          IconButton(
            onPressed: () => context.push('/cart'),
            icon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              child: const Icon(Icons.shopping_bag_outlined),
            ),
          ),
        ],
      ),
      body: menu.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (grouped) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (user != null && !user.isSubscriber)
              _SubscriptionBanner(
                onTap: () => context.push('/subscription'),
              ),
            for (final entry in grouped.entries) ...[
              _CategoryHeader(
                title: entry.key,
                subtitle: entry.key == 'Pizza'
                    ? '30 cm · 6 rebanadas · ideal para 2 · todas \$130'
                    : null,
              ),
              ...entry.value.map((p) => _ProductTile(product: p)),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.title, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!,
                style: const TextStyle(color: Color(0xFF6B6B6B), fontSize: 12)),
          ],
          const SizedBox(height: 4),
          Container(height: 2, width: 40, color: Colors.black),
        ],
      ),
    );
  }
}

class _SubscriptionBanner extends StatelessWidget {
  const _SubscriptionBanner({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.black,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '1 CAFÉ AL DÍA POR \$1.',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Hazte socio. Toca para suscribirte.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductTile extends ConsumerWidget {
  const _ProductTile({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.description,
                    style: const TextStyle(color: Color(0xFF6B6B6B)),
                  ),
                  const SizedBox(height: 8),
                  Text(formatCents(product.priceCents),
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            IconButton.filled(
              onPressed: () {
                ref.read(cartControllerProvider.notifier).add(product);
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text('${product.name} agregado'),
                      duration: const Duration(milliseconds: 700),
                    ),
                  );
              },
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }
}

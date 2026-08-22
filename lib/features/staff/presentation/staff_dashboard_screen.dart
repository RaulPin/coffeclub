import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/money.dart';
import '../../branches/data/branch_repository.dart';
import '../../orders/data/orders_repository.dart';
import '../../orders/domain/order.dart';
import '../application/shift_controller.dart';

/// Estado visual de un pedido (reutiliza la paleta semántica del diseño).
OrderStage _stageOf(OrderStatus s) => switch (s) {
      OrderStatus.pending => OrderStage.queued,
      OrderStatus.preparing => OrderStage.preparing,
      OrderStatus.ready => OrderStage.ready,
      OrderStatus.pickedUp => OrderStage.collected,
    };

/// Filtro de estado activo en el dashboard (null = todos).
final _staffFilterProvider =
    StateProvider.autoDispose<OrderStatus?>((ref) => null);

/// Panel del empleado: cola de pedidos de SU sucursal en tiempo real.
class StaffDashboardScreen extends ConsumerWidget {
  const StaffDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shift = ref.watch(shiftControllerProvider);
    final branchId = shift?.branchId ?? '';

    final all = ref.watch(allOrdersProvider).valueOrNull ?? const [];
    final branchOrders =
        all.where((o) => o.branchId == branchId).toList();

    final branches = ref.watch(branchesProvider).valueOrNull ?? const [];
    final matches = branches.where((b) => b.id == branchId).toList();
    final branchName = matches.isEmpty ? null : matches.first.name;

    final filter = ref.watch(_staffFilterProvider);
    final now = DateTime.now();

    bool isToday(DateTime d) =>
        d.year == now.year && d.month == now.month && d.day == now.day;

    final active =
        branchOrders.where((o) => o.status != OrderStatus.pickedUp).toList();
    final salesToday = branchOrders
        .where((o) => o.status == OrderStatus.pickedUp && isToday(o.createdAt))
        .fold<int>(0, (s, o) => s + o.totalCents);

    int countOf(OrderStatus s) =>
        branchOrders.where((o) => o.status == s).length;

    final visible = (filter == null
        ? branchOrders.where((o) => o.status != OrderStatus.pickedUp).toList()
        : branchOrders.where((o) => o.status == filter).toList())
      ..sort((a, b) {
        final pr = _priority(a.status).compareTo(_priority(b.status));
        return pr != 0 ? pr : a.createdAt.compareTo(b.createdAt);
      });

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(branchName == null ? 'Pedidos' : 'Sucursal $branchName'),
        actions: [
          TextButton.icon(
            onPressed: () => context.push('/staff/close'),
            icon: const Icon(Icons.point_of_sale, size: 18),
            label: const Text('Cierre'),
          ),
          const SizedBox(width: AppSpacing.sm),
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
          _StatsRow(
            active: active.length,
            queued: countOf(OrderStatus.pending),
            preparing: countOf(OrderStatus.preparing),
            ready: countOf(OrderStatus.ready),
            salesTodayCents: salesToday,
          ),
          const SizedBox(height: AppSpacing.lg),
          _FilterChips(
            selected: filter,
            counts: {
              null: active.length,
              OrderStatus.pending: countOf(OrderStatus.pending),
              OrderStatus.preparing: countOf(OrderStatus.preparing),
              OrderStatus.ready: countOf(OrderStatus.ready),
              OrderStatus.pickedUp: countOf(OrderStatus.pickedUp),
            },
            onSelected: (f) =>
                ref.read(_staffFilterProvider.notifier).state = f,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (visible.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 48),
              child: Center(
                child: Text(
                  'Sin pedidos en esta vista.\nLlegan aquí en tiempo real.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted),
                ),
              ),
            )
          else
            for (final order in visible) ...[
              _OrderCard(order: order),
              const SizedBox(height: AppSpacing.md),
            ],
        ],
      ),
    );
  }

  int _priority(OrderStatus s) => switch (s) {
        OrderStatus.pending => 0,
        OrderStatus.preparing => 1,
        OrderStatus.ready => 2,
        OrderStatus.pickedUp => 3,
      };
}

// ─── Stats row ──────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.active,
    required this.queued,
    required this.preparing,
    required this.ready,
    required this.salesTodayCents,
  });

  final int active;
  final int queued;
  final int preparing;
  final int ready;
  final int salesTodayCents;

  @override
  Widget build(BuildContext context) {
    final tiles = <({String label, String value})>[
      (label: 'Activos', value: '$active'),
      (label: 'En cola', value: '$queued'),
      (label: 'Preparando', value: '$preparing'),
      (label: 'Listos', value: '$ready'),
      (label: 'Vendido hoy', value: formatMxn(salesTodayCents)),
    ];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.9,
      children: [
        for (final t in tiles)
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.button),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  t.label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    t.value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ─── Filter chips ───────────────────────────────────────────────────────────

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.selected,
    required this.counts,
    required this.onSelected,
  });

  final OrderStatus? selected;
  final Map<OrderStatus?, int> counts;
  final ValueChanged<OrderStatus?> onSelected;

  @override
  Widget build(BuildContext context) {
    final options = <({OrderStatus? value, String label})>[
      (value: null, label: 'Activos'),
      (value: OrderStatus.pending, label: 'En cola'),
      (value: OrderStatus.preparing, label: 'Preparando'),
      (value: OrderStatus.ready, label: 'Listo'),
      (value: OrderStatus.pickedUp, label: 'Recogido'),
    ];
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, i) {
          final o = options[i];
          final active = o.value == selected;
          final dotColor = o.value == null
              ? null
              : OrderStageStyle.of(_stageOf(o.value!)).dot;
          return GestureDetector(
            onTap: () => onSelected(o.value),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              decoration: BoxDecoration(
                color: active ? AppColors.ink : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.button),
                border: Border.all(
                  color: active ? AppColors.ink : AppColors.border,
                ),
              ),
              child: Row(
                children: [
                  if (dotColor != null) ...[
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: active ? Colors.white54 : dotColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    o.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: active ? Colors.white : AppColors.muted,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${counts[o.value] ?? 0}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: active ? Colors.white : AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Order card ─────────────────────────────────────────────────────────────

class _OrderCard extends ConsumerWidget {
  const _OrderCard({required this.order});
  final CoffeeOrder order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(ordersRepositoryProvider);
    final style = OrderStageStyle.of(_stageOf(order.status));
    final minutes = DateTime.now().difference(order.createdAt).inMinutes;
    final collected = order.status == OrderStatus.pickedUp;
    final urgent = !collected && minutes >= 8;
    final itemsLine = order.items
        .map((i) => '${i.quantity > 1 ? '${i.quantity}× ' : ''}${i.product.name}')
        .join(', ');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: urgent ? AppColors.warning : AppColors.border,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (urgent) Container(height: 3, color: AppColors.warning),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            order.id,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                          if (urgent) ...[
                            const SizedBox(width: AppSpacing.sm),
                            const Icon(Icons.warning_amber_rounded,
                                size: 14, color: AppColors.warning),
                            const SizedBox(width: 2),
                            const Text(
                              'Tardando',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF7A4F00),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    _StatusPill(style: style),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  itemsLine,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    const Icon(Icons.schedule,
                        size: 13, color: AppColors.muted),
                    const SizedBox(width: 4),
                    Text(
                      minutes < 1 ? 'ahora' : 'hace $minutes min',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      formatMxn(order.totalCents),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                if (order.status == OrderStatus.ready &&
                    order.lockerNumber != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      _InfoChip(
                        icon: Icons.lock_outline,
                        label: 'Casillero #${order.lockerNumber}',
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      if (order.lockerPin != null)
                        _InfoChip(label: 'PIN ${order.lockerPin}'),
                    ],
                  ),
                ],
                if (!collected) ...[
                  const SizedBox(height: AppSpacing.md),
                  _ActionButton(order: order, repo: repo),
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
  const _StatusPill({required this.style});
  final OrderStageStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 5),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: style.dot),
          ),
          const SizedBox(width: 6),
          Text(
            style.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: style.foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({this.icon, required this.label});
  final IconData? icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: AppColors.ink),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.order, required this.repo});
  final CoffeeOrder order;
  final OrdersRepository repo;

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final IconData icon;
    late final Color color;
    late final Color fg;
    VoidCallback? onTap;

    switch (order.status) {
      case OrderStatus.pending:
        label = 'Iniciar preparación';
        icon = Icons.play_arrow_rounded;
        color = AppColors.warning;
        fg = AppColors.ink;
        onTap = () => repo.startPreparing(order.id);
      case OrderStatus.preparing:
        label = 'Marcar como listo';
        icon = Icons.inventory_2_outlined;
        color = AppColors.success;
        fg = Colors.white;
        onTap = () => repo.markReady(order.id);
      case OrderStatus.ready:
        label = 'Confirmar recogida';
        icon = Icons.check_rounded;
        color = AppColors.ink;
        fg = Colors.white;
        onTap = () => repo.pickUp(order.id);
      case OrderStatus.pickedUp:
        label = 'Recogido';
        icon = Icons.check_rounded;
        color = AppColors.border;
        fg = AppColors.muted;
        onTap = null;
    }

    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: fg,
          minimumSize: const Size.fromHeight(44),
        ),
        icon: Icon(icon, size: 18),
        label: Text(label),
      ),
    );
  }
}

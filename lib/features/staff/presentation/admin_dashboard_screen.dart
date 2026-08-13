import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/money.dart';
import '../../branches/domain/branch.dart';
import '../../branches/data/branch_repository.dart';
import '../../orders/data/orders_repository.dart';
import '../../orders/domain/order.dart';
import '../application/staff_auth_controller.dart';

/// Métricas de una sucursal calculadas desde las órdenes.
class _BranchMetrics {
  const _BranchMetrics({
    required this.activeOrders,
    required this.inLocker,
    required this.todaySalesCents,
  });
  final int activeOrders;
  final int inLocker;
  final int todaySalesCents;
}

_BranchMetrics _metricsFor(String branchId, List<CoffeeOrder> orders) {
  final now = DateTime.now();
  var active = 0;
  var inLocker = 0;
  var sales = 0;
  for (final o in orders) {
    if (o.branchId != branchId) continue;
    if (o.status != OrderStatus.pickedUp) active++;
    if (o.status == OrderStatus.ready) inLocker++;
    final sameDay = o.createdAt.year == now.year &&
        o.createdAt.month == now.month &&
        o.createdAt.day == now.day;
    if (sameDay) sales += o.totalCents;
  }
  return _BranchMetrics(
    activeOrders: active,
    inLocker: inLocker,
    todaySalesCents: sales,
  );
}

/// Panel del administrador general: todas las sucursales de un vistazo.
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchesAsync = ref.watch(branchesProvider);
    final List<CoffeeOrder> orders =
        ref.watch(allOrdersProvider).valueOrNull ?? const [];
    final admin = ref.watch(staffAuthControllerProvider);

    final totalTodaySales = orders.fold<int>(0, (sum, o) {
      final now = DateTime.now();
      final sameDay = o.createdAt.year == now.year &&
          o.createdAt.month == now.month &&
          o.createdAt.day == now.day;
      return sameDay ? sum + o.totalCents : sum;
    });

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('ADMINISTRACIÓN'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await ref.read(staffAuthControllerProvider.notifier).signOut();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: branchesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (branches) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Hola, ${admin?.name ?? 'Administrador'}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text('Ventas de hoy (todas las sucursales): '
                '${formatCents(totalTodaySales)}'),
            const SizedBox(height: 16),
            ...branches.map((b) => _BranchCard(
                  branch: b,
                  metrics: _metricsFor(b.id, orders),
                )),
          ],
        ),
      ),
    );
  }
}

class _BranchCard extends StatelessWidget {
  const _BranchCard({required this.branch, required this.metrics});
  final Branch branch;
  final _BranchMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/staff/branch/${branch.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(branch.name,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                  const Icon(Icons.chevron_right),
                ],
              ),
              Text(branch.address,
                  style: const TextStyle(color: Color(0xFF6B6B6B), fontSize: 12)),
              const SizedBox(height: 16),
              Row(
                children: [
                  _Metric(label: 'Activos', value: '${metrics.activeOrders}'),
                  _Metric(label: 'En casillero', value: '${metrics.inLocker}'),
                  _Metric(
                      label: 'Ventas hoy',
                      value: formatCents(metrics.todaySalesCents)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          Text(label,
              style: const TextStyle(color: Color(0xFF6B6B6B), fontSize: 12)),
        ],
      ),
    );
  }
}

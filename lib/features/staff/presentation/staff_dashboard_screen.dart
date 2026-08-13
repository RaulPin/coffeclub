import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/money.dart';
import '../../branches/data/branch_repository.dart';
import '../../orders/data/orders_repository.dart';
import '../../orders/domain/order.dart';
import '../application/shift_controller.dart';

/// Panel del empleado: cola de pedidos de SU sucursal en tiempo real.
class StaffDashboardScreen extends ConsumerWidget {
  const StaffDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shift = ref.watch(shiftControllerProvider);
    final branchId = shift?.branchId ?? '';
    final List<CoffeeOrder> queue = ref.watch(branchQueueProvider(branchId));

    final branches = ref.watch(branchesProvider).valueOrNull ?? const [];
    final matches = branches.where((b) => b.id == branchId).toList();
    final branchName = matches.isEmpty ? null : matches.first.name;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(branchName == null ? 'PEDIDOS' : 'Sucursal $branchName'),
        actions: [
          TextButton.icon(
            onPressed: () => context.push('/staff/close'),
            icon: const Icon(Icons.point_of_sale),
            label: const Text('Cierre de caja'),
          ),
        ],
      ),
      body: queue.isEmpty
          ? const Center(
              child: Text('Sin pedidos por ahora.\nLlegan aquí en tiempo real.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF6B6B6B))),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: queue.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _OrderCard(order: queue[i]),
            ),
    );
  }
}

class _OrderCard extends ConsumerWidget {
  const _OrderCard({required this.order});
  final CoffeeOrder order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(ordersRepositoryProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('#${order.id.substring(order.id.length - 4)}',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                _StatusChip(status: order.status),
              ],
            ),
            const SizedBox(height: 8),
            ...order.items.map(
              (it) => Text('${it.quantity}× ${it.product.name}'),
            ),
            const SizedBox(height: 8),
            Text('Total: ${formatCents(order.totalCents)}',
                style: const TextStyle(color: Color(0xFF6B6B6B))),
            const SizedBox(height: 12),
            if (order.status == OrderStatus.pending)
              ElevatedButton(
                onPressed: () => repo.startPreparing(order.id),
                child: const Text('Empezar a preparar'),
              )
            else if (order.status == OrderStatus.preparing)
              ElevatedButton.icon(
                onPressed: () => repo.markReady(order.id),
                icon: const Icon(Icons.inventory_2_outlined),
                label: const Text('Marcar listo y asignar casillero'),
              )
            else if (order.status == OrderStatus.ready)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Colócalo en el casillero ${order.lockerNumber}. '
                  'Esperando recogida del socio.',
                  style: TextStyle(color: Colors.green.shade900),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      OrderStatus.pending => Colors.orange,
      OrderStatus.preparing => Colors.blue,
      OrderStatus.ready => Colors.green,
      OrderStatus.pickedUp => Colors.grey,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status.label,
          style: TextStyle(color: color, fontWeight: FontWeight.w600)),
    );
  }
}

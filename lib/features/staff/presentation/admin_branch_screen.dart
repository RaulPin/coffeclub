import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/money.dart';
import '../../branches/data/branch_repository.dart';
import '../../orders/data/orders_repository.dart';
import '../../orders/domain/order.dart';

/// Vista de solo lectura para el admin: pedidos activos de una sucursal.
class AdminBranchScreen extends ConsumerWidget {
  const AdminBranchScreen({super.key, required this.branchId});

  final String branchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(branchQueueProvider(branchId));
    final branches = ref.watch(branchesProvider).valueOrNull ?? const [];
    final matches = branches.where((b) => b.id == branchId).toList();
    final branchName = matches.isEmpty ? branchId : matches.first.name;

    return Scaffold(
      appBar: AppBar(title: Text(branchName)),
      body: queue.isEmpty
          ? const Center(
              child: Text('Sin pedidos activos ahora.',
                  style: TextStyle(color: Color(0xFF6B6B6B))),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: queue.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final o = queue[i];
                return Card(
                  child: ListTile(
                    title: Text('#${o.id.substring(o.id.length - 4)} · '
                        '${formatCents(o.totalCents)}'),
                    subtitle: Text(
                      o.items.map((it) => '${it.quantity}× ${it.product.name}')
                          .join(', '),
                    ),
                    trailing: Text(
                      o.status.label,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

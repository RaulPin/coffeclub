import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/config/app_config.dart';
import '../../../core/utils/money.dart';
import '../../orders/data/orders_repository.dart';
import '../../orders/domain/order.dart';
import '../application/shift_controller.dart';
import '../application/staff_auth_controller.dart';
import '../domain/shift.dart';

/// Cierre de caja: resumen del turno antes de entregar a la siguiente persona.
class ShiftCloseScreen extends ConsumerWidget {
  const ShiftCloseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shift = ref.watch(shiftControllerProvider);
    final List<CoffeeOrder> orders =
        ref.watch(allOrdersProvider).valueOrNull ?? const [];
    final pendingPickup = ref.watch(unfinishedOrdersProvider);

    if (shift == null) {
      return const Scaffold(
        body: Center(child: Text('No hay turno abierto.')),
      );
    }

    // Economía del turno para la cafetería (comisión de Barra sobre productos).
    final duringShift =
        orders.where((o) => !o.createdAt.isBefore(shift.startedAt)).toList();
    final productSales = duringShift.fold<int>(
      0,
      (sum, o) => sum + o.items.fold<int>(0, (s, i) => s + i.subtotalCents),
    );
    final commission =
        (productSales * AppConfig.platformCommissionRate).round();
    final cafeNet = productSales - commission;
    final timeFmt = DateFormat('HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('CIERRE DE CAJA')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Text('Turno de ${shift.employeeName}',
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800)),
            Text('Inició a las ${timeFmt.format(shift.startedAt)}',
                style: const TextStyle(color: Color(0xFF6B6B6B))),
            const SizedBox(height: 24),
            _StatRow(label: 'Órdenes atendidas', value: '${duringShift.length}'),
            const Divider(),
            _StatRow(
                label: 'Ventas (productos)', value: formatMxn(productSales)),
            const Divider(),
            _StatRow(
                label: 'Comisión Barra (5%)',
                value: '−${formatMxn(commission)}'),
            const Divider(),
            _StatRow(
                label: 'Neto para la cafetería',
                value: formatMxn(cafeNet),
                strong: true),
            const Divider(),
            _StatRow(
                label: 'Pedidos aún por recoger',
                value: '${pendingPickup.length}'),
            if (pendingPickup.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Aún en barra: códigos '
                '${pendingPickup.map((o) => o.pickupCode).join(', ')}.',
                style: TextStyle(color: Colors.orange.shade800),
              ),
            ],
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () => _confirmClose(context, ref),
              icon: const Icon(Icons.lock_clock),
              label: const Text('Cerrar turno'),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClose(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cerrar turno?'),
        content: const Text(
            'Se generará el cierre de caja y el siguiente empleado deberá '
            'iniciar sesión para continuar.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Cerrar turno')),
        ],
      ),
    );

    if (confirmed != true) return;

    final report = ref.read(shiftControllerProvider.notifier).closeShift();
    // Cierra la sesión del empleado: el siguiente turno inicia sesión.
    await ref.read(staffAuthControllerProvider.notifier).signOut();
    if (report != null && context.mounted) {
      _showReport(context, report);
    }
  }

  void _showReport(BuildContext context, ShiftReport report) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Cierre completado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Empleado: ${report.shift.employeeName}'),
            Text('Órdenes: ${report.ordersCount}'),
            Text('Ventas: ${formatCents(report.totalSalesCents)}'),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Volver a la pantalla de inicio de turno para el relevo.
              context.go('/staff');
            },
            child: const Text('Entregar turno'),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    this.strong = false,
  });
  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: strong ? FontWeight.w800 : FontWeight.w500,
              )),
          Text(value,
              style: TextStyle(
                  fontSize: strong ? 20 : 18, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

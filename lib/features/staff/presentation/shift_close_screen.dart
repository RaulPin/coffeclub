import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/money.dart';
import '../../orders/data/orders_store.dart';
import '../application/shift_controller.dart';
import '../domain/shift.dart';

/// Cierre de caja: resumen del turno antes de entregar a la siguiente persona.
class ShiftCloseScreen extends ConsumerWidget {
  const ShiftCloseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shift = ref.watch(shiftControllerProvider);
    final orders = ref.watch(ordersStoreProvider);
    final pendingPickup = ref.watch(unfinishedOrdersProvider);

    if (shift == null) {
      return const Scaffold(
        body: Center(child: Text('No hay turno abierto.')),
      );
    }

    // Vista previa de los totales del turno (mismo cálculo que el cierre).
    final duringShift =
        orders.where((o) => !o.createdAt.isBefore(shift.startedAt)).toList();
    final totalCents =
        duringShift.fold<int>(0, (sum, o) => sum + o.totalCents);
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
                label: 'Ventas del turno', value: formatCents(totalCents)),
            const Divider(),
            _StatRow(
                label: 'Pedidos aún en casillero',
                value: '${pendingPickup.length}'),
            if (pendingPickup.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Avisa a la siguiente persona: casilleros '
                '${pendingPickup.map((o) => o.lockerNumber).join(', ')} '
                'siguen ocupados.',
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
  const _StatRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(value,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

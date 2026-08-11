import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/order_repository.dart';
import '../domain/order.dart';

class OrderTrackingScreen extends ConsumerStatefulWidget {
  const OrderTrackingScreen({super.key});

  @override
  ConsumerState<OrderTrackingScreen> createState() =>
      _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final order = ref.read(activeOrderProvider);
    if (order == null) return;
    final left = order.estimatedReadyAt.difference(DateTime.now());
    setState(() => _remaining = left.isNegative ? Duration.zero : left);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _countdown {
    final m = _remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final order = ref.watch(activeOrderProvider);

    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('PEDIDO')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No tienes pedidos activos.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/menu'),
                child: const Text('Ir al menú'),
              ),
            ],
          ),
        ),
      );
    }

    final isReady = order.status == OrderStatus.ready ||
        order.status == OrderStatus.pickedUp;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TU PEDIDO'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Center(
              child: Text(
                order.status.label.toUpperCase(),
                style: TextStyle(
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                  color: isReady ? Colors.green.shade700 : Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 32),
            if (!isReady) ...[
              const Center(child: Text('Estará listo en')),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _countdown,
                  style: const TextStyle(
                      fontSize: 64, fontWeight: FontWeight.w800),
                ),
              ),
            ] else
              const Center(
                child: Icon(Icons.check_circle,
                    size: 96, color: Colors.green),
              ),
            const SizedBox(height: 40),
            _LockerCard(order: order),
            const Spacer(),
            if (order.status == OrderStatus.ready)
              ElevatedButton.icon(
                onPressed: () =>
                    ref.read(activeOrderProvider.notifier).openLocker(),
                icon: const Icon(Icons.lock_open),
                label: Text('Abrir casillero ${order.lockerNumber}'),
              )
            else if (order.status == OrderStatus.pickedUp)
              ElevatedButton(
                onPressed: () {
                  ref.read(activeOrderProvider.notifier).clear();
                  context.go('/menu');
                },
                child: const Text('¡Disfruta! Volver al menú'),
              )
            else
              const Center(
                child: Text('Te avisaremos cuando esté listo.',
                    style: TextStyle(color: Color(0xFF6B6B6B))),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _LockerCard extends StatelessWidget {
  const _LockerCard({required this.order});
  final CoffeeOrder order;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                order.lockerNumber?.toString().padLeft(2, '0') ?? '--',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Recoge en el casillero',
                      style: TextStyle(color: Color(0xFF6B6B6B))),
                  const SizedBox(height: 4),
                  Text(
                    'Casillero ${order.lockerNumber ?? '--'}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  if (order.lockerPin != null) ...[
                    const SizedBox(height: 4),
                    Text('PIN: ${order.lockerPin}',
                        style: const TextStyle(color: Color(0xFF6B6B6B))),
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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../data/orders_repository.dart';
import '../domain/order.dart';

/// Mapea el estado de dominio al estado visual (con su paleta).
extension _StageMapping on OrderStatus {
  OrderStage get stage => switch (this) {
        OrderStatus.pending => OrderStage.queued,
        OrderStatus.preparing => OrderStage.preparing,
        OrderStatus.ready => OrderStage.ready,
        OrderStatus.pickedUp => OrderStage.collected,
      };

  int get stageIndex => OrderStage.values.indexOf(stage);
}

class OrderTrackingScreen extends ConsumerStatefulWidget {
  const OrderTrackingScreen({super.key});

  @override
  ConsumerState<OrderTrackingScreen> createState() =>
      _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  Timer? _timer;
  Duration _remaining = Duration.zero;
  bool _pinShown = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final order = ref.read(activeOrderProvider).valueOrNull;
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
    final order = ref.watch(activeOrderProvider).valueOrNull;

    if (order == null) return const _NoActiveOrder();

    final stageIndex = order.status.stageIndex;
    final isReady = stageIndex >= 2; // Listo o Recogido
    final isCollected = order.status == OrderStatus.pickedUp;
    final itemsSummary =
        order.items.map((i) => i.product.name).join(' · ');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tu pedido'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.lg,
          AppSpacing.screen,
          AppSpacing.xxl,
        ),
        children: [
          Text(
            _headline(order.status),
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Pedido ${order.id} · $itemsSummary',
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.xl),
          _ProgressTracker(currentIndex: stageIndex),
          const SizedBox(height: AppSpacing.xl),
          if (!isReady) ...[
            _EtaCard(countdown: _countdown),
            const SizedBox(height: AppSpacing.md),
          ],
          _LockerCard(
            order: order,
            unlocked: isReady,
            collected: isCollected,
            pinShown: _pinShown,
            onTogglePin: () => setState(() => _pinShown = !_pinShown),
          ),
          const SizedBox(height: AppSpacing.xl),
          _ActionButton(order: order),
        ],
      ),
    );
  }

  String _headline(OrderStatus status) => switch (status) {
        OrderStatus.pending => 'Recibimos tu pedido',
        OrderStatus.preparing => 'El barista está en ello',
        OrderStatus.ready => 'Tu pedido está listo',
        OrderStatus.pickedUp => '¡Que lo disfrutes!',
      };
}

// ─── Progress tracker ───────────────────────────────────────────────────────

class _ProgressTracker extends StatelessWidget {
  const _ProgressTracker({required this.currentIndex});
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    const stages = OrderStage.values;
    final pct = stages.length > 1 ? currentIndex / (stages.length - 1) : 0.0;
    final currentColor = OrderStageStyle.of(stages[currentIndex]).dot;

    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < stages.length; i++)
              Expanded(
                child: Text(
                  OrderStageStyle.of(stages[i]).label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: i == currentIndex
                        ? AppColors.ink
                        : i < currentIndex
                            ? AppColors.muted
                            : AppColors.borderStrong,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  height: 8,
                  width: constraints.maxWidth * pct,
                  decoration: BoxDecoration(
                    color: currentColor,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            for (var i = 0; i < stages.length; i++)
              Expanded(
                child: Center(
                  child: _StageDot(
                    index: i,
                    currentIndex: currentIndex,
                    color: currentColor,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _StageDot extends StatelessWidget {
  const _StageDot({
    required this.index,
    required this.currentIndex,
    required this.color,
  });

  final int index;
  final int currentIndex;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final done = index < currentIndex;
    final current = index == currentIndex;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done
            ? AppColors.ink
            : current
                ? color
                : AppColors.border,
      ),
      alignment: Alignment.center,
      child: done
          ? const Icon(Icons.check, size: 14, color: Colors.white)
          : Text(
              '${index + 1}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: current ? Colors.white : AppColors.muted,
              ),
            ),
    );
  }
}

// ─── ETA card ───────────────────────────────────────────────────────────────

class _EtaCard extends StatelessWidget {
  const _EtaCard({required this.countdown});
  final String countdown;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          const Text(
            'TIEMPO ESTIMADO',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            countdown,
            style: const TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'minutos restantes',
            style: TextStyle(color: AppColors.muted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─── Locker + PIN card ──────────────────────────────────────────────────────

class _LockerCard extends StatelessWidget {
  const _LockerCard({
    required this.order,
    required this.unlocked,
    required this.collected,
    required this.pinShown,
    required this.onTogglePin,
  });

  final CoffeeOrder order;
  final bool unlocked;
  final bool collected;
  final bool pinShown;
  final VoidCallback onTogglePin;

  @override
  Widget build(BuildContext context) {
    final stageStyle = OrderStageStyle.of(order.status.stage);
    final onDark = collected;
    final fg = onDark ? Colors.white : AppColors.ink;
    final mutedFg =
        onDark ? Colors.white.withValues(alpha: 0.5) : AppColors.muted;
    final pin = order.lockerPin ?? '----';
    final lockerLabel = order.lockerNumber != null
        ? 'Casillero #${order.lockerNumber}'
        : 'Asignando casillero…';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: onDark ? AppColors.ink : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: onDark ? null : AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CASILLERO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        color: mutedFg,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      lockerLabel,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: fg,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: stageStyle.background,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  stageStyle.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: stageStyle.foreground,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'PIN DE ACCESO',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: mutedFg,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              for (final digit in pin.split(''))
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: Container(
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: onDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : AppColors.paper,
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                      child: Text(
                        unlocked ? (pinShown ? digit : '•') : '•',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: unlocked ? fg : AppColors.faint,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (!unlocked)
            Text(
              'El PIN aparece cuando tu pedido esté listo.',
              style: TextStyle(color: mutedFg, fontSize: 12),
            )
          else if (!collected)
            GestureDetector(
              onTap: onTogglePin,
              child: Text(
                pinShown ? 'Ocultar PIN' : 'Revelar PIN',
                style: TextStyle(
                  color: mutedFg,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Action button ──────────────────────────────────────────────────────────

class _ActionButton extends ConsumerWidget {
  const _ActionButton({required this.order});
  final CoffeeOrder order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (order.status) {
      case OrderStatus.ready:
        return SizedBox(
          height: AppRadius.buttonHeight,
          child: ElevatedButton.icon(
            onPressed: () =>
                ref.read(ordersRepositoryProvider).pickUp(order.id),
            icon: const Icon(Icons.lock_open, size: 18),
            label: Text('Abrir casillero ${order.lockerNumber ?? ''}'.trim()),
          ),
        );
      case OrderStatus.pickedUp:
        return SizedBox(
          height: AppRadius.buttonHeight,
          child: ElevatedButton(
            onPressed: () {
              ref.read(activeOrderIdProvider.notifier).state = null;
              context.go('/menu');
            },
            child: const Text('Volver al menú'),
          ),
        );
      default:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.border),
          ),
          child: const Row(
            children: [
              Icon(Icons.notifications_none, size: 18, color: AppColors.muted),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Te avisaremos en cuanto esté listo en tu casillero.',
                  style: TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              ),
            ],
          ),
        );
    }
  }
}

// ─── No active order ────────────────────────────────────────────────────────

class _NoActiveOrder extends StatelessWidget {
  const _NoActiveOrder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tu pedido'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.sheet),
                  boxShadow: AppColors.cardShadow,
                ),
                child: const Icon(Icons.receipt_long_outlined,
                    size: 32, color: AppColors.muted),
              ),
              const SizedBox(height: AppSpacing.xl),
              const Text(
                'Sin pedidos activos',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Haz un pedido y podrás seguirlo aquí.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: () => context.go('/menu'),
                  child: const Text('Ir al menú'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

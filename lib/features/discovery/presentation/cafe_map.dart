import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../branches/domain/branch.dart';

/// Mapa de cafeterías con OpenStreetMap (sin API key).
/// Dibuja un pin por cada cafetería con coordenadas; al tocarlo se abre una
/// tarjeta con su info y un botón para entrar a su menú.
class CafeMap extends StatefulWidget {
  const CafeMap({
    super.key,
    required this.branches,
    required this.onOpen,
  });

  /// Cafeterías a mostrar. Solo se dibujan las que tienen coordenadas.
  final List<Branch> branches;

  /// Se llama al pulsar "Ver menú" en la tarjeta de una cafetería.
  final void Function(Branch cafe) onOpen;

  @override
  State<CafeMap> createState() => _CafeMapState();
}

class _CafeMapState extends State<CafeMap> {
  final _controller = MapController();
  Branch? _selected;

  // Centro aproximado de CDMX, usado si ninguna cafetería tiene coordenadas.
  static const _fallbackCenter = LatLng(19.4203, -99.1760);

  List<Branch> get _located =>
      widget.branches.where((b) => b.hasLocation).toList();

  LatLng _centerOf(List<Branch> located) {
    if (located.isEmpty) return _fallbackCenter;
    final lat =
        located.map((b) => b.lat!).reduce((a, b) => a + b) / located.length;
    final lng =
        located.map((b) => b.lng!).reduce((a, b) => a + b) / located.length;
    return LatLng(lat, lng);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final located = _located;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCenter: _centerOf(located),
              initialZoom: 13,
              minZoom: 10,
              maxZoom: 18,
              onTap: (_, __) => setState(() => _selected = null),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.barra.app',
              ),
              MarkerLayer(
                markers: [
                  for (final cafe in located)
                    Marker(
                      point: LatLng(cafe.lat!, cafe.lng!),
                      width: 44,
                      height: 44,
                      alignment: Alignment.topCenter,
                      child: _Pin(
                        selected: _selected?.id == cafe.id,
                        onTap: () => setState(() => _selected = cafe),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Atribución obligatoria de OpenStreetMap.
          Positioned(
            right: 6,
            bottom: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '© OpenStreetMap',
                style: TextStyle(fontSize: 9, color: AppColors.muted),
              ),
            ),
          ),

          // Tarjeta de la cafetería seleccionada.
          if (_selected != null)
            Positioned(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: AppSpacing.md,
              child: _CafeSheet(
                cafe: _selected!,
                onOpen: () => widget.onOpen(_selected!),
                onClose: () => setState(() => _selected = null),
              ),
            ),
        ],
      ),
    );
  }
}

class _Pin extends StatelessWidget {
  const _Pin({required this.selected, required this.onTap});
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(
        Icons.location_on,
        size: selected ? 44 : 36,
        color: selected ? AppColors.ink : const Color(0xFF8A5A3B),
        shadows: const [
          Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
    );
  }
}

class _CafeSheet extends StatelessWidget {
  const _CafeSheet({
    required this.cafe,
    required this.onOpen,
    required this.onClose,
  });
  final Branch cafe;
  final VoidCallback onOpen;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.button),
            child: SizedBox(
              width: 52,
              height: 52,
              child: cafe.imageUrl != null
                  ? Image.network(
                      cafe.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _thumbPlaceholder(),
                    )
                  : _thumbPlaceholder(),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  cafe.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 13, color: Color(0xFFF6C445)),
                    const SizedBox(width: 2),
                    Text(
                      cafe.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Icon(Icons.schedule, size: 12, color: AppColors.muted),
                    const SizedBox(width: 3),
                    Text(
                      '~${cafe.etaMinutes} min',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          FilledButton(
            onPressed: onOpen,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.ink,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              minimumSize: const Size(0, 40),
            ),
            child: const Text('Ver menú'),
          ),
        ],
      ),
    );
  }

  Widget _thumbPlaceholder() => Container(
        color: AppColors.paper,
        alignment: Alignment.center,
        child: const Icon(Icons.storefront_outlined,
            size: 22, color: AppColors.faint),
      );
}

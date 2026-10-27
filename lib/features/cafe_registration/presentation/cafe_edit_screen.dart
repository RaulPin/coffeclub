import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../branches/data/branch_repository.dart';
import '../../branches/data/cafe_profile_repository.dart';
import '../../branches/domain/branch.dart';
import '../../staff/application/shift_controller.dart';
import '../data/geocoding_service.dart';
import 'photo_url_field.dart';

/// Permite al dueño editar los datos de su cafetería (nombre, dirección,
/// descripción, foto, tiempo de preparación y ubicación en el mapa).
class CafeEditScreen extends ConsumerStatefulWidget {
  const CafeEditScreen({super.key});

  @override
  ConsumerState<CafeEditScreen> createState() => _CafeEditScreenState();
}

class _CafeEditScreenState extends ConsumerState<CafeEditScreen> {
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _tagline = TextEditingController();
  final _imageUrl = TextEditingController();
  final _eta = TextEditingController();
  final _mapController = MapController();

  bool _initialized = false;
  LatLng? _location;
  bool _saving = false;
  String? _error;

  // Autocompletado de direcciones.
  Timer? _debounce;
  List<GeoResult> _predictions = const [];
  bool _searching = false;

  static const _fallbackCenter = LatLng(19.4203, -99.1760);

  @override
  void dispose() {
    _debounce?.cancel();
    _mapController.dispose();
    _name.dispose();
    _address.dispose();
    _tagline.dispose();
    _imageUrl.dispose();
    _eta.dispose();
    super.dispose();
  }

  void _hydrate(Branch cafe) {
    _name.text = cafe.name;
    _address.text = cafe.address;
    _tagline.text = cafe.tagline;
    _imageUrl.text = cafe.imageUrl ?? '';
    _eta.text = cafe.etaMinutes.toString();
    if (cafe.lat != null && cafe.lng != null) {
      _location = LatLng(cafe.lat!, cafe.lng!);
    }
    _initialized = true;
  }

  void _onAddressChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 4) {
      setState(() => _predictions = const []);
      return;
    }
    _debounce =
        Timer(const Duration(milliseconds: 450), () => _runSearch(value));
  }

  Future<void> _runSearch(String value) async {
    setState(() => _searching = true);
    final results = await ref.read(geocodingServiceProvider).search(value);
    if (!mounted) return;
    setState(() {
      _predictions = results;
      _searching = false;
    });
  }

  void _pickPrediction(GeoResult r) {
    FocusScope.of(context).unfocus();
    final point = LatLng(r.lat, r.lng);
    setState(() {
      _address.text = r.label;
      _location = point;
      _predictions = const [];
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        _mapController.move(point, 16);
      } catch (_) {/* el mapa aún no está listo */}
    });
  }

  Future<void> _save(String cafeId) async {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'El nombre no puede quedar vacío.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(cafeProfileRepositoryProvider).update(
            cafeId,
            name: _name.text,
            address: _address.text,
            tagline: _tagline.text,
            imageUrl: _imageUrl.text,
            etaMinutes: int.tryParse(_eta.text.trim()),
            lat: _location?.latitude,
            lng: _location?.longitude,
          );
      ref.invalidate(branchesProvider);
      ref.invalidate(cafeProfileProvider(cafeId));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Datos actualizados')),
      );
      Navigator.of(context).pop();
    } catch (_) {
      setState(() {
        _saving = false;
        _error = 'No pudimos guardar los cambios. Inténtalo de nuevo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cafeId = ref.watch(shiftControllerProvider)?.branchId;

    return Scaffold(
      appBar: AppBar(title: const Text('Editar cafetería')),
      body: cafeId == null
          ? const Center(child: Text('No hay una cafetería activa.'))
          : ref.watch(cafeProfileProvider(cafeId)).when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) =>
                    Center(child: Text('No pudimos cargar los datos: $e')),
                data: (cafe) {
                  if (cafe == null) {
                    return const Center(
                        child: Text('No encontramos la cafetería.'));
                  }
                  if (!_initialized) _hydrate(cafe);
                  return _form(cafeId);
                },
              ),
    );
  }

  Widget _form(String cafeId) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.lg,
        AppSpacing.screen,
        AppSpacing.xxl,
      ),
      children: [
        _label('DATOS DE LA CAFETERÍA'),
        const SizedBox(height: AppSpacing.sm),
        _field(_name, 'Nombre de la cafetería'),
        const SizedBox(height: AppSpacing.md),
        _AddressField(
          controller: _address,
          searching: _searching,
          onChanged: _onAddressChanged,
        ),
        if (_predictions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          _PredictionList(predictions: _predictions, onPick: _pickPrediction),
        ],
        const SizedBox(height: AppSpacing.md),
        _field(_tagline, 'Descripción corta (opcional)'),
        const SizedBox(height: AppSpacing.md),
        PhotoUrlField(controller: _imageUrl),
        const SizedBox(height: AppSpacing.md),
        _field(_eta, 'Tiempo de preparación (min)', keyboard: TextInputType.number),
        const SizedBox(height: AppSpacing.xl),

        _label('UBICACIÓN EN EL MAPA'),
        const SizedBox(height: 4),
        Text(
          _location == null
              ? 'Toca el mapa para marcar tu ubicación.'
              : 'Ubicación marcada. Toca para ajustarla.',
          style: const TextStyle(color: AppColors.muted, fontSize: 13),
        ),
        const SizedBox(height: AppSpacing.sm),
        _MapBox(
          controller: _mapController,
          center: _location ?? _fallbackCenter,
          selected: _location,
          onPick: (p) => setState(() => _location = p),
        ),

        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(_error!, style: const TextStyle(color: Color(0xFFC0392B))),
        ],
        const SizedBox(height: AppSpacing.xl),
        SizedBox(
          height: AppRadius.buttonHeight,
          child: ElevatedButton(
            onPressed: _saving ? null : () => _save(cafeId),
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.4, color: Colors.white),
                  )
                : const Text('Guardar cambios'),
          ),
        ),
      ],
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 2,
          color: AppColors.muted,
        ),
      );

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      autocorrect: false,
      decoration: InputDecoration(hintText: label),
    );
  }
}

// ─── Piezas compartidas con el registro ──────────────────────────────────────

class _AddressField extends StatelessWidget {
  const _AddressField({
    required this.controller,
    required this.searching,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool searching;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.streetAddress,
      autocorrect: false,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Dirección (escribe para buscar)',
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: searching
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : null,
      ),
    );
  }
}

class _PredictionList extends StatelessWidget {
  const _PredictionList({required this.predictions, required this.onPick});

  final List<GeoResult> predictions;
  final void Function(GeoResult) onPick;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppColors.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < predictions.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, color: AppColors.border, indent: 48),
            ListTile(
              dense: true,
              leading: const Icon(Icons.location_on_outlined,
                  size: 20, color: AppColors.muted),
              title: Text(
                predictions[i].label,
                style: const TextStyle(fontSize: 13.5),
              ),
              onTap: () => onPick(predictions[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _MapBox extends StatelessWidget {
  const _MapBox({
    required this.controller,
    required this.center,
    required this.selected,
    required this.onPick,
  });

  final MapController controller;
  final LatLng center;
  final LatLng? selected;
  final void Function(LatLng) onPick;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: SizedBox(
        height: 220,
        child: FlutterMap(
          mapController: controller,
          options: MapOptions(
            initialCenter: center,
            initialZoom: selected != null ? 16 : 13,
            minZoom: 10,
            maxZoom: 18,
            onTap: (_, point) => onPick(point),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.barra.app',
              tileProvider: CancellableNetworkTileProvider(),
            ),
            if (selected != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: selected!,
                    width: 44,
                    height: 44,
                    alignment: Alignment.topCenter,
                    child: const Icon(
                      Icons.location_on,
                      size: 40,
                      color: AppColors.ink,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

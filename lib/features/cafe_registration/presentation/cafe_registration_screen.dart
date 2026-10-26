import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../staff/application/shift_controller.dart';
import '../../staff/application/staff_auth_controller.dart';
import '../../staff/domain/staff_user.dart';
import '../application/cafe_registration_controller.dart';
import '../data/cafe_registration_repository.dart';

/// Alta self-service de una cafetería en Barra: datos del negocio, ubicación
/// en el mapa y cuenta de acceso del dueño.
class CafeRegistrationScreen extends ConsumerStatefulWidget {
  const CafeRegistrationScreen({super.key});

  @override
  ConsumerState<CafeRegistrationScreen> createState() =>
      _CafeRegistrationScreenState();
}

class _CafeRegistrationScreenState
    extends ConsumerState<CafeRegistrationScreen> {
  final _cafeName = TextEditingController();
  final _address = TextEditingController();
  final _tagline = TextEditingController();
  final _ownerName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  LatLng? _location;
  bool _loading = false;
  String? _error;

  // Centro aproximado de CDMX para arrancar el mapa.
  static const _initialCenter = LatLng(19.4203, -99.1760);

  @override
  void dispose() {
    _cafeName.dispose();
    _address.dispose();
    _tagline.dispose();
    _ownerName.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String? _validate() {
    if (_cafeName.text.trim().isEmpty) return 'Escribe el nombre de la cafetería.';
    if (_address.text.trim().isEmpty) return 'Escribe la dirección.';
    if (_ownerName.text.trim().isEmpty) return 'Escribe tu nombre.';
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) return 'Escribe un correo válido.';
    if (_password.text.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    }
    return null;
  }

  Future<void> _submit() async {
    final problem = _validate();
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = CafeRegistration(
        cafeName: _cafeName.text,
        address: _address.text,
        tagline: _tagline.text,
        ownerName: _ownerName.text,
        email: _email.text,
        password: _password.text,
        lat: _location?.latitude,
        lng: _location?.longitude,
      );
      final user =
          await ref.read(cafeRegistrationRepositoryProvider).registerCafe(data);

      // Deja la sesión del dueño lista y abre su turno en su cafetería.
      ref.read(staffAuthControllerProvider.notifier).applySession(user);
      if (user.role == StaffRole.employee && user.branchId != null) {
        ref
            .read(shiftControllerProvider.notifier)
            .startShift(user.name, user.branchId!);
      }
      if (mounted) context.go('/staff');
    } on FirebaseAuthException catch (e) {
      setState(() {
        _loading = false;
        _error = _message(e.code);
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _error = 'No pudimos completar el registro. Inténtalo de nuevo.';
      });
    }
  }

  String _message(String code) => switch (code) {
        'email-already-in-use' => 'Ese correo ya tiene una cuenta.',
        'invalid-email' => 'El correo no es válido.',
        'weak-password' => 'La contraseña es muy débil (mínimo 6 caracteres).',
        'operation-not-allowed' =>
          'Habilita Correo/contraseña en Firebase → Authentication.',
        'network-request-failed' => 'Sin conexión. Revisa tu internet.',
        _ => 'No pudimos completar el registro. Inténtalo de nuevo.',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registra tu cafetería')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.lg,
          AppSpacing.screen,
          AppSpacing.xxl,
        ),
        children: [
          const Text(
            'Únete a Barra',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Publica tu menú para llevar y recibe pedidos. Barra cobra 5% de '
            'comisión por pedido; tú defines tus precios.',
            style: TextStyle(color: AppColors.muted, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: AppSpacing.xl),

          _label('TU CAFETERÍA'),
          const SizedBox(height: AppSpacing.sm),
          _field(_cafeName, 'Nombre de la cafetería', TextInputType.text),
          const SizedBox(height: AppSpacing.md),
          _field(_address, 'Dirección', TextInputType.streetAddress),
          const SizedBox(height: AppSpacing.md),
          _field(_tagline, 'Descripción corta (opcional)', TextInputType.text),
          const SizedBox(height: AppSpacing.xl),

          _label('UBICACIÓN EN EL MAPA'),
          const SizedBox(height: 4),
          Text(
            _location == null
                ? 'Toca el mapa para marcar dónde está tu cafetería.'
                : 'Ubicación marcada. Toca de nuevo para ajustarla.',
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.sm),
          _MapPicker(
            initialCenter: _initialCenter,
            selected: _location,
            onPick: (p) => setState(() => _location = p),
          ),
          const SizedBox(height: AppSpacing.xl),

          _label('TU CUENTA DE ACCESO'),
          const SizedBox(height: AppSpacing.sm),
          _field(_ownerName, 'Tu nombre', TextInputType.name),
          const SizedBox(height: AppSpacing.md),
          _field(_email, 'Correo', TextInputType.emailAddress),
          const SizedBox(height: AppSpacing.md),
          _field(_password, 'Contraseña (mín. 6)', TextInputType.text,
              obscure: true),

          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(_error!, style: const TextStyle(color: Color(0xFFC0392B))),
          ],

          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            height: AppRadius.buttonHeight,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.4, color: Colors.white),
                    )
                  : const Text('Registrar cafetería'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Al registrarte aceptas recibir pedidos a través de Barra.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
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
    String label,
    TextInputType keyboard, {
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      obscureText: obscure,
      autocorrect: false,
      enableSuggestions: !obscure,
      decoration: InputDecoration(hintText: label),
    );
  }
}

/// Mini-mapa para elegir la ubicación de la cafetería tocando un punto.
class _MapPicker extends StatelessWidget {
  const _MapPicker({
    required this.initialCenter,
    required this.selected,
    required this.onPick,
  });

  final LatLng initialCenter;
  final LatLng? selected;
  final void Function(LatLng) onPick;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: SizedBox(
        height: 220,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: selected ?? initialCenter,
            initialZoom: 13,
            minZoom: 10,
            maxZoom: 18,
            onTap: (_, point) => onPick(point),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.barra.app',
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

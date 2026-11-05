import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../staff/application/shift_controller.dart';
import '../../staff/application/staff_auth_controller.dart';
import '../data/employee_service.dart';

/// Pantalla del dueño para ver y administrar a su personal (baristas).
class ManageEmployeesScreen extends ConsumerWidget {
  const ManageEmployeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cafeId = ref.watch(shiftControllerProvider)?.branchId;
    final me = ref.watch(staffAuthControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Empleados')),
      floatingActionButton: cafeId == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showAddSheet(context, ref, cafeId),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Agregar'),
            ),
      body: cafeId == null
          ? const Center(child: Text('No hay una cafetería activa.'))
          : ref.watch(cafeEmployeesProvider(cafeId)).when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) =>
                    Center(child: Text('No pudimos cargar el personal: $e')),
                data: (employees) => ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screen,
                    AppSpacing.lg,
                    AppSpacing.screen,
                    96,
                  ),
                  children: [
                    const Text(
                      'Las cuentas que crees aquí sirven para que tu personal '
                      'entre a la estación y marque su entrada y salida.',
                      style: TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    for (final emp in employees) ...[
                      _EmployeeTile(
                        employee: emp,
                        isMe: emp.uid == me?.id,
                        onDelete: () =>
                            _confirmDelete(context, ref, cafeId, emp),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ],
                ),
              ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String cafeId,
    CafeEmployee emp,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar empleado'),
        content: Text('¿Quitar el acceso de ${emp.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar',
                style: TextStyle(color: Color(0xFFC0392B))),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref
          .read(employeeServiceProvider)
          .deleteEmployee(cafeId: cafeId, employeeUid: emp.uid);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo eliminar.')),
        );
      }
    }
  }

  void _showAddSheet(BuildContext context, WidgetRef ref, String cafeId) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      builder: (_) => _AddEmployeeSheet(cafeId: cafeId),
    );
  }
}

class _EmployeeTile extends StatelessWidget {
  const _EmployeeTile({
    required this.employee,
    required this.isMe,
    required this.onDelete,
  });
  final CafeEmployee employee;
  final bool isMe;
  final VoidCallback onDelete;

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
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.paper,
            child: Text(
              employee.name.isNotEmpty ? employee.name[0].toUpperCase() : '?',
              style: const TextStyle(
                  fontWeight: FontWeight.w900, color: AppColors.ink),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        employee.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                    ),
                    if (employee.isOwner) ...[
                      const SizedBox(width: 6),
                      _tag('Dueño'),
                    ] else if (isMe) ...[
                      const SizedBox(width: 6),
                      _tag('Tú'),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  employee.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              ],
            ),
          ),
          if (!employee.isOwner && !isMe)
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, color: AppColors.muted),
            ),
        ],
      ),
    );
  }

  Widget _tag(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: AppColors.muted,
          ),
        ),
      );
}

class _AddEmployeeSheet extends ConsumerStatefulWidget {
  const _AddEmployeeSheet({required this.cafeId});
  final String cafeId;

  @override
  ConsumerState<_AddEmployeeSheet> createState() => _AddEmployeeSheetState();
}

class _AddEmployeeSheetState extends ConsumerState<_AddEmployeeSheet> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    final email = _email.text.trim();
    final password = _password.text;
    if (name.isEmpty) {
      setState(() => _error = 'Escribe el nombre.');
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Escribe un correo válido.');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'La contraseña debe tener al menos 6 caracteres.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(employeeServiceProvider).createEmployee(
            cafeId: widget.cafeId,
            name: name,
            email: email,
            password: password,
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name ya puede iniciar sesión.')),
        );
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString().contains('already-exists')
            ? 'Ese correo ya tiene una cuenta.'
            : 'No se pudo crear la cuenta. Inténtalo de nuevo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.xl,
        AppSpacing.screen,
        AppSpacing.xl + bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Nuevo empleado',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          const Text(
            'Creará una cuenta para que entre a la estación. Compártele el '
            'correo y la contraseña; podrá cambiarla después.',
            style: TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.xl),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'Nombre'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: const InputDecoration(hintText: 'Correo'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _password,
            obscureText: true,
            decoration:
                const InputDecoration(hintText: 'Contraseña temporal (mín. 6)'),
          ),
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
                  : const Text('Crear cuenta'),
            ),
          ),
        ],
      ),
    );
  }
}

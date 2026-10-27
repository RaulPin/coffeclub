import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/app_user.dart';

/// Perfil del cliente: datos de la cuenta, membresía, preferencias y
/// cierre de sesión.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _notifications = true;

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que quieres salir de tu cuenta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cerrar sesión',
                style: TextStyle(color: Color(0xFFC0392B))),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await ref.read(authControllerProvider.notifier).signOut();
    // El router redirige a /login al quedar sin sesión.
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider);
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final isMember = user.isSubscriber;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.lg,
          AppSpacing.screen,
          AppSpacing.xxl,
        ),
        children: [
          _Header(user: user),
          const SizedBox(height: AppSpacing.xl),

          // Membresía Barra+
          _MembershipCard(
            isMember: isMember,
            onTap: () => context.go('/subscription'),
          ),
          const SizedBox(height: AppSpacing.xl),

          _SectionLabel('Cuenta'),
          const SizedBox(height: AppSpacing.sm),
          _Card(
            children: [
              _Tile(
                icon: Icons.receipt_long_outlined,
                title: 'Mis pedidos',
                subtitle: 'Revisa el estado de tu pedido activo',
                onTap: () => context.go('/order'),
              ),
              const _Line(),
              _Tile(
                icon: Icons.card_membership_outlined,
                title: 'Barra+',
                subtitle: isMember ? 'Socio activo' : 'Sin cuota de servicio',
                onTap: () => context.go('/subscription'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          _SectionLabel('Preferencias'),
          const SizedBox(height: AppSpacing.sm),
          _Card(
            children: [
              _SwitchTile(
                icon: Icons.notifications_none_rounded,
                title: 'Notificaciones',
                subtitle: 'Avisos cuando tu pedido esté listo',
                value: _notifications,
                onChanged: (v) => setState(() => _notifications = v),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          _SectionLabel('Acerca de'),
          const SizedBox(height: AppSpacing.sm),
          _Card(
            children: [
              _Tile(
                icon: Icons.info_outline_rounded,
                title: 'Barra',
                subtitle: 'Versión 0.1.0',
                onTap: null,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          SizedBox(
            height: AppRadius.buttonHeight,
            child: OutlinedButton.icon(
              onPressed: _signOut,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFC0392B),
                side: const BorderSide(color: Color(0xFFE6C9C4)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Cerrar sesión'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.user});
  final AppUser user;

  String get _initials {
    final parts = user.name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) {
      return user.email.isNotEmpty ? user.email[0].toUpperCase() : '?';
    }
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: AppColors.ink,
            shape: BoxShape.circle,
          ),
          clipBehavior: Clip.antiAlias,
          alignment: Alignment.center,
          child: user.photoUrl != null && user.photoUrl!.isNotEmpty
              ? Image.network(
                  user.photoUrl!,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _initialsLabel(),
                )
              : _initialsLabel(),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name.isEmpty ? 'Tu cuenta' : user.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                user.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.muted, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _initialsLabel() => Text(
        _initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w900,
        ),
      );
}

class _MembershipCard extends StatelessWidget {
  const _MembershipCard({required this.isMember, required this.onTap});
  final bool isMember;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Row(
          children: [
            const Icon(Icons.bolt, color: Colors.white, size: 22),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isMember ? 'Barra+ · Socio activo' : 'Únete a Barra+',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isMember
                        ? 'Sin cuota de servicio en tus pedidos'
                        : 'Quita la cuota de servicio por \$29/mes',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Piezas reutilizables ────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 2,
        color: AppColors.muted,
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppColors.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, color: AppColors.border, indent: 56);
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.ink, size: 22),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.muted, fontSize: 13),
      ),
      trailing: onTap == null
          ? null
          : const Icon(Icons.chevron_right_rounded, color: AppColors.faint),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.ink,
      secondary: Icon(icon, color: AppColors.ink, size: 22),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.muted, fontSize: 13),
      ),
    );
  }
}

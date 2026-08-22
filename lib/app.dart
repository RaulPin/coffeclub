import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';

class CoffeClubApp extends ConsumerWidget {
  const CoffeClubApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
      builder: (context, child) => _PhoneFrame(child: child),
    );
  }
}

/// En pantallas anchas (web/escritorio) limita el contenido al ancho de un
/// celular y lo centra, para que la app se vea como en el mockup en vez de
/// estirada. En un celular/emulador real no hace nada (la pantalla es angosta).
class _PhoneFrame extends StatelessWidget {
  const _PhoneFrame({required this.child});
  final Widget? child;

  static const double _maxWidth = 460;

  @override
  Widget build(BuildContext context) {
    final content = child ?? const SizedBox.shrink();
    final width = MediaQuery.sizeOf(context).width;
    if (width <= _maxWidth) return content;

    return ColoredBox(
      color: const Color(0xFF16130F),
      child: Center(
        child: ClipRRect(
          child: SizedBox(
            width: _maxWidth,
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                size: Size(_maxWidth, MediaQuery.sizeOf(context).height),
              ),
              child: ColoredBox(color: AppColors.paper, child: content),
            ),
          ),
        ),
      ),
    );
  }
}

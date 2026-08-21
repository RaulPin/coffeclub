import 'package:flutter/material.dart';

/// Tokens de color de The Club Coffe, alineados con el diseño de Figma.
///
/// La base es la paleta minimalista blanco/negro; encima viven los colores
/// semánticos de los estados de pedido (cola → preparando → listo → recogido).
abstract final class AppColors {
  // --- Base ---
  static const Color ink = Color(0xFF0A0A0A);
  static const Color paper = Color(0xFFF7F5F1);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color muted = Color(0xFF6B6B6B);

  /// Bordes sutiles (cards, chips, inputs).
  static const Color border = Color(0xFFE8E6E2);

  /// Borde con un poco más de contraste.
  static const Color borderStrong = Color(0xFFD0CEC9);

  /// Superficie ligeramente hundida (pies de card, campos).
  static const Color subtle = Color(0xFFFAFAF9);

  /// Texto/íconos deshabilitados o de muy baja jerarquía.
  static const Color faint = Color(0xFFC8C5C0);

  // --- Acentos ---
  /// Éxito / gratis / disponible.
  static const Color success = Color(0xFF3DAA6B);

  /// Aviso / urgente / en preparación.
  static const Color warning = Color(0xFFE8A838);

  // --- Sombra estándar de card ---
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x12000000), // ~7% negro
      blurRadius: 6,
      offset: Offset(0, 1),
    ),
  ];
}

/// Estados por los que pasa un pedido, con su paleta propia.
enum OrderStage { queued, preparing, ready, collected }

/// Estilo visual (colores) de cada estado de pedido, tomado del diseño.
class OrderStageStyle {
  const OrderStageStyle({
    required this.label,
    required this.foreground,
    required this.background,
    required this.dot,
    required this.border,
  });

  final String label;

  /// Color del texto de la píldora de estado.
  final Color foreground;

  /// Fondo de la píldora de estado.
  final Color background;

  /// Punto/indicador del estado.
  final Color dot;

  /// Borde asociado (para separadores de card en ese estado).
  final Color border;

  static const Map<OrderStage, OrderStageStyle> _all = {
    OrderStage.queued: OrderStageStyle(
      label: 'En cola',
      foreground: Color(0xFF7A5C3A),
      background: Color(0xFFF5EDE0),
      dot: Color(0xFFC8B89A),
      border: Color(0xFFE8D9C4),
    ),
    OrderStage.preparing: OrderStageStyle(
      label: 'Preparando',
      foreground: Color(0xFF7A4F00),
      background: Color(0xFFFEF3D0),
      dot: Color(0xFFE8A838),
      border: Color(0xFFF0D88A),
    ),
    OrderStage.ready: OrderStageStyle(
      label: 'Listo',
      foreground: Color(0xFF0E5C30),
      background: Color(0xFFD8F5E7),
      dot: Color(0xFF3DAA6B),
      border: Color(0xFFA8E0C0),
    ),
    OrderStage.collected: OrderStageStyle(
      label: 'Recogido',
      foreground: Color(0xFF0A0A0A),
      background: Color(0xFFE8E6E2),
      dot: Color(0xFF0A0A0A),
      border: Color(0xFFD0CEC9),
    ),
  };

  static OrderStageStyle of(OrderStage stage) => _all[stage]!;
}

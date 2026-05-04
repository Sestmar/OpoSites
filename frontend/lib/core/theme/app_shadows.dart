import 'package:flutter/material.dart';

/// Sombras de opoSites — optimizadas para dark mode (más oscuras, sin white glow).
abstract final class AppShadows {
  /// Sombra estándar para cards normales.
  static const card = [
    BoxShadow(
      color: Color(0x4D000000), // rgba(0,0,0,0.30)
      blurRadius: 3,
      offset: Offset(0, 1),
    ),
    BoxShadow(
      color: Color(0x33000000), // rgba(0,0,0,0.20)
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  /// Sombra prominente para cards destacadas (continuar, AI card, bottom nav).
  static const cardLg = [
    BoxShadow(
      color: Color(0x4D000000),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
    BoxShadow(
      color: Color(0x40000000), // rgba(0,0,0,0.25)
      blurRadius: 40,
      offset: Offset(0, 12),
    ),
  ];

  /// Glow teal — para AI card, botones CTA y elementos con énfasis primario.
  static const glowPrimary = [
    BoxShadow(
      color: Color(0x4D14B8A6), // rgba(20,184,166,0.30)
      blurRadius: 20,
      offset: Offset(0, 4),
    ),
  ];

  /// Glow ámbar — para la tarjeta de racha.
  static const glowWarm = [
    BoxShadow(
      color: Color(0x40F59E0B), // rgba(245,158,11,0.25)
      blurRadius: 20,
      offset: Offset(0, 6),
    ),
  ];
}

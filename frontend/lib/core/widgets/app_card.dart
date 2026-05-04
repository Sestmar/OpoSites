import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';

/// Card base de opoSites.
///
/// Usa [AppColors] adaptado al brightness actual del tema.
/// Soporta override de color, sombra, borde y radio.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final List<BoxShadow>? shadows;
  final Color? color;
  final BoxBorder? border;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = 16,
    this.shadows,
    this.color,
    this.border,
  });

  /// Constructor para cards grandes con radio 20 y sombra prominente.
  const AppCard.large({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 20,
    this.shadows = AppShadows.cardLg,
    this.color,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final bg = color ?? AppColors.surfaceFor(b);
    final borderColor = AppColors.borderFor(b);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        border: border ?? Border.all(color: borderColor, width: 0.5),
        boxShadow: shadows ?? AppShadows.card,
      ),
      child: child,
    );
  }
}

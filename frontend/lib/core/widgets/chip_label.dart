import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Chip/pill con texto en mayúsculas — usado para estados, categorías y CTAs.
///
/// Por defecto usa el color primario teal adaptado al brightness.
/// Pasá [backgroundColor] y [textColor] para los acentos (warm, mint, rose).
class ChipLabel extends StatelessWidget {
  final String text;
  final Color? backgroundColor;
  final Color? textColor;

  const ChipLabel({
    super.key,
    required this.text,
    this.backgroundColor,
    this.textColor,
  });

  /// Chip de acento ámbar — para racha, logros.
  const ChipLabel.warm({
    super.key,
    required this.text,
  })  : backgroundColor = null,
        textColor = AppColors.accentWarm;

  /// Chip de acento verde — para completado, aciertos.
  const ChipLabel.mint({
    super.key,
    required this.text,
  })  : backgroundColor = null,
        textColor = AppColors.accentMint;

  /// Chip de acento coral — para alertas.
  const ChipLabel.rose({
    super.key,
    required this.text,
  })  : backgroundColor = null,
        textColor = AppColors.accentRose;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final fg = textColor ?? AppColors.primaryFor(b);
    final bg = backgroundColor ?? _softFor(b, fg);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text.toUpperCase(),
        style: AppText.label.copyWith(color: fg),
      ),
    );
  }

  Color _softFor(Brightness b, Color fg) {
    if (fg == AppColors.accentWarm) return AppColors.accentWarmSoftFor(b);
    if (fg == AppColors.accentMint) return AppColors.accentMintSoftFor(b);
    if (fg == AppColors.accentRose) return AppColors.accentRoseSoftFor(b);
    return AppColors.primarySoftFor(b);
  }
}

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../core/widgets/sparkline.dart';

/// Tile de estadística — icono + número grande + label + sparkline opcional.
///
/// Altura fija [_kHeight] para que el bento row quede alineado.
/// El sparkline se superpone en la esquina superior derecha si [sparklineData]
/// tiene al menos 2 puntos.
class StatTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String value;
  final String label;
  final Color? valueColor;
  final List<double>? sparklineData;
  final VoidCallback? onTap;

  const StatTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.value,
    required this.label,
    this.valueColor,
    this.sparklineData,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;

    return Pressable(
      onTap: onTap,
      child: Container(
        height: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceFor(b),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderFor(b), width: 0.5),
          boxShadow: AppShadows.card,
        ),
        child: Stack(
          children: [
            // Sparkline overlay (esquina superior derecha)
            if (sparklineData != null && sparklineData!.length >= 2)
              Positioned(
                top: 0,
                right: 0,
                width: 56,
                height: 40,
                child: Opacity(
                  opacity: 0.5,
                  child: Sparkline(
                    points: sparklineData!,
                    color: iconColor,
                  ),
                ),
              ),

            // Contenido principal
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Icono
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, size: 16, color: iconColor),
                ),

                // Número + label
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        style: AppText.h2.copyWith(
                          color: valueColor ?? AppColors.textFor(b),
                        ),
                      ),
                    ),
                    Text(
                      label,
                      style: AppText.caption.copyWith(
                        color: AppColors.textMutedFor(b),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

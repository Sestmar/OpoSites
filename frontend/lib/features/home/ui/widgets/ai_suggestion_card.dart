import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/pressable.dart';

/// Card "Sugerido por IA" — sugerencia derivada de los datos reales del usuario.
///
/// Usa un fondo diferenciado del resto de cards con un glow sutil del color
/// primario. No requiere endpoint nuevo: la sugerencia se deriva en [HomeScreen]
/// a partir de [ProgresoResumen.temasDebiles] y [Racha].
class AiSuggestionCard extends StatelessWidget {
  final String suggestion;
  final VoidCallback? onTap;

  const AiSuggestionCard({
    super.key,
    required this.suggestion,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;

    // Fondo ligeramente diferenciado: surfaceMuted + borde primary
    final bgColor = AppColors.surfaceMutedFor(b);
    final borderColor = AppColors.primaryFor(b).withOpacity(0.3);

    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryFor(b).withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Icono con gradiente ────────────────────────────────────────
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.accentRose],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 18,
              ),
            ),

            const SizedBox(width: 12),

            // ── Texto ──────────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'SUGERIDO POR IA',
                    style: AppText.label.copyWith(
                      color: AppColors.primaryFor(b),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    suggestion,
                    style: AppText.body.copyWith(
                      color: AppColors.textFor(b),
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // ── Flecha CTA ─────────────────────────────────────────────────
            Icon(
              Icons.arrow_forward_ios,
              size: 13,
              color: AppColors.textFaintFor(b),
            ),
          ],
        ),
      ),
    );
  }
}

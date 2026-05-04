import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/pressable.dart';

/// Grid 2×2 de accesos rápidos a las funciones principales de la app.
class QuickAccessGrid extends StatelessWidget {
  final VoidCallback onTestRapido;
  final VoidCallback onSimulacro;
  final VoidCallback onPorTemas;
  final VoidCallback onMisFallos;

  const QuickAccessGrid({
    super.key,
    required this.onTestRapido,
    required this.onSimulacro,
    required this.onPorTemas,
    required this.onMisFallos,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _QuickTile(
                icon: Icons.bolt,
                iconColor: AppColors.primary,
                title: 'Test rápido',
                subtitle: '10 preguntas',
                onTap: onTestRapido,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickTile(
                icon: Icons.assignment_outlined,
                iconColor: AppColors.accentWarm,
                title: 'Simulacro',
                subtitle: 'Examen completo',
                onTap: onSimulacro,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _QuickTile(
                icon: Icons.book_outlined,
                iconColor: AppColors.accentMint,
                title: 'Por temas',
                subtitle: 'Elige el tema',
                onTap: onPorTemas,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickTile(
                icon: Icons.warning_amber_outlined,
                iconColor: AppColors.accentRose,
                title: 'Mis fallos',
                subtitle: 'Repasa errores',
                onTap: onMisFallos,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Tile individual ───────────────────────────────────────────────────────────

class _QuickTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final iconBg = iconColor.withOpacity(b == Brightness.dark ? 0.14 : 0.10);

    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceFor(b),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderFor(b), width: 0.5),
        ),
        child: Row(
          children: [
            // Icono
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 17, color: iconColor),
            ),
            const SizedBox(width: 10),
            // Textos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppText.cardTitle.copyWith(
                      color: AppColors.textFor(b),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: AppText.caption.copyWith(
                      color: AppColors.textMutedFor(b),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/pressable.dart';

/// Sección "También disponible" — lista quiet con iconos neutros y dividers.
///
/// Muestra accesos de segundo nivel: Calendario, Noticias y Chat IA.
class QuietListSection extends StatelessWidget {
  final VoidCallback onCalendario;
  final VoidCallback onNoticias;
  final VoidCallback onChat;

  const QuietListSection({
    super.key,
    required this.onCalendario,
    required this.onNoticias,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Heading de sección
        Text(
          'TAMBIÉN DISPONIBLE',
          style: AppText.label.copyWith(
            color: AppColors.textMutedFor(b),
          ),
        ),
        const SizedBox(height: 8),

        // Lista de filas
        _QuietTile(
          icon: Icons.calendar_month_outlined,
          title: 'Calendario',
          subtitle: 'Eventos y plazos',
          isFirst: true,
          onTap: onCalendario,
        ),
        _QuietTile(
          icon: Icons.newspaper_outlined,
          title: 'Noticias y convocatorias',
          subtitle: 'Últimas actualizaciones',
          onTap: onNoticias,
        ),
        _QuietTile(
          icon: Icons.chat_bubble_outline,
          title: 'Chat IA',
          subtitle: 'Resuelve tus dudas',
          isLast: true,
          onTap: onChat,
        ),
      ],
    );
  }
}

// ── Tile individual ───────────────────────────────────────────────────────────

class _QuietTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  const _QuietTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;

    return Column(
      children: [
        if (!isFirst)
          Divider(
            height: 0,
            thickness: 0.5,
            color: AppColors.borderFor(b),
          ),
        Pressable(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 2),
            child: Row(
              children: [
                // Icono neutro
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMutedFor(b),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 16,
                    color: AppColors.textMutedFor(b),
                  ),
                ),
                const SizedBox(width: 12),

                // Textos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppText.body.copyWith(
                          color: AppColors.textFor(b),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: AppText.caption.copyWith(
                          color: AppColors.textFaintFor(b),
                        ),
                      ),
                    ],
                  ),
                ),

                // Chevron
                Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: AppColors.textFaintFor(b),
                ),
              ],
            ),
          ),
        ),
        if (isLast)
          Divider(
            height: 0,
            thickness: 0.5,
            color: AppColors.borderFor(b),
          ),
      ],
    );
  }
}

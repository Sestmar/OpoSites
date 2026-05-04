import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Sección de saludo — fecha + H1 con la segunda línea en gradiente teal→rose.
class GreetingSection extends StatelessWidget {
  const GreetingSection({super.key});

  String get _dateStr {
    final now = DateTime.now();
    const weekdays = [
      '',
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    const months = [
      '',
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return '${weekdays[now.weekday]} ${now.day} · ${months[now.month]}'
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fecha
        Text(
          _dateStr,
          style: AppText.caption.copyWith(
            color: AppColors.textMutedFor(b),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 6),

        // H1 línea 1 — color normal
        Text(
          'Tus herramientas',
          style: AppText.display.copyWith(color: AppColors.textFor(b)),
        ),

        // H1 línea 2 — gradiente teal → rose
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.accentRose],
          ).createShader(bounds),
          child: Text(
            'de estudio.',
            style: AppText.display.copyWith(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

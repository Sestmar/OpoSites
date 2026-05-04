import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../data/models/documento_test.dart';

class DocumentoTestResultScreen extends StatelessWidget {
  const DocumentoTestResultScreen({super.key, required this.sesion});

  final DocumentoTestSesion sesion;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final aciertos = sesion.aciertos;
    final total = sesion.totalPreguntas;
    final porcentaje = total > 0 ? (aciertos / total * 100).round() : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado del test'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
        children: [
          // ── Tarjeta de puntuación ─────────────────────────────────────────
          _PuntuacionCard(
            aciertos: aciertos,
            total: total,
            porcentaje: porcentaje,
          ),
          const SizedBox(height: 24),

          // ── Revisión pregunta a pregunta ──────────────────────────────────
          Text(
            'REVISIÓN',
            style: AppText.label.copyWith(color: AppColors.textMutedFor(b)),
          ),
          const SizedBox(height: 10),
          ...List.generate(
            total,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PreguntaRevisionCard(
                index: i,
                pregunta: sesion.test.preguntas[i],
                respuestaUsuario: sesion.respuestasUsuario[i],
                correcta: sesion.esCorrecta(i),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Botón de salida ───────────────────────────────────────────────
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            // Volvemos al detalle haciendo pop dos veces:
            // resultado → test_screen → detalle.
            onPressed: () {
              context.pop(); // cierra resultado
              context.pop(); // cierra test screen
            },
            child: const Text('Volver al documento'),
          ),
        ],
      ),
    );
  }
}

// ── Tarjeta de puntuación ──────────────────────────────────────────────────────

class _PuntuacionCard extends StatelessWidget {
  const _PuntuacionCard({
    required this.aciertos,
    required this.total,
    required this.porcentaje,
  });

  final int aciertos;
  final int total;
  final int porcentaje;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final color = _colorPorcentaje(porcentaje, b);

    return AppCard.large(
      child: Column(
        children: [
          Icon(
            _iconoPorcentaje(porcentaje),
            size: 48,
            color: color,
          ),
          const SizedBox(height: 12),
          Text(
            '$porcentaje%',
            style: AppText.display.copyWith(color: color),
          ),
          const SizedBox(height: 4),
          Text(
            '$aciertos de $total correctas',
            style: AppText.body.copyWith(color: AppColors.textMutedFor(b)),
          ),
          const SizedBox(height: 4),
          Text(
            _etiqueta(porcentaje),
            style: AppText.bodySmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Color _colorPorcentaje(int pct, Brightness b) {
    if (pct >= 70) return AppColors.primaryFor(b);
    if (pct >= 40) return const Color(0xFFF59E0B); // ámbar
    return const Color(0xFFE53E3E); // rojo error
  }

  IconData _iconoPorcentaje(int pct) {
    if (pct >= 70) return Icons.emoji_events_outlined;
    if (pct >= 40) return Icons.trending_up_outlined;
    return Icons.refresh_outlined;
  }

  String _etiqueta(int pct) {
    if (pct >= 70) return '¡Buen resultado!';
    if (pct >= 40) return 'Vas por buen camino';
    return 'Seguí practicando';
  }
}

// ── Revisión de una pregunta ───────────────────────────────────────────────────

class _PreguntaRevisionCard extends StatelessWidget {
  const _PreguntaRevisionCard({
    required this.index,
    required this.pregunta,
    required this.respuestaUsuario,
    required this.correcta,
  });

  final int index;
  final DocumentoTestPregunta pregunta;
  final int respuestaUsuario;
  final bool correcta;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final primary = AppColors.primaryFor(b);
    const errorColor = Color(0xFFE53E3E);

    final headerColor = correcta ? primary : errorColor;
    final headerBg = correcta
        ? primary.withOpacity(0.1)
        : errorColor.withOpacity(0.08);

    return AppCard(
      padding: const EdgeInsets.all(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera: número + icono
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(
                  correcta ? Icons.check_circle_outline : Icons.cancel_outlined,
                  color: headerColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pregunta ${index + 1}',
                    style: AppText.label.copyWith(color: headerColor),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Enunciado
                Text(
                  pregunta.enunciado,
                  style: AppText.body.copyWith(
                    color: AppColors.textFor(b),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                // Opciones
                ...List.generate(pregunta.opciones.length, (i) {
                  final esCorrecta = i == pregunta.respuestaCorrecta;
                  final esElegida = i == respuestaUsuario;
                  final mostrarError = esElegida && !esCorrecta;

                  Color? bg;
                  Color borderCol = AppColors.borderFor(b);
                  if (esCorrecta) {
                    bg = primary.withOpacity(0.1);
                    borderCol = primary.withOpacity(0.4);
                  } else if (mostrarError) {
                    bg = errorColor.withOpacity(0.08);
                    borderCol = errorColor.withOpacity(0.4);
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderCol),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '${_letra(i)}. ',
                            style: AppText.bodySmall.copyWith(
                              color: AppColors.textMutedFor(b),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              pregunta.opciones[i],
                              style: AppText.bodySmall
                                  .copyWith(color: AppColors.textFor(b)),
                            ),
                          ),
                          if (esCorrecta)
                            Icon(Icons.check, color: primary, size: 16),
                          if (mostrarError)
                            Icon(Icons.close, color: errorColor, size: 16),
                        ],
                      ),
                    ),
                  );
                }),

                // Explicación
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMutedFor(b),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline,
                          size: 16, color: AppColors.textMutedFor(b)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          pregunta.explicacion,
                          style: AppText.bodySmall.copyWith(
                            color: AppColors.textMutedFor(b),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _letra(int i) => switch (i) {
        0 => 'A',
        1 => 'B',
        2 => 'C',
        _ => 'D',
      };
}

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../data/models/material_generado.dart';

class ConceptosClaveScreen extends StatelessWidget {
  const ConceptosClaveScreen({super.key, required this.material});

  final MaterialGenerado material;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final conceptos = material.conceptoList;

    return Scaffold(
      appBar: AppBar(title: const Text('Conceptos clave')),
      body: conceptos.isEmpty
          ? Center(
              child: Text(
                'Sin conceptos disponibles.',
                style: AppText.body.copyWith(color: AppColors.textMutedFor(b)),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: conceptos.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _ConceptoCard(
                numero: i + 1,
                concepto: conceptos[i],
              ),
            ),
    );
  }
}

class _ConceptoCard extends StatelessWidget {
  const _ConceptoCard({required this.numero, required this.concepto});
  final int numero;
  final Concepto concepto;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final primary = AppColors.primaryFor(b);

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Número ───────────────────────────────────────────────────────
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$numero',
                style: AppText.label.copyWith(
                  color: Colors.white,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // ── Término + definición ─────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  concepto.termino,
                  style: AppText.cardTitle.copyWith(color: AppColors.textFor(b)),
                ),
                const SizedBox(height: 4),
                Text(
                  concepto.definicion,
                  style: AppText.body.copyWith(
                    color: AppColors.textMutedFor(b),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

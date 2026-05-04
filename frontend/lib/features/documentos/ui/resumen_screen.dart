import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/models/material_generado.dart';

class ResumenScreen extends StatelessWidget {
  const ResumenScreen({super.key, required this.material});

  final MaterialGenerado material;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final texto = material.resumenTexto;

    return Scaffold(
      appBar: AppBar(title: const Text('Resumen')),
      body: texto.isEmpty
          ? Center(
              child: Text(
                'Sin contenido disponible.',
                style: AppText.body.copyWith(color: AppColors.textMutedFor(b)),
              ),
            )
          : Markdown(
              data: texto,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                  .copyWith(
                p: AppText.body.copyWith(
                  color: AppColors.textFor(b),
                  height: 1.6,
                ),
                h2: AppText.h2.copyWith(color: AppColors.textFor(b)),
                h3: AppText.cardTitle.copyWith(color: AppColors.textFor(b)),
              ),
            ),
    );
  }
}

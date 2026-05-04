import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../data/models/material_generado.dart';

class FlashcardsScreen extends StatefulWidget {
  const FlashcardsScreen({super.key, required this.material});

  final MaterialGenerado material;

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  late final List<Flashcard> _tarjetas;
  int _index = 0;
  bool _mostrandoRespuesta = false;

  @override
  void initState() {
    super.initState();
    _tarjetas = widget.material.flashcardList;
  }

  void _toggleRespuesta() =>
      setState(() => _mostrandoRespuesta = !_mostrandoRespuesta);

  void _anterior() {
    if (_index <= 0) return;
    setState(() {
      _index--;
      _mostrandoRespuesta = false;
    });
  }

  void _siguiente() {
    if (_index >= _tarjetas.length - 1) return;
    setState(() {
      _index++;
      _mostrandoRespuesta = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;

    if (_tarjetas.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Flashcards')),
        body: Center(
          child: Text(
            'No hay tarjetas disponibles.',
            style: AppText.body.copyWith(color: AppColors.textMutedFor(b)),
          ),
        ),
      );
    }

    final tarjeta = _tarjetas[_index];
    final total = _tarjetas.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcards'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${_index + 1} / $total',
                style: AppText.body.copyWith(
                  color: AppColors.textMutedFor(b),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Barra de progreso ────────────────────────────────────────────
            LinearProgressIndicator(
              value: (_index + 1) / total,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 24),

            // ── Tarjeta ──────────────────────────────────────────────────────
            // Sin GestureDetector — causa mouse_tracker crash en web durante setState
            Expanded(
              child: _FlashCard(
                texto: _mostrandoRespuesta ? tarjeta.respuesta : tarjeta.pregunta,
                esRespuesta: _mostrandoRespuesta,
              ),
            ),
            const SizedBox(height: 24),

            // ── Navegación ───────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton.outlined(
                  onPressed: _index > 0 ? _anterior : null,
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Anterior',
                ),
                FilledButton.icon(
                  onPressed: _toggleRespuesta,
                  // Override del tema global (minWidth=infinity) que rompe el Row en web.
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(140, 44),
                  ),
                  icon: Icon(_mostrandoRespuesta
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                  label: Text(_mostrandoRespuesta ? 'Ocultar' : 'Revelar'),
                ),
                IconButton.outlined(
                  onPressed: _index < total - 1 ? _siguiente : null,
                  icon: const Icon(Icons.arrow_forward),
                  tooltip: 'Siguiente',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FlashCard extends StatelessWidget {
  const _FlashCard({required this.texto, required this.esRespuesta});

  final String texto;
  final bool esRespuesta;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;

    final cardColor = esRespuesta
        ? AppColors.primaryFor(b).withOpacity(0.12)
        : null; // null → AppCard default surfaceFor(b)

    return AppCard.large(
      color: cardColor,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            esRespuesta ? 'RESPUESTA' : 'PREGUNTA',
            style: AppText.label.copyWith(
              color: esRespuesta
                  ? AppColors.primaryFor(b)
                  : AppColors.textMutedFor(b),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            texto,
            textAlign: TextAlign.center,
            style: AppText.body.copyWith(
              color: AppColors.textFor(b),
              fontSize: 17,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

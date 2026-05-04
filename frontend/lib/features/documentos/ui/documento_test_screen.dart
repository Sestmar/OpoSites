import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../data/models/documento_test.dart';

class DocumentoTestScreen extends StatefulWidget {
  const DocumentoTestScreen({super.key, required this.test});

  final DocumentoTest test;

  @override
  State<DocumentoTestScreen> createState() => _DocumentoTestScreenState();
}

class _DocumentoTestScreenState extends State<DocumentoTestScreen> {
  int _indice = 0;
  late final List<int> _respuestas; // -1 = sin responder

  @override
  void initState() {
    super.initState();
    _respuestas = List.filled(widget.test.preguntas.length, -1);
  }

  DocumentoTestPregunta get _preguntaActual =>
      widget.test.preguntas[_indice];

  bool get _esUltima => _indice == widget.test.preguntas.length - 1;
  bool get _respondioActual => _respuestas[_indice] != -1;

  void _seleccionar(int opcion) {
    setState(() => _respuestas[_indice] = opcion);
  }

  void _siguiente() {
    if (!_esUltima) {
      setState(() => _indice++);
    }
  }

  void _anterior() {
    if (_indice > 0) {
      setState(() => _indice--);
    }
  }

  void _entregar() {
    final sesion = DocumentoTestSesion(
      test: widget.test,
      respuestasUsuario: List.unmodifiable(_respuestas),
    );
    context.push(
      AppRoutes.documentoTestResultado(widget.test.documentoId),
      extra: sesion,
    );
  }

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final total = widget.test.preguntas.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Pregunta ${_indice + 1} de $total'),
        actions: [
          TextButton(
            onPressed: _entregar,
            child: const Text('Entregar'),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Barra de progreso ──────────────────────────────────────────────
          LinearProgressIndicator(
            value: (_indice + 1) / total,
            backgroundColor: AppColors.borderFor(b),
            color: AppColors.primaryFor(b),
            minHeight: 3,
          ),

          // ── Contenido principal ────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              children: [
                // Enunciado
                AppCard(
                  child: Text(
                    _preguntaActual.enunciado,
                    style: AppText.body.copyWith(
                      color: AppColors.textFor(b),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Opciones
                ...List.generate(
                  _preguntaActual.opciones.length,
                  (i) => _OpcionTile(
                    letra: _letraOpcion(i),
                    texto: _preguntaActual.opciones[i],
                    seleccionada: _respuestas[_indice] == i,
                    onTap: () => _seleccionar(i),
                  ),
                ),
              ],
            ),
          ),

          // ── Navegación inferior ────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  if (_indice > 0)
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(100, 44),
                      ),
                      onPressed: _anterior,
                      child: const Text('Anterior'),
                    ),
                  const Spacer(),
                  if (_esUltima)
                    FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(120, 44),
                      ),
                      onPressed: _entregar,
                      child: const Text('Entregar'),
                    )
                  else
                    FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(120, 44),
                      ),
                      onPressed: _respondioActual ? _siguiente : null,
                      child: const Text('Siguiente'),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _letraOpcion(int i) => switch (i) {
        0 => 'A',
        1 => 'B',
        2 => 'C',
        _ => 'D',
      };
}

// ── Tile de opción ─────────────────────────────────────────────────────────────

class _OpcionTile extends StatelessWidget {
  const _OpcionTile({
    required this.letra,
    required this.texto,
    required this.seleccionada,
    required this.onTap,
  });

  final String letra;
  final String texto;
  final bool seleccionada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final primary = AppColors.primaryFor(b);

    final bgColor = seleccionada
        ? primary.withOpacity(0.12)
        : AppColors.surfaceFor(b);
    final borderColor = seleccionada
        ? primary.withOpacity(0.5)
        : AppColors.borderFor(b);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: seleccionada ? primary : primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    letra,
                    style: AppText.label.copyWith(
                      color: seleccionada
                          ? Colors.white
                          : AppColors.textMutedFor(b),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  texto,
                  style: AppText.body.copyWith(
                    color: AppColors.textFor(b),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

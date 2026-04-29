import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/test_question.dart';
import '../providers/test_fallos_provider.dart';

class TestFallosScreen extends ConsumerStatefulWidget {
  const TestFallosScreen({super.key});

  @override
  ConsumerState<TestFallosScreen> createState() => _TestFallosScreenState();
}

class _TestFallosScreenState extends ConsumerState<TestFallosScreen> {
  @override
  void initState() {
    super.initState();
    // Disparamos la carga al entrar a la pantalla
    Future.microtask(
      () => ref.read(testFallosProvider.notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fallosAsync = ref.watch(testFallosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preguntas falladas'),
        actions: [
          // Botón de recarga manual
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar',
            onPressed: () => ref.read(testFallosProvider.notifier).load(),
          ),
        ],
      ),
      body: switch (fallosAsync) {
        AsyncLoading() => const Center(child: CircularProgressIndicator()),

        AsyncError(:final error) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 12),
                Text(
                  'No se pudieron cargar los fallos.\n$error',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.read(testFallosProvider.notifier).load(),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),

        AsyncData(:final value) when value.isEmpty => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  '¡Sin fallos pendientes!',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Hacé más tests para acumular preguntas de repaso.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),

        AsyncData(:final value) => _FallosList(preguntas: value),

        // Catch-all por exhaustividad del compilador
        _ => const SizedBox.shrink(),
      },
    );
  }
}

// ── Lista de preguntas falladas ────────────────────────────────────────────────

class _FallosList extends StatelessWidget {
  const _FallosList({required this.preguntas});
  final List<TestQuestion> preguntas;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            '${preguntas.length} pregunta${preguntas.length == 1 ? '' : 's'} para repasar',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: preguntas.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _FalloTile(pregunta: preguntas[i]),
          ),
        ),
      ],
    );
  }
}

class _FalloTile extends StatefulWidget {
  const _FalloTile({required this.pregunta});
  final TestQuestion pregunta;

  @override
  State<_FalloTile> createState() => _FalloTileState();
}

class _FalloTileState extends State<_FalloTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final q = widget.pregunta;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabecera
              Row(
                children: [
                  Icon(
                    Icons.replay_rounded,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      q.enunciado,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: _expanded ? null : 2,
                      overflow: _expanded ? null : TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 20,
                  ),
                ],
              ),

              // Opciones expandidas (para MCQ / TRUE_FALSE)
              if (_expanded && q.tipo != QuestionType.desarrollo) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),
                ...q.opciones.map(
                  (o) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.circle, size: 8),
                        const SizedBox(width: 8),
                        Expanded(child: Text(o)),
                      ],
                    ),
                  ),
                ),
              ],

              // Badge de dificultad
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: _DifficultyBadge(level: q.dificultad),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DifficultyBadge extends StatelessWidget {
  const _DifficultyBadge({required this.level});
  final int level;

  @override
  Widget build(BuildContext context) {
    final color = switch (level) {
      1 || 2 => Colors.green,
      3 => Colors.orange,
      _ => Colors.red,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        'Dificultad $level',
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: color),
      ),
    );
  }
}

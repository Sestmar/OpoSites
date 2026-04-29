import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../tests/data/models/test_result.dart';
import '../providers/simulacro_session_provider.dart';

class SimulacroResultScreen extends ConsumerWidget {
  const SimulacroResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activeSimulacroProvider);

    if (state is! SimulacroStateCompleted) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.go(AppRoutes.practicarSimulacros),
      );
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final result = state.result;
    final fallos = result.detalle.where((d) => !d.correcto).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado del simulacro'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Nota ──────────────────────────────────────────────────────
          _NotaCard(result: result),
          const SizedBox(height: 16),

          // ── Resumen ───────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _SummaryTile(
                  icon: Icons.check_circle_outline,
                  label: 'Correctas',
                  value: '${result.correctas}',
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryTile(
                  icon: Icons.cancel_outlined,
                  label: 'Incorrectas',
                  value: '$fallos',
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryTile(
                  icon: Icons.help_outline,
                  label: 'Sin resp.',
                  value: '${result.total - result.correctas - fallos}',
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Análisis por tema (siempre presente en simulacros) ────────
          if (result.analisisPorTema != null &&
              result.analisisPorTema!.isNotEmpty) ...[
            Text('Análisis por tema',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _TopicAnalysisTable(topics: result.analisisPorTema!),
            const SizedBox(height: 20),
          ],

          // ── Detalle por pregunta ───────────────────────────────────────
          Text('Detalle pregunta a pregunta',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...result.detalle.asMap().entries.map(
                (e) => _QuestionResultTile(
                  index: e.key + 1,
                  detail: e.value,
                ),
              ),
          const SizedBox(height: 24),

          // ── Acciones ──────────────────────────────────────────────────
          OutlinedButton.icon(
            onPressed: () {
              ref.read(activeSimulacroProvider.notifier).reset();
              context.go(AppRoutes.practicarSimulacros);
            },
            icon: const Icon(Icons.list_alt_outlined),
            label: const Text('Ver más simulacros'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () {
              ref.read(activeSimulacroProvider.notifier).reset();
              context.go(AppRoutes.home);
            },
            icon: const Icon(Icons.home_outlined),
            label: const Text('Ir a inicio'),
          ),
        ],
      ),
    );
  }
}

// ── Widgets auxiliares ─────────────────────────────────────────────────────────

class _NotaCard extends StatelessWidget {
  const _NotaCard({required this.result});
  final TestResult result;

  @override
  Widget build(BuildContext context) {
    final nota = result.nota;
    final color =
        nota >= 5 ? Colors.green : Theme.of(context).colorScheme.error;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          children: [
            Text(
              nota.toStringAsFixed(1),
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              'sobre 10',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '${result.correctas} de ${result.total} correctas',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    )),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _TopicAnalysisTable extends StatelessWidget {
  const _TopicAnalysisTable({required this.topics});
  final List<TopicAnalysis> topics;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          // Cabecera
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text('Tema',
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
                SizedBox(
                  width: 60,
                  child: Text('Acierto',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
                SizedBox(
                  width: 60,
                  child: Text('Resp.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Filas por tema
          ...topics.map(
            (t) => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          t.nombreTema,
                          style: Theme.of(context).textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(
                        width: 60,
                        child: Center(
                          child: _AciertoBadge(
                              porcentaje: t.porcentajeAcierto),
                        ),
                      ),
                      SizedBox(
                        width: 60,
                        child: Text(
                          '${t.correctas}/${t.total}',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AciertoBadge extends StatelessWidget {
  const _AciertoBadge({required this.porcentaje});
  final double porcentaje;

  @override
  Widget build(BuildContext context) {
    final color = porcentaje >= 50 ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${porcentaje.toStringAsFixed(0)}%',
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _QuestionResultTile extends StatelessWidget {
  const _QuestionResultTile({required this.index, required this.detail});
  final int index;
  final QuestionResult detail;

  @override
  Widget build(BuildContext context) {
    final isCorrect = detail.correcto;
    final wasSkipped = detail.respuestaUsuario == null;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          isCorrect
              ? Icons.check_circle
              : wasSkipped
                  ? Icons.remove_circle_outline
                  : Icons.cancel,
          color: isCorrect
              ? Colors.green
              : wasSkipped
                  ? Theme.of(context).colorScheme.onSurfaceVariant
                  : Theme.of(context).colorScheme.error,
        ),
        title: Text('Pregunta $index'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isCorrect && !wasSkipped) ...[
              Text('Tu respuesta: ${detail.respuestaUsuario}'),
              Text('Correcta: ${detail.respuestaCorrecta}',
                  style: TextStyle(color: Colors.green.shade700)),
            ],
            if (wasSkipped) const Text('Sin responder'),
            if (detail.explicacion != null &&
                detail.explicacion!.isNotEmpty)
              Text(detail.explicacion!,
                  style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        isThreeLine: !isCorrect,
      ),
    );
  }
}

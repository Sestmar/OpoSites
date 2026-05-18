import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../data/models/test_result.dart';
import '../providers/test_session_provider.dart';

class TestResultScreen extends ConsumerWidget {
  const TestResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final testState = ref.watch(activeTestProvider);

    if (testState is! TestStateCompleted) {
      // Llegamos aquí sin resultado — volvemos al inicio
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.go(AppRoutes.practicarTests),
      );
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final result = testState.result;
    final marcadasCount = testState.marcadasCount;
    final fallos = result.detalle.where((d) => !d.correcto).length;
    final sinRespuesta = result.detalle.where((d) => d.respuestaUsuario == null).length;
    final incorrectas = fallos - sinRespuesta;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado del test'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Nota ────────────────────────────────────────────────────────
          _NotaCard(result: result),
          const SizedBox(height: 20),

          // ── Resumen ──────────────────────────────────────────────────────
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
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryTile(
                  icon: Icons.cancel_outlined,
                  label: 'Incorrectas',
                  value: '$incorrectas',
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryTile(
                  icon: Icons.help_outline,
                  label: 'Sin resp.',
                  value: '$sinRespuesta',
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Detalle por pregunta ─────────────────────────────────────────
          Text('Detalle', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...result.detalle.asMap().entries.map(
                (e) => _QuestionResultTile(
                  index: e.key + 1,
                  detail: e.value,
                ),
              ),
          const SizedBox(height: 24),

          // ── Marcadas para repaso ─────────────────────────────────────────
          if (marcadasCount > 0) ...[
            const SizedBox(height: 4),
            ListTile(
              leading: Icon(
                Icons.bookmark_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                '$marcadasCount pregunta${marcadasCount > 1 ? 's' : ''} marcada${marcadasCount > 1 ? 's' : ''} para repasar',
              ),
              subtitle: const Text('Puedes repasar desde "Practicar"'),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
            const SizedBox(height: 8),
          ],

          // ── Acciones ─────────────────────────────────────────────────────
          if (fallos > 0)
            OutlinedButton.icon(
              onPressed: () => context.go(AppRoutes.testFallos),
              icon: const Icon(Icons.refresh),
              label: const Text('Repasar fallos'),
            ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () {
              ref.read(activeTestProvider.notifier).reset();
              context.go(AppRoutes.practicarTests);
            },
            icon: const Icon(Icons.add),
            label: const Text('Nuevo test'),
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
    final color = nota >= 5 ? Colors.green : Theme.of(context).colorScheme.error;

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
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
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
              Text(
                'Correcta: ${detail.respuestaCorrecta}',
                style: TextStyle(color: Colors.green.shade700),
              ),
            ],
            if (wasSkipped) const Text('Sin responder'),
            if (detail.explicacion != null && detail.explicacion!.isNotEmpty)
              Text(
                detail.explicacion!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        isThreeLine: !isCorrect,
      ),
    );
  }
}

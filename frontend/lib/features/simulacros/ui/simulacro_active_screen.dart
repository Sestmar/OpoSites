import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../plan/providers/plan_provider.dart';
import '../../plan/providers/plan_semana_provider.dart';
import '../../tests/data/models/question_answer.dart';
import '../../tests/data/models/test_question.dart';
import '../../tests/data/models/test_session.dart';
import '../providers/simulacro_session_provider.dart';

class SimulacroActiveScreen extends ConsumerStatefulWidget {
  const SimulacroActiveScreen({super.key});

  @override
  ConsumerState<SimulacroActiveScreen> createState() =>
      _SimulacroActiveScreenState();
}

class _SimulacroActiveScreenState
    extends ConsumerState<SimulacroActiveScreen> {
  int _currentIndex = 0;
  int _secondsRemaining = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(activeSimulacroProvider);
      if (state is SimulacroStateActive) {
        setState(() => _secondsRemaining = state.duracionMinutos * 60);
        _startTimer();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_secondsRemaining <= 0) {
        _timer?.cancel();
        ref.read(activeSimulacroProvider.notifier).entregarSimulacro();
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  String _formatTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:'
          '${m.toString().padLeft(2, '0')}:'
          '${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Color _timerColor(BuildContext context) {
    if (_secondsRemaining > 300) return Colors.green; // > 5 min
    if (_secondsRemaining > 120) return Colors.orange; // 2–5 min
    return Theme.of(context).colorScheme.error; // < 2 min
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<SimulacroState>(activeSimulacroProvider, (_, next) {
      if (next is SimulacroStateCompleted) {
        _timer?.cancel();
        // Auto-completar la tarea del plan si este simulacro fue lanzado desde él
        final tareaId = ref.read(planTareaActivaProvider);
        if (tareaId != null) {
          ref.read(planSemanaProvider.notifier).completarTarea(tareaId);
          ref.read(planTareaActivaProvider.notifier).state = null;
        }
        context.go(AppRoutes.simulacroResultado);
      }
      if (next is SimulacroStateError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    });

    final state = ref.watch(activeSimulacroProvider);

    return switch (state) {
      SimulacroStateIdle() || SimulacroStateLoading() => Scaffold(
          appBar: AppBar(title: const Text('Simulacro')),
          body: const Center(child: CircularProgressIndicator()),
        ),

      SimulacroStateError(:final message) => Scaffold(
          appBar: AppBar(title: const Text('Simulacro')),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.go(AppRoutes.practicarSimulacros),
                  child: const Text('Volver a la lista'),
                ),
              ],
            ),
          ),
        ),

      SimulacroStateActive(:final session, :final answers) ||
      SimulacroStateSubmitting(:final session, :final answers) =>
        _buildSimulacroUI(context, ref, state, session, answers),

      SimulacroStateCompleted() => const SizedBox.shrink(),
    };
  }

  Widget _buildSimulacroUI(
    BuildContext context,
    WidgetRef ref,
    SimulacroState state,
    TestSession session,
    List<QuestionAnswer> answers,
  ) {
    final questions = session.preguntas;
    final isSubmitting = state is SimulacroStateSubmitting;
    final total = questions.length;
    final question = questions[_currentIndex.clamp(0, total - 1)];

    final currentAnswer = answers.firstWhere(
      (a) => a.preguntaId == question.id,
      orElse: () => QuestionAnswer(preguntaId: question.id),
    );
    final selectedOption = currentAnswer.respuestaUsuario;

    final isFirst = _currentIndex == 0;
    final isLast = _currentIndex == total - 1;
    final respondidas = answers.where((a) => a.respuestaUsuario != null).length;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('${_currentIndex + 1} / $total'),
        actions: [
          // ── Cronómetro ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                _formatTime(_secondsRemaining),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: _timerColor(context),
                      fontWeight: FontWeight.bold,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Barra de progreso ──────────────────────────────────────────
          LinearProgressIndicator(value: (_currentIndex + 1) / total),

          // ── Pregunta y opciones ────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    question.enunciado,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 20),
                  if (question.tipo == QuestionType.desarrollo)
                    TextFormField(
                      initialValue: selectedOption,
                      maxLines: 4,
                      enabled: !isSubmitting,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Escribe tu respuesta…',
                      ),
                      onChanged: (v) => ref
                          .read(activeSimulacroProvider.notifier)
                          .seleccionarRespuesta(question.id, v),
                    )
                  else
                    ...question.opciones.map(
                      (opcion) => _OptionTile(
                        opcion: opcion,
                        label: question.tipo == QuestionType.trueFalse
                            ? switch (opcion) {
                                'X' => 'Incorrecto (X)',
                                '-' => 'Correcto (-)',
                                _ => opcion,
                              }
                            : opcion,
                        isSelected: selectedOption == opcion,
                        isSubmitting: isSubmitting,
                        onTap: () => ref
                            .read(activeSimulacroProvider.notifier)
                            .seleccionarRespuesta(question.id, opcion),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Pie: navegación y entrega ────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Contador de respondidas
                  Text(
                    '$respondidas / $total respondidas',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (!isFirst)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isSubmitting
                                ? null
                                : () => setState(
                                    () => _currentIndex = _currentIndex - 1),
                            child: const Text('Anterior'),
                          ),
                        ),
                      if (!isFirst) const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: isLast
                            ? FilledButton(
                                onPressed: isSubmitting
                                    ? null
                                    : () => ref
                                        .read(activeSimulacroProvider.notifier)
                                        .entregarSimulacro(),
                                child: isSubmitting
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                    : const Text('Entregar simulacro'),
                              )
                            : FilledButton(
                                onPressed: isSubmitting
                                    ? null
                                    : () => setState(() =>
                                        _currentIndex = _currentIndex + 1),
                                child: const Text('Siguiente'),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tile de opción (extraído para no repetir con TestActiveScreen) ─────────────

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.opcion,
    required this.isSelected,
    required this.isSubmitting,
    required this.onTap,
    this.label,
  });
  final String opcion;
  final String? label;
  final bool isSelected;
  final bool isSubmitting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isSubmitting ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color:
                    isSelected ? Theme.of(context).colorScheme.primary : null,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(label ?? opcion)),
            ],
          ),
        ),
      ),
    );
  }
}

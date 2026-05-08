import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../data/models/question_answer.dart';
import '../data/models/test_question.dart';
import '../data/models/test_session.dart';
import '../providers/test_session_provider.dart';
import '../../plan/providers/plan_provider.dart';
import '../../plan/providers/plan_semana_provider.dart';

class TestActiveScreen extends ConsumerStatefulWidget {
  const TestActiveScreen({super.key});

  @override
  ConsumerState<TestActiveScreen> createState() => _TestActiveScreenState();
}

class _TestActiveScreenState extends ConsumerState<TestActiveScreen> {
  int _currentIndex = 0;
  Timer? _timer;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    final testState = ref.read(activeTestProvider);
    if (testState is TestStateActive) {
      final minutos = testState.session.tiempoMinutos;
      if (minutos != null && minutos > 0) {
        _secondsLeft = minutos * 60;
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (_secondsLeft <= 1) {
            _timer?.cancel();
            _timer = null;
            final current = ref.read(activeTestProvider);
            if (current is TestStateActive) {
              ref.read(activeTestProvider.notifier).enviarRespuestas();
            }
          } else {
            setState(() => _secondsLeft--);
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Navegamos cuando se completa el envío
    ref.listen<TestState>(activeTestProvider, (_, next) {
      if (next is TestStateCompleted) {
        // Auto-completar la tarea del plan si este test fue lanzado desde él
        final tareaId = ref.read(planTareaActivaProvider);
        if (tareaId != null) {
          ref.read(planSemanaProvider.notifier).completarTarea(tareaId);
          ref.read(planTareaActivaProvider.notifier).state = null;
        }
        context.go(AppRoutes.testResultado);
      }
      if (next is TestStateError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    });

    final testState = ref.watch(activeTestProvider);

    return switch (testState) {
      // ── Pantalla de guarda: si llegamos aquí sin test activo ───────────────
      TestStateIdle() || TestStateLoading() => Scaffold(
          appBar: AppBar(title: const Text('Test')),
          body: const Center(child: CircularProgressIndicator()),
        ),

      TestStateError(:final message) => Scaffold(
          appBar: AppBar(title: const Text('Test')),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.go(AppRoutes.practicarTests),
                  child: const Text('Volver al inicio'),
                ),
              ],
            ),
          ),
        ),

      // ── Test en curso ──────────────────────────────────────────────────────
      TestStateActive(:final session, :final answers) ||
      TestStateSubmitting(:final session, :final answers) =>
        _buildTestUI(context, ref, testState, session, answers),

      // ── Completado: la navegación ya la disparó el listener ───────────────
      TestStateCompleted() => const SizedBox.shrink(),
    };
  }

  Widget _buildTestUI(
    BuildContext context,
    WidgetRef ref,
    TestState state,
    TestSession session,
    List<QuestionAnswer> answers,
  ) {
    final questions = session.preguntas;
    final isSubmitting = state is TestStateSubmitting;
    final total = questions.length;
    final question = questions[_currentIndex.clamp(0, total - 1)];

    // Respuesta actualmente seleccionada para esta pregunta
    final currentAnswer = answers.firstWhere(
      (a) => a.preguntaId == question.id,
      orElse: () => QuestionAnswer(preguntaId: question.id),
    );
    final selectedOption = currentAnswer.respuestaUsuario;

    final isFirst = _currentIndex == 0;
    final isLast = _currentIndex == total - 1;

    return Scaffold(
      appBar: AppBar(
        title: Text('Pregunta ${_currentIndex + 1} / $total'),
        automaticallyImplyLeading: false,
        actions: [
          // Countdown (solo si hay límite de tiempo activo)
          if (_secondsLeft > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Text(
                  _formatTime(_secondsLeft),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _secondsLeft < 60
                            ? Theme.of(context).colorScheme.error
                            : null,
                        fontWeight: FontWeight.bold,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                ),
              ),
            ),
          // Progreso rápido: X respondidas
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                '${(answers as List).cast().where((a) => a.respuestaUsuario != null).length}/$total respondidas',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Barra de progreso ────────────────────────────────────────────
          LinearProgressIndicator(
            value: (_currentIndex + 1) / total,
          ),

          // ── Pregunta y opciones ──────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Enunciado
                  Text(
                    question.enunciado,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 20),

                  // Opciones
                  if (question.tipo == QuestionType.desarrollo)
                    _buildDesarrolloInput(context, ref, question, selectedOption, isSubmitting)
                  else
                    ...question.opciones.asMap().entries.map(
                          (entry) => _buildOptionTile(
                            context,
                            ref,
                            question,
                            entry.value,
                            selectedOption,
                            isSubmitting,
                          ),
                        ),
                ],
              ),
            ),
          ),

          // ── Navegación ───────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
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
                                    .read(activeTestProvider.notifier)
                                    .enviarRespuestas(),
                            child: isSubmitting
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Text('Enviar test'),
                          )
                        : FilledButton(
                            onPressed: isSubmitting
                                ? null
                                : () => setState(
                                    () => _currentIndex = _currentIndex + 1),
                            child: const Text('Siguiente'),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Widget _buildOptionTile(
    BuildContext context,
    WidgetRef ref,
    TestQuestion question,
    String opcion,
    String? selectedOption,
    bool isSubmitting,
  ) {
    final isSelected = selectedOption == opcion;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected
          ? Theme.of(context).colorScheme.primaryContainer
          : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isSubmitting
            ? null
            : () => ref
                .read(activeTestProvider.notifier)
                .seleccionarRespuesta(question.id, opcion),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(opcion)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesarrolloInput(
    BuildContext context,
    WidgetRef ref,
    TestQuestion question,
    String? selectedOption,
    bool isSubmitting,
  ) {
    return TextFormField(
      initialValue: selectedOption,
      maxLines: 4,
      enabled: !isSubmitting,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        hintText: 'Escribe tu respuesta…',
      ),
      onChanged: (v) => ref
          .read(activeTestProvider.notifier)
          .seleccionarRespuesta(question.id, v),
    );
  }
}

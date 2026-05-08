import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../features/auth/providers/auth_provider.dart';
import '../../../plan/data/models/plan_configuracion.dart';
import '../../../plan/providers/plan_provider.dart';

// ── Pantalla de onboarding extra ───────────────────────────────────────────────
//
// Aparece una sola vez, justo después de que el usuario selecciona su oposición.
// Recoge fecha de examen (paso 1) y horas de estudio por semana (paso 2).
// Ambos pasos son opcionales — el usuario puede saltar cada uno.
// Al terminar guarda los datos informados via PATCH /plan/configuracion.

class OnboardingExtraScreen extends ConsumerStatefulWidget {
  const OnboardingExtraScreen({super.key});

  @override
  ConsumerState<OnboardingExtraScreen> createState() =>
      _OnboardingExtraScreenState();
}

class _OnboardingExtraScreenState extends ConsumerState<OnboardingExtraScreen> {
  int _step = 0; // 0 = fecha examen, 1 = horas por semana

  DateTime? _fechaExamen;
  int _horasSemana = 10;
  bool _saving = false;

  // ── Paso 1: fecha ──────────────────────────────────────────────────────────

  Future<void> _pickFecha() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaExamen ?? now.add(const Duration(days: 90)),
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _fechaExamen = picked);
  }

  // ── Finalizar ──────────────────────────────────────────────────────────────

  Future<void> _finalizar({bool saltarHoras = false}) async {
    setState(() => _saving = true);

    final fecha = _fechaExamen;
    final horas = saltarHoras ? null : _horasSemana;

    // Solo llamamos al backend si hay al menos un dato para guardar
    if (fecha != null || horas != null) {
      final fechaStr = fecha == null
          ? null
          : '${fecha.year.toString().padLeft(4, '0')}-'
            '${fecha.month.toString().padLeft(2, '0')}-'
            '${fecha.day.toString().padLeft(2, '0')}';

      await ref
          .read(planConfiguracionNotifierProvider.notifier)
          .actualizar(UpdatePlanConfiguracionRequest(
            horasSemana: horas,
            fechaExamenObjetivo: fechaStr,
          ));
    }

    if (!mounted) return;

    // Actualizar auth con la rama ya guardada en backend
    final me = ref.read(authProvider);
    if (me is AuthAuthenticated && me.ramaPrincipalId == null) {
      // Caso edge: ramaSelected aún no se llamó (no debería pasar, pero por seguridad)
      context.go(AppRoutes.home);
      return;
    }

    context.go(AppRoutes.home);
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primary,
              primary.withOpacity(0.6),
              theme.colorScheme.surface,
            ],
            stops: const [0.0, 0.25, 0.65],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // ── Indicador de paso ──────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _StepDot(active: _step == 0, done: _step > 0),
                    const SizedBox(width: 8),
                    _StepDot(active: _step == 1, done: false),
                  ],
                ),
                const SizedBox(height: 32),

                // ── Contenido del paso activo ──────────────────────────────
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _step == 0
                        ? _Step1Fecha(
                            key: const ValueKey(0),
                            fechaSeleccionada: _fechaExamen,
                            onPickFecha: _pickFecha,
                            onSkip: () => setState(() => _step = 1),
                            onContinue: () => setState(() => _step = 1),
                          )
                        : _Step2Horas(
                            key: const ValueKey(1),
                            horas: _horasSemana,
                            onHorasChanged: (h) =>
                                setState(() => _horasSemana = h),
                            onSkip: () => _finalizar(saltarHoras: true),
                            onContinue: _saving ? null : _finalizar,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Paso 1: fecha de examen ────────────────────────────────────────────────────

class _Step1Fecha extends StatelessWidget {
  const _Step1Fecha({
    super.key,
    required this.fechaSeleccionada,
    required this.onPickFecha,
    required this.onSkip,
    required this.onContinue,
  });

  final DateTime? fechaSeleccionada;
  final VoidCallback onPickFecha;
  final VoidCallback onSkip;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDate = fechaSeleccionada != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('📅', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 16),
        Text(
          '¿Cuándo es\ntu examen?',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Ajustamos la intensidad del plan según el tiempo que te queda.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white.withOpacity(0.8),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 32),

        // ── Selector de fecha ────────────────────────────────────────────
        GestureDetector(
          onTap: onPickFecha,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: hasDate
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surface.withOpacity(0.9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasDate
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
                width: hasDate ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  color: hasDate
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Text(
                  hasDate
                      ? _formatFecha(fechaSeleccionada!)
                      : 'Seleccioná una fecha',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: hasDate
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight:
                        hasDate ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),

        const Spacer(),

        // ── Acciones ─────────────────────────────────────────────────────
        FilledButton(
          onPressed: onContinue,
          child: const Text('Continuar'),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: onSkip,
          child: Text(
            'Saltar por ahora',
            style: TextStyle(color: Colors.white.withOpacity(0.7)),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  String _formatFecha(DateTime d) {
    const meses = [
      '', 'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];
    return '${d.day} de ${meses[d.month]} de ${d.year}';
  }
}

// ── Paso 2: horas de estudio ───────────────────────────────────────────────────

class _Step2Horas extends StatelessWidget {
  const _Step2Horas({
    super.key,
    required this.horas,
    required this.onHorasChanged,
    required this.onSkip,
    required this.onContinue,
  });

  final int horas;
  final ValueChanged<int> onHorasChanged;
  final VoidCallback onSkip;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('⏱️', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 16),
        Text(
          '¿Cuántas horas\npor semana?',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'El plan distribuye las tareas según las horas que tenés disponibles.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white.withOpacity(0.8),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 40),

        // ── Stepper de horas ─────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton.outlined(
                onPressed: horas > 1
                    ? () => onHorasChanged(horas - 1)
                    : null,
                icon: const Icon(Icons.remove_rounded),
              ),
              Column(
                children: [
                  Text(
                    '$horas',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    horas == 1 ? 'hora / semana' : 'horas / semana',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              IconButton.outlined(
                onPressed: horas < 40
                    ? () => onHorasChanged(horas + 1)
                    : null,
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
        ),

        const Spacer(),

        // ── Acciones ─────────────────────────────────────────────────────
        FilledButton(
          onPressed: onContinue,
          child: onContinue == null
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Empezar'),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: onSkip,
          child: Text(
            'Saltar por ahora',
            style: TextStyle(color: Colors.white.withOpacity(0.7)),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ── Indicador de paso ──────────────────────────────────────────────────────────

class _StepDot extends StatelessWidget {
  const _StepDot({required this.active, required this.done});
  final bool active;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: active ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: (active || done)
            ? Colors.white
            : Colors.white.withOpacity(0.35),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

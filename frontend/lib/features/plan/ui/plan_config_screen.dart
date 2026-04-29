import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/plan_configuracion.dart';
import '../providers/plan_provider.dart';

// ── Pantalla principal ─────────────────────────────────────────────────────────

class PlanConfigScreen extends ConsumerStatefulWidget {
  const PlanConfigScreen({super.key});

  @override
  ConsumerState<PlanConfigScreen> createState() => _PlanConfigScreenState();
}

class _PlanConfigScreenState extends ConsumerState<PlanConfigScreen> {
  final _horasSemanaCtrl = TextEditingController();
  final _fechaExamenCtrl = TextEditingController();
  PreferenciaPlan _preferencia = PreferenciaPlan.mixto;

  /// Evita reinicializar el formulario si el provider se recarga (ej. tras guardar).
  bool _formInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(planConfiguracionNotifierProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _horasSemanaCtrl.dispose();
    _fechaExamenCtrl.dispose();
    super.dispose();
  }

  /// Inicializa el formulario con los datos del servidor la primera vez.
  void _initForm(PlanConfiguracion config) {
    if (_formInitialized) return;
    _horasSemanaCtrl.text = config.horasSemana.toString();
    _fechaExamenCtrl.text = config.fechaExamenObjetivo ?? '';
    setState(() {
      _preferencia = config.preferencia;
      _formInitialized = true;
    });
  }

  Future<void> _guardar() async {
    final horas = int.tryParse(_horasSemanaCtrl.text.trim());
    if (horas == null || horas < 1 || horas > 40) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresá un número de horas válido (1–40)'),
        ),
      );
      return;
    }

    final fechaText = _fechaExamenCtrl.text.trim();
    final request = UpdatePlanConfiguracionRequest(
      horasSemana: horas,
      preferencia: _preferencia,
      fechaExamenObjetivo: fechaText.isEmpty ? null : fechaText,
    );

    // actualizar usa AsyncValue.guard: los errores van al estado, no se lanzan.
    await ref
        .read(planConfiguracionNotifierProvider.notifier)
        .actualizar(request);

    if (!mounted) return;

    final currentState = ref.read(planConfiguracionNotifierProvider);
    if (currentState.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: ${currentState.error}'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuración guardada correctamente')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(planConfiguracionNotifierProvider);

    // Inicializar form cuando llegan los datos por primera vez.
    state.whenData((config) {
      if (config != null) _initForm(config);
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Configuración del plan')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorBody(
          message: e.toString(),
          onRetry: () =>
              ref.read(planConfiguracionNotifierProvider.notifier).load(),
        ),
        data: (config) {
          if (config == null || !_formInitialized) {
            return const Center(child: CircularProgressIndicator());
          }
          return _ConfigForm(
            horasSemanaCtrl: _horasSemanaCtrl,
            fechaExamenCtrl: _fechaExamenCtrl,
            preferencia: _preferencia,
            diasHastaExamen: config.diasHastaExamen,
            isSaving: false,
            onPreferenciaChanged: (p) => setState(() => _preferencia = p!),
            onGuardar: _guardar,
          );
        },
      ),
    );
  }
}

// ── Formulario ─────────────────────────────────────────────────────────────────

class _ConfigForm extends StatelessWidget {
  const _ConfigForm({
    required this.horasSemanaCtrl,
    required this.fechaExamenCtrl,
    required this.preferencia,
    required this.onPreferenciaChanged,
    required this.onGuardar,
    this.diasHastaExamen,
    this.isSaving = false,
  });

  final TextEditingController horasSemanaCtrl;
  final TextEditingController fechaExamenCtrl;
  final PreferenciaPlan preferencia;
  final int? diasHastaExamen;
  final bool isSaving;
  final ValueChanged<PreferenciaPlan?> onPreferenciaChanged;
  final VoidCallback onGuardar;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── Horas por semana ──
        Text(
          'Horas de estudio por semana',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: horasSemanaCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Ej: 10',
            suffixText: 'h/semana',
          ),
        ),
        const SizedBox(height: 24),

        // ── Preferencia ──
        Text(
          'Preferencia de estudio',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<PreferenciaPlan>(
          value: preferencia,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          items: const [
            DropdownMenuItem(
              value: PreferenciaPlan.mixto,
              child: Text('Mixto (Test + Repaso)'),
            ),
            DropdownMenuItem(
              value: PreferenciaPlan.test,
              child: Text('Solo Tests'),
            ),
            DropdownMenuItem(
              value: PreferenciaPlan.teoria,
              child: Text('Solo Teoría'),
            ),
          ],
          onChanged: onPreferenciaChanged,
        ),
        const SizedBox(height: 24),

        // ── Fecha del examen ──
        Text(
          'Fecha objetivo del examen',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 4),
        Text(
          'Formato YYYY-MM-DD. Dejá en blanco si no tenés fecha definida.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: fechaExamenCtrl,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Ej: 2026-09-15',
          ),
        ),
        if (diasHastaExamen != null) ...[
          const SizedBox(height: 8),
          Text(
            'Quedan $diasHastaExamen días para el examen.',
            style: TextStyle(
              color: diasHastaExamen! <= 30
                  ? Colors.orange
                  : Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        const SizedBox(height: 32),

        // ── Botón guardar ──
        FilledButton(
          onPressed: isSaving ? null : onGuardar,
          child: isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Guardar cambios'),
        ),
      ],
    );
  }
}

// ── Estado error ───────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

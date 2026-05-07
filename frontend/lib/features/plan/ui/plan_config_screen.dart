import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
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
    final b = Theme.of(context).brightness;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
      children: [
        // ── Horas de estudio ──────────────────────────────────────────
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HORAS DE ESTUDIO',
                style: AppText.label
                    .copyWith(color: AppColors.textMutedFor(b)),
              ),
              const SizedBox(height: 3),
              Text(
                '¿Cuántas horas por semana podés dedicar?',
                style: AppText.caption
                    .copyWith(color: AppColors.textFaintFor(b)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: horasSemanaCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  hintText: 'Ej: 10',
                  suffixText: 'h / semana',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Preferencia de estudio ────────────────────────────────────
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PREFERENCIA',
                style: AppText.label
                    .copyWith(color: AppColors.textMutedFor(b)),
              ),
              const SizedBox(height: 3),
              Text(
                '¿Qué tipo de tareas querés que priorice el plan?',
                style: AppText.caption
                    .copyWith(color: AppColors.textFaintFor(b)),
              ),
              const SizedBox(height: 12),
              SegmentedButton<PreferenciaPlan>(
                segments: const [
                  ButtonSegment(
                    value: PreferenciaPlan.mixto,
                    label: Text('Mixto'),
                    icon: Icon(Icons.auto_awesome_outlined),
                  ),
                  ButtonSegment(
                    value: PreferenciaPlan.test,
                    label: Text('Tests'),
                    icon: Icon(Icons.quiz_outlined),
                  ),
                  ButtonSegment(
                    value: PreferenciaPlan.teoria,
                    label: Text('Teoría'),
                    icon: Icon(Icons.menu_book_outlined),
                  ),
                ],
                selected: {preferencia},
                onSelectionChanged: (s) => onPreferenciaChanged(s.first),
                style: const ButtonStyle(
                    visualDensity: VisualDensity.compact),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Fecha del examen ──────────────────────────────────────────
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FECHA DEL EXAMEN',
                style: AppText.label
                    .copyWith(color: AppColors.textMutedFor(b)),
              ),
              const SizedBox(height: 3),
              Text(
                'Opcional. Usamos esta fecha para ajustar la intensidad del plan.',
                style: AppText.caption
                    .copyWith(color: AppColors.textFaintFor(b)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: fechaExamenCtrl,
                decoration: InputDecoration(
                  hintText: 'AAAA-MM-DD',
                  suffixIcon: Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: AppColors.textFaintFor(b),
                  ),
                ),
              ),
              if (diasHastaExamen != null && diasHastaExamen! > 0) ...[
                const SizedBox(height: 10),
                Text(
                  diasHastaExamen! <= 30
                      ? 'Quedan $diasHastaExamen días — modo intensivo activo.'
                      : 'Quedan $diasHastaExamen días para el examen.',
                  style: AppText.caption.copyWith(
                    color: diasHastaExamen! <= 30
                        ? AppColors.accentWarmSoftFor(b)
                        : AppColors.primaryFor(b),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── Guardar ───────────────────────────────────────────────────
        FilledButton(
          onPressed: isSaving ? null : onGuardar,
          child: isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
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
    final b = Theme.of(context).brightness;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined,
                size: 52, color: AppColors.textFaintFor(b)),
            const SizedBox(height: 16),
            Text(
              'No se pudo cargar la configuración',
              style: AppText.cardTitle
                  .copyWith(color: AppColors.textFor(b)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style:
                  AppText.caption.copyWith(color: AppColors.textMutedFor(b)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

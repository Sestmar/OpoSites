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

// Días de la semana en orden lunes→domingo.
// La clave es el nombre en inglés que usa el backend; el label es lo que ve el usuario.
const _diasSemana = [
  (key: 'MONDAY',    label: 'L'),
  (key: 'TUESDAY',   label: 'M'),
  (key: 'WEDNESDAY', label: 'X'),
  (key: 'THURSDAY',  label: 'J'),
  (key: 'FRIDAY',    label: 'V'),
  (key: 'SATURDAY',  label: 'S'),
  (key: 'SUNDAY',    label: 'D'),
];

const _horasDefault = 2;
const _horasMin = 1;
const _horasMax = 8;

class _PlanConfigScreenState extends ConsumerState<PlanConfigScreen> {
  final _horasSemanaCtrl = TextEditingController();
  final _fechaExamenCtrl = TextEditingController();
  PreferenciaPlan _preferencia = PreferenciaPlan.mixto;

  /// Días activos: clave = "MONDAY"…"SUNDAY", valor = horas (1–8).
  /// null mientras no se haya cargado la config del servidor.
  Map<String, int>? _diasDisponibles;

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
      // Hidratar días disponibles: null del servidor → mapa vacío (sin días activos por defecto).
      _diasDisponibles = config.diasDisponibles != null
          ? Map<String, int>.from(config.diasDisponibles!)
          : {};
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
    // Enviar diasDisponibles solo si ya fue inicializado (evita sobreescribir con null).
    // Mapa vacío es válido y significa "sin días activos".
    final request = UpdatePlanConfiguracionRequest(
      horasSemana: horas,
      preferencia: _preferencia,
      fechaExamenObjetivo: fechaText.isEmpty ? null : fechaText,
      diasDisponibles: _diasDisponibles,
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
            diasDisponibles: _diasDisponibles ?? {},
            diasHastaExamen: config.diasHastaExamen,
            isSaving: false,
            onPreferenciaChanged: (p) => setState(() => _preferencia = p!),
            onDiaToggled: (key) {
              setState(() {
                final dias = Map<String, int>.from(_diasDisponibles ?? {});
                if (dias.containsKey(key)) {
                  dias.remove(key);
                } else {
                  dias[key] = _horasDefault;
                }
                _diasDisponibles = dias;
              });
            },
            onHorasChanged: (key, horas) {
              setState(() {
                final dias = Map<String, int>.from(_diasDisponibles ?? {});
                dias[key] = horas;
                _diasDisponibles = dias;
              });
            },
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
    required this.diasDisponibles,
    required this.onPreferenciaChanged,
    required this.onDiaToggled,
    required this.onHorasChanged,
    required this.onGuardar,
    this.diasHastaExamen,
    this.isSaving = false,
  });

  final TextEditingController horasSemanaCtrl;
  final TextEditingController fechaExamenCtrl;
  final PreferenciaPlan preferencia;
  final Map<String, int> diasDisponibles;
  final int? diasHastaExamen;
  final bool isSaving;
  final ValueChanged<PreferenciaPlan?> onPreferenciaChanged;
  final ValueChanged<String> onDiaToggled;
  final void Function(String key, int horas) onHorasChanged;
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
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surfaceFor(b),
                  hintText: 'Ej: 10',
                  hintStyle: TextStyle(color: AppColors.textFaintFor(b)),
                  suffixText: 'h / semana',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.borderFor(b)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.borderFor(b)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                        color: AppColors.primaryFor(b), width: 1.5),
                  ),
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

        // ── Días disponibles ──────────────────────────────────────────
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DÍAS DISPONIBLES',
                style: AppText.label.copyWith(color: AppColors.textMutedFor(b)),
              ),
              const SizedBox(height: 3),
              Text(
                '¿Qué días podés estudiar? El plan solo generará tareas esos días.',
                style: AppText.caption.copyWith(color: AppColors.textFaintFor(b)),
              ),
              const SizedBox(height: 14),
              // ── Chips de días ──────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _diasSemana.map((d) {
                  final activo = diasDisponibles.containsKey(d.key);
                  final teal = AppColors.primaryFor(b);
                  return GestureDetector(
                    onTap: () => onDiaToggled(d.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: activo ? teal : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: activo ? teal : AppColors.borderFor(b),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          d.label,
                          style: AppText.label.copyWith(
                            color: activo
                                ? Colors.white
                                : AppColors.textMutedFor(b),
                            fontWeight: activo
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              // ── Steppers de horas para días activos ───────────────
              ..._diasSemana.where((d) => diasDisponibles.containsKey(d.key)).map((d) {
                final horas = diasDisponibles[d.key]!;
                final teal = AppColors.primaryFor(b);
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 28,
                        child: Text(
                          d.label,
                          style: AppText.body.copyWith(
                            color: AppColors.textFor(b),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: horas > _horasMin
                            ? () => onHorasChanged(d.key, horas - 1)
                            : null,
                        icon: const Icon(Icons.remove_rounded),
                        iconSize: 18,
                        style: IconButton.styleFrom(
                          minimumSize: const Size(32, 32),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      SizedBox(
                        width: 36,
                        child: Text(
                          '${horas}h',
                          textAlign: TextAlign.center,
                          style: AppText.body.copyWith(
                            color: teal,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: horas < _horasMax
                            ? () => onHorasChanged(d.key, horas + 1)
                            : null,
                        icon: const Icon(Icons.add_rounded),
                        iconSize: 18,
                        style: IconButton.styleFrom(
                          minimumSize: const Size(32, 32),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          horas == 1 ? '1 hora' : '$horas horas',
                          style: AppText.caption.copyWith(
                            color: AppColors.textFaintFor(b),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
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
                  filled: true,
                  fillColor: AppColors.surfaceFor(b),
                  hintText: 'AAAA-MM-DD',
                  hintStyle: TextStyle(color: AppColors.textFaintFor(b)),
                  suffixIcon: Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: AppColors.textFaintFor(b),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.borderFor(b)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.borderFor(b)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                        color: AppColors.primaryFor(b), width: 1.5),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../auth/providers/auth_provider.dart' show dioProvider;
import '../providers/test_session_provider.dart';

// ── Modelos inline ─────────────────────────────────────────────────────────────

class _Rama {
  const _Rama({required this.id, required this.nombre});
  final int id;
  final String nombre;

  factory _Rama.fromJson(Map<String, dynamic> json) => _Rama(
        id: json['id'] as int,
        nombre: json['nombre'] as String,
      );
}

class _Tema {
  const _Tema({required this.id, required this.nombre});
  final int id;
  final String nombre;

  factory _Tema.fromJson(Map<String, dynamic> json) => _Tema(
        id: json['id'] as int,
        nombre: json['nombre'] as String,
      );
}

// ── Providers (auto-dispose: solo viven mientras la pantalla esté) ─────────────

final _oposicionesProvider = FutureProvider.autoDispose<List<_Rama>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get<List<dynamic>>(ApiEndpoints.oposiciones);
  return (response.data ?? [])
      .map((e) => _Rama.fromJson(e as Map<String, dynamic>))
      .toList();
});

final _temasProvider =
    FutureProvider.autoDispose.family<List<_Tema>, int>((ref, ramaId) async {
  final dio = ref.watch(dioProvider);
  final response =
      await dio.get<List<dynamic>>(ApiEndpoints.oposicionTemas(ramaId));
  return (response.data ?? [])
      .map((e) => _Tema.fromJson(e as Map<String, dynamic>))
      .toList();
});

// ── Constantes ─────────────────────────────────────────────────────────────────

const _cantidades = [5, 10, 15, 20, 25, 30];
const _tiemposMinutos = [5, 10, 15, 20, 30];

// SegmentedButton usa int; -1 es sentinel para "Todas" (null dificultad).
const _dificultadSegments = <({String label, int seg, int? value})>[
  (label: 'Todas',   seg: -1, value: null),
  (label: 'Fácil',  seg:  1, value:  1),
  (label: 'Media',  seg:  3, value:  3),
  (label: 'Difícil', seg: 5, value:  5),
];

// ── Pantalla ───────────────────────────────────────────────────────────────────

class TestConfigScreen extends ConsumerStatefulWidget {
  const TestConfigScreen({super.key});

  @override
  ConsumerState<TestConfigScreen> createState() => _TestConfigScreenState();
}

class _TestConfigScreenState extends ConsumerState<TestConfigScreen> {
  int? _selectedRamaId;
  int _cantidad = 10;
  final Set<int> _selectedTemaIds = {};
  int? _dificultad;          // null = todas
  bool _tiempoEnabled = false;
  int _tiempoMinutos = 10;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(activeTestProvider.notifier).reset());
  }

  void _onRamaChanged(int? ramaId) {
    setState(() {
      _selectedRamaId = ramaId;
      _selectedTemaIds.clear();
    });
  }

  void _toggleTema(int temaId) {
    setState(() {
      if (_selectedTemaIds.contains(temaId)) {
        _selectedTemaIds.remove(temaId);
      } else {
        _selectedTemaIds.add(temaId);
      }
    });
  }

  void _clearTemas() => setState(() => _selectedTemaIds.clear());

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final oposicionesAsync = ref.watch(_oposicionesProvider);

    ref.listen<TestState>(activeTestProvider, (_, next) {
      if (next is TestStateActive) context.go(AppRoutes.testActivo);
    });

    final testState = ref.watch(activeTestProvider);
    final isLoading = testState is TestStateLoading;
    final errorMsg = testState is TestStateError ? testState.message : null;

    return Scaffold(
      backgroundColor: AppColors.bgFor(b),
      appBar: AppBar(
        backgroundColor: AppColors.bgFor(b),
        title: Text(
          'Configurar test',
          style: AppText.cardTitle.copyWith(color: AppColors.textFor(b)),
        ),
      ),
      body: oposicionesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48,
                  color: AppColors.textMutedFor(b)),
              const SizedBox(height: 12),
              Text(
                'No se pudieron cargar las oposiciones.',
                textAlign: TextAlign.center,
                style: AppText.body.copyWith(color: AppColors.textMutedFor(b)),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(_oposicionesProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (ramas) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Oposición ──────────────────────────────────────────────────
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Oposición',
                      style: AppText.cardTitle
                          .copyWith(color: AppColors.textFor(b)),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: _selectedRamaId,
                      hint: Text(
                        'Selecciona una oposición',
                        style: AppText.body
                            .copyWith(color: AppColors.textFaintFor(b)),
                      ),
                      dropdownColor: AppColors.surfaceFor(b),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surfaceMutedFor(b),
                        prefixIcon: Icon(Icons.school_outlined,
                            color: AppColors.textMutedFor(b)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                              color: AppColors.borderFor(b), width: 0.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                              color: AppColors.borderFor(b), width: 0.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                              color: AppColors.primaryFor(b), width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
                      items: ramas
                          .map((r) => DropdownMenuItem(
                                value: r.id,
                                child: Text(r.nombre,
                                    style: AppText.body.copyWith(
                                        color: AppColors.textFor(b))),
                              ))
                          .toList(),
                      onChanged: isLoading ? null : _onRamaChanged,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Temas (solo si hay rama seleccionada) ─────────────────────
              if (_selectedRamaId != null) ...[
                AppCard(
                  child: _TemasSection(
                    ramaId: _selectedRamaId!,
                    selectedIds: _selectedTemaIds,
                    onToggle: isLoading ? null : _toggleTema,
                    onClearAll: isLoading ? null : _clearTemas,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Número de preguntas ────────────────────────────────────────
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Número de preguntas',
                      style: AppText.cardTitle
                          .copyWith(color: AppColors.textFor(b)),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: _cantidades.map((n) {
                        return ChoiceChip(
                          label: Text('$n'),
                          selected: _cantidad == n,
                          onSelected: isLoading
                              ? null
                              : (_) => setState(() => _cantidad = n),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Dificultad — SegmentedButton ───────────────────────────────
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dificultad',
                      style: AppText.cardTitle
                          .copyWith(color: AppColors.textFor(b)),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<int>(
                        segments: _dificultadSegments
                            .map((d) => ButtonSegment<int>(
                                  value: d.seg,
                                  label: Text(d.label),
                                ))
                            .toList(),
                        selected: {_dificultad ?? -1},
                        onSelectionChanged: isLoading
                            ? null
                            : (s) => setState(() {
                                  _dificultad =
                                      s.first == -1 ? null : s.first;
                                }),
                        showSelectedIcon: false,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Tiempo límite ──────────────────────────────────────────────
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Tiempo límite',
                          style: AppText.cardTitle
                              .copyWith(color: AppColors.textFor(b)),
                        ),
                        const Spacer(),
                        Switch(
                          value: _tiempoEnabled,
                          activeColor: AppColors.primaryFor(b),
                          onChanged: isLoading
                              ? null
                              : (v) =>
                                  setState(() => _tiempoEnabled = v),
                        ),
                      ],
                    ),
                    if (!_tiempoEnabled)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'Sin límite de tiempo',
                          style: AppText.bodySmall
                              .copyWith(color: AppColors.textFaintFor(b)),
                        ),
                      ),
                    if (_tiempoEnabled) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: _tiemposMinutos.map((t) {
                          return ChoiceChip(
                            label: Text('$t min'),
                            selected: _tiempoMinutos == t,
                            onSelected: isLoading
                                ? null
                                : (_) =>
                                    setState(() => _tiempoMinutos = t),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Error ──────────────────────────────────────────────────────
              if (errorMsg != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    errorMsg,
                    style: AppText.body.copyWith(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Botón ──────────────────────────────────────────────────────
              FilledButton.icon(
                onPressed: isLoading || _selectedRamaId == null
                    ? null
                    : () => ref.read(activeTestProvider.notifier).generarTest(
                          ramaId: _selectedRamaId!,
                          cantidad: _cantidad,
                          temaIds: _selectedTemaIds.isEmpty
                              ? null
                              : _selectedTemaIds.toList(),
                          dificultad: _dificultad,
                          tiempoMinutos:
                              _tiempoEnabled ? _tiempoMinutos : null,
                        ),
                icon: isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow_rounded),
                label: Text(isLoading ? 'Generando…' : 'Empezar test'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sección de temas ───────────────────────────────────────────────────────────

class _TemasSection extends ConsumerWidget {
  const _TemasSection({
    required this.ramaId,
    required this.selectedIds,
    required this.onToggle,
    required this.onClearAll,
  });

  final int ramaId;
  final Set<int> selectedIds;
  final void Function(int temaId)? onToggle;
  final VoidCallback? onClearAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = Theme.of(context).brightness;
    final temasAsync = ref.watch(_temasProvider(ramaId));

    return temasAsync.when(
      loading: () => Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryFor(b)),
          ),
          const SizedBox(width: 10),
          Text(
            'Cargando temas…',
            style:
                AppText.bodySmall.copyWith(color: AppColors.textMutedFor(b)),
          ),
        ],
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (temas) {
        if (temas.isEmpty) return const SizedBox.shrink();

        final allSelected = selectedIds.isEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Temas',
                  style:
                      AppText.cardTitle.copyWith(color: AppColors.textFor(b)),
                ),
                const Spacer(),
                // Botón "Todos los temas" — limpia la selección
                TextButton(
                  onPressed: allSelected ? null : onClearAll,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: AppColors.primaryFor(b),
                  ),
                  child: Text(
                    'Todos los temas',
                    style: AppText.bodySmall.copyWith(
                      color: allSelected
                          ? AppColors.textFaintFor(b)
                          : AppColors.primaryFor(b),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              allSelected
                  ? 'Todos los temas incluidos'
                  : '${selectedIds.length} tema${selectedIds.length > 1 ? 's' : ''} seleccionado${selectedIds.length > 1 ? 's' : ''}',
              style:
                  AppText.caption.copyWith(color: AppColors.textFaintFor(b)),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: temas.map((t) {
                final selected = selectedIds.contains(t.id);
                return FilterChip(
                  label: Text(t.nombre),
                  selected: selected,
                  onSelected:
                      onToggle == null ? null : (_) => onToggle!(t.id),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}

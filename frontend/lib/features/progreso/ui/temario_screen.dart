import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/pressable.dart';
import '../../auth/providers/auth_provider.dart';
import '../../tests/providers/test_session_provider.dart';
import '../data/models/progreso_tema.dart';
import '../providers/progreso_provider.dart';

// ── Modelo local ───────────────────────────────────────────────────────────────

class _TemaApp {
  const _TemaApp({
    required this.id,
    required this.nombre,
    required this.orden,
    this.descripcionCorta,
    required this.preguntasCount,
  });

  final int id;
  final String nombre;
  final int orden;
  final String? descripcionCorta;
  final int preguntasCount;

  factory _TemaApp.fromJson(Map<String, dynamic> json) => _TemaApp(
        id: (json['id'] as num).toInt(),
        nombre: json['nombre'] as String,
        orden: (json['orden'] as num?)?.toInt() ?? 0,
        descripcionCorta: json['descripcionCorta'] as String?,
        preguntasCount: (json['preguntasCount'] as num?)?.toInt() ?? 0,
      );
}

// ── Provider local (sin code gen) ─────────────────────────────────────────────

final _temasAppProvider =
    FutureProvider.autoDispose.family<List<_TemaApp>, int>((ref, ramaId) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get<List<dynamic>>(
    ApiEndpoints.oposicionTemas(ramaId),
  );
  return (response.data ?? [])
      .map((e) => _TemaApp.fromJson(e as Map<String, dynamic>))
      .toList();
});

// ── Pantalla ───────────────────────────────────────────────────────────────────

class TemarioScreen extends ConsumerStatefulWidget {
  const TemarioScreen({super.key});

  @override
  ConsumerState<TemarioScreen> createState() => _TemarioScreenState();
}

class _TemarioScreenState extends ConsumerState<TemarioScreen> {
  int? _loadingTemaId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(progresoTemasProvider).valueOrNull?.isEmpty ?? true) {
        ref.read(progresoTemasProvider.notifier).load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final auth = ref.watch(authProvider);
    final ramaId = auth is AuthAuthenticated ? auth.ramaPrincipalId : null;

    // Navegar al test cuando esté activo, limpiar spinner si hay error
    ref.listen<TestState>(activeTestProvider, (_, next) {
      if (next is TestStateActive) {
        setState(() => _loadingTemaId = null);
        context.push(AppRoutes.testActivo);
      } else if (next is TestStateError) {
        setState(() => _loadingTemaId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo iniciar el test. Intentá de nuevo.'),
            backgroundColor: AppColors.accentRose,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.bgFor(b),
      appBar: AppBar(
        backgroundColor: AppColors.bgFor(b),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primaryFor(b)),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Temario',
          style: AppText.cardTitle.copyWith(color: AppColors.textFor(b)),
        ),
        centerTitle: true,
      ),
      body: ramaId == null
          ? Center(
              child: Text(
                'Seleccioná tu oposición primero.',
                style: AppText.body.copyWith(color: AppColors.textMutedFor(b)),
              ),
            )
          : _Body(
              ramaId: ramaId,
              loadingTemaId: _loadingTemaId,
              onPracticar: _practicar,
            ),
    );
  }

  Future<void> _practicar(int ramaId, int temaId) async {
    setState(() => _loadingTemaId = temaId);
    await ref.read(activeTestProvider.notifier).generarTest(
          ramaId: ramaId,
          temaIds: [temaId],
          cantidad: 10,
        );
  }
}

// ── Cuerpo: lista de temas con progreso ───────────────────────────────────────

class _Body extends ConsumerWidget {
  const _Body({
    required this.ramaId,
    required this.loadingTemaId,
    required this.onPracticar,
  });

  final int ramaId;
  final int? loadingTemaId;
  final Future<void> Function(int ramaId, int temaId) onPracticar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = Theme.of(context).brightness;
    final temasAsync = ref.watch(_temasAppProvider(ramaId));
    final progresoTemas = ref.watch(progresoTemasProvider).valueOrNull ?? [];
    final progresoMap = {for (final p in progresoTemas) p.temaId: p};

    return temasAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (_, __) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_outlined, size: 40, color: AppColors.textFaintFor(b)),
            const SizedBox(height: 12),
            Text(
              'No se pudieron cargar los temas.',
              style: AppText.body.copyWith(color: AppColors.textMutedFor(b)),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => ref.invalidate(_temasAppProvider(ramaId)),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
      data: (temas) {
        if (temas.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.menu_book_outlined, size: 40, color: AppColors.textFaintFor(b)),
                const SizedBox(height: 12),
                Text(
                  'No hay temas para esta oposición todavía.',
                  style: AppText.body.copyWith(color: AppColors.textMutedFor(b)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
          itemCount: temas.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final tema = temas[i];
            return _TemaCard(
              tema: tema,
              progreso: progresoMap[tema.id],
              ramaId: ramaId,
              isLoading: loadingTemaId == tema.id,
              onPracticar: onPracticar,
            );
          },
        );
      },
    );
  }
}

// ── Tarjeta de tema individual ─────────────────────────────────────────────────

class _TemaCard extends StatelessWidget {
  const _TemaCard({
    required this.tema,
    required this.progreso,
    required this.ramaId,
    required this.isLoading,
    required this.onPracticar,
  });

  final _TemaApp tema;
  final ProgresoTema? progreso;
  final int ramaId;
  final bool isLoading;
  final Future<void> Function(int ramaId, int temaId) onPracticar;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final pct = progreso?.porcentajeAcierto ?? 0.0;
    final hasData = progreso != null && progreso!.totalRespondidas > 0;
    final color = _colorForPct(pct, b);

    return Pressable(
      onTap: isLoading ? null : () => onPracticar(ramaId, tema.id),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceFor(b),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderFor(b), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera: badge orden + nombre + chip %
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge de orden
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primaryFor(b).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${tema.orden}',
                    style: AppText.label.copyWith(
                      color: AppColors.primaryFor(b),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tema.nombre,
                        style: AppText.cardTitle.copyWith(
                          color: AppColors.textFor(b),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (tema.descripcionCorta != null &&
                          tema.descripcionCorta!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          tema.descripcionCorta!,
                          style: AppText.caption.copyWith(
                            color: AppColors.textMutedFor(b),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                if (hasData) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${pct.toStringAsFixed(0)}%',
                      style: AppText.label.copyWith(color: color),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 12),

            // Barra de progreso + botón Practicar
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: hasData ? (pct / 100).clamp(0.0, 1.0) : 0.0,
                          minHeight: 6,
                          backgroundColor: Colors.white.withOpacity(0.05),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            hasData ? color : AppColors.textFaintFor(b),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        hasData
                            ? '${progreso!.correctas}/${progreso!.totalRespondidas} respondidas'
                            : '${tema.preguntasCount} preguntas disponibles',
                        style: AppText.caption.copyWith(
                          color: AppColors.textMutedFor(b),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 116,
                  height: 36,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(110, 36),
                      backgroundColor: AppColors.primaryFor(b),
                      foregroundColor: const Color(0xFF003731),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: isLoading ? null : () => onPracticar(ramaId, tema.id),
                    icon: isLoading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF003731),
                            ),
                          )
                        : const Icon(Icons.play_arrow_rounded, size: 16),
                    label: Text(
                      isLoading ? 'Generando…' : 'Practicar',
                      style: AppText.label,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _colorForPct(double pct, Brightness b) {
    if (pct >= 75) return AppColors.accentMint;
    if (pct >= 50) return AppColors.accentWarm;
    if (pct > 0)  return AppColors.accentRose;
    return AppColors.textFaintFor(b);
  }
}

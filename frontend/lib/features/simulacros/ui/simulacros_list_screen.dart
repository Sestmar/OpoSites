import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/router/app_router.dart';
import '../../auth/providers/auth_provider.dart' show dioProvider;
import '../data/models/simulacro.dart';
import '../providers/simulacro_session_provider.dart';

// ── Modelo mínimo de rama (mismo que en TestConfig, privado al archivo) ────────

class _Rama {
  const _Rama({required this.id, required this.nombre});
  final int id;
  final String nombre;
  factory _Rama.fromJson(Map<String, dynamic> json) => _Rama(
        id: json['id'] as int,
        nombre: json['nombre'] as String,
      );
}

// ── Providers ─────────────────────────────────────────────────────────────────

final _oposicionesProvider = FutureProvider.autoDispose<List<_Rama>>((ref) async {
  final response = await ref
      .watch(dioProvider)
      .get<List<dynamic>>(ApiEndpoints.oposiciones);
  return (response.data ?? [])
      .map((e) => _Rama.fromJson(e as Map<String, dynamic>))
      .toList();
});

/// Carga los simulacros de una rama concreta. Se recrea si cambia [ramaId].
final _simulacrosPorRamaProvider =
    FutureProvider.autoDispose.family<List<Simulacro>, int>(
  (ref, ramaId) =>
      ref.watch(simulacrosRepositoryProvider).getSimulacrosByRama(ramaId),
);

// ── Pantalla ───────────────────────────────────────────────────────────────────

class SimulacrosListScreen extends ConsumerStatefulWidget {
  const SimulacrosListScreen({super.key});

  @override
  ConsumerState<SimulacrosListScreen> createState() =>
      _SimulacrosListScreenState();
}

class _SimulacrosListScreenState extends ConsumerState<SimulacrosListScreen> {
  int? _selectedRamaId;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(activeSimulacroProvider.notifier).reset());
  }

  @override
  Widget build(BuildContext context) {
    final oposicionesAsync = ref.watch(_oposicionesProvider);

    // Navegar cuando el simulacro se inicia con éxito
    ref.listen<SimulacroState>(activeSimulacroProvider, (_, next) {
      if (next is SimulacroStateActive) {
        context.go(AppRoutes.simulacroActivo);
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Simulacros')),
      body: oposicionesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(
          message: 'No se pudieron cargar las oposiciones.\n$e',
          onRetry: () => ref.invalidate(_oposicionesProvider),
        ),
        data: (ramas) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Selector de rama ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: DropdownButtonFormField<int>(
                initialValue: _selectedRamaId,
                hint: const Text('Selecciona una oposición'),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.school_outlined),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: ramas
                    .map((r) => DropdownMenuItem(
                          value: r.id,
                          child: Text(r.nombre),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedRamaId = v),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(),

            // ── Lista de simulacros ────────────────────────────────────────
            Expanded(
              child: _selectedRamaId == null
                  ? const Center(
                      child: Text('Selecciona una oposición para ver\nlos simulacros disponibles',
                          textAlign: TextAlign.center),
                    )
                  : _SimulacrosList(ramaId: _selectedRamaId!),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Lista de simulacros por rama ───────────────────────────────────────────────

class _SimulacrosList extends ConsumerWidget {
  const _SimulacrosList({required this.ramaId});
  final int ramaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final simulacrosAsync = ref.watch(_simulacrosPorRamaProvider(ramaId));
    final iniciandoState = ref.watch(activeSimulacroProvider);
    final isIniciando = iniciandoState is SimulacroStateLoading;

    return simulacrosAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorView(
        message: 'No se pudieron cargar los simulacros.\n$e',
        onRetry: () => ref.invalidate(_simulacrosPorRamaProvider(ramaId)),
      ),
      data: (simulacros) => simulacros.isEmpty
          ? const Center(
              child: Text(
                'No hay simulacros disponibles\npara esta oposición.',
                textAlign: TextAlign.center,
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: simulacros.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _SimulacroCard(
                simulacro: simulacros[i],
                isIniciando: isIniciando,
                onIniciar: () => ref
                    .read(activeSimulacroProvider.notifier)
                    .iniciarSimulacro(simulacros[i].id),
              ),
            ),
    );
  }
}

// ── Card individual ────────────────────────────────────────────────────────────

class _SimulacroCard extends StatelessWidget {
  const _SimulacroCard({
    required this.simulacro,
    required this.isIniciando,
    required this.onIniciar,
  });
  final Simulacro simulacro;
  final bool isIniciando;
  final VoidCallback onIniciar;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nombre
            Text(
              simulacro.nombre,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Metadatos en fila
            Wrap(
              spacing: 16,
              children: [
                _MetaBadge(
                  icon: Icons.timer_outlined,
                  label: '${simulacro.duracionMinutos} min',
                ),
                _MetaBadge(
                  icon: Icons.quiz_outlined,
                  label: '${simulacro.preguntasCount} preguntas',
                ),
                if (simulacro.fechaOficial != null)
                  _MetaBadge(
                    icon: Icons.event_outlined,
                    label: simulacro.fechaOficial!,
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Botón
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isIniciando ? null : onIniciar,
                icon: isIniciando
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow_rounded),
                label: Text(isIniciando ? 'Iniciando…' : 'Iniciar simulacro'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  const _MetaBadge({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                )),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

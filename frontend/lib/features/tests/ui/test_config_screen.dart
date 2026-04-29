import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/router/app_router.dart';
import '../../auth/providers/auth_provider.dart' show dioProvider;
import '../providers/test_session_provider.dart';

// ── Modelo mínimo de rama (solo lo que necesita la pantalla) ──────────────────

class _Rama {
  const _Rama({required this.id, required this.nombre});
  final int id;
  final String nombre;

  factory _Rama.fromJson(Map<String, dynamic> json) => _Rama(
        id: json['id'] as int,
        nombre: json['nombre'] as String,
      );
}

// ── Provider de ramas (auto-dispose: solo vive mientras esta pantalla esté) ───

final _oposicionesProvider = FutureProvider.autoDispose<List<_Rama>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get<List<dynamic>>(ApiEndpoints.oposiciones);
  return (response.data ?? [])
      .map((e) => _Rama.fromJson(e as Map<String, dynamic>))
      .toList();
});

// ── Cantidades disponibles en el selector ──────────────────────────────────────

const _cantidades = [5, 10, 15, 20, 25, 30];

// ── Pantalla ───────────────────────────────────────────────────────────────────

class TestConfigScreen extends ConsumerStatefulWidget {
  const TestConfigScreen({super.key});

  @override
  ConsumerState<TestConfigScreen> createState() => _TestConfigScreenState();
}

class _TestConfigScreenState extends ConsumerState<TestConfigScreen> {
  int? _selectedRamaId;
  int _cantidad = 10;

  @override
  void initState() {
    super.initState();
    // Limpiamos cualquier sesión anterior al entrar a config
    Future.microtask(() => ref.read(activeTestProvider.notifier).reset());
  }

  @override
  Widget build(BuildContext context) {
    final oposicionesAsync = ref.watch(_oposicionesProvider);

    // Navegamos cuando el test se genera con éxito
    ref.listen<TestState>(activeTestProvider, (_, next) {
      if (next is TestStateActive) {
        context.go(AppRoutes.testActivo);
      }
    });

    final testState = ref.watch(activeTestProvider);
    final isLoading = testState is TestStateLoading;
    final errorMsg = testState is TestStateError ? testState.message : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Configurar test')),
      body: oposicionesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              Text('No se pudieron cargar las oposiciones.\n$e',
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(_oposicionesProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (ramas) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Selector de rama ───────────────────────────────────────────
              Text('Oposición',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                initialValue: _selectedRamaId,
                hint: const Text('Selecciona una oposición'),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.school_outlined),
                ),
                items: ramas
                    .map((r) => DropdownMenuItem(
                          value: r.id,
                          child: Text(r.nombre),
                        ))
                    .toList(),
                onChanged: isLoading
                    ? null
                    : (v) => setState(() => _selectedRamaId = v),
              ),
              const SizedBox(height: 24),

              // ── Número de preguntas ────────────────────────────────────────
              Text('Número de preguntas',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _cantidades.map((n) {
                  final selected = _cantidad == n;
                  return ChoiceChip(
                    label: Text('$n'),
                    selected: selected,
                    onSelected: isLoading
                        ? null
                        : (_) => setState(() => _cantidad = n),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // ── Error ──────────────────────────────────────────────────────
              if (errorMsg != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    errorMsg,
                    style: TextStyle(
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

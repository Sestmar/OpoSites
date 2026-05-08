import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart' show dioProvider;
import '../data/pregunta_marcada_repository.dart';

// ── Infraestructura ────────────────────────────────────────────────────────────

/// Provider del repositorio de preguntas marcadas.
/// keepAlive: true — vive mientras la app esté activa.
final preguntaMarcadaRepositoryProvider = Provider<PreguntaMarcadaRepository>(
  (ref) => PreguntaMarcadaRepository(dio: ref.watch(dioProvider)),
);

// ── Conteo de marcadas ─────────────────────────────────────────────────────────

/// Número total de preguntas marcadas del usuario.
/// [ramaId] null = todas las ramas.
///
/// autoDispose para que se recargue cada vez que la pantalla de config se monta.
final preguntasMarcadasConteoProvider =
    FutureProvider.autoDispose.family<int, int?>((ref, ramaId) =>
        ref.read(preguntaMarcadaRepositoryProvider).getConteo(ramaId: ramaId));

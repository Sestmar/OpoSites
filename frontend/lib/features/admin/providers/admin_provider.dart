import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/admin_repository.dart';
import '../data/models/ingestion_result.dart';
import '../data/models/noticia_borrador.dart';

// ── Repositorio ────────────────────────────────────────────────────────────────

final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => AdminRepository(dio: ref.watch(dioProvider)),
);

// ── Borradores ─────────────────────────────────────────────────────────────────

class BorradoresState {
  const BorradoresState({required this.items, required this.total});
  final List<NoticiaBorrador> items;
  final int total;
}

/// Lista de borradores pendientes de revisión.
/// Expone [publicar] y [rechazar] para actualizar el estado y refrescar la lista.
class BorradoresNotifier extends AutoDisposeAsyncNotifier<BorradoresState> {
  @override
  Future<BorradoresState> build() async {
    final result = await ref.read(adminRepositoryProvider).listarBorradores();
    return BorradoresState(items: result.items, total: result.total);
  }

  Future<void> publicar(int id) async {
    await ref.read(adminRepositoryProvider).publicar(id);
    ref.invalidateSelf();
  }

  Future<void> rechazar(int id) async {
    await ref.read(adminRepositoryProvider).rechazar(id);
    ref.invalidateSelf();
  }
}

final borradoresProvider =
    AutoDisposeAsyncNotifierProvider<BorradoresNotifier, BorradoresState>(
  BorradoresNotifier.new,
);

// ── Ingesta ────────────────────────────────────────────────────────────────────

/// Estado de la última ejecución manual de ingesta.
/// null = aún no se ha ejecutado en esta sesión.
class IngestaNotifier extends AutoDisposeAsyncNotifier<IngestionResult?> {
  @override
  Future<IngestionResult?> build() async => null;

  Future<void> ejecutar() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(adminRepositoryProvider).ejecutarIngesta(),
    );
    // Refrescar borradores tras la ingesta — pueden haber llegado novedades
    ref.invalidate(borradoresProvider);
  }
}

final ingestaProvider =
    AutoDisposeAsyncNotifierProvider<IngestaNotifier, IngestionResult?>(
  IngestaNotifier.new,
);

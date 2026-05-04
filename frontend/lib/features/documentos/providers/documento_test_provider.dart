import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart' show dioProvider;
import '../data/documento_test_repository.dart';
import '../data/models/documento_test.dart';

// ── Repositorio ────────────────────────────────────────────────────────────────

final documentoTestRepositoryProvider = Provider<DocumentoTestRepository>(
  (ref) => DocumentoTestRepository(dio: ref.watch(dioProvider)),
);

// ── Notifier (familia por documentoId) ────────────────────────────────────────

/// Estado: null = no hay test aún para este documento; DocumentoTest = test cargado.
///
/// build() devuelve null — no hace fetch automático.
/// Usa [generar] para crear un test nuevo vía LLM.
/// Usa [cargarUltimo] para consultar si ya existe uno.
final documentoTestProvider = AsyncNotifierProvider.family<
    DocumentoTestNotifier, DocumentoTest?, int>(
  DocumentoTestNotifier.new,
);

class DocumentoTestNotifier extends FamilyAsyncNotifier<DocumentoTest?, int> {
  @override
  FutureOr<DocumentoTest?> build(int arg) => null;

  /// Genera un nuevo test en el backend y actualiza el estado.
  Future<DocumentoTest> generar() async {
    state = const AsyncLoading();
    final test = await ref
        .read(documentoTestRepositoryProvider)
        .generarTest(arg);
    state = AsyncData(test);
    return test;
  }

  /// Carga el último test existente. Devuelve null si no hay ninguno.
  Future<DocumentoTest?> cargarUltimo() async {
    final test = await ref
        .read(documentoTestRepositoryProvider)
        .obtenerUltimo(arg);
    state = AsyncData(test);
    return test;
  }
}

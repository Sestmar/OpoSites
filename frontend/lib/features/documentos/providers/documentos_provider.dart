import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart' show dioProvider;
import '../data/documento_repository.dart';
import '../data/models/documento.dart';
import '../data/models/material_generado.dart';

// ── Repositorio ────────────────────────────────────────────────────────────────

final documentoRepositoryProvider = Provider<DocumentoRepository>(
  (ref) => DocumentoRepository(dio: ref.watch(dioProvider)),
);

// ── Lista de documentos ────────────────────────────────────────────────────────

/// Estado de la lista de documentos del usuario.
///
/// ### Flujo de uso
/// ```dart
/// // Cargar al entrar a DocumentosScreen
/// ref.read(documentosNotifierProvider.notifier).cargar();
///
/// // Subir un documento
/// await ref.read(documentosNotifierProvider.notifier).subirDocumento(bytes: ..., nombre: ...);
///
/// // Eliminar
/// await ref.read(documentosNotifierProvider.notifier).eliminar(docId);
/// ```
final documentosNotifierProvider =
    AsyncNotifierProvider<DocumentosNotifier, List<Documento>>(
  DocumentosNotifier.new,
);

class DocumentosNotifier extends AsyncNotifier<List<Documento>> {
  @override
  FutureOr<List<Documento>> build() async {
    return ref.read(documentoRepositoryProvider).getDocumentos();
  }

  Future<void> refrescar() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(documentoRepositoryProvider).getDocumentos(),
    );
  }

  /// Sube el archivo, añade el resultado al inicio de la lista y lo devuelve.
  /// Lanza [ApiException] si falla — la UI captura para mostrar SnackBar.
  Future<Documento> subirDocumento({
    required Uint8List bytes,
    required String nombre,
  }) async {
    final doc = await ref.read(documentoRepositoryProvider).subirDocumento(
          bytes: bytes,
          nombre: nombre,
        );
    final current = state.valueOrNull ?? [];
    state = AsyncData([doc, ...current]);
    return doc;
  }

  /// Elimina el documento del servidor y de la lista local.
  Future<void> eliminar(int id) async {
    await ref.read(documentoRepositoryProvider).eliminarDocumento(id);
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.where((d) => d.id != id).toList());
  }
}

// ── Materiales de un documento (familia por documentoId) ───────────────────────

/// Materiales generados para un documento específico.
///
/// ### Flujo de uso
/// ```dart
/// final materialesAsync = ref.watch(documentoMaterialesProvider(docId));
///
/// // Generar nuevo material
/// final material = await ref
///     .read(documentoMaterialesProvider(docId).notifier)
///     .generar(TipoMaterial.flashcards);
/// ```
final documentoMaterialesProvider = AsyncNotifierProvider.family<
    DocumentoMaterialesNotifier, List<MaterialGenerado>, int>(
  DocumentoMaterialesNotifier.new,
);

class DocumentoMaterialesNotifier
    extends FamilyAsyncNotifier<List<MaterialGenerado>, int> {
  @override
  FutureOr<List<MaterialGenerado>> build(int arg) async {
    return ref.read(documentoRepositoryProvider).getMateriales(arg);
  }

  /// Llama al backend para generar material del tipo dado.
  /// Añade el resultado al inicio de la lista y lo devuelve para navegación.
  /// Lanza [ApiException] si falla — la UI captura para mostrar SnackBar.
  Future<MaterialGenerado> generar(TipoMaterial tipo) async {
    final material =
        await ref.read(documentoRepositoryProvider).generarMaterial(
              documentoId: arg,
              tipo: tipo,
            );
    final current = state.valueOrNull ?? [];
    state = AsyncData([material, ...current]);
    return material;
  }

  Future<void> refrescar() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(documentoRepositoryProvider).getMateriales(arg),
    );
  }
}

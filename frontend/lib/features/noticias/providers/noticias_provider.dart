import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart' show dioProvider;
import '../data/models/noticia.dart';
import '../data/models/noticia_conteos.dart';
import '../data/models/noticia_resumen.dart';
import '../data/noticias_repository.dart';

part 'noticias_provider.g.dart';

// ── Provider de infraestructura ────────────────────────────────────────────────

@Riverpod(keepAlive: true)
NoticiasRepository noticiasRepository(NoticiasRepositoryRef ref) =>
    NoticiasRepository(dio: ref.watch(dioProvider));

// ── Provider de conteos ────────────────────────────────────────────────────────

/// Conteos por tipo de noticia para una rama dada (null = globales).
/// Se recalcula automáticamente al cambiar de rama.
/// Usar como: ref.watch(noticiaConteosProvider(ramaId))
final noticiaConteosProvider =
    FutureProvider.family<NoticiaConteos, int?>((ref, ramaId) =>
        ref.read(noticiasRepositoryProvider).getConteos(ramaId: ramaId));

// ── Estado de la lista paginada ────────────────────────────────────────────────

/// Estado de la lista de noticias con soporte de paginación e infinite scroll.
///
/// [items]         → acumulación de todas las páginas cargadas hasta ahora.
/// [paginaActual]  → último índice de página cargado (0-based).
/// [hayMas]        → false cuando el servidor devolvió [last: true].
/// [filtroTipo]    → filtro activo de tipo de noticia (null = todos).
/// [filtroRamaId]  → filtro activo de rama (null = todas las ramas).
class NoticiasListState {
  const NoticiasListState({
    required this.items,
    required this.paginaActual,
    required this.hayMas,
    this.filtroTipo,
    this.filtroRamaId,
    this.filtroQ,
  });

  final List<NoticiaResumen> items;
  final int paginaActual;
  final bool hayMas;
  final TipoNoticia? filtroTipo;
  final int? filtroRamaId;
  final String? filtroQ;

  /// Estado inicial vacío — antes de cualquier carga.
  static const empty = NoticiasListState(
    items: [],
    paginaActual: 0,
    hayMas: false,
  );
}

// ── Notifier de lista ──────────────────────────────────────────────────────────

/// Lista paginada de noticias con filtros y soporte de infinite scroll.
///
/// ### Flujo de uso
/// 1. La pantalla llama [cargar] en [initState] → limpia lista y carga página 0.
/// 2. Al llegar al final del scroll, la UI llama [cargarMas] → añade página 1, 2…
/// 3. Para cambiar filtros, la UI llama [cargar] con los nuevos filtros.
///
/// ### cargar vs cargarMas
/// - [cargar] pone el estado en AsyncLoading y reemplaza la lista completa.
/// - [cargarMas] NO modifica el estado de carga visible — añade ítems silenciosamente.
///   Lanza excepción si falla para que la UI muestre un SnackBar sin perder la lista.
@Riverpod(keepAlive: true)
class NoticiasListNotifier extends _$NoticiasListNotifier {
  @override
  AsyncValue<NoticiasListState> build() => const AsyncData(NoticiasListState.empty);

  /// Carga o recarga la lista desde página 0 con los filtros indicados.
  ///
  /// [tipo]   null = todas las categorías.
  /// [ramaId] null = todas las ramas del usuario.
  /// [q]      null o vacío = sin filtro de búsqueda.
  Future<void> cargar({TipoNoticia? tipo, int? ramaId, String? q}) async {
    final efectivoQ = (q != null && q.trim().isNotEmpty) ? q.trim() : null;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final page = await ref
          .read(noticiasRepositoryProvider)
          .getNoticias(tipo: tipo, ramaId: ramaId, q: efectivoQ, page: 0);
      return NoticiasListState(
        items: page.content,
        paginaActual: 0,
        hayMas: !page.last,
        filtroTipo: tipo,
        filtroRamaId: ramaId,
        filtroQ: efectivoQ,
      );
    });
  }

  /// Recarga respetando los filtros actuales (tipo, ramaId y q).
  Future<void> recargarActual() async {
    final current = state.valueOrNull;
    await cargar(
      tipo: current?.filtroTipo,
      ramaId: current?.filtroRamaId,
      q: current?.filtroQ,
    );
  }

  /// Carga la siguiente página y añade los ítems al final de la lista.
  ///
  /// No-op si ya no hay más páginas o si el estado actual no tiene datos.
  /// Lanza [ApiException] si la red falla — la UI debe capturarla para
  /// mostrar feedback sin perder los ítems ya cargados.
  Future<void> cargarMas() async {
    final current = state.valueOrNull;
    if (current == null || !current.hayMas) return;

    final page = await ref.read(noticiasRepositoryProvider).getNoticias(
          tipo: current.filtroTipo,
          ramaId: current.filtroRamaId,
          q: current.filtroQ,
          page: current.paginaActual + 1,
        );

    state = AsyncData(NoticiasListState(
      items: [...current.items, ...page.content],
      paginaActual: page.number,
      hayMas: !page.last,
      filtroTipo: current.filtroTipo,
      filtroRamaId: current.filtroRamaId,
      filtroQ: current.filtroQ,
    ));
  }

  /// Marca la noticia [id] como leída en la lista local (sin refetch).
  ///
  /// Solo actualiza el campo [leida] del ítem correspondiente.
  /// Llamar después de [NoticiaDetalleNotifier.marcarLeida] para mantener
  /// ambas vistas sincronizadas.
  void actualizarLeida(int id) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(NoticiasListState(
      items: current.items
          .map((n) => n.id == id ? _noticiaResumenLeida(n) : n)
          .toList(),
      paginaActual: current.paginaActual,
      hayMas: current.hayMas,
      filtroTipo: current.filtroTipo,
      filtroRamaId: current.filtroRamaId,
      filtroQ: current.filtroQ,
    ));
  }

  // Reconstruye un NoticiaResumen con leida=true sin json_annotation.
  NoticiaResumen _noticiaResumenLeida(NoticiaResumen n) => NoticiaResumen(
        id: n.id,
        titulo: n.titulo,
        tipo: n.tipo,
        fechaPublicacion: n.fechaPublicacion,
        leida: true,
        ramaId: n.ramaId,
        nombreRama: n.nombreRama,
      );
}

// ── Notifier de detalle ────────────────────────────────────────────────────────

/// Detalle de una noticia individual.
///
/// ### Flujo de uso
/// 1. La pantalla llama [cargar(id)] en initState → carga el detalle.
/// 2. Tras mostrar el contenido, la UI llama [marcarLeida(id)] → POST al backend
///    y actualiza [leida: true] en el estado local.
/// 3. Opcional: llamar [NoticiasListNotifier.actualizarLeida(id)] para
///    sincronizar el estado en la lista sin recargar toda la página.
///
/// Estado inicial null — la pantalla dispara [cargar] al montarse.
@Riverpod(keepAlive: true)
class NoticiaDetalleNotifier extends _$NoticiaDetalleNotifier {
  @override
  AsyncValue<Noticia?> build() => const AsyncData(null);

  /// Carga el detalle completo de la noticia [id].
  Future<void> cargar(int id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(noticiasRepositoryProvider).getDetalle(id),
    );
  }

  /// Marca la noticia [id] como leída en el backend y actualiza el estado local.
  ///
  /// Lanza [ApiException] si la petición falla — la UI captura para SnackBar.
  Future<void> marcarLeida(int id) async {
    await ref.read(noticiasRepositoryProvider).marcarLeida(id);
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(current.copyWithLeida(true));
    }
  }
}

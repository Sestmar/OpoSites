import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../data/models/noticia_resumen.dart';
import '../providers/noticias_provider.dart';

// ── Pantalla principal ─────────────────────────────────────────────────────────

class NoticiasListScreen extends ConsumerStatefulWidget {
  const NoticiasListScreen({super.key});

  @override
  ConsumerState<NoticiasListScreen> createState() => _NoticiasListScreenState();
}

class _NoticiasListScreenState extends ConsumerState<NoticiasListScreen>
    with AutomaticKeepAliveClientMixin {
  final _scrollCtrl = ScrollController();

  TipoNoticia? _selectedTipo;
  bool _cargandoMas = false;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    final current = ref.read(noticiasListNotifierProvider).valueOrNull;
    _selectedTipo = current?.filtroTipo;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (current == null || current.items.isEmpty) {
        ref.read(noticiasListNotifierProvider.notifier).cargar(tipo: _selectedTipo);
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Scroll infinito ──────────────────────────────────────────────────────────

  void _onScroll() {
    if (_cargandoMas) return;
    final pos = _scrollCtrl.position;
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    final currentState = ref.read(noticiasListNotifierProvider).valueOrNull;
    if (currentState == null || !currentState.hayMas) return;

    setState(() => _cargandoMas = true);
    try {
      await ref.read(noticiasListNotifierProvider.notifier).cargarMas();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_userMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _cargandoMas = false);
    }
  }

  Future<void> _refresh() {
    return ref.read(noticiasListNotifierProvider.notifier).recargarActual();
  }

  // ── Filtros ──────────────────────────────────────────────────────────────────

  void _applyFilter(TipoNoticia? tipo) {
    if (_selectedTipo == tipo) return;
    setState(() => _selectedTipo = tipo);
    ref.read(noticiasListNotifierProvider.notifier).cargar(tipo: tipo);
  }

  // ── Navegación ───────────────────────────────────────────────────────────────

  void _openDetalle(NoticiaResumen noticia) {
    context.push(AppRoutes.noticiaDetalleUri(noticia.id));
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final b = Theme.of(context).brightness;
    final state = ref.watch(noticiasListNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Noticias')),
      body: Column(
        children: [
          _FilterRow(
            selected: _selectedTipo,
            onSelected: _applyFilter,
          ),
          const Divider(height: 1),
          Expanded(
            child: state.when(
              loading: () => Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryFor(b),
                ),
              ),
              error: (e, _) => _ErrorBody(
                message: _userMessage(e),
                onRetry: () => ref
                    .read(noticiasListNotifierProvider.notifier)
                    .recargarActual(),
                onRefresh: _refresh,
              ),
              data: (listState) {
                if (listState.items.isEmpty) {
                  return _EmptyBody(
                    onRefresh: _refresh,
                    onClearFilter:
                        _selectedTipo != null ? () => _applyFilter(null) : null,
                  );
                }
                return RefreshIndicator(
                  color: AppColors.primaryFor(b),
                  onRefresh: _refresh,
                  child: _NoticiasList(
                    items: listState.items,
                    hayMas: listState.hayMas,
                    cargandoMas: _cargandoMas,
                    scrollCtrl: _scrollCtrl,
                    onTap: _openDetalle,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filtros de tipo ────────────────────────────────────────────────────────────

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.selected, required this.onSelected});

  final TipoNoticia? selected;
  final ValueChanged<TipoNoticia?> onSelected;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _FilterChip(
            label: 'Todas',
            isSelected: selected == null,
            onTap: () => onSelected(null),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Convocatorias',
            isSelected: selected == TipoNoticia.convocatoria,
            color: _tipoColor(TipoNoticia.convocatoria),
            textColor: AppColors.textFor(b),
            onTap: () => onSelected(TipoNoticia.convocatoria),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Cambios',
            isSelected: selected == TipoNoticia.cambio,
            color: _tipoColor(TipoNoticia.cambio),
            textColor: AppColors.textFor(b),
            onTap: () => onSelected(TipoNoticia.cambio),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Noticias',
            isSelected: selected == TipoNoticia.noticia,
            color: _tipoColor(TipoNoticia.noticia),
            textColor: AppColors.textFor(b),
            onTap: () => onSelected(TipoNoticia.noticia),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
    this.textColor,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: AppColors.surfaceMutedFor(b),
      selectedColor: effectiveColor.withOpacity(0.16),
      checkmarkColor: effectiveColor,
      avatar: isSelected ? Icon(Icons.check, size: 16, color: effectiveColor) : null,
      side: BorderSide(
        color: isSelected ? effectiveColor : AppColors.borderFor(b),
      ),
      labelStyle: isSelected
          ? AppText.bodySmall.copyWith(color: effectiveColor, fontWeight: FontWeight.w700)
          : AppText.bodySmall.copyWith(
              color: textColor ?? AppColors.textMutedFor(b),
            ),
    );
  }
}

// ── Lista de noticias ──────────────────────────────────────────────────────────

class _NoticiasList extends StatelessWidget {
  const _NoticiasList({
    required this.items,
    required this.hayMas,
    required this.cargandoMas,
    required this.scrollCtrl,
    required this.onTap,
  });

  final List<NoticiaResumen> items;
  final bool hayMas;
  final bool cargandoMas;
  final ScrollController scrollCtrl;
  final ValueChanged<NoticiaResumen> onTap;

  @override
  Widget build(BuildContext context) {
    final itemCount = items.length + (hayMas ? 1 : 0);

    return ListView.separated(
      controller: scrollCtrl,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == items.length) {
          // Footer: indicador de carga de más páginas
          return Padding(
            padding: const EdgeInsets.all(8),
            child: Center(
              child: cargandoMas
                  ? const CircularProgressIndicator()
                  : const SizedBox.shrink(),
            ),
          );
        }
        return _NoticiaResumenTile(
          noticia: items[index],
          onTap: () => onTap(items[index]),
        );
      },
    );
  }
}

// ── Tile de noticia ────────────────────────────────────────────────────────────

class _NoticiaResumenTile extends StatelessWidget {
  const _NoticiaResumenTile({required this.noticia, required this.onTap});

  final NoticiaResumen noticia;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final color = _tipoColor(noticia.tipo);

    return GestureDetector(
      onTap: onTap,
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: noticia.leida
                  ? Icon(
                      Icons.check_circle_outline,
                      color: AppColors.textFaintFor(b),
                      size: 18,
                    )
                  : Icon(Icons.circle, color: color, size: 10),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    noticia.titulo,
                    style: AppText.cardTitle.copyWith(
                      color: noticia.leida
                          ? AppColors.textMutedFor(b)
                          : AppColors.textFor(b),
                      fontWeight:
                          noticia.leida ? FontWeight.w500 : FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _TipoBadge(tipo: noticia.tipo),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _formatFecha(noticia.fechaPublicacion),
                          style: AppText.caption.copyWith(
                            color: AppColors.textFaintFor(b),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widgets de apoyo ───────────────────────────────────────────────────────────

class _TipoBadge extends StatelessWidget {
  const _TipoBadge({required this.tipo});

  final TipoNoticia tipo;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final color = _tipoColor(tipo);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(b == Brightness.dark ? 0.22 : 0.14),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _tipoLabel(tipo),
        style: AppText.label.copyWith(
          fontSize: 10,
          color: color,
        ),
      ),
    );
  }
}

Color _tipoColor(TipoNoticia tipo) => switch (tipo) {
      TipoNoticia.convocatoria => AppColors.accentWarm,
      TipoNoticia.cambio => AppColors.accentRose,
      TipoNoticia.noticia => AppColors.primary,
    };

String _tipoLabel(TipoNoticia tipo) => switch (tipo) {
      TipoNoticia.convocatoria => 'Convocatoria',
      TipoNoticia.cambio => 'Cambio',
      TipoNoticia.noticia => 'Noticia',
    };

// ── Estados vacío y error ──────────────────────────────────────────────────────

class _EmptyBody extends StatelessWidget {
  const _EmptyBody({
    required this.onRefresh,
    this.onClearFilter,
  });

  final Future<void> Function() onRefresh;
  final VoidCallback? onClearFilter;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return RefreshIndicator(
      color: AppColors.primaryFor(b),
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 72),
          AppCard.large(
            child: Column(
              children: [
                Icon(
                  Icons.newspaper_outlined,
                  size: 44,
                  color: AppColors.textFaintFor(b),
                ),
                const SizedBox(height: 12),
                Text(
                  'No hay noticias para este filtro.',
                  style: AppText.cardTitle.copyWith(
                    color: AppColors.textFor(b),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Prueba a refrescar o ver todas las categorías.',
                  style: AppText.bodySmall.copyWith(
                    color: AppColors.textMutedFor(b),
                  ),
                  textAlign: TextAlign.center,
                ),
                if (onClearFilter != null) ...[
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: onClearFilter,
                    icon: const Icon(Icons.filter_alt_off_outlined),
                    label: const Text('Ver todas'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({
    required this.message,
    required this.onRetry,
    required this.onRefresh,
  });

  final String message;
  final VoidCallback onRetry;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return RefreshIndicator(
      color: AppColors.primaryFor(b),
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 72),
          AppCard.large(
            child: Column(
              children: [
                Icon(
                  Icons.wifi_off_outlined,
                  size: 44,
                  color: AppColors.textFaintFor(b),
                ),
                const SizedBox(height: 12),
                Text(
                  'No se pudieron cargar las noticias',
                  style: AppText.cardTitle.copyWith(
                    color: AppColors.textFor(b),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: AppText.bodySmall.copyWith(
                    color: AppColors.textMutedFor(b),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                OutlinedButton(
                  onPressed: onRetry,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Muestra solo la fecha si la hora es 00:00, o fecha + hora si tiene hora real.
/// Entrada esperada: "dd/MM/yyyy HH:mm" (formato del backend).
String _formatFecha(String fechaPublicacion) {
  if (fechaPublicacion.endsWith('00:00')) {
    return fechaPublicacion.substring(0, 10); // "dd/MM/yyyy"
  }
  return fechaPublicacion;
}

String _userMessage(Object error) {
  if (error is ApiException) {
    return error.message;
  }
  return 'Ha ocurrido un error. Inténtalo de nuevo.';
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../data/models/noticia_resumen.dart';
import '../providers/noticias_provider.dart';

// ── Pantalla principal ─────────────────────────────────────────────────────────

class NoticiasListScreen extends ConsumerStatefulWidget {
  const NoticiasListScreen({super.key});

  @override
  ConsumerState<NoticiasListScreen> createState() => _NoticiasListScreenState();
}

class _NoticiasListScreenState extends ConsumerState<NoticiasListScreen> {
  final _scrollCtrl = ScrollController();

  TipoNoticia? _selectedTipo;
  bool _cargandoMas = false;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(noticiasListNotifierProvider.notifier).cargar();
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
          SnackBar(content: Text('Error al cargar más: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _cargandoMas = false);
    }
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
  Widget build(BuildContext context) {
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
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => _ErrorBody(
                message: e.toString(),
                onRetry: () => ref
                    .read(noticiasListNotifierProvider.notifier)
                    .cargar(tipo: _selectedTipo),
              ),
              data: (listState) {
                if (listState.items.isEmpty) {
                  return const _EmptyBody();
                }
                return _NoticiasList(
                  items: listState.items,
                  hayMas: listState.hayMas,
                  cargandoMas: _cargandoMas,
                  scrollCtrl: _scrollCtrl,
                  onTap: _openDetalle,
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
            onTap: () => onSelected(TipoNoticia.convocatoria),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Cambios',
            isSelected: selected == TipoNoticia.cambio,
            color: _tipoColor(TipoNoticia.cambio),
            onTap: () => onSelected(TipoNoticia.cambio),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Noticias',
            isSelected: selected == TipoNoticia.noticia,
            color: _tipoColor(TipoNoticia.noticia),
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
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: effectiveColor.withOpacity(0.15),
      checkmarkColor: effectiveColor,
      labelStyle: isSelected
          ? TextStyle(color: effectiveColor, fontWeight: FontWeight.w600)
          : null,
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
      itemCount: itemCount,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (index == items.length) {
          // Footer: indicador de carga de más páginas
          return Padding(
            padding: const EdgeInsets.all(16),
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
    final color = _tipoColor(noticia.tipo);

    return ListTile(
      leading: noticia.leida
          ? Icon(Icons.check_circle_outline,
              color: Colors.grey.shade400, size: 20)
          : Icon(Icons.circle, color: color, size: 10),
      title: Text(
        noticia.titulo,
        style: TextStyle(
          fontWeight: noticia.leida ? FontWeight.normal : FontWeight.w600,
          color: noticia.leida ? Colors.grey.shade600 : null,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            _TipoBadge(tipo: noticia.tipo),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                noticia.fechaPublicacion,
                style: TextStyle(
                    fontSize: 11, color: Colors.grey.shade500),
              ),
            ),
          ],
        ),
      ),
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    );
  }
}

// ── Widgets de apoyo ───────────────────────────────────────────────────────────

class _TipoBadge extends StatelessWidget {
  const _TipoBadge({required this.tipo});

  final TipoNoticia tipo;

  @override
  Widget build(BuildContext context) {
    final color = _tipoColor(tipo);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _tipoLabel(tipo),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

Color _tipoColor(TipoNoticia tipo) => switch (tipo) {
      TipoNoticia.convocatoria => Colors.deepPurple,
      TipoNoticia.cambio => Colors.orange,
      TipoNoticia.noticia => Colors.blue,
    };

String _tipoLabel(TipoNoticia tipo) => switch (tipo) {
      TipoNoticia.convocatoria => 'Convocatoria',
      TipoNoticia.cambio => 'Cambio',
      TipoNoticia.noticia => 'Noticia',
    };

// ── Estados vacío y error ──────────────────────────────────────────────────────

class _EmptyBody extends StatelessWidget {
  const _EmptyBody();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.newspaper_outlined, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No hay noticias para estos filtros.',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(
                onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

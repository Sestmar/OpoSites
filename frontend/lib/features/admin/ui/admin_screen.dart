import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/models/ingestion_result.dart';
import '../data/models/noticia_borrador.dart';
import '../providers/admin_provider.dart' show adminRepositoryProvider, borradoresProvider, ingestaProvider, BorradoresState;

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ingestaState  = ref.watch(ingestaProvider);
    final borradoresState = ref.watch(borradoresProvider);


    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Admin'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Recargar borradores',
            onPressed: () => ref.invalidate(borradoresProvider),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            sliver: SliverToBoxAdapter(
              child: _IngestaSection(state: ingestaState),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            sliver: SliverToBoxAdapter(
              child: _BorradoresSectionHeader(
                total: borradoresState.valueOrNull?.total,
              ),
            ),
          ),
          ..._buildBorradoresSliver(context, ref, borradoresState),
          const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
        ],
      ),
    );
  }

  List<Widget> _buildBorradoresSliver(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<BorradoresState> state,
  ) {
    return state.when(
      loading: () => [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      ],
      error: (_, __) => [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _ErrorChip(message: 'Error al cargar borradores'),
          ),
        ),
      ],
      data: (borradoresState) {
        final borradores = borradoresState.items;
        if (borradores.isEmpty) {
          return [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              sliver: SliverToBoxAdapter(child: _EmptyBorradores()),
            ),
          ];
        }
        return [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverList.separated(
              itemCount: borradores.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _BorradorCard(
                borrador: borradores[i],
                onPublicar: () =>
                    ref.read(borradoresProvider.notifier).publicar(borradores[i].id),
                onRechazar: () =>
                    ref.read(borradoresProvider.notifier).rechazar(borradores[i].id),
              ),
            ),
          ),
        ];
      },
    );
  }
}

// ── Sección: Ingesta ───────────────────────────────────────────────────────────

class _IngestaSection extends ConsumerWidget {
  const _IngestaSection({required this.state});

  final AsyncValue<IngestionResult?> state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ingesta de noticias',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Ejecuta la ingesta manualmente para obtener noticias ahora. '
          'La ingesta automática corre cada 6 horas.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          icon: state.isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.sync_outlined),
          label: const Text('Ejecutar ingesta'),
          onPressed: state.isLoading
              ? null
              : () => ref.read(ingestaProvider.notifier).ejecutar(),
        ),
        if (state.hasError) ...[
          const SizedBox(height: 8),
          _ErrorChip(message: 'Error al ejecutar la ingesta'),
        ],
        if (state.hasValue && state.value != null) ...[
          const SizedBox(height: 12),
          _IngestaResultCard(result: state.value!),
        ],
      ],
    );
  }
}

class _IngestaResultCard extends StatelessWidget {
  const _IngestaResultCard({required this.result});

  final IngestionResult result;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Resultado de la última ingesta',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _StatRow(label: 'Fuentes procesadas', value: result.fuentesProcesadas),
            _StatRow(label: 'Ítems leídos',       value: result.itemsLeidos),
            _StatRow(
              label: 'Descartados por filtro',
              value: result.itemsFiltrados,
            ),
            _StatRow(
              label: 'Ítems creados',
              value: result.itemsCreados,
              highlight: result.itemsCreados > 0,
            ),
            _StatRow(label: 'Duplicados omitidos', value: result.itemsDuplicados),
            _StatRow(
              label: 'Errores',
              value: result.errores,
              highlight: result.errores > 0,
              highlightColor: Theme.of(context).colorScheme.error,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    this.highlight = false,
    this.highlightColor,
  });

  final String label;
  final int value;
  final bool highlight;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    final color = highlight
        ? (highlightColor ?? Theme.of(context).colorScheme.primary)
        : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(
            '$value',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: highlight ? FontWeight.bold : null,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}

// ── Sección: Borradores (header) ──────────────────────────────────────────────

class _BorradoresSectionHeader extends StatelessWidget {
  const _BorradoresSectionHeader({this.total});

  final int? total;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          total != null
              ? 'Borradores pendientes ($total)'
              : 'Borradores pendientes',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Revisá cada noticia y decidí si publicarla o rechazarla.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
      ],
    );
  }
}

// ── Tarjeta de borrador ───────────────────────────────────────────────────────

class _BorradorCard extends StatelessWidget {
  const _BorradorCard({
    required this.borrador,
    required this.onPublicar,
    required this.onRechazar,
  });

  final NoticiaBorrador borrador;
  final VoidCallback onPublicar;
  final VoidCallback onRechazar;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Rama + fecha ─────────────────────────────────────────────────
            Row(
              children: [
                if (borrador.nombreRama != null)
                  _RamaChip(nombre: borrador.nombreRama!),
                const Spacer(),
                Text(
                  borrador.fechaPublicacion,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.grey.shade500,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Título ───────────────────────────────────────────────────────
            Text(
              borrador.titulo,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            // ── Contenido ────────────────────────────────────────────────────
            if (borrador.contenido != null &&
                borrador.contenido!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                borrador.contenido!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // ── Enlace externo ───────────────────────────────────────────────
            if (borrador.urlExterna != null) ...[
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => launchUrl(
                  Uri.parse(borrador.urlExterna!),
                  mode: LaunchMode.externalApplication,
                ),
                child: Text(
                  'Ver fuente original',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                ),
              ),
            ],

            const SizedBox(height: 12),

            // ── Acciones ─────────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                    side: BorderSide(
                        color: Theme.of(context).colorScheme.error),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: onRechazar,
                  child: const Text('Rechazar'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: onPublicar,
                  child: const Text('Publicar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RamaChip extends StatelessWidget {
  const _RamaChip({required this.nombre});

  final String nombre;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        nombre,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
      ),
    );
  }
}

// ── Estado vacío ──────────────────────────────────────────────────────────────

class _EmptyBorradores extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined, size: 40, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            'No hay borradores pendientes',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade500,
                ),
          ),
        ],
      ),
    );
  }
}

// ── Error chip ────────────────────────────────────────────────────────────────

class _ErrorChip extends StatelessWidget {
  const _ErrorChip({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline,
            size: 16, color: Theme.of(context).colorScheme.error),
        const SizedBox(width: 6),
        Text(
          message,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
        ),
      ],
    );
  }
}

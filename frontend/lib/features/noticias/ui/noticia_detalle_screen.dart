import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/models/noticia.dart';
import '../data/models/noticia_resumen.dart';
import '../providers/noticias_provider.dart';

// ── Pantalla principal ─────────────────────────────────────────────────────────

/// Detalle de una noticia.
///
/// Al cargar el contenido, la pantalla marca automáticamente la noticia como
/// leída (si no lo estaba) y sincroniza el estado en [NoticiasListNotifier].
class NoticiaDetalleScreen extends ConsumerStatefulWidget {
  const NoticiaDetalleScreen({required this.id, super.key});

  final int id;

  @override
  ConsumerState<NoticiaDetalleScreen> createState() =>
      _NoticiaDetalleScreenState();
}

class _NoticiaDetalleScreenState
    extends ConsumerState<NoticiaDetalleScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(noticiaDetalleNotifierProvider.notifier).cargar(widget.id);
    });
  }

  Future<void> _marcarLeida() async {
    try {
      await ref
          .read(noticiaDetalleNotifierProvider.notifier)
          .marcarLeida(widget.id);
      // Sincroniza el estado de leída en la lista sin refetch.
      ref
          .read(noticiasListNotifierProvider.notifier)
          .actualizarLeida(widget.id);
    } catch (_) {
      // Fallo silencioso — no es bloqueante para la UX de lectura.
    }
  }

  Future<void> _abrirEnlace(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(noticiaDetalleNotifierProvider);

    // Auto-marcar como leída la primera vez que llegan los datos.
    ref.listen<AsyncValue<Noticia?>>(noticiaDetalleNotifierProvider,
        (_, next) {
      next.whenData((noticia) {
        if (noticia != null && !noticia.leida) {
          _marcarLeida();
        }
      });
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorBody(
          message: e.toString(),
          onRetry: () => ref
              .read(noticiaDetalleNotifierProvider.notifier)
              .cargar(widget.id),
        ),
        data: (noticia) {
          if (noticia == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return _NoticiaContent(
            noticia: noticia,
            onAbrirEnlace: noticia.urlExterna != null
                ? () => _abrirEnlace(noticia.urlExterna!)
                : null,
            onMarcarLeida: noticia.leida ? null : _marcarLeida,
          );
        },
      ),
    );
  }
}

// ── Contenido de la noticia ────────────────────────────────────────────────────

class _NoticiaContent extends StatelessWidget {
  const _NoticiaContent({
    required this.noticia,
    this.onAbrirEnlace,
    this.onMarcarLeida,
  });

  final Noticia noticia;
  final VoidCallback? onAbrirEnlace;
  final VoidCallback? onMarcarLeida;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cabecera ──
          Row(
            children: [
              _TipoBadge(tipo: noticia.tipo),
              if (noticia.leida) ...[
                const SizedBox(width: 8),
                _LeidaBadge(),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            noticia.titulo,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            noticia.fechaPublicacion,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
          if (noticia.nombreRama != null) ...[
            const SizedBox(height: 4),
            Text(
              noticia.nombreRama!,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 13),
            ),
          ],

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),

          // ── Contenido ──
          if (noticia.contenido != null && noticia.contenido!.isNotEmpty)
            Text(
              noticia.contenido!,
              style: const TextStyle(fontSize: 15, height: 1.6),
            )
          else
            Text(
              'Esta noticia no tiene contenido textual.',
              style: TextStyle(color: Colors.grey.shade500),
            ),

          const SizedBox(height: 24),

          // ── Acciones ──
          if (onAbrirEnlace != null)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onAbrirEnlace,
                icon: const Icon(Icons.open_in_new),
                label: const Text('Abrir enlace oficial'),
              ),
            ),

          if (onMarcarLeida != null) ...[
            if (onAbrirEnlace != null) const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onMarcarLeida,
                icon: const Icon(Icons.check),
                label: const Text('Marcar como leída'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Badges ─────────────────────────────────────────────────────────────────────

class _TipoBadge extends StatelessWidget {
  const _TipoBadge({required this.tipo});

  final TipoNoticia tipo;

  @override
  Widget build(BuildContext context) {
    final color = _tipoColor(tipo);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _tipoLabel(tipo),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _LeidaBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check, size: 12, color: Colors.green),
          const SizedBox(width: 4),
          const Text(
            'Leída',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Estado error ───────────────────────────────────────────────────────────────

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
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────────

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

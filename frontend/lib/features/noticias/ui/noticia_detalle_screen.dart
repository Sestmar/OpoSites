import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
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
  bool _autoMarkIntentado = false;

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
    if (uri == null) {
      _showSnack('El enlace no es válido.');
      return;
    }
    if (await canLaunchUrl(uri)) {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) _showSnack('No se pudo abrir el enlace.');
      return;
    }
    _showSnack('No se pudo abrir el enlace.');
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final state = ref.watch(noticiaDetalleNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Noticia')),
      body: state.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: AppColors.primaryFor(b)),
        ),
        error: (e, _) => _ErrorBody(
          message: _userMessage(e),
          onRetry: () => ref
              .read(noticiaDetalleNotifierProvider.notifier)
              .cargar(widget.id),
        ),
        data: (noticia) {
          if (noticia == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!noticia.leida && !_autoMarkIntentado) {
            _autoMarkIntentado = true;
            WidgetsBinding.instance.addPostFrameCallback((_) => _marcarLeida());
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
    final b = Theme.of(context).brightness;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: AppCard.large(
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
              style: AppText.h2.copyWith(color: AppColors.textFor(b)),
            ),
            const SizedBox(height: 8),
            Text(
              noticia.fechaPublicacion,
              style: AppText.bodySmall.copyWith(
                color: AppColors.textMutedFor(b),
              ),
            ),
            if (noticia.nombreRama != null) ...[
              const SizedBox(height: 4),
              Text(
                noticia.nombreRama!,
                style: AppText.bodySmall.copyWith(
                  color: AppColors.primaryFor(b),
                ),
              ),
            ],

            const SizedBox(height: 16),
            Divider(color: AppColors.borderFor(b), height: 1),
            const SizedBox(height: 16),

            // ── Contenido ──
            if (noticia.contenido != null && noticia.contenido!.isNotEmpty)
              Text(
                noticia.contenido!,
                style: AppText.body.copyWith(
                  color: AppColors.textFor(b),
                  height: 1.55,
                ),
              )
            else
              Text(
                'Esta noticia no tiene contenido textual.',
                style: AppText.bodySmall.copyWith(
                  color: AppColors.textMutedFor(b),
                ),
              ),

            const SizedBox(height: 22),

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
    final b = Theme.of(context).brightness;
    final color = _tipoColor(tipo);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(b == Brightness.dark ? 0.22 : 0.14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _tipoLabel(tipo),
        style: AppText.bodySmall.copyWith(
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _LeidaBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accentMintSoftFor(b),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check, size: 12, color: AppColors.accentMint),
          const SizedBox(width: 4),
          Text(
            'Leída',
            style: AppText.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.accentMint,
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
    final b = Theme.of(context).brightness;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_outlined,
              size: 48,
              color: AppColors.textFaintFor(b),
            ),
            const SizedBox(height: 12),
            Text(
              'No se pudo cargar la noticia',
              textAlign: TextAlign.center,
              style: AppText.cardTitle.copyWith(color: AppColors.textFor(b)),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style:
                  AppText.bodySmall.copyWith(color: AppColors.textMutedFor(b)),
            ),
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
      TipoNoticia.convocatoria => AppColors.accentWarm,
      TipoNoticia.cambio => AppColors.accentRose,
      TipoNoticia.noticia => AppColors.primary,
    };

String _tipoLabel(TipoNoticia tipo) => switch (tipo) {
      TipoNoticia.convocatoria => 'Convocatoria',
      TipoNoticia.cambio => 'Cambio',
      TipoNoticia.noticia => 'Noticia',
    };

String _userMessage(Object error) {
  if (error is ApiException) {
    return error.message;
  }
  return 'Ha ocurrido un error. Inténtalo de nuevo.';
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/pressable.dart';
import '../data/models/documento.dart';
import '../data/models/material_generado.dart';
import '../providers/documentos_provider.dart';

class DocumentoDetalleScreen extends ConsumerStatefulWidget {
  const DocumentoDetalleScreen({
    super.key,
    required this.docId,
    required this.documento,
  });

  final int docId;
  final Documento documento;

  @override
  ConsumerState<DocumentoDetalleScreen> createState() =>
      _DocumentoDetalleScreenState();
}

class _DocumentoDetalleScreenState
    extends ConsumerState<DocumentoDetalleScreen> {
  TipoMaterial? _generando;

  Future<void> _generar(TipoMaterial tipo) async {
    if (_generando != null) return;

    // ── Chequeo de duplicados ────────────────────────────────────────────────
    final materiales =
        ref.read(documentoMaterialesProvider(widget.docId)).valueOrNull ?? [];
    final existente = materiales
        .where((m) => m.tipo == tipo)
        .toList();

    if (existente.isNotEmpty) {
      if (!mounted) return;
      final accion = await _mostrarDialogoDuplicado(tipo, existente.first);
      if (accion == _AccionDuplicado.abrir) {
        _navegarAMaterial(existente.first);
        return;
      }
      if (accion != _AccionDuplicado.regenerar) return; // canceló
    }

    // ── Generación ───────────────────────────────────────────────────────────
    setState(() => _generando = tipo);
    try {
      final material = await ref
          .read(documentoMaterialesProvider(widget.docId).notifier)
          .generar(tipo);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '${tipoMaterialLabel(tipo)} generado correctamente')),
      );
      _navegarAMaterial(material);
    } catch (e) {
      if (!mounted) return;
      _showError(_msgError(e));
    } finally {
      if (mounted) setState(() => _generando = null);
    }
  }

  Future<_AccionDuplicado?> _mostrarDialogoDuplicado(
      TipoMaterial tipo, MaterialGenerado existente) {
    final label = tipoMaterialLabel(tipo);
    return showDialog<_AccionDuplicado>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Ya existe $label'),
        content: Text(
          'Este documento ya tiene $label generado. '
          '¿Querés abrir el existente o regenerarlo?',
        ),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(null),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => ctx.pop(_AccionDuplicado.abrir),
            child: const Text('Ver existente'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 36),
            ),
            onPressed: () => ctx.pop(_AccionDuplicado.regenerar),
            child: const Text('Regenerar'),
          ),
        ],
      ),
    );
  }

  void _navegarAMaterial(MaterialGenerado material) {
    switch (material.tipo) {
      case TipoMaterial.flashcards:
        context.push(AppRoutes.documentoFlashcards(widget.docId),
            extra: material);
      case TipoMaterial.resumen:
        context.push(AppRoutes.documentoResumen(widget.docId),
            extra: material);
      case TipoMaterial.conceptosClave:
        context.push(AppRoutes.documentoConceptos(widget.docId),
            extra: material);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final doc = widget.documento;
    final materialesAsync =
        ref.watch(documentoMaterialesProvider(widget.docId));
    final fechaFmt = DateFormat('dd MMM yyyy', 'es').format(doc.creadoEn);

    return Scaffold(
      appBar: AppBar(
          title: Text(doc.nombre,
              maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          // ── Metadatos ──────────────────────────────────────────────────────
          _MetaCard(doc: doc, fechaFmt: fechaFmt),
          const SizedBox(height: 20),

          // ── Aviso PDF escaneado ────────────────────────────────────────────
          if (!doc.textoDisponible) ...[
            _WarningBanner(
              icon: Icons.scanner_outlined,
              message:
                  'No se pudo extraer texto de este documento. Puede ser un PDF escaneado. La generación de materiales no está disponible.',
            ),
            const SizedBox(height: 16),
          ],

          // ── Generar con IA ─────────────────────────────────────────────────
          Text('GENERAR CON IA',
              style: AppText.label.copyWith(
                  color: AppColors.textMutedFor(b))),
          const SizedBox(height: 10),
          _AccionesGeneracion(
            textoDisponible: doc.textoDisponible,
            generando: _generando,
            materialesActuales: materialesAsync.valueOrNull ?? [],
            onGenerar: _generar,
          ),
          const SizedBox(height: 24),

          // ── Materiales ya generados ────────────────────────────────────────
          Text('MATERIALES GENERADOS',
              style: AppText.label.copyWith(
                  color: AppColors.textMutedFor(b))),
          const SizedBox(height: 10),
          materialesAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => _WarningBanner(
              icon: Icons.error_outline,
              message: _msgError(e),
            ),
            data: (materiales) {
              if (materiales.isEmpty) {
                return _EmptyMateriales();
              }
              return Column(
                children: materiales
                    .map((m) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _MaterialTile(
                            material: m,
                            onTap: () => _navegarAMaterial(m),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Enum interno para la acción de duplicado ───────────────────────────────────

enum _AccionDuplicado { abrir, regenerar }

// ── Helpers ────────────────────────────────────────────────────────────────────

String _msgError(Object e) {
  if (e is ApiException) return e.message;
  return 'Ocurrió un error inesperado. Intentalo de nuevo.';
}

// ── Widgets de apoyo ───────────────────────────────────────────────────────────

class _MetaCard extends StatelessWidget {
  const _MetaCard({required this.doc, required this.fechaFmt});
  final Documento doc;
  final String fechaFmt;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final isPdf = doc.tipoArchivo == 'PDF';
    final iconColor = isPdf
        ? Theme.of(context).colorScheme.error
        : AppColors.primaryFor(b);

    return AppCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isPdf
                  ? Icons.picture_as_pdf_outlined
                  : Icons.description_outlined,
              color: iconColor,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doc.tipoArchivo,
                    style: AppText.label
                        .copyWith(color: AppColors.textMutedFor(b))),
                const SizedBox(height: 2),
                Text(doc.tamanoFormateado,
                    style: AppText.body
                        .copyWith(color: AppColors.textFor(b))),
                Text('Subido el $fechaFmt',
                    style: AppText.caption
                        .copyWith(color: AppColors.textMutedFor(b))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    // Usamos un color ámbar adaptado al brightness
    final bannerColor = b == Brightness.dark
        ? const Color(0xFF78350F).withOpacity(0.4) // ámbar oscuro
        : const Color(0xFFFFF7ED); // ámbar claro
    final textColor = b == Brightness.dark
        ? const Color(0xFFFBBF24)
        : const Color(0xFF92400E);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bannerColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: AppText.bodySmall.copyWith(color: textColor)),
          ),
        ],
      ),
    );
  }
}

class _EmptyMateriales extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;

    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(Icons.auto_awesome_outlined,
              size: 36, color: AppColors.primaryFor(b).withOpacity(0.6)),
          const SizedBox(height: 12),
          Text(
            'Sin materiales todavía',
            style:
                AppText.cardTitle.copyWith(color: AppColors.textFor(b)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Usá los botones de arriba para que la IA genere flashcards, un resumen o los conceptos clave de este documento.',
            textAlign: TextAlign.center,
            style: AppText.bodySmall
                .copyWith(color: AppColors.textMutedFor(b)),
          ),
        ],
      ),
    );
  }
}

class _AccionesGeneracion extends StatelessWidget {
  const _AccionesGeneracion({
    required this.textoDisponible,
    required this.generando,
    required this.materialesActuales,
    required this.onGenerar,
  });

  final bool textoDisponible;
  final TipoMaterial? generando;
  final List<MaterialGenerado> materialesActuales;
  final void Function(TipoMaterial) onGenerar;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: TipoMaterial.values.map((tipo) {
        final isGenerandoEste = generando == tipo;
        final disabled = !textoDisponible || generando != null;
        final yaExiste = materialesActuales.any((m) => m.tipo == tipo);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: OutlinedButton.icon(
            onPressed: disabled ? null : () => onGenerar(tipo),
            icon: isGenerandoEste
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(_iconoTipo(tipo)),
            label: Text(
              isGenerandoEste
                  ? 'Generando…'
                  : yaExiste
                      ? 'Regenerar ${tipoMaterialLabel(tipo)}'
                      : 'Generar ${tipoMaterialLabel(tipo)}',
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              alignment: Alignment.centerLeft,
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _iconoTipo(TipoMaterial tipo) => switch (tipo) {
        TipoMaterial.flashcards => Icons.style_outlined,
        TipoMaterial.resumen => Icons.summarize_outlined,
        TipoMaterial.conceptosClave => Icons.label_outline,
      };
}

class _MaterialTile extends StatelessWidget {
  const _MaterialTile({required this.material, required this.onTap});
  final MaterialGenerado material;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final fechaFmt =
        DateFormat('dd MMM yyyy  HH:mm', 'es').format(material.creadoEn);
    final color = _colorTipo(material.tipo, b);

    return Pressable(
      onTap: onTap,
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_iconoTipo(material.tipo), color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tipoMaterialLabel(material.tipo),
                    style: AppText.cardTitle
                        .copyWith(color: AppColors.textFor(b)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Generado el $fechaFmt',
                    style: AppText.caption
                        .copyWith(color: AppColors.textMutedFor(b)),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                size: 20, color: AppColors.textFaintFor(b)),
          ],
        ),
      ),
    );
  }

  IconData _iconoTipo(TipoMaterial tipo) => switch (tipo) {
        TipoMaterial.flashcards => Icons.style_outlined,
        TipoMaterial.resumen => Icons.summarize_outlined,
        TipoMaterial.conceptosClave => Icons.label_outline,
      };

  Color _colorTipo(TipoMaterial tipo, Brightness b) => switch (tipo) {
        TipoMaterial.flashcards => AppColors.accentRoseSoftFor(b),
        TipoMaterial.resumen => AppColors.primaryFor(b),
        TipoMaterial.conceptosClave => AppColors.accentWarmSoftFor(b),
      };
}

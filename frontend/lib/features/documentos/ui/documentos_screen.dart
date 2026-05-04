import 'package:file_picker/file_picker.dart';
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
import '../providers/documentos_provider.dart';

class DocumentosScreen extends ConsumerStatefulWidget {
  const DocumentosScreen({super.key});

  @override
  ConsumerState<DocumentosScreen> createState() => _DocumentosScreenState();
}

class _DocumentosScreenState extends ConsumerState<DocumentosScreen> {
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(documentosNotifierProvider.notifier).refrescar(),
    );
  }

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) {
      _showError('No se pudieron leer los datos del archivo.');
      return;
    }

    setState(() => _uploading = true);
    try {
      await ref.read(documentosNotifierProvider.notifier).subirDocumento(
            bytes: file.bytes!,
            nombre: file.name,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Documento subido correctamente')),
        );
      }
    } catch (e) {
      _showError(_msgError(e));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _eliminar(Documento doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar documento'),
        content: Text(
            '¿Eliminar "${doc.nombre}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
              onPressed: () => ctx.pop(false),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () => ctx.pop(true),
            child: Text('Eliminar',
                style: TextStyle(
                    color: Theme.of(ctx).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ref.read(documentosNotifierProvider.notifier).eliminar(doc.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Documento eliminado')),
        );
      }
    } catch (e) {
      _showError(_msgError(e));
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
    final docsAsync = ref.watch(documentosNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis documentos'),
        actions: [
          if (_uploading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _uploading ? null : _pickAndUpload,
        icon: const Icon(Icons.upload_file),
        label: const Text('Subir documento'),
      ),
      body: docsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(
          message: _msgError(e),
          onRetry: () =>
              ref.read(documentosNotifierProvider.notifier).refrescar(),
        ),
        data: (docs) {
          if (docs.isEmpty) return const _EmptyView();
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(documentosNotifierProvider.notifier).refrescar(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _DocumentoTile(
                doc: docs[i],
                onTap: () => context.push(
                  AppRoutes.documentoDetalle(docs[i].id),
                  extra: docs[i],
                ),
                onEliminar: () => _eliminar(docs[i]),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────────

String _msgError(Object e) {
  if (e is ApiException) return e.message;
  return 'Ocurrió un error inesperado. Intentalo de nuevo.';
}

// ── Widgets de apoyo ───────────────────────────────────────────────────────────

class _DocumentoTile extends StatelessWidget {
  const _DocumentoTile({
    required this.doc,
    required this.onTap,
    required this.onEliminar,
  });

  final Documento doc;
  final VoidCallback onTap;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final fechaFmt = DateFormat('dd MMM yyyy', 'es').format(doc.creadoEn);
    final isPdf = doc.tipoArchivo == 'PDF';
    final iconColor = isPdf
        ? Theme.of(context).colorScheme.error
        : AppColors.primaryFor(b);
    final iconBg = iconColor.withOpacity(0.1);

    return Pressable(
      onTap: onTap,
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // ── Ícono de tipo ──────────────────────────────────────────────
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isPdf
                    ? Icons.picture_as_pdf_outlined
                    : Icons.description_outlined,
                color: iconColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),

            // ── Nombre y metadata ──────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.cardTitle.copyWith(
                        color: AppColors.textFor(b)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${doc.tipoArchivo}  ·  ${doc.tamanoFormateado}  ·  $fechaFmt',
                    style: AppText.caption
                        .copyWith(color: AppColors.textMutedFor(b)),
                  ),
                ],
              ),
            ),

            // ── Menú contextual ────────────────────────────────────────────
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'delete') onEliminar();
              },
              icon: Icon(Icons.more_vert,
                  size: 20, color: AppColors.textMutedFor(b)),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline,
                          color: Theme.of(context).colorScheme.error,
                          size: 18),
                      const SizedBox(width: 8),
                      Text('Eliminar',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_stories_outlined,
                size: 64, color: AppColors.textFaintFor(b)),
            const SizedBox(height: 20),
            Text(
              'Todavía no tenés documentos',
              style: AppText.h2.copyWith(color: AppColors.textFor(b)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Subí un PDF o TXT y la IA generará flashcards, resúmenes y conceptos clave para ayudarte a estudiar.',
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(color: AppColors.textMutedFor(b)),
            ),
            const SizedBox(height: 8),
            Text(
              'Usá el botón "Subir documento" para empezar.',
              textAlign: TextAlign.center,
              style:
                  AppText.bodySmall.copyWith(color: AppColors.textFaintFor(b)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

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
            Icon(Icons.cloud_off_outlined,
                size: 52, color: AppColors.textFaintFor(b)),
            const SizedBox(height: 16),
            Text(
              'No se pudo cargar la lista',
              style: AppText.cardTitle.copyWith(color: AppColors.textFor(b)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style:
                  AppText.bodySmall.copyWith(color: AppColors.textMutedFor(b)),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

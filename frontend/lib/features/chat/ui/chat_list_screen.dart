import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../documentos/data/models/documento.dart';
import '../../documentos/providers/documentos_provider.dart';
import '../data/models/conversacion_resumen.dart';
import '../providers/chat_providers.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  bool _creando = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(conversacionesListNotifierProvider.notifier).cargar();
    });
  }

  Future<void> _nuevaConversacion() async {
    if (_creando) return;

    // 1.4 + 1.6 — Mostrar selector de documento y modo antes de crear
    final config = await _seleccionarConfig();
    if (!mounted || config == null) return;

    setState(() => _creando = true);
    try {
      final id = await ref
          .read(conversacionesListNotifierProvider.notifier)
          .crear(documentoId: config.$1, modo: config.$2);
      if (mounted) context.push(AppRoutes.chatDetalle(id));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo crear la conversación')),
        );
      }
    } finally {
      if (mounted) setState(() => _creando = false);
    }
  }

  /// Muestra un bottom sheet para que el usuario elija documento y modo.
  /// Devuelve (documentoId, modo) o null si el usuario cancela.
  Future<(int?, String)?> _seleccionarConfig() async {
    final documentos =
        ref.read(documentosNotifierProvider).valueOrNull ?? [];

    return showModalBottomSheet<(int?, String)>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _DocumentoSelectorSheet(documentos: documentos),
    );
  }

  Future<void> _eliminar(int id) async {
    try {
      await ref
          .read(conversacionesListNotifierProvider.notifier)
          .eliminar(id);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo eliminar la conversación')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(conversacionesListNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Chat IA')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _creando ? null : _nuevaConversacion,
        icon: _creando
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add),
        label: const Text('Nueva conversación'),
      ),
      body: listState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorBody(
          message: e.toString(),
          onRetry: () =>
              ref.read(conversacionesListNotifierProvider.notifier).cargar(),
        ),
        data: (lista) => lista.isEmpty
            ? _EmptyBody(onNueva: _nuevaConversacion, creando: _creando)
            : _ConversacionesList(
                conversaciones: lista,
                onTap: (id) => context.push(AppRoutes.chatDetalle(id)),
                onEliminar: _eliminar,
              ),
      ),
    );
  }
}

// ── Lista ──────────────────────────────────────────────────────────────────────

class _ConversacionesList extends StatelessWidget {
  const _ConversacionesList({
    required this.conversaciones,
    required this.onTap,
    required this.onEliminar,
  });

  final List<ConversacionResumen> conversaciones;
  final void Function(int id) onTap;
  final void Function(int id) onEliminar;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: conversaciones.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
      itemBuilder: (_, i) {
        final c = conversaciones[i];
        return Dismissible(
          key: ValueKey(c.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: Theme.of(context).colorScheme.errorContainer,
            child: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
          confirmDismiss: (_) => _confirmarEliminar(context),
          onDismissed: (_) => onEliminar(c.id),
          child: _ConversacionTile(
            conversacion: c,
            onTap: () => onTap(c.id),
            onEliminar: () => onEliminar(c.id),
          ),
        );
      },
    );
  }

  Future<bool?> _confirmarEliminar(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar conversación'),
        content: const Text('¿Seguro que querés eliminar esta conversación?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

// ── Tile individual ────────────────────────────────────────────────────────────

class _ConversacionTile extends StatelessWidget {
  const _ConversacionTile({
    required this.conversacion,
    required this.onTap,
    required this.onEliminar,
  });

  final ConversacionResumen conversacion;
  final VoidCallback onTap;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final fecha = DateFormat('d MMM yyyy', 'es').format(conversacion.createdAt);
    final esExaminador = conversacion.modo == 'EXAMINADOR';

    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: esExaminador
              ? Theme.of(context).colorScheme.tertiaryContainer.withOpacity(0.5)
              : Colors.blueGrey.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          esExaminador ? Icons.school_outlined : Icons.smart_toy_outlined,
          color: esExaminador
              ? Theme.of(context).colorScheme.tertiary
              : Colors.blueGrey,
          size: 22,
        ),
      ),
      title: Text(
        conversacion.tituloDisplay,
        style: const TextStyle(fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          if (esExaminador) ...[
            Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Examinador',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onTertiaryContainer,
                ),
              ),
            ),
          ],
          Text(
            fecha,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            color: Colors.grey.shade400,
            tooltip: 'Eliminar',
            onPressed: onEliminar,
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
      onTap: onTap,
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyBody extends StatelessWidget {
  const _EmptyBody({required this.onNueva, required this.creando});

  final VoidCallback onNueva;
  final bool creando;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.smart_toy_outlined,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Aún no tenés conversaciones',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey.shade500,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Consultá dudas sobre tu oposición con la IA.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: creando ? null : onNueva,
              icon: const Icon(Icons.add),
              label: const Text('Nueva conversación'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error state ────────────────────────────────────────────────────────────────

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
            Icon(Icons.error_outline,
                size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
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

// ── 1.4 + 1.6 Selector de documento y modo ────────────────────────────────────

/// Bottom sheet para elegir documento y modo antes de crear una conversación.
/// Devuelve (documentoId, modo) como Dart record, o null si el usuario cancela.
class _DocumentoSelectorSheet extends StatefulWidget {
  const _DocumentoSelectorSheet({required this.documentos});

  final List<Documento> documentos;

  @override
  State<_DocumentoSelectorSheet> createState() =>
      _DocumentoSelectorSheetState();
}

class _DocumentoSelectorSheetState extends State<_DocumentoSelectorSheet> {
  String _modo = 'GENERAL';
  int? _documentoId;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Text(
              'Nueva conversación',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),

          // ── Selector de modo ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Text(
              'Modo',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary,
                    letterSpacing: 0.8,
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'GENERAL',
                  icon: Icon(Icons.chat_outlined, size: 18),
                  label: Text('General'),
                ),
                ButtonSegment(
                  value: 'EXAMINADOR',
                  icon: Icon(Icons.school_outlined, size: 18),
                  label: Text('Examinador'),
                ),
              ],
              selected: {_modo},
              onSelectionChanged: (s) => setState(() => _modo = s.first),
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
            child: Text(
              _modo == 'EXAMINADOR'
                  ? 'Practica como si fuera el examen; la IA pregunta y corrige.'
                  : 'Pregunta lo que quieras sobre tu oposición.',
              style:
                  TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ),

          const Divider(height: 1),

          // ── Selector de documento ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Text(
              'Documento (opcional)',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary,
                    letterSpacing: 0.8,
                  ),
            ),
          ),
          // Opción sin documento
          RadioListTile<int?>(
            value: null,
            groupValue: _documentoId,
            onChanged: (v) => setState(() => _documentoId = v),
            title: const Text('Sin documento'),
            subtitle: Text(
              'La IA responde usando tu contexto general de oposición.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            dense: true,
          ),

          if (widget.documentos.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.documentos.length,
                itemBuilder: (_, i) {
                  final doc = widget.documentos[i];
                  return RadioListTile<int?>(
                    value: doc.textoDisponible ? doc.id : null,
                    groupValue: _documentoId,
                    onChanged: doc.textoDisponible
                        ? (v) => setState(() => _documentoId = v)
                        : null,
                    title: Text(
                      doc.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      doc.textoDisponible
                          ? 'Texto disponible'
                          : 'Sin texto extraído',
                      style: TextStyle(
                        fontSize: 12,
                        color: doc.textoDisponible
                            ? Colors.green.shade600
                            : Colors.grey.shade400,
                      ),
                    ),
                    dense: true,
                  );
                },
              ),
            ),

          const Divider(height: 1),

          // ── Botón crear ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () =>
                    Navigator.pop(context, (_documentoId, _modo)),
                icon: const Icon(Icons.add),
                label: const Text('Crear conversación'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

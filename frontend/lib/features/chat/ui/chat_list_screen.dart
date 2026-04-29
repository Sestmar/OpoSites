import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
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
    setState(() => _creando = true);
    try {
      final id =
          await ref.read(conversacionesListNotifierProvider.notifier).crear();
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

    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.blueGrey.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.smart_toy_outlined,
            color: Colors.blueGrey, size: 22),
      ),
      title: Text(
        conversacion.tituloDisplay,
        style: const TextStyle(fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        fecha,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
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

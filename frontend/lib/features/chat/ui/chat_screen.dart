import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/chat_mensaje.dart';
import '../data/models/conversacion_resumen.dart';
import '../providers/chat_providers.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.conversacionId});

  final int conversacionId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _cargandoContexto = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _inicializar());
  }

  @override
  void dispose() {
    // Refresca la lista al salir para que updatedAt/título queden actualizados.
    ref.read(conversacionesListNotifierProvider.notifier).refrescar();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Carga inicial ──────────────────────────────────────────────────────────

  Future<void> _inicializar() async {
    final resumen = await _obtenerResumen();
    if (!mounted || resumen == null) return;
    ref
        .read(chatNotifierProvider(widget.conversacionId).notifier)
        .cargar(resumen);
  }

  /// Busca el resumen en la lista cargada. Si la lista está vacía, la carga primero.
  Future<ConversacionResumen?> _obtenerResumen() async {
    var lista =
        ref.read(conversacionesListNotifierProvider).valueOrNull ?? [];

    if (lista.isEmpty) {
      setState(() => _cargandoContexto = true);
      await ref.read(conversacionesListNotifierProvider.notifier).cargar();
      lista = ref.read(conversacionesListNotifierProvider).valueOrNull ?? [];
      if (mounted) setState(() => _cargandoContexto = false);
    }

    try {
      return lista.firstWhere((c) => c.id == widget.conversacionId);
    } catch (_) {
      return null;
    }
  }

  // ── Envío ──────────────────────────────────────────────────────────────────

  Future<void> _enviar() async {
    final texto = _textController.text.trim();
    if (texto.isEmpty) return;
    _textController.clear();
    await ref
        .read(chatNotifierProvider(widget.conversacionId).notifier)
        .enviarMensaje(texto);
    _scrollAlFinal();
  }

  void _scrollAlFinal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Mostrar SnackBar cuando hay error de envío
    ref.listen<AsyncValue<ChatState>>(
      chatNotifierProvider(widget.conversacionId),
      (prev, next) {
        final error = next.valueOrNull?.errorUltimoMensaje;
        final prevError = prev?.valueOrNull?.errorUltimoMensaje;
        if (error != null && error != prevError && mounted) {
          final esRateLimit = next.valueOrNull?.esRateLimit ?? false;
          final notifier =
              ref.read(chatNotifierProvider(widget.conversacionId).notifier);
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              content: Text(
                esRateLimit
                    ? 'La IA está ocupada. Esperá unos segundos.'
                    : 'No se pudo enviar el mensaje.',
              ),
              duration: Duration(seconds: esRateLimit ? 6 : 4),
              action: SnackBarAction(
                label: esRateLimit ? 'Reintentar' : 'OK',
                onPressed: esRateLimit
                    ? () => notifier.reintentar()
                    : () => notifier.limpiarError(),
              ),
            ));
        }
        // Auto-scroll cuando llega un mensaje nuevo
        if (next.valueOrNull?.conversacion.mensajes.length !=
            prev?.valueOrNull?.conversacion.mensajes.length) {
          _scrollAlFinal();
        }
      },
    );

    if (_cargandoContexto) {
      return Scaffold(
        appBar: AppBar(title: const Text('Asistente IA')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final chatState = ref.watch(chatNotifierProvider(widget.conversacionId));

    return chatState.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Asistente IA')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Asistente IA')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(e.toString(), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _inicializar,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
      data: (s) => Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Asistente IA'),
              if (s.conversacion.nombreRama != null)
                Text(
                  s.conversacion.nombreRama!,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.white70),
                ),
            ],
          ),
        ),
        body: Column(
          children: [
            // ── Historial de mensajes ──────────────────────────────────────
            Expanded(
              child: s.conversacion.mensajes.isEmpty && !s.iaEscribiendo
                  ? const _EmptyChat()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      itemCount: s.conversacion.mensajes.length +
                          (s.iaEscribiendo ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (s.iaEscribiendo &&
                            i == s.conversacion.mensajes.length) {
                          return const _IaEscribiendoIndicator();
                        }
                        return _MensajeBurbuja(
                          mensaje: s.conversacion.mensajes[i],
                        );
                      },
                    ),
            ),

            // ── Input ──────────────────────────────────────────────────────
            _InputBar(
              controller: _textController,
              disabled: s.iaEscribiendo,
              onEnviar: _enviar,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Burbuja de mensaje ─────────────────────────────────────────────────────────

class _MensajeBurbuja extends StatelessWidget {
  const _MensajeBurbuja({required this.mensaje});

  final ChatMensaje mensaje;

  @override
  Widget build(BuildContext context) {
    final esUsuario = !mensaje.esIa;
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment:
          esUsuario ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: esUsuario
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(esUsuario ? 16 : 4),
            bottomRight: Radius.circular(esUsuario ? 4 : 16),
          ),
        ),
        child: Text(
          mensaje.mensaje,
          style: TextStyle(
            color: esUsuario
                ? colorScheme.onPrimary
                : colorScheme.onSurface,
            fontSize: 14.5,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

// ── Indicador "IA escribiendo…" ────────────────────────────────────────────────

class _IaEscribiendoIndicator extends StatelessWidget {
  const _IaEscribiendoIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'IA respondiendo…',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Estado vacío ───────────────────────────────────────────────────────────────

class _EmptyChat extends StatelessWidget {
  const _EmptyChat();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.smart_toy_outlined,
                size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Empezá preguntando algo\nsobre tu oposición',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade500,
                    height: 1.5,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Barra de input ─────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.disabled,
    required this.onEnviar,
  });

  final TextEditingController controller;
  final bool disabled;
  final VoidCallback onEnviar;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).dividerColor,
              width: 0.8,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !disabled,
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'Escribe tu consulta…',
                  filled: true,
                  fillColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: disabled ? null : onEnviar,
              icon: const Icon(Icons.send_rounded),
              tooltip: 'Enviar',
            ),
          ],
        ),
      ),
    );
  }
}

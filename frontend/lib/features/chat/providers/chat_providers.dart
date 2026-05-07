import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_exception.dart';
import '../../auth/providers/auth_provider.dart' show dioProvider;
import '../data/chat_repository.dart';
import '../data/models/chat_conversacion.dart';
import '../data/models/chat_mensaje.dart';
import '../data/models/conversacion_resumen.dart';
import '../data/models/enviar_mensaje_request.dart';

part 'chat_providers.g.dart';

// ── Provider de infraestructura ────────────────────────────────────────────────

@Riverpod(keepAlive: true)
ChatRepository chatRepository(ChatRepositoryRef ref) =>
    ChatRepository(dio: ref.watch(dioProvider));

// ── Estado del chat activo ─────────────────────────────────────────────────────

/// Estado interno del [ChatNotifier].
///
/// Separa la conversación (datos persistidos) del estado de UI transitorio:
/// si la IA está escribiendo y si el último envío falló.
class ChatState {
  const ChatState({
    required this.conversacion,
    this.iaEscribiendo = false,
    this.errorUltimoMensaje,
    this.esRateLimit = false,
    this.textoFallido,
  });

  final ChatConversacion conversacion;

  /// true mientras esperamos la respuesta de la IA.
  final bool iaEscribiendo;

  /// Mensaje de error del último envío fallido (null si no hubo error).
  final String? errorUltimoMensaje;

  /// true si el error fue un 429 (rate limit de Groq).
  final bool esRateLimit;

  /// Texto del mensaje que falló — usado por reintentar().
  final String? textoFallido;

  ChatState copyWith({
    ChatConversacion? conversacion,
    bool? iaEscribiendo,
    String? errorUltimoMensaje,
    bool? esRateLimit,
    String? textoFallido,
    bool clearError = false,
  }) =>
      ChatState(
        conversacion: conversacion ?? this.conversacion,
        iaEscribiendo: iaEscribiendo ?? this.iaEscribiendo,
        errorUltimoMensaje:
            clearError ? null : (errorUltimoMensaje ?? this.errorUltimoMensaje),
        esRateLimit: clearError ? false : (esRateLimit ?? this.esRateLimit),
        textoFallido: clearError ? null : (textoFallido ?? this.textoFallido),
      );
}

// ── Notifier de lista de conversaciones ───────────────────────────────────────

/// Lista de conversaciones del usuario.
///
/// ### Flujo de uso
/// ```dart
/// // Cargar al entrar a la pantalla de lista
/// ref.read(conversacionesListNotifierProvider.notifier).cargar();
///
/// // Crear nueva conversación y navegar a ella
/// final id = await ref.read(conversacionesListNotifierProvider.notifier).crear();
/// context.push(AppRoutes.chatDetalle(id));
///
/// // Eliminar desde la lista (swipe-to-delete)
/// ref.read(conversacionesListNotifierProvider.notifier).eliminar(id);
/// ```
@Riverpod(keepAlive: true)
class ConversacionesListNotifier extends _$ConversacionesListNotifier {
  @override
  AsyncValue<List<ConversacionResumen>> build() => const AsyncData([]);

  /// Carga la lista desde el servidor (reemplaza estado completo).
  Future<void> cargar() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(chatRepositoryProvider).getConversaciones(),
    );
  }

  /// Alias semántico de [cargar] — para el botón de refresh.
  Future<void> refrescar() => cargar();

  /// Crea una nueva conversación vacía, la añade al inicio de la lista
  /// y devuelve el [id] para que la UI pueda navegar a ella.
  ///
  /// Lanza [ApiException] si falla — la UI captura para SnackBar.
  Future<int> crear() async {
    final resumen = await ref.read(chatRepositoryProvider).crearConversacion();
    final current = state.valueOrNull ?? [];
    state = AsyncData([resumen, ...current]);
    return resumen.id;
  }

  /// Elimina la conversación [id] del servidor y de la lista local.
  ///
  /// Lanza [ApiException] si falla — la UI captura para SnackBar.
  Future<void> eliminar(int id) async {
    await ref.read(chatRepositoryProvider).eliminarConversacion(id);
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.where((c) => c.id != id).toList());
  }
}

// ── Notifier de chat activo (familia por conversacionId) ──────────────────────

/// Estado completo de una conversación activa, incluyendo mensajes y flags de UI.
///
/// ### Flujo de uso
/// ```dart
/// // 1. Cargar al entrar al chat
/// ref.read(chatNotifierProvider(id).notifier).cargar(resumen);
///
/// // 2. Leer estado reactivo
/// final chatState = ref.watch(chatNotifierProvider(id));
/// chatState.when(
///   data: (s) {
///     final mensajes  = s.conversacion.mensajes;
///     final escribiendo = s.iaEscribiendo;
///     final error       = s.errorUltimoMensaje;
///   },
///   loading: (_) => CircularProgressIndicator(),
///   error: (e, _) => Text('$e'),
/// );
///
/// // 3. Enviar mensaje (el resultado se refleja automáticamente en el estado)
/// await ref.read(chatNotifierProvider(id).notifier).enviarMensaje('¿Qué es la OPE?');
/// ```
@Riverpod(keepAlive: true)
class ChatNotifier extends _$ChatNotifier {
  @override
  AsyncValue<ChatState> build(int conversacionId) => const AsyncLoading();

  /// Carga el historial de mensajes de la conversación.
  ///
  /// Recibe el [resumen] ya disponible en la lista para evitar un GET adicional.
  Future<void> cargar(ConversacionResumen resumen) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final mensajes = await ref
          .read(chatRepositoryProvider)
          .getMensajes(conversacionId);
      return ChatState(
        conversacion: ChatConversacion.fromResumen(resumen, mensajes),
      );
    });
  }

  /// Envía un mensaje del usuario con actualización optimista.
  ///
  /// 1. Añade el mensaje del usuario a la lista local inmediatamente.
  /// 2. Activa [iaEscribiendo] = true.
  /// 3. Llama al backend (síncrono: Gemini responde en el mismo POST).
  /// 4. Añade la respuesta de la IA y desactiva [iaEscribiendo].
  ///
  /// Si falla, revierte el mensaje del usuario y guarda el error en
  /// [errorUltimoMensaje] para que la UI lo muestre sin perder el historial.
  Future<void> enviarMensaje(String texto) async {
    final current = state.valueOrNull;
    if (current == null || current.iaEscribiendo) return;

    // Mensaje optimista del usuario (id=-1, se descarta si hay error)
    final mensajeUsuario = ChatMensaje(
      id: -1,
      esIa: false,
      mensaje: texto,
      createdAt: DateTime.now(),
    );

    // 1. Actualización optimista + flag de escritura
    final mensajesConUsuario = [
      ...current.conversacion.mensajes,
      mensajeUsuario,
    ];
    state = AsyncData(current.copyWith(
      conversacion: current.conversacion.copyWith(mensajes: mensajesConUsuario),
      iaEscribiendo: true,
      clearError: true,
    ));

    try {
      // 2. Llamada al backend
      final mensajeIa = await ref.read(chatRepositoryProvider).enviarMensaje(
            conversacionId: conversacionId,
            request: EnviarMensajeRequest(mensaje: texto),
          );

      // 3. Añadir respuesta de la IA
      final stateActual = state.valueOrNull;
      if (stateActual == null) return;

      state = AsyncData(stateActual.copyWith(
        conversacion: stateActual.conversacion.copyWith(
          mensajes: [...stateActual.conversacion.mensajes, mensajeIa],
        ),
        iaEscribiendo: false,
        clearError: true,
      ));
    } catch (e) {
      // 4. Revertir mensaje optimista y guardar error
      final stateActual = state.valueOrNull;
      if (stateActual == null) return;

      final mensajesSinOptimista = stateActual.conversacion.mensajes
          .where((m) => m.id != -1)
          .toList();
      final esRateLimit = e is RateLimitException;

      state = AsyncData(stateActual.copyWith(
        conversacion: stateActual.conversacion
            .copyWith(mensajes: mensajesSinOptimista),
        iaEscribiendo: false,
        errorUltimoMensaje:
            e is ApiException ? e.message : 'Ocurrió un error inesperado.',
        esRateLimit: esRateLimit,
        textoFallido: esRateLimit ? texto : null,
      ));
    }
  }

  /// Reenvía el último mensaje que falló por rate limit.
  Future<void> reintentar() async {
    final current = state.valueOrNull;
    final texto = current?.textoFallido;
    if (texto == null) return;
    state = AsyncData(current!.copyWith(clearError: true));
    await enviarMensaje(texto);
  }

  /// Limpia el error del último mensaje fallido.
  void limpiarError() {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(clearError: true));
  }
}

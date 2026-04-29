// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$chatRepositoryHash() => r'30fe6d71b82227efcd5e574008d29ae82808c99d';

/// See also [chatRepository].
@ProviderFor(chatRepository)
final chatRepositoryProvider = Provider<ChatRepository>.internal(
  chatRepository,
  name: r'chatRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$chatRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ChatRepositoryRef = ProviderRef<ChatRepository>;
String _$conversacionesListNotifierHash() =>
    r'd323d060ead2c15197d74561dc71e5349532f07f';

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
///
/// Copied from [ConversacionesListNotifier].
@ProviderFor(ConversacionesListNotifier)
final conversacionesListNotifierProvider = NotifierProvider<
    ConversacionesListNotifier, AsyncValue<List<ConversacionResumen>>>.internal(
  ConversacionesListNotifier.new,
  name: r'conversacionesListNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$conversacionesListNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ConversacionesListNotifier
    = Notifier<AsyncValue<List<ConversacionResumen>>>;
String _$chatNotifierHash() => r'580e6294abf90e57d3a295fa1654880bf58da09b';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$ChatNotifier extends BuildlessNotifier<AsyncValue<ChatState>> {
  late final int conversacionId;

  AsyncValue<ChatState> build(
    int conversacionId,
  );
}

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
///
/// Copied from [ChatNotifier].
@ProviderFor(ChatNotifier)
const chatNotifierProvider = ChatNotifierFamily();

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
///
/// Copied from [ChatNotifier].
class ChatNotifierFamily extends Family<AsyncValue<ChatState>> {
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
  ///
  /// Copied from [ChatNotifier].
  const ChatNotifierFamily();

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
  ///
  /// Copied from [ChatNotifier].
  ChatNotifierProvider call(
    int conversacionId,
  ) {
    return ChatNotifierProvider(
      conversacionId,
    );
  }

  @override
  ChatNotifierProvider getProviderOverride(
    covariant ChatNotifierProvider provider,
  ) {
    return call(
      provider.conversacionId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'chatNotifierProvider';
}

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
///
/// Copied from [ChatNotifier].
class ChatNotifierProvider
    extends NotifierProviderImpl<ChatNotifier, AsyncValue<ChatState>> {
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
  ///
  /// Copied from [ChatNotifier].
  ChatNotifierProvider(
    int conversacionId,
  ) : this._internal(
          () => ChatNotifier()..conversacionId = conversacionId,
          from: chatNotifierProvider,
          name: r'chatNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$chatNotifierHash,
          dependencies: ChatNotifierFamily._dependencies,
          allTransitiveDependencies:
              ChatNotifierFamily._allTransitiveDependencies,
          conversacionId: conversacionId,
        );

  ChatNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.conversacionId,
  }) : super.internal();

  final int conversacionId;

  @override
  AsyncValue<ChatState> runNotifierBuild(
    covariant ChatNotifier notifier,
  ) {
    return notifier.build(
      conversacionId,
    );
  }

  @override
  Override overrideWith(ChatNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: ChatNotifierProvider._internal(
        () => create()..conversacionId = conversacionId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        conversacionId: conversacionId,
      ),
    );
  }

  @override
  NotifierProviderElement<ChatNotifier, AsyncValue<ChatState>> createElement() {
    return _ChatNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ChatNotifierProvider &&
        other.conversacionId == conversacionId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, conversacionId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ChatNotifierRef on NotifierProviderRef<AsyncValue<ChatState>> {
  /// The parameter `conversacionId` of this provider.
  int get conversacionId;
}

class _ChatNotifierProviderElement
    extends NotifierProviderElement<ChatNotifier, AsyncValue<ChatState>>
    with ChatNotifierRef {
  _ChatNotifierProviderElement(super.provider);

  @override
  int get conversacionId => (origin as ChatNotifierProvider).conversacionId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

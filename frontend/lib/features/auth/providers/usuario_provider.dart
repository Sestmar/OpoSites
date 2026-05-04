import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/usuario_me.dart';
import 'auth_provider.dart';

/// Perfil completo del usuario autenticado.
///
/// Usa el endpoint existente GET /api/v1/auth/me — sin nuevo contrato de backend.
/// keepAlive por defecto (FutureProvider sin autoDispose en Riverpod 2.x).
///
/// Invalidar con [ref.invalidate(currentUserProvider)] tras actualizar el perfil.
final currentUserProvider = FutureProvider<UsuarioMe>((ref) {
  return ref.read(authRepositoryProvider).getMe();
});

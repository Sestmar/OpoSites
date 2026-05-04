import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../auth/data/models/usuario_me.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/perfil_repository.dart';

final perfilRepositoryProvider = Provider<PerfilRepository>(
  (ref) => PerfilRepository(dio: ref.watch(dioProvider)),
);

/// Perfil del usuario autenticado. Se invalida tras editar o cambiar de rama.
final perfilProvider = FutureProvider.autoDispose<UsuarioMe>(
  (ref) => ref.read(perfilRepositoryProvider).getMe(),
);

// ── Notifier con acciones (upload foto, updateMe) ─────────────────────────────

class PerfilNotifier extends AutoDisposeAsyncNotifier<UsuarioMe> {
  @override
  Future<UsuarioMe> build() => ref.read(perfilRepositoryProvider).getMe();

  Future<void> uploadFoto(XFile foto) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(perfilRepositoryProvider).uploadFoto(foto),
    );
  }

  Future<void> updateMe({
    String? nombre,
    String? ciudad,
    String? fechaExamenObjetivo,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(perfilRepositoryProvider).updateMe(
            nombre: nombre,
            ciudad: ciudad,
            fechaExamenObjetivo: fechaExamenObjetivo,
          ),
    );
  }

  Future<void> deleteAccount() async {
    state = const AsyncLoading();
    await AsyncValue.guard(
      () => ref.read(perfilRepositoryProvider).deleteMe(),
    );
  }
}

final perfilNotifierProvider =
    AutoDisposeAsyncNotifierProvider<PerfilNotifier, UsuarioMe>(
  PerfilNotifier.new,
);

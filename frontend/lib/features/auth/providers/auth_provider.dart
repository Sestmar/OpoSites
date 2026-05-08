import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/storage/secure_storage.dart';
import '../data/auth_repository.dart';
import '../../noticias/providers/noticias_provider.dart';
import '../../plan/providers/plan_semana_provider.dart';

part 'auth_provider.g.dart';

// ── Providers de infraestructura ───────────────────────────────────────────────
//
// Declarados aquí porque son los únicos consumidores por ahora.
// Cuando aparezcan más repositorios se mueven a lib/core/providers/.

@Riverpod(keepAlive: true)
SecureStorage secureStorage(SecureStorageRef ref) => SecureStorage();

@Riverpod(keepAlive: true)
Dio dio(DioRef ref) => ApiClient.create(ref.watch(secureStorageProvider));

@Riverpod(keepAlive: true)
AuthRepository authRepository(AuthRepositoryRef ref) => AuthRepository(
      dio: ref.watch(dioProvider),
      storage: ref.watch(secureStorageProvider),
    );

// ── Estado ─────────────────────────────────────────────────────────────────────

/// Estado de la sesión del usuario.
///
/// El compilador fuerza exhaustividad en los `switch` al ser `sealed`.
sealed class AuthState {
  const AuthState();
}

/// Estado inicial: todavía no se intentó restaurar la sesión.
/// El Splash screen espera aquí hasta que [Auth._restoreSession] termine.
final class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Operación asíncrona en curso: login, register, logout o restore.
final class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Sesión activa. El accessToken está en [SecureStorage].
///
/// [ramaPrincipalId] es null cuando el usuario aún no eligió su oposición
/// y debe pasar por el onboarding. Cualquier otro valor (incluido -1 cuando
/// no se pudo verificar por red) significa que ya tiene rama asignada.
final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated({this.ramaPrincipalId});
  final int? ramaPrincipalId;
}

/// Sin sesión. El usuario debe ir a Login o Register.
final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Error al hacer login o register. [message] viene del backend o de red.
final class AuthError extends AuthState {
  const AuthError(this.message);
  final String message;
}

// ── Notifier ───────────────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
class Auth extends _$Auth {
  @override
  AuthState build() {
    // Restauramos la sesión en el próximo microtask para no bloquear el build.
    // El estado arranca en [AuthInitial] mientras tanto — el Splash lo muestra.
    Future.microtask(_restoreSession);
    return const AuthInitial();
  }

  // ── Restauración de sesión ─────────────────────────────────────────────────

  /// Verifica si hay tokens guardados en SecureStorage.
  ///
  /// No valida el token contra el servidor: si está vencido, [AuthInterceptor]
  /// hará el refresh automáticamente en la primera request real.
  /// Si el refresh también falla, [AuthInterceptor] limpiará los tokens
  /// y la app deberá manejar el [UnauthorizedException] yendo a Login.
  Future<void> _restoreSession() async {
    state = const AuthLoading();
    final storage = ref.read(secureStorageProvider);
    final hasTokens = await storage.hasTokens();
    if (!hasTokens) {
      state = const AuthUnauthenticated();
      return;
    }
    try {
      final me = await ref.read(authRepositoryProvider).getMe();
      state = AuthAuthenticated(ramaPrincipalId: me.ramaPrincipalId);
    } catch (_) {
      // Sin red en el arranque: dejamos pasar al home (evita bloquear al usuario)
      state = const AuthAuthenticated(ramaPrincipalId: -1);
    }
  }

  // ── Acciones públicas ──────────────────────────────────────────────────────

  /// Inicia sesión con email y contraseña.
  ///
  /// En éxito guarda los tokens y transiciona a [AuthAuthenticated].
  /// En error transiciona a [AuthError] con el mensaje del servidor.
  Future<void> login({required String email, required String password}) async {
    state = const AuthLoading();
    try {
      final response = await ref
          .read(authRepositoryProvider)
          .login(email: email, password: password);
      await ref.read(secureStorageProvider).saveTokens(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
          );
      final me = await ref.read(authRepositoryProvider).getMe();
      state = AuthAuthenticated(ramaPrincipalId: me.ramaPrincipalId);
    } on ApiException catch (e) {
      state = AuthError(e.message);
    }
  }

  /// Crea una cuenta nueva.
  ///
  /// En éxito guarda los tokens (el backend hace auto-login) y transiciona
  /// a [AuthAuthenticated].
  Future<void> register({
    required String email,
    required String password,
    required String nombre,
    String? ciudad,
  }) async {
    state = const AuthLoading();
    try {
      final response = await ref.read(authRepositoryProvider).register(
            email: email,
            password: password,
            nombre: nombre,
            ciudad: ciudad,
          );
      await ref.read(secureStorageProvider).saveTokens(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
          );
      final me = await ref.read(authRepositoryProvider).getMe();
      state = AuthAuthenticated(ramaPrincipalId: me.ramaPrincipalId);
    } on ApiException catch (e) {
      state = AuthError(e.message);
    }
  }

  /// Cierra sesión: revoca el refresh token en el servidor y limpia el storage.
  /// Siempre transiciona a [AuthUnauthenticated] aunque el servidor falle
  /// (ver [AuthRepository.logout]).
  Future<void> logout() async {
    state = const AuthLoading();
    await ref.read(authRepositoryProvider).logout();
    // Invalidar providers con keepAlive que acumulan datos del usuario saliente.
    ref.invalidate(planSemanaProvider);
    ref.invalidate(noticiasListNotifierProvider);
    ref.invalidate(noticiaConteosProvider);
    state = const AuthUnauthenticated();
  }

  /// Llamado desde [SelectOposicionScreen] después de que el usuario elige rama.
  /// Actualiza el estado para que el router redirija al home.
  void ramaSelected(int ramaId) {
    state = AuthAuthenticated(ramaPrincipalId: ramaId);
  }

  /// Inicia sesión con Google.
  ///
  /// Obtiene el idToken de Google Sign-In y lo envía al backend /auth/google.
  /// En éxito guarda los tokens y transiciona a [AuthAuthenticated].
  /// En error (usuario cancela o falla la red) transiciona a [AuthError].
  Future<void> loginWithGoogle() async {
    state = const AuthLoading();
    try {
      final googleUser = await GoogleSignIn(
        serverClientId:
            '473420233111-1suhv1oaa0oodikcrt3mpgafg4dnhfic.apps.googleusercontent.com',
      ).signIn();
      if (googleUser == null) {
        // El usuario canceló el selector de cuentas
        state = const AuthUnauthenticated();
        return;
      }
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        state = const AuthError('No se pudo obtener el token de Google.');
        return;
      }
      final response =
          await ref.read(authRepositoryProvider).loginWithGoogle(idToken);
      await ref.read(secureStorageProvider).saveTokens(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
          );
      final me = await ref.read(authRepositoryProvider).getMe();
      state = AuthAuthenticated(ramaPrincipalId: me.ramaPrincipalId);
    } on ApiException catch (e) {
      state = AuthError(e.message);
    } catch (_) {
      state = const AuthError('No se pudo iniciar sesión con Google.');
    }
  }

  /// Limpia el error para que la UI pueda mostrar el formulario de nuevo.
  void clearError() {
    if (state is AuthError) state = const AuthUnauthenticated();
  }
}

import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/storage/secure_storage.dart';
import 'models/auth_response.dart';
import 'models/login_request.dart';
import 'models/register_request.dart';

/// Único punto de acceso a los endpoints /auth/**.
///
/// Convierte [DioException] → [ApiException] para que las capas superiores
/// (providers, UI) no dependan de Dio y puedan hacer pattern matching limpio.
///
/// Regla de logout: siempre limpia tokens locales aunque el servidor falle.
class AuthRepository {
  const AuthRepository({
    required Dio dio,
    required SecureStorage storage,
  })  : _dio = dio,
        _storage = storage;

  final Dio _dio;
  final SecureStorage _storage;

  // ── Endpoints ─────────────────────────────────────────────────────────────

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) =>
      _authCall(
        () => _dio.post<Map<String, dynamic>>(
          ApiEndpoints.login,
          data: LoginRequest(email: email, password: password).toJson(),
        ),
      );

  Future<AuthResponse> register({
    required String email,
    required String password,
    required String nombre,
    String? ciudad,
  }) =>
      _authCall(
        () => _dio.post<Map<String, dynamic>>(
          ApiEndpoints.register,
          data: RegisterRequest(
            email: email,
            password: password,
            nombre: nombre,
            ciudad: ciudad,
          ).toJson(),
        ),
      );

  /// [idToken] es el ID token de Google obtenido desde el cliente Flutter
  /// con el paquete google_sign_in.
  Future<AuthResponse> loginWithGoogle(String idToken) =>
      _authCall(
        () => _dio.post<Map<String, dynamic>>(
          ApiEndpoints.loginGoogle,
          data: {'idToken': idToken},
        ),
      );

  Future<AuthResponse> refresh(String refreshToken) =>
      _authCall(
        () => _dio.post<Map<String, dynamic>>(
          ApiEndpoints.refresh,
          data: {'refreshToken': refreshToken},
        ),
      );

  /// Revoca el refresh token en el servidor y limpia el almacenamiento local.
  /// Garantiza limpieza local aunque el servidor no responda.
  Future<void> logout() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken != null) {
      try {
        await _dio.post<void>(
          ApiEndpoints.logout,
          data: {'refreshToken': refreshToken},
        );
      } on DioException {
        // Si el servidor falla, seguimos limpiando localmente
      }
    }
    await _storage.clearTokens();
  }

  // ── Helper ────────────────────────────────────────────────────────────────

  /// Ejecuta [call], parsea la respuesta como [AuthResponse]
  /// y convierte cualquier [DioException] en [ApiException].
  Future<AuthResponse> _authCall(
    Future<Response<Map<String, dynamic>>> Function() call,
  ) async {
    try {
      final response = await call();
      return AuthResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw _toApiException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  ApiException _toApiException(DioException e) {
    // Errores de red / timeout
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return const RequestTimeoutException();
    }
    if (e.type == DioExceptionType.connectionError) {
      return const NetworkException();
    }

    // Errores HTTP con respuesta del servidor
    final code = e.response?.statusCode;
    final data = e.response?.data;
    final message = (data is Map)
        ? (data['message'] as String? ?? data['error'] as String? ?? 'Error desconocido')
        : 'Error desconocido';

    return switch (code) {
      400 => ValidationException(message),
      401 => const UnauthorizedException(),
      403 => const ForbiddenException(),
      404 => NotFoundException(message),
      _   => ServerException(message, code),
    };
  }
}

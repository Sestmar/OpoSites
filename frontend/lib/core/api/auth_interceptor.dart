import 'package:dio/dio.dart';

import '../constants/api_endpoints.dart';
import '../storage/secure_storage.dart';
import '../../features/auth/data/models/auth_response.dart';

/// Interceptor de Dio que gestiona el ciclo de vida del JWT.
///
/// onRequest → adjunta 'Authorization: Bearer <accessToken>' a toda request.
/// onError   → si recibe 401, intenta renovar el token con /auth/refresh
///             y reintenta la request original de forma transparente.
///             Si el refresh falla, limpia los tokens locales.
///
/// El _refreshDio interno es una instancia SIN este interceptor para evitar
/// un bucle infinito al llamar a /auth/refresh.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.storage, required this.mainDio})
      : _refreshDio = Dio(
          BaseOptions(
            baseUrl: ApiEndpoints.baseUrl,
            connectTimeout: const Duration(seconds: 40),
            receiveTimeout: const Duration(seconds: 40),
            headers: {'Content-Type': 'application/json'},
          ),
        );

  final SecureStorage storage;

  /// Instancia principal — usada para reintenter la request original.
  final Dio mainDio;

  /// Instancia sin interceptores — usada exclusivamente para /auth/refresh.
  final Dio _refreshDio;

  /// Evita refrescar simultáneamente si varias requests fallan con 401 a la vez.
  bool _isRefreshing = false;

  // ── onRequest ─────────────────────────────────────────────────────────────

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await storage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  // ── onError ───────────────────────────────────────────────────────────────

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final is401 = err.response?.statusCode == 401;
    final isRefreshCall = err.requestOptions.path == ApiEndpoints.refresh;

    // Solo intervenir en 401 y si no es la propia llamada de refresh
    if (!is401 || isRefreshCall) {
      handler.next(err);
      return;
    }

    // Si ya hay un refresh en curso, rechazar esta request directamente.
    // El usuario verá un error y podrá reintentar — aceptable en un MVP.
    if (_isRefreshing) {
      handler.next(err);
      return;
    }

    _isRefreshing = true;

    try {
      final refreshToken = await storage.getRefreshToken();

      if (refreshToken == null) {
        // Sin refresh token: sesión perdida, no hay nada que hacer
        await storage.clearTokens();
        handler.next(err);
        return;
      }

      // Llamar a /auth/refresh con la instancia sin interceptores
      final authResponse = await _doRefresh(refreshToken);

      // Persiste los tokens nuevos
      await storage.saveTokens(
        accessToken: authResponse.accessToken,
        refreshToken: authResponse.refreshToken,
      );

      // Reintenta la request original — onRequest leerá el nuevo token de storage
      final retryResponse = await mainDio.fetch<dynamic>(err.requestOptions);
      handler.resolve(retryResponse);
    } catch (_) {
      // Refresh fallido: limpiar tokens y propagar el 401 original.
      // El authProvider (bloque 3) detectará el UnauthorizedException y redirigirá a Login.
      await storage.clearTokens();
      handler.next(err);
    } finally {
      _isRefreshing = false;
    }
  }

  // ── Helper interno ────────────────────────────────────────────────────────

  Future<AuthResponse> _doRefresh(String refreshToken) async {
    final response = await _refreshDio.post<Map<String, dynamic>>(
      ApiEndpoints.refresh,
      data: {'refreshToken': refreshToken},
    );
    return AuthResponse.fromJson(response.data!);
  }
}

import 'package:dio/dio.dart';

import '../constants/api_endpoints.dart';
import '../storage/secure_storage.dart';
import 'auth_interceptor.dart';

/// Factoría del cliente HTTP de opoSites.
///
/// Uso:
/// ```dart
/// final storage = SecureStorage();
/// final dio     = ApiClient.create(storage);
/// ```
///
/// El [Dio] resultante:
///   - Apunta a [ApiEndpoints.baseUrl].
///   - Adjunta el JWT automáticamente (vía [AuthInterceptor]).
///   - Renueva el JWT en caso de 401 (auto-refresh transparente).
///   - En modo debug loguea requests y responses en consola.
abstract final class ApiClient {
  /// Crea y configura la instancia de [Dio].
  ///
  /// Inyectar [storage] permite testearlo sin tocar almacenamiento real.
  static Dio create(SecureStorage storage) {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 40),
        // 30 s para dar margen a respuestas lentas de Gemini IA
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
        // Dio lanza DioException en 4xx/5xx por defecto — lo queremos así
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    dio.interceptors.add(
      AuthInterceptor(storage: storage, mainDio: dio),
    );

    // LogInterceptor solo en debug builds — sin impacto en producción
    assert(() {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: false, // evitar loguear el token JWT
          logPrint: (obj) => print('[HTTP] $obj'), // ignore: avoid_print
        ),
      );
      return true;
    }());

    return dio;
  }
}

/// Jerarquía de errores tipados de la API.
///
/// Al ser `sealed`, el compilador fuerza exhaustividad en los switch:
///
/// ```dart
/// switch (e) {
///   case NetworkException()  => mostrar 'Sin conexión',
///   case UnauthorizedException() => ir a Login,
///   case ValidationException(:final message) => mostrar message,
///   // ...
/// }
/// ```
sealed class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => 'ApiException(${runtimeType}): $message';
}

/// Sin conexión a internet o el servidor no es alcanzable.
final class NetworkException extends ApiException {
  const NetworkException()
      : super('Sin conexión. Verificá tu conexión a internet.');
}

/// La request superó el tiempo de espera máximo.
/// Nota: clase distinta de dart:async TimeoutException — no importar ambas.
final class RequestTimeoutException extends ApiException {
  const RequestTimeoutException()
      : super('La solicitud tardó demasiado. Intentalo de nuevo.');
}

/// 400 — el backend rechazó los datos enviados (@Valid fallido).
/// [message] contiene el mensaje de validación del servidor.
final class ValidationException extends ApiException {
  const ValidationException(super.message);
}

/// 401 — sesión expirada o token inválido, incluso tras intentar refresh.
/// La app debe redirigir a Login y limpiar los tokens locales.
final class UnauthorizedException extends ApiException {
  const UnauthorizedException()
      : super('Tu sesión expiró. Iniciá sesión nuevamente.');
}

/// 403 — el usuario autenticado no tiene permisos para este recurso.
final class ForbiddenException extends ApiException {
  const ForbiddenException()
      : super('No tenés permisos para realizar esta acción.');
}

/// 404 — recurso no encontrado.
final class NotFoundException extends ApiException {
  const NotFoundException([super.message = 'Recurso no encontrado.']);
}

/// 429 — límite de requests al servicio de IA. Reintentar en unos segundos.
final class RateLimitException extends ApiException {
  const RateLimitException([
    super.message = 'La IA está ocupada. Esperá unos segundos y volvé a intentarlo.',
  ]);
}

/// 5xx — error interno del servidor.
final class ServerException extends ApiException {
  const ServerException([
    super.message = 'Error del servidor. Intentalo más tarde.',
    this.statusCode,
  ]);

  final int? statusCode;
}

/// Error no clasificado (excepción inesperada, JSON malformado, etc.).
final class UnknownException extends ApiException {
  const UnknownException([super.message = 'Ocurrió un error inesperado.']);
}

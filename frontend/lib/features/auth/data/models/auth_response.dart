import 'package:json_annotation/json_annotation.dart';

part 'auth_response.g.dart';

/// Respuesta del backend para cualquier operación de autenticación exitosa.
/// Usado en: /auth/login, /auth/register, /auth/google, /auth/refresh.
@JsonSerializable()
class AuthResponse {
  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
  });

  final String accessToken;
  final String refreshToken;

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}

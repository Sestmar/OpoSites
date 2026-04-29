import 'package:json_annotation/json_annotation.dart';

part 'register_request.g.dart';

/// Body para POST /auth/register.
/// [ciudad] es opcional — el backend lo acepta como null.
@JsonSerializable(includeIfNull: false)
class RegisterRequest {
  const RegisterRequest({
    required this.email,
    required this.password,
    required this.nombre,
    this.ciudad,
  });

  final String email;
  final String password;
  final String nombre;
  final String? ciudad;

  Map<String, dynamic> toJson() => _$RegisterRequestToJson(this);
}

import 'package:json_annotation/json_annotation.dart';

part 'login_request.g.dart';

/// Body para POST /auth/login.
@JsonSerializable(includeIfNull: false)
class LoginRequest {
  const LoginRequest({required this.email, required this.password});

  final String email;
  final String password;

  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);
}

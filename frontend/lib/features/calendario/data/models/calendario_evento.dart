import 'package:json_annotation/json_annotation.dart';

part 'calendario_evento.g.dart';

// ── Enum ───────────────────────────────────────────────────────────────────────

/// Espejo de TipoEvento.java.
///
/// - ESTUDIO     → evento de sesión de estudio (auto-generado por el plan).
/// - SIMULACRO   → simulacro completado (auto-generado).
/// - CONVOCATORIA → fecha oficial de convocatoria/examen (auto-generado).
/// - MANUAL      → evento creado manualmente por el usuario.
///
/// Solo los eventos de tipo MANUAL (y autoGenerado=false) pueden
/// editarse o eliminarse.
@JsonEnum()
enum TipoEvento { estudio, simulacro, convocatoria, manual }

// ── Modelo de respuesta ────────────────────────────────────────────────────────

/// Espejo de EventoResponse.java.
///
/// Evento del calendario personal del usuario:
///   GET /api/v1/calendario/eventos?desde=&hasta=&tipo=
///
/// [fechaInicio] y [fechaFin] vienen como ISO 8601: "2026-04-29T10:00:00".
/// [autoGenerado] true → solo lectura; false → editable/eliminable.
/// [ramaId] y [nombreRama] presentes si el evento está ligado a una oposición.
@JsonSerializable()
class CalendarioEvento {
  const CalendarioEvento({
    required this.id,
    required this.titulo,
    required this.fechaInicio,
    required this.tipo,
    required this.autoGenerado,
    this.descripcion,
    this.fechaFin,
    this.ramaId,
    this.nombreRama,
  });

  final int id;
  final String titulo;
  final String? descripcion;

  /// Fecha/hora de inicio en ISO 8601: "2026-04-29T10:00:00".
  final String fechaInicio;

  /// Fecha/hora de fin en ISO 8601. Null si el evento es puntual.
  final String? fechaFin;

  final TipoEvento tipo;
  final int? ramaId;
  final String? nombreRama;

  /// true → creado por el sistema (plan, simulacro, convocatoria). Solo lectura.
  /// false → creado manualmente por el usuario. Editable y eliminable.
  final bool autoGenerado;

  factory CalendarioEvento.fromJson(Map<String, dynamic> json) =>
      _$CalendarioEventoFromJson(json);

  Map<String, dynamic> toJson() => _$CalendarioEventoToJson(this);
}

// ── Requests ───────────────────────────────────────────────────────────────────

/// Request para POST /api/v1/calendario/eventos.
///
/// [titulo] y [fechaInicio] son obligatorios (validados en el servidor).
/// [fechaInicio] y [fechaFin] deben pasarse como ISO 8601 sin zona horaria:
///   "2026-04-29T10:00:00"
/// [ramaId] null → evento no ligado a ninguna oposición.
/// [tipo] debería ser siempre [TipoEvento.manual] para eventos creados por el usuario.
@JsonSerializable(includeIfNull: false)
class CreateEventoRequest {
  const CreateEventoRequest({
    required this.titulo,
    required this.fechaInicio,
    required this.tipo,
    this.descripcion,
    this.fechaFin,
    this.ramaId,
  });

  final String titulo;
  final String? descripcion;

  /// ISO 8601 sin zona: "2026-04-29T10:00:00".
  final String fechaInicio;

  /// ISO 8601 sin zona. Null para evento puntual.
  final String? fechaFin;

  final TipoEvento tipo;
  final int? ramaId;

  Map<String, dynamic> toJson() => _$CreateEventoRequestToJson(this);
}

/// Request para PUT /api/v1/calendario/eventos/{id}.
///
/// Todos los campos son opcionales — solo se envían los que cambian
/// gracias a [includeIfNull: false].
/// Solo aplicable a eventos con [CalendarioEvento.autoGenerado] == false.
@JsonSerializable(includeIfNull: false)
class UpdateEventoRequest {
  const UpdateEventoRequest({
    this.titulo,
    this.descripcion,
    this.fechaInicio,
    this.fechaFin,
  });

  final String? titulo;
  final String? descripcion;

  /// ISO 8601 sin zona: "2026-04-29T10:00:00". Null = no modificar.
  final String? fechaInicio;

  /// ISO 8601 sin zona. Null = no modificar.
  final String? fechaFin;

  Map<String, dynamic> toJson() => _$UpdateEventoRequestToJson(this);
}

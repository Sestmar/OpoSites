import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Escala tipográfica de opoSites — Plus Jakarta Sans.
///
/// Todos los métodos devuelven un [TextStyle] base sin color,
/// para que el widget aplique el color del token correspondiente.
abstract final class AppText {
  /// 28px w700 — Greeting H1, pantallas de resultado.
  static TextStyle get display => GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.7,
        height: 1.1,
      );

  /// 22px w700 — Números grandes (racha, stats).
  static TextStyle get h2 => GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        height: 1.15,
      );

  /// 15px w600 — Títulos de tarjeta, secciones.
  static TextStyle get cardTitle => GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.25,
      );

  /// 13.5px w500 — Texto general.
  static TextStyle get body => GoogleFonts.plusJakartaSans(
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.1,
        height: 1.3,
      );

  /// 12px w500 — Subtítulos, meta-info dentro de cards.
  static TextStyle get bodySmall => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.35,
      );

  /// 11px w500 — Horarios, captions, metadatos.
  static TextStyle get caption => GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.4,
      );

  /// 10.5px w600 uppercase — Chips, headers de sección.
  static TextStyle get label => GoogleFonts.plusJakartaSans(
        fontSize: 10.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        height: 1,
      );
}

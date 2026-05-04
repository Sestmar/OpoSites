import 'package:flutter/material.dart';

/// Paleta de tokens de color de opoSites.
///
/// Dark-first. Los widgets usan estos tokens directamente en lugar de depender
/// solo del [ColorScheme] de Material, para tener control total sobre
/// superficies, bordes y acentos custom (warm, mint, rose).
abstract final class AppColors {
  // ── Dark — superficies ────────────────────────────────────────────────────
  static const darkBg           = Color(0xFF080D0D);
  static const darkSurface      = Color(0xFF0F1A19);
  static const darkSurfaceMuted = Color(0xFF162120);
  static const darkBorder       = Color(0x12FFFFFF); // rgba(255,255,255,0.07)
  static const darkBorderStrong = Color(0x1FFFFFFF); // rgba(255,255,255,0.12)

  // ── Dark — texto ──────────────────────────────────────────────────────────
  static const darkText      = Color(0xFFF0F4F4);
  static const darkTextMuted = Color(0xFF8EA8A5);
  static const darkTextFaint = Color(0xFF536662);

  // ── Light — superficies ───────────────────────────────────────────────────
  static const lightBg           = Color(0xFFF4F7F7);
  static const lightSurface      = Color(0xFFFFFFFF);
  static const lightSurfaceMuted = Color(0xFFEBF1F0);
  static const lightBorder       = Color(0x140F1F1E); // rgba(15,31,30,0.08)
  static const lightBorderStrong = Color(0x240F1F1E); // rgba(15,31,30,0.14)

  // ── Light — texto ─────────────────────────────────────────────────────────
  static const lightText      = Color(0xFF0B1614);
  static const lightTextMuted = Color(0xFF4A6562);
  static const lightTextFaint = Color(0xFF7A9693);

  // ── Primary — teal ───────────────────────────────────────────────────────
  static const primary          = Color(0xFF14B8A6);
  static const primaryDark      = Color(0xFF2DD4C4); // +luminosidad en dark
  static const primaryStrong    = Color(0xFF0D9488);
  static const primarySoftLight = Color(0xFFE6F7F5);
  static const primarySoftDark  = Color(0x2414B8A6); // ~14% opacity

  // ── Accent warm — ámbar (racha, logros) ──────────────────────────────────
  static const accentWarm          = Color(0xFFF59E0B);
  static const accentWarmSoftLight = Color(0xFFFEF3C7);
  static const accentWarmSoftDark  = Color(0x1FF59E0B);

  // ── Accent mint — verde (aciertos, completado) ───────────────────────────
  static const accentMint          = Color(0xFF10B981);
  static const accentMintSoftLight = Color(0xFFD1FAE5);
  static const accentMintSoftDark  = Color(0x1F10B981);

  // ── Accent rose — coral (alertas, días críticos) ─────────────────────────
  static const accentRose          = Color(0xFFFB7185);
  static const accentRoseSoftLight = Color(0xFFFFE4E8);
  static const accentRoseSoftDark  = Color(0x1FFB7185);

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Devuelve el token [primary] adaptado al brightness actual.
  static Color primaryFor(Brightness b) =>
      b == Brightness.dark ? primaryDark : primary;

  /// Devuelve el [primarySoft] adaptado al brightness actual.
  static Color primarySoftFor(Brightness b) =>
      b == Brightness.dark ? primarySoftDark : primarySoftLight;

  /// Superficie base según brightness.
  static Color surfaceFor(Brightness b) =>
      b == Brightness.dark ? darkSurface : lightSurface;

  /// Fondo global según brightness.
  static Color bgFor(Brightness b) =>
      b == Brightness.dark ? darkBg : lightBg;

  /// Color de borde según brightness.
  static Color borderFor(Brightness b) =>
      b == Brightness.dark ? darkBorder : lightBorder;

  /// Texto primario según brightness.
  static Color textFor(Brightness b) =>
      b == Brightness.dark ? darkText : lightText;

  /// Texto secundario según brightness.
  static Color textMutedFor(Brightness b) =>
      b == Brightness.dark ? darkTextMuted : lightTextMuted;

  /// Texto faint según brightness.
  static Color textFaintFor(Brightness b) =>
      b == Brightness.dark ? darkTextFaint : lightTextFaint;

  /// Superficie muted según brightness.
  static Color surfaceMutedFor(Brightness b) =>
      b == Brightness.dark ? darkSurfaceMuted : lightSurfaceMuted;

  /// Accent soft según brightness (genérico para warm/mint/rose).
  static Color accentWarmSoftFor(Brightness b) =>
      b == Brightness.dark ? accentWarmSoftDark : accentWarmSoftLight;

  static Color accentMintSoftFor(Brightness b) =>
      b == Brightness.dark ? accentMintSoftDark : accentMintSoftLight;

  static Color accentRoseSoftFor(Brightness b) =>
      b == Brightness.dark ? accentRoseSoftDark : accentRoseSoftLight;
}

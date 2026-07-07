import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Five typefaces, each with exactly one job. Don't add to them.
///
/// - DM Serif Display — display headlines, masthead, drop caps (regular only)
/// - Crimson Pro      — all body copy: scripture, prayers, reflections
/// - Old Standard TT  — italic flourishes, captions, refs, subheads (always italic)
/// - IBM Plex Mono    — all metadata: timestamps, kickers, labels (UPPERCASE + tracking)
/// - Special Elite    — typewriter character: board notes, testimonies
abstract class AppType {
  // ── DM Serif Display — display only, never bold ──
  static TextStyle display(double size, {Color color = AppColors.ink}) =>
      GoogleFonts.dmSerifDisplay(
        fontSize: size,
        height: 1.05,
        color: color,
        fontWeight: FontWeight.w400,
      );

  static TextStyle masthead({Color color = AppColors.ink}) =>
      display(34, color: color).copyWith(letterSpacing: -0.5);

  // ── Crimson Pro — body copy, 400/600, italic available ──
  static TextStyle body(
    double size, {
    Color color = AppColors.inkSoft,
    FontWeight weight = FontWeight.w400,
    bool italic = false,
    double height = 1.5,
  }) =>
      GoogleFonts.crimsonPro(
        fontSize: size,
        height: height,
        color: color,
        fontWeight: weight,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      );

  static TextStyle scripture({Color color = AppColors.ink}) =>
      body(20, color: color, height: 1.55);

  // ── Old Standard TT — always italic, always small ──
  static TextStyle flourish(double size, {Color color = AppColors.inkFaded}) =>
      GoogleFonts.oldStandardTt(
        fontSize: size,
        color: color,
        fontStyle: FontStyle.italic,
        height: 1.4,
      );

  // ── IBM Plex Mono — metadata, always uppercase + letter-spacing ──
  static TextStyle mono(
    double size, {
    Color color = AppColors.inkFaded,
    FontWeight weight = FontWeight.w500,
  }) =>
      GoogleFonts.ibmPlexMono(
        fontSize: size,
        color: color,
        fontWeight: weight,
        letterSpacing: 0.12 * size,
        height: 1.3,
      );

  /// Eyebrow / kicker label — accent red, uppercase mono.
  static TextStyle eyebrow({Color color = AppColors.accent}) =>
      mono(10, color: color, weight: FontWeight.w600);

  // ── Special Elite — typewriter character ──
  static TextStyle typewriter(double size, {Color color = AppColors.inkSoft}) =>
      GoogleFonts.specialElite(fontSize: size, color: color, height: 1.45);
}

/// Always-uppercase helper for mono labels per the design system.
extension MonoCase on String {
  String get kicker => toUpperCase();
}

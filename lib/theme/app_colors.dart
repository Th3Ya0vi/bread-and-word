import 'package:flutter/material.dart';

/// Bread & Word palette — one palette, no dark mode, no theming.
/// Everything looks like paper: printed scripture, a prayer journal,
/// a parish bulletin. The four-step ink ramp carries the hierarchy.
abstract class AppColors {
  // Paper surfaces
  static const paper = Color(0xFFF3EDE0); // primary background
  static const paperDeep = Color(0xFFEBE3D2); // cards, quiet panels
  static const paperBright = Color(0xFFFAF5E9); // elevated surfaces

  // Ink ramp — use this instead of reaching for more colors
  static const ink = Color(0xFF1A1612); // primary text, rules, headings
  static const inkSoft = Color(0xFF3A342C); // body on emphasized surfaces
  static const inkFaded = Color(0xFF6B6359); // metadata, captions, dividers
  static const inkGhost = Color(0xFFA8997F); // inactive, hints, placeholders

  // Accents — used surgically, never decorative
  static const accent = Color(0xFFB3321F); // section markers, drop caps, active
  static const accentDeep = Color(0xFF8A1F10); // hover / pressed
  static const green = Color(0xFF2D5A3D); // answered prayer / success, rare
}

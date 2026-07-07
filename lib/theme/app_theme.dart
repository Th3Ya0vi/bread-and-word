import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// The whole product is built on rules and borders, not corners and shadows.
/// No rounded corners. No drop shadows. No gradients. This restraint is the point.
abstract class AppTheme {
  /// Border weights from the design system.
  static const Border hairline = Border.fromBorderSide(
    BorderSide(color: AppColors.ink, width: 1),
  );

  static BoxBorder get softDivider => const Border(
        bottom: BorderSide(color: AppColors.inkFaded, width: 1),
      );

  static ThemeData build() {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.paper,
      canvasColor: AppColors.paper,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      colorScheme: const ColorScheme.light(
        surface: AppColors.paper,
        primary: AppColors.ink,
        secondary: AppColors.accent,
        error: AppColors.accent,
        onSurface: AppColors.ink,
        onPrimary: AppColors.paperBright,
      ),
    );

    return base.copyWith(
      textTheme: GoogleFonts.crimsonProTextTheme(base.textTheme).apply(
        bodyColor: AppColors.inkSoft,
        displayColor: AppColors.ink,
      ),
      dividerColor: AppColors.inkFaded,
      iconTheme: const IconThemeData(color: AppColors.ink, size: 22),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: _BwPageTransition(),
          TargetPlatform.android: _BwPageTransition(),
          TargetPlatform.macOS: _BwPageTransition(),
        },
      ),
    );
  }
}

/// A calm, considered page push — a soft fade with a gentle upward slide.
class _BwPageTransition extends PageTransitionsBuilder {
  const _BwPageTransition();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.035),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

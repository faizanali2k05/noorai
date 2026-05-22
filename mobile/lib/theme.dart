import 'package:flutter/material.dart';

/// NoorAI brand palette — premium, flat Pakistan-flag colours (green & white).
/// No gradients: a single confident green carries every brand surface, with
/// white as the canvas. This reads cleaner and more premium than a gradient.
class NoorColors {
  static const Color primary = Color(0xFF0E7C42); // vibrant Pakistan green
  static const Color primaryDark = Color(0xFF0A5C30); // deep green
  static const Color primaryDeepest = Color(0xFF01411C); // official flag green
  static const Color greenSoft = Color(0xFFE4F5EC); // light green-white
  static const Color greenOutline = Color(0xFFA7D7BD);

  /// The solid brand surface colour used for hero panels, the splash, and
  /// large filled areas — the deep official flag green for a premium feel.
  static const Color brand = primaryDeepest;

  static const Color background = Color(0xFFF4FBF6); // white w/ green tint
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF0F231A);
  static const Color textSecondary = Color(0xFF5B6B62);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color success = Color(0xFF10B981);
  static const Color danger = Color(0xFFDC2626);
  static const Color amber = Color(0xFFD97706);

  // Legacy aliases kept so existing references keep compiling.
  static const Color tealSoft = greenSoft;
  static const Color tealOutline = greenOutline;
  static const Color blueSoft = greenSoft;
  static const Color blueOutline = greenOutline;
}

class NoorSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

ThemeData buildNoorTheme() {
  final base = ColorScheme.fromSeed(
    seedColor: NoorColors.primary,
    primary: NoorColors.primary,
    surface: NoorColors.surface,
  );

  final textTheme = ThemeData.light().textTheme.apply(
        fontFamily: 'Poppins',
        bodyColor: NoorColors.textPrimary,
        displayColor: NoorColors.textPrimary,
      );

  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Poppins',
    textTheme: textTheme,
    colorScheme: base,
    scaffoldBackgroundColor: NoorColors.background,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: NoorColors.primaryDeepest,
      iconTheme: IconThemeData(color: NoorColors.primaryDeepest),
      titleTextStyle: TextStyle(
        fontFamily: 'Poppins',
        color: NoorColors.primaryDeepest,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
    ),
    cardTheme: CardThemeData(
      color: NoorColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE3EFE8)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD3E5DA)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD3E5DA)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: NoorColors.primary, width: 1.6),
      ),
      hintStyle: const TextStyle(color: NoorColors.textMuted),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: NoorColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
            fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: NoorColors.primaryDark,
        side: const BorderSide(color: NoorColors.greenOutline, width: 1.4),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: NoorColors.primary),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: NoorColors.greenSoft,
      labelStyle: const TextStyle(
          fontFamily: 'Poppins',
          color: NoorColors.primaryDark,
          fontWeight: FontWeight.w600),
      side: BorderSide.none,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: NoorColors.primaryDeepest,
      contentTextStyle:
          TextStyle(fontFamily: 'Poppins', color: Colors.white),
    ),
    progressIndicatorTheme:
        const ProgressIndicatorThemeData(color: NoorColors.primary),
    dividerTheme: const DividerThemeData(color: Color(0xFFE3EFE8)),
    // App-wide page transition: a soft fade + gentle rise, instead of the
    // default platform slide. Every `Navigator.push` inherits this.
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: NoorPageTransitionsBuilder(),
        TargetPlatform.iOS: NoorPageTransitionsBuilder(),
        TargetPlatform.windows: NoorPageTransitionsBuilder(),
        TargetPlatform.macOS: NoorPageTransitionsBuilder(),
        TargetPlatform.linux: NoorPageTransitionsBuilder(),
      },
    ),
  );
}

/// A refined route transition — fade combined with a subtle upward glide and a
/// hair of scale, eased on a smooth cubic. Reads more premium than the stock
/// platform slide and applies everywhere via [ThemeData.pageTransitionsTheme].
class NoorPageTransitionsBuilder extends PageTransitionsBuilder {
  const NoorPageTransitionsBuilder();

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
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.985, end: 1.0).animate(curved),
          child: child,
        ),
      ),
    );
  }
}

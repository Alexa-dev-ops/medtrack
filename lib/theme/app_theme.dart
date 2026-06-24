import 'package:flutter/material.dart';

/// MedTrack design system.
///
/// Palette idea: a calm clinical teal paired with a warm coral "pulse"
/// accent — literally the colour of a heartbeat trace on a dark monitor.
/// Teal reads as trustworthy/medical without being cold; coral is reserved
/// for the one signature motif (the heartbeat) and for things that need
/// a beat of urgency (skipped doses, errors).
class AppTheme {
  AppTheme._();

  // ---------------------------------------------------------------------
  // Core palette
  // ---------------------------------------------------------------------
  static const Color primary = Color(0xFF2F6F77);
  static const Color primaryDark = Color(0xFF173F44);
  static const Color primaryLight = Color(0xFF8FC4C9);

  /// The "pulse" colour — used sparingly for the heartbeat motif and
  /// high-emphasis accents. Not the same as [error].
  static const Color pulse = Color(0xFFFF6F59);

  /// Added to map the missing accent getter from medications_screen.dart
  static const Color accent = pulse;

  static const Color success = Color(0xFF2BAE66);
  static const Color warning = Color(0xFFF2A93B);
  static const Color error = Color(0xFFE2574C);

  static const Color background = Color(0xFFF5F8F8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE5ECEC);

  static const Color textPrimary = Color(0xFF142B2E);
  static const Color textSecondary = Color(0xFF6C7E80);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ---------------------------------------------------------------------
  // Shared tokens
  // ---------------------------------------------------------------------
  static const double radiusSm = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 22;
  static const double radiusXl = 28;

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  static List<BoxShadow> softShadow({Color? color, double opacity = 0.08}) => [
        BoxShadow(
          color: (color ?? primaryDark).withValues(alpha: opacity),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ];

  static List<BoxShadow> liftShadow({Color? color, double opacity = 0.18}) => [
        BoxShadow(
          color: (color ?? primary).withValues(alpha: opacity),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ];

  // ---------------------------------------------------------------------
  // Type scale — system font, but with a deliberate weight/spacing
  // hierarchy so it doesn't read as default Material text.
  // ---------------------------------------------------------------------
  static const TextStyle displayLarge = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.4,
    color: textPrimary,
    height: 1.15,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    color: textPrimary,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.1,
    color: textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textPrimary,
    height: 1.4,
  );

  static const TextStyle bodyMuted = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: textSecondary,
    height: 1.4,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w600,
    color: textSecondary,
    letterSpacing: 0.2,
  );

  static const TextStyle eyebrow = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: textOnPrimary,
    letterSpacing: 0.4,
  );

  // ---------------------------------------------------------------------
  // ThemeData
  // ---------------------------------------------------------------------
  static ThemeData get lightTheme {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.light);

    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: base.colorScheme.copyWith(
        primary: primary,
        secondary: pulse,
        surface: surface,
        error: error,
      ),
      splashColor: primary.withValues(alpha: 0.08),
      highlightColor: Colors.transparent,
      dividerColor: divider,
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: titleLarge,
        iconTheme: IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
      ),
      textTheme: base.textTheme.copyWith(
        headlineMedium: displayLarge,
        titleLarge: titleLarge,
        titleMedium: titleMedium,
        bodyLarge: body,
        bodyMedium: body,
        bodySmall: bodyMuted,
        labelSmall: caption,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: textOnPrimary,
          disabledBackgroundColor: primary.withValues(alpha: 0.4),
          minimumSize: const Size.fromHeight(54),
          elevation: 0,
          shadowColor: Colors.transparent,
          textStyle: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        labelStyle: bodyMuted,
        hintStyle: bodyMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: primary, width: 1.6),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        elevation: 0,
        height: 64,
        surfaceTintColor: Colors.transparent,
        indicatorColor: primary.withValues(alpha: 0.12),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            color: selected ? primary : textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? primary : textSecondary,
          );
        }),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: background,
        labelStyle: caption,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
        side: BorderSide.none,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
      ),
    );
  }
}

import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFF070B14);
  static const bgAlt = Color(0xFF0E1726);
  static const surface = Color(0xFF111B2B);
  static const surface2 = Color(0xFF182437);
  static const surface3 = Color(0xFF1E2C3F);
  static const border = Color(0xFF2A3A51);
  static const text = Color(0xFFEAF2FF);
  static const muted = Color(0xFF9AA9C4);
  static const accent = Color(0xFF6EE7D8);
  static const accentStrong = Color(0xFF7C6AF8);
  static const accentSoft = Color(0xFF8AA7FF);
  static const up = Color(0xFF2ED9A0);
  static const down = Color(0xFFFF5F7A);
  static const warn = Color(0xFFFFC76B);
  static const glow = Color(0xFF4FD1C5);
}

ThemeData buildTheme() {
  final base = ThemeData.dark(useMaterial3: true);

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    canvasColor: AppColors.bg,
    hintColor: AppColors.muted,
    primaryColor: AppColors.accent,
    colorScheme: const ColorScheme.dark(
      brightness: Brightness.dark,
      primary: AppColors.accent,
      onPrimary: AppColors.bg,
      secondary: AppColors.accentStrong,
      onSecondary: AppColors.text,
      tertiary: AppColors.accentSoft,
      surface: AppColors.surface,
      surfaceContainerHighest: AppColors.surface2,
      onSurface: AppColors.text,
      onSurfaceVariant: AppColors.muted,
      outline: AppColors.border,
      error: AppColors.down,
      onError: AppColors.text,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
      decorationColor: AppColors.text,
    ),
    iconTheme: const IconThemeData(color: AppColors.text),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.text,
        letterSpacing: -0.4,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      elevation: 0,
      indicatorColor: AppColors.accent.withAlpha(30),
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      iconTheme: WidgetStateProperty.all(
        const IconThemeData(size: 22),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface2,
      hintStyle: const TextStyle(color: AppColors.muted),
      labelStyle: const TextStyle(color: AppColors.muted),
      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.4),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: AppColors.surface2,
      selectedColor: AppColors.accent.withAlpha(36),
      side: const BorderSide(color: AppColors.border),
      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      showCheckmark: false,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    listTileTheme: const ListTileThemeData(
      titleTextStyle: TextStyle(color: AppColors.text, fontWeight: FontWeight.w600),
      subtitleTextStyle: TextStyle(color: AppColors.muted),
      iconColor: AppColors.muted,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
      space: 1,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
      },
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.accent,
      selectionColor: Color(0xFF7C6AF8),
      selectionHandleColor: AppColors.accent,
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStateProperty.all(AppColors.border),
      trackColor: WidgetStateProperty.all(Colors.transparent),
      radius: const Radius.circular(10),
      thickness: WidgetStateProperty.all(8),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surface3,
      contentTextStyle: const TextStyle(color: AppColors.text),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    visualDensity: VisualDensity.comfortable,
  );
}

const tabularFigures = [FontFeature.tabularFigures()];

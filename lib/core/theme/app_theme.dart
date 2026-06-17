import 'package:flutter/material.dart';
import 'package:hanpay_mobil/core/theme/app_colors.dart';

abstract final class AppTheme {
  static ThemeData light() {
    const primary = AppColors.lightPrimary;
    final scheme = ColorScheme.light(
      primary: primary,
      onPrimary: Colors.white,
      secondary: AppColors.payBlue,
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: AppColors.lightForeground,
      onSurfaceVariant: AppColors.lightMuted,
      outline: AppColors.lightBorder,
      outlineVariant: AppColors.lightBorder,
      primaryContainer: primary.withValues(alpha: 0.1),
      onPrimaryContainer: primary,
    );

    return _base(scheme, brightness: Brightness.light).copyWith(
      scaffoldBackgroundColor: AppColors.lightBackground,
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? primary : AppColors.lightMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? primary : AppColors.lightMuted);
        }),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        extendedSizeConstraints: BoxConstraints(minHeight: 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  static ThemeData dark() {
    const primary = AppColors.payBlue;
    final scheme = ColorScheme.dark(
      primary: primary,
      onPrimary: AppColors.navyBackground,
      secondary: AppColors.gradientEnd,
      onSecondary: Colors.white,
      surface: AppColors.navySurfaceMid,
      onSurface: Colors.white,
      onSurfaceVariant: Color(0xFFCBD5E1),
      outline: Colors.white24,
      outlineVariant: Colors.white12,
      primaryContainer: primary.withValues(alpha: 0.15),
      onPrimaryContainer: Colors.white,
    );

    return _base(scheme, brightness: Brightness.dark).copyWith(
      scaffoldBackgroundColor: AppColors.navyBackground,
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.navySurfaceMid,
        indicatorColor: primary.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? Colors.white : const Color(0xFF94A3B8),
          );
        }),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.navySurface,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }

  static ThemeData _base(ColorScheme scheme, {required Brightness brightness}) {
    final isLight = brightness == Brightness.light;

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      brightness: brightness,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: isLight ? Colors.white : AppColors.navySurfaceMid,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        filled: true,
        fillColor: isLight ? Colors.white : Colors.white.withValues(alpha: 0.06),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      cardTheme: CardThemeData(
        elevation: isLight ? 0 : 0,
        color: isLight ? Colors.white : Colors.white.withValues(alpha: 0.04),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: isLight ? AppColors.lightBorder : Colors.white12),
        ),
        shadowColor: isLight ? Colors.black.withValues(alpha: 0.04) : Colors.transparent,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      dividerTheme: DividerThemeData(
        color: isLight ? AppColors.lightBorder : Colors.white12,
        space: 1,
        thickness: 1,
      ),
    );
  }
}

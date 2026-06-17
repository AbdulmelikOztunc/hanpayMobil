import 'package:flutter/material.dart';

/// HanPay brand colors aligned with [FrontEndReact/turkmenpay-web].
abstract final class AppColors {
  // Brand blues (brand-logo.tsx + login modal)
  static const hanBlue = Color(0xFF1148C4);
  static const payBlue = Color(0xFF2F7CFF);
  static const hexOuter = Color(0xFF2B7BFF);
  static const hexInner = Color(0xFF3F8DFF);

  // Login / marketing dark surfaces (LoginPage.tsx)
  static const navyBackground = Color(0xFF070C20);
  static const navySurface = Color(0xFF111C4A);
  static const navySurfaceMid = Color(0xFF0C1536);
  static const navyCardEnd = Color(0xFF0A1130);

  // Primary action gradient (from-sky-500 to-indigo-600)
  static const gradientStart = Color(0xFF0EA5E9);
  static const gradientEnd = Color(0xFF4F46E5);

  // App light theme (index.css :root)
  static const lightBackground = Color(0xFFF8FAFC);
  static const lightForeground = Color(0xFF0F172A);
  static const lightMuted = Color(0xFF64748B);
  static const lightBorder = Color(0xFFDCE3EE);
  static const lightPrimary = Color(0xFF0B42A7);

  // Status
  static const emerald = Color(0xFF34D399);
  static const emeraldMuted = Color(0xFF6EE7B7);

  static const primaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [gradientStart, gradientEnd],
  );

  static const loginCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [navySurface, navySurfaceMid, navyBackground],
  );
}

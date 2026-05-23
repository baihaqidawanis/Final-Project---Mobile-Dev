import 'package:flutter/material.dart';

class AppColors {
  // Primary palette
  static const Color primary = Color(0xFF00B4A6);       // Teal
  static const Color primaryDark = Color(0xFF007A70);
  static const Color primaryLight = Color(0xFFB2EBE8);

  // Accent
  static const Color accent = Color(0xFF4CAF7D);         // Green

  // Neutrals
  static const Color background = Color(0xFFF7FAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A2E2D);
  static const Color textSecondary = Color(0xFF6B7F7E);
  static const Color border = Color(0xFFE0ECEB);

  // Status colors
  static const Color pending = Color(0xFFFF9800);
  static const Color accepted = Color(0xFF4CAF50);
  static const Color completed = Color(0xFF2196F3);
  static const Color cancelled = Color(0xFFF44336);
}

class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );
  static const TextStyle heading2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const TextStyle heading3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );
  static const TextStyle bodySecondary = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.5,
  );
}

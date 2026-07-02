import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors - Inspired by CamScanner
  static const Color primary = Color(0xFF1A73E8);
  static const Color primaryLight = Color(0xFF4DA3FF);
  static const Color primaryDark = Color(0xFF0D47A1);
  
  // Accent
  static const Color accent = Color(0xFF00BFA5);
  static const Color accentLight = Color(0xFF5DF2D6);
  
  // Background
  static const Color backgroundLight = Color(0xFFF5F7FA);
  static const Color backgroundDark = Color(0xFF121212);
  
  // Surface
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  
  // Text
  static const Color textPrimaryLight = Color(0xFF1A1A2E);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);
  
  // Functional
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  
  // Document specific
  static const Color scanBlue = Color(0xFF2196F3);
  static const Color scanGreen = Color(0xFF4CAF50);
  static const Color cardBorder = Color(0xFFE5E7EB);
  
  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1A73E8), Color(0xFF00BFA5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

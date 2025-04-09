import 'package:flutter/material.dart';

class AppColors {
  // Primary brand colors
  static const Color primary = Color(0xFF6A1B9A); // Deep Purple
  static const Color primaryDark = Color(0xFF303F9F);
  static const Color primaryLight = Color(0xFFC5CAE9);
  
  // Accent colors
  static const Color accent = Color(0xFFFDD835);  // Bright Yellow
  static const Color accentDark = Color(0xFFF50057);
  static const Color accentLight = Color(0xFFFF80AB);
  
  // Backgrounds
  static const Color background = Color(0xFF121212); // Very Dark Grey/Black
  static const Color secondaryBackground = Color(0xFF1C006C);
  static const Color cardBackground = Color(0xFF1E1E1E); // Dark Grey
  
  // Text colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color textHint = Color(0xFFBDBDBD);
  
  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Colors.redAccent;
  static const Color info = Color(0xFF2196F3);
  
  // Gradient colors
  static const List<Color> gradientBackground = [
    Color(0xFF0B0033),
    Color(0xFF2A004D),
    Color(0xFF5D006C),
    Color(0xFF9A0079),
    Color(0xFFC71585),
    Color(0xFFFF4500),
  ];

  // Define gradient stops if needed, or handle in GradientBackground widget
  static const List<double> gradientStops = [0.0, 0.2, 0.4, 0.6, 0.8, 1.0];

  // Optional: Define begin/end if you want consistency controlled here
  static const Alignment gradientBegin = Alignment.topLeft;
  static const Alignment gradientEnd = Alignment.bottomRight;
} 
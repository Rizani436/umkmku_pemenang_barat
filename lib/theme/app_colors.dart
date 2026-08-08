import 'package:flutter/material.dart';



class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF5B4FDD);
  static const Color primaryLight = Color(0xFF7B6FF0);

  static const Color accent = Color(0xFFF5C463);
  static const Color accentTextDark = Color(0xFF6B4F1A);

  static const Color textOnPrimary = Colors.white;


  static const Color background = Color(0xFFF3F1FB);
  static const Color surface = Colors.white;
  static const Color inputFill = Color(0xFFF5F4FA);
  static const Color inputBorder = Color(0xFFE1DFEC);
  static const Color textPrimary = Color(0xFF1F1B33);
  static const Color textSecondary = Color(0xFF74718A);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF5B4FDD), Color(0xFF6F63EA)],
  );
}

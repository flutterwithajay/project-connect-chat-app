// lib/theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // Primary Colors
  static const Color primaryColor = Color(0xFF4361EE); // Blue
  static const Color secondaryColor = Color(0xFF3A0CA3); // Purple
  static const Color accentColor = Color(0xFF4CC9F0); // Light Blue
  static const Color backgroundColor = Color(0xFFF8F9FA); // Light Grey
  
  // Text Colors
  static const Color textPrimary = Color(0xFF212529);
  static const Color textSecondary = Color(0xFF6C757D);
  
  // Status Colors
  static const Color successColor = Color(0xFF2ECC71);
  static const Color errorColor = Color(0xFFE74C3C);
  static const Color warningColor = Color(0xFFF39C12);
  
  // Gradient
  static Gradient primaryGradient = LinearGradient(
    colors: [primaryColor, secondaryColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Text Styles
  static TextStyle appNameStyle = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: Colors.white,
    letterSpacing: 1.5,
  );
  
  static TextStyle headingStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: textPrimary,
  );
  
  static TextStyle bodyStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );
  
  // App Bar Style
  static AppBarTheme appBarTheme = AppBarTheme(
    backgroundColor: primaryColor,
    elevation: 5,
    centerTitle: false,
    titleTextStyle: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: Colors.white,
    ),
    iconTheme: IconThemeData(color: Colors.white),
  );
}
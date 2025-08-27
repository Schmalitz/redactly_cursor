import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final base = ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      fontFamily: 'Roboto',
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.purplePrimary),
      scaffoldBackgroundColor: AppColors.greyWorkspace,
      dividerColor: AppColors.greyStroke,
      tooltipTheme: const TooltipThemeData(waitDuration: Duration(milliseconds: 400)),
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        // Einheitliche Header-Labels (Spaltenköpfe etc.)
        labelLarge: base.textTheme.labelLarge?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          color: Colors.black.withOpacity(0.90),
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          color: Colors.black.withOpacity(0.90),
        ),
      ),
      // Einheitliche Outlined/Elevated Styles können wir später feintunen
    );
  }
}

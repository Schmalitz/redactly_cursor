import 'package:flutter/material.dart';

/// Zentrale Farbpalette für Reductly – 5 Graus + 3 Purples
class AppColors {
  // Greys (macOS-inspiriert)
  static const greySidebar   = Color(0xFFE5E5EA); // deckend, wie Notes Sidebar
  static const greyTitlebar  = Color(0xFFF2F2F5);
  static const greyWorkspace = Color(0xFFF7F7FA);
  static const greyEditor    = Color(0xFFFFFFFF);
  static const greyPreview   = Color(0xFFF4EFFA); // leicht purple-tinted
  static const greyStroke    = Color(0xFFE6E6EA);
  static const greyHover     = Color(0x0F000000); // schwarz @ 6%

  // Purples
  static const purplePrimary   = Color(0xFF6D4AFF);
  static const purpleHoverFill = Color(0xFFE9E3FF);
  static const purpleSelection = Color(0xFFEEE8FF);

  // Inactive window tints (leicht entsättigt/aufgehellt)
  static Color tintInactive(Color c) => c.withOpacity(c.opacity * 0.92);
  static const double focusGlowOpacity = 0.35;
}

/// Bequemer Zugriff über Theme-Erweiterung
extension AppColorsX on ThemeData {
  Color get cSidebar    => AppColors.greySidebar;
  Color get cTitlebar   => AppColors.greyTitlebar;
  Color get cWorkspace  => AppColors.greyWorkspace;
  Color get cEditor     => AppColors.greyEditor;
  Color get cPreview    => AppColors.greyPreview;
  Color get cStroke     => AppColors.greyStroke;
  Color get cHover      => AppColors.greyHover;

  Color get cPrimary    => AppColors.purplePrimary;
  Color get cHoverFill  => AppColors.purpleHoverFill;
  Color get cSelection  => AppColors.purpleSelection;
}

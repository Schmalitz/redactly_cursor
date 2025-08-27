// lib/theme/app_buttons.dart
import 'package:flutter/material.dart';

/// Einheitliches Buttonset: Solid / Outline / Ghost (+ Destructive optional)
class AppButton extends StatelessWidget {
  const AppButton._({
    required this.onPressed,
    required this.label,
    this.leadingIcon,
    this.trailingIcon,
    required this.variant,
    this.minWidth,
    this.expand = false,
  });

  final VoidCallback? onPressed;
  final String label;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final _ButtonVariant variant;
  final double? minWidth;
  final bool expand;

  // Factories
  factory AppButton.solid({
    Key? key,
    required VoidCallback? onPressed,
    required String label,
    IconData? icon,
    IconData? leadingIcon,
    IconData? trailingIcon,
    double? minWidth,
    bool expand = false,
  }) =>
      AppButton._(
        onPressed: onPressed,
        label: label,
        leadingIcon: leadingIcon ?? icon,
        trailingIcon: trailingIcon,
        variant: _ButtonVariant.solid,
        minWidth: minWidth,
        expand: expand,
      );

  factory AppButton.outline({
    Key? key,
    required VoidCallback? onPressed,
    required String label,
    IconData? icon,
    IconData? leadingIcon,
    IconData? trailingIcon,
    double? minWidth,
    bool expand = false,
  }) =>
      AppButton._(
        onPressed: onPressed,
        label: label,
        leadingIcon: leadingIcon ?? icon,
        trailingIcon: trailingIcon,
        variant: _ButtonVariant.outline,
        minWidth: minWidth,
        expand: expand,
      );

  factory AppButton.ghost({
    Key? key,
    required VoidCallback? onPressed,
    required String label,
    IconData? icon,
    IconData? leadingIcon,
    IconData? trailingIcon,
    double? minWidth,
    bool expand = false,
  }) =>
      AppButton._(
        onPressed: onPressed,
        label: label,
        leadingIcon: leadingIcon ?? icon,
        trailingIcon: trailingIcon,
        variant: _ButtonVariant.ghost,
        minWidth: minWidth,
        expand: expand,
      );

  factory AppButton.solidDestructive({
    Key? key,
    required VoidCallback? onPressed,
    required String label,
    IconData? icon,
    IconData? leadingIcon,
    IconData? trailingIcon,
    double? minWidth,
    bool expand = false,
  }) =>
      AppButton._(
        onPressed: onPressed,
        label: label,
        leadingIcon: leadingIcon ?? icon,
        trailingIcon: trailingIcon,
        variant: _ButtonVariant.solidDestructive,
        minWidth: minWidth,
        expand: expand,
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<ButtonTokens>(); // ← null-sicher

    // Maße/Typo defaults (falls tokens fehlen)
    const double kIcon = 18;
    const double kMinWidth = 56;
    const EdgeInsets kPadding = EdgeInsets.symmetric(horizontal: 18, vertical: 12);
    final BorderRadius kRadius = BorderRadius.circular(12);
    final TextStyle kText = theme.textTheme.labelLarge?.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
    ) ??
        const TextStyle(fontSize: 14, fontWeight: FontWeight.w600);
    final Color kPrimary = theme.colorScheme.primary;

    // Fallback-Styles, falls tokens == null
    ButtonStyle _fallbackSolid(BorderRadius r) => ElevatedButton.styleFrom(
      padding: kPadding,
      textStyle: kText,
      shape: RoundedRectangleBorder(borderRadius: r),
      elevation: 1.5,
      shadowColor: Colors.black.withOpacity(0.10),
      foregroundColor: Colors.white,
      backgroundColor: kPrimary,
      surfaceTintColor: Colors.transparent,
    ).merge(ButtonStyle(
      overlayColor: MaterialStateProperty.resolveWith((s) {
        if (s.contains(MaterialState.hovered) || s.contains(MaterialState.pressed)) {
          return kPrimary.withOpacity(0.10);
        }
        return null;
      }),
    ));

    ButtonStyle _fallbackOutline(BorderRadius r) => ElevatedButton.styleFrom(
      padding: kPadding,
      textStyle: kText,
      shape: RoundedRectangleBorder(borderRadius: r),
      elevation: 0,
      shadowColor: Colors.transparent,
      foregroundColor: kPrimary,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
    ).merge(ButtonStyle(
      side: MaterialStatePropertyAll(BorderSide(color: kPrimary, width: 1.5)),
      overlayColor: MaterialStateProperty.resolveWith((s) {
        if (s.contains(MaterialState.hovered) || s.contains(MaterialState.pressed)) {
          return kPrimary.withOpacity(0.08);
        }
        return null;
      }),
    ));

    ButtonStyle _fallbackGhost(BorderRadius r) => ElevatedButton.styleFrom(
      padding: kPadding,
      textStyle: kText,
      shape: RoundedRectangleBorder(borderRadius: r),
      elevation: 0,
      shadowColor: Colors.transparent,
      foregroundColor: kPrimary,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
    ).merge(ButtonStyle(
      overlayColor: MaterialStateProperty.resolveWith((s) {
        if (s.contains(MaterialState.hovered) || s.contains(MaterialState.pressed)) {
          return kPrimary.withOpacity(0.06);
        }
        return null;
      }),
    ));

    ButtonStyle _fallbackDestructive(BorderRadius r) => ElevatedButton.styleFrom(
      padding: kPadding,
      textStyle: kText,
      shape: RoundedRectangleBorder(borderRadius: r),
      elevation: 1.5,
      shadowColor: Colors.black.withOpacity(0.10),
      foregroundColor: Colors.white,
      backgroundColor: const Color(0xFFDA3A36),
      surfaceTintColor: Colors.transparent,
    );

    ButtonStyle _styleForVariant(_ButtonVariant v) {
      final BorderRadius r = tokens?.radius ?? kRadius;
      switch (v) {
        case _ButtonVariant.solid:
          return (tokens?.solid ?? _fallbackSolid(r));
        case _ButtonVariant.outline:
          return (tokens?.outline ?? _fallbackOutline(r));
        case _ButtonVariant.ghost:
          return (tokens?.ghost ?? _fallbackGhost(r));
        case _ButtonVariant.solidDestructive:
          return (tokens?.solidDestructive ?? _fallbackDestructive(r));
      }
    }

    final labelWidget = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    final children = <Widget>[
      if (leadingIcon != null)
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Icon(leadingIcon, size: tokens?.iconSize ?? kIcon),
        ),
      Flexible(child: labelWidget),
      if (trailingIcon != null)
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Icon(trailingIcon, size: tokens?.iconSize ?? kIcon),
        ),
    ];

    return ElevatedButton(
      onPressed: onPressed,
      style: _styleForVariant(variant),
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: minWidth ?? (tokens?.minWidth ?? kMinWidth)),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: children,
        ),
      ),
    );
  }
}

enum _ButtonVariant { solid, outline, ghost, solidDestructive }

/// Theme-Extension mit allen Button-Tokens + fertigen ButtonStyles.
@immutable
class ButtonTokens extends ThemeExtension<ButtonTokens> {
  const ButtonTokens({
    required this.radius,
    required this.padding,
    required this.textStyle,
    required this.shadowColor,
    required this.iconSize,
    required this.minWidth,
    required this.solid,
    required this.outline,
    required this.ghost,
    required this.solidDestructive,
  });

  final BorderRadius radius;
  final EdgeInsets padding;
  final TextStyle textStyle;
  final Color shadowColor;
  final double iconSize;
  final double minWidth;

  final ButtonStyle solid;
  final ButtonStyle outline;
  final ButtonStyle ghost;
  final ButtonStyle solidDestructive;

  @override
  ButtonTokens copyWith({
    BorderRadius? radius,
    EdgeInsets? padding,
    TextStyle? textStyle,
    Color? shadowColor,
    double? iconSize,
    double? minWidth,
    ButtonStyle? solid,
    ButtonStyle? outline,
    ButtonStyle? ghost,
    ButtonStyle? solidDestructive,
  }) {
    return ButtonTokens(
      radius: radius ?? this.radius,
      padding: padding ?? this.padding,
      textStyle: textStyle ?? this.textStyle,
      shadowColor: shadowColor ?? this.shadowColor,
      iconSize: iconSize ?? this.iconSize,
      minWidth: minWidth ?? this.minWidth,
      solid: solid ?? this.solid,
      outline: outline ?? this.outline,
      ghost: ghost ?? this.ghost,
      solidDestructive: solidDestructive ?? this.solidDestructive,
    );
  }

  @override
  ThemeExtension<ButtonTokens> lerp(ThemeExtension<ButtonTokens>? other, double t) {
    if (other is! ButtonTokens) return this;
    return this; // keine Interpolation nötig
  }
}

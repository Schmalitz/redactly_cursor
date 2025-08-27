// lib/screens/editor_screen/widgets/title_bar.dart
import 'dart:io' show Platform;

import 'package:anonymizer/models/session.dart';
import 'package:anonymizer/providers/mode_provider.dart';
import 'package:anonymizer/providers/session_provider.dart';
import 'package:anonymizer/providers/settings_provider.dart';
import 'package:anonymizer/theme/app_colors.dart';
import 'package:anonymizer/theme/app_theme.dart'; // Farb-Extensions etc.
import 'package:anonymizer/theme/app_buttons.dart'; // ButtonTokens (für Styles)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:window_manager/window_manager.dart';

import 'window_buttons_mac.dart';
import 'window_buttons_win.dart';

/// TitleBar mit Sidebar-Overlay & editorbündigem Titel.
class TitleBar extends ConsumerWidget implements PreferredSizeWidget {
  const TitleBar({
    super.key,
    this.height = 60,
    this.leftOverlayWidth = 0,
    this.leftOverlayColor,
    this.actions = const <Widget>[],
    this.leading,
    required this.contentLeftInset,
  });

  final double height;
  final double leftOverlayWidth;
  final Color? leftOverlayColor;
  final List<Widget> actions;
  final Widget? leading;
  final double contentLeftInset;

  @override
  Size get preferredSize => Size.fromHeight(height);

  // macOS: Ampel-Blockbreite & Abstände
  static const double _macDot = 12;
  static const double _macGap = 8;
  static const double _macLeftPadding = 22;
  static const double _gapAfterAmpel = 20;

  static double get _macButtonsBlockWidth =>
      _macLeftPadding + (_macDot * 3) + (_macGap * 2);

  // Sidebar-Toggle
  static const double _toggleIconSize = 22;
  static const double _toggleTapTargetW = 30;
  static const double _toggleTapTargetH = 24;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionProvider);
    final activeId = ref.watch(activeSessionIdProvider);
    final theme = Theme.of(context);

    Session? active;
    for (final s in sessions) {
      if (s.id == activeId) {
        active = s;
        break;
      }
    }
    final title = active?.title ?? 'No Session';

    final bg = theme.cTitlebar;
    final overlay = leftOverlayColor ?? theme.cSidebar;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (_) => windowManager.startDragging(),
      onDoubleTap: () async {
        final isMax = await windowManager.isMaximized();
        isMax ? windowManager.unmaximize() : windowManager.maximize();
      },
      child: Container(
        height: height,
        color: bg,
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            // Sidebar-Farb-Overlay unter Titlebar
            if (leftOverlayWidth > 0)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: leftOverlayWidth,
                child: Container(color: overlay),
              ),

            // Fenster-Buttons
            if (Platform.isMacOS)
              const Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: _macLeftPadding),
                  child: MacWindowButtons(),
                ),
              )
            else
              const Align(
                alignment: Alignment.centerRight,
                child: WinWindowButtons(),
              ),

            // Linke Steuerzone: Toggle (+ optional leading)
            _LeftControlsArea(
              macButtonsBlockWidth: _macButtonsBlockWidth,
              gapAfterAmpel: _gapAfterAmpel,
              toggleIconSize: _toggleIconSize,
              toggleTapTargetW: _toggleTapTargetW,
              toggleTapTargetH: _toggleTapTargetH,
              leading: leading,
            ),

            // Session-Titel exakt bündig zum Editor-Content (aus Shell geliefert)
            // + NIE unter die linken Controls laufen lassen (safeLeft)
            Positioned.fill(
              child: Builder(
                builder: (context) {
                  final baseLeft = Platform.isMacOS
                      ? (_macButtonsBlockWidth + _gapAfterAmpel)
                      : 14;

                  final double leftControlsEnd = baseLeft +
                      _toggleTapTargetW +
                      14 +
                      (leading != null ? 24 : 0);

                  final double safeLeft = contentLeftInset > leftControlsEnd
                      ? contentLeftInset
                      : leftControlsEnd;

                  return Padding(
                    padding: EdgeInsets.only(
                      left: safeLeft,
                      // rechts Platz für Mode-Switch / Win-Buttons
                      right: Platform.isMacOS ? 120 : 160,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: IgnorePointer(
                        ignoring: true,
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Rechts: Actions + Mode-Switch (zweigeteilter Button)
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...actions,
                  Padding(
                    // mehr Platz rechts neben De-Anonymize:
                    padding: EdgeInsets.only(right: Platform.isMacOS ? 16 : 64),
                    child: const _ModeSegmentedSwitch(),
                  ),
                ],
              ),
            ),

            // Hairline unten: links Overlay-Farbe, rechts Stroke → wirkt durchgezogen
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 1,
              child: Row(
                children: [
                  if (leftOverlayWidth > 0)
                    Container(width: leftOverlayWidth, color: overlay),
                  Expanded(child: Container(color: theme.cStroke)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeftControlsArea extends StatelessWidget {
  const _LeftControlsArea({
    required this.macButtonsBlockWidth,
    required this.gapAfterAmpel,
    required this.toggleIconSize,
    required this.toggleTapTargetW,
    required this.toggleTapTargetH,
    required this.leading,
  });

  final double macButtonsBlockWidth;
  final double gapAfterAmpel;
  final double toggleIconSize;
  final double toggleTapTargetW;
  final double toggleTapTargetH;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final double baseLeft =
    Platform.isMacOS ? (macButtonsBlockWidth + gapAfterAmpel) : 14;

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(left: baseLeft),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SidebarToggleButton(
              iconSize: toggleIconSize,
              tapW: toggleTapTargetW,
              tapTargetH: toggleTapTargetH,
            ),
            if (leading != null) ...[
              const SizedBox(width: 14),
              leading!,
            ],
          ],
        ),
      ),
    );
  }
}

class _SidebarToggleButton extends ConsumerStatefulWidget {
  const _SidebarToggleButton({
    super.key,
    required this.iconSize,
    required this.tapW,
    required this.tapTargetH,
  });

  final double iconSize;
  final double tapW;
  final double tapTargetH;

  double get tapH => tapTargetH;

  @override
  ConsumerState<_SidebarToggleButton> createState() =>
      _SidebarToggleButtonState();
}

class _SidebarToggleButtonState extends ConsumerState<_SidebarToggleButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final isPinned = ref.watch(sidebarPinnedProvider);

    const double weight = 400;
    const double grade = 0;
    const double optical = 48;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => ref.read(sidebarPinnedProvider.notifier).state = !isPinned,
        child: Container(
          width: widget.tapW,
          height: widget.tapH,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _hover ? Theme.of(context).cHover : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            isPinned ? Symbols.left_panel_close : Symbols.left_panel_open,
            size: widget.iconSize,
            weight: weight,
            grade: grade,
            opticalSize: optical,
          ),
        ),
      ),
    );
  }
}

/// Zweigeteilter Mode-Switch – gleicher Stil wie die ActionBar-Duo-Buttons
class _ModeSegmentedSwitch extends ConsumerWidget {
  const _ModeSegmentedSwitch();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = theme.extension<ButtonTokens>();
    final mode = ref.watch(redactModeProvider);
    final bool isAnon = mode == RedactMode.anonymize;

    const BorderRadius leftR  = BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12));
    const BorderRadius rightR = BorderRadius.only(topRight: Radius.circular(12), bottomRight: Radius.circular(12));

    ButtonStyle _style(bool active, BorderRadius r) {
      final base = active ? (tokens?.solid) : (tokens?.outline);
      if (base != null) {
        return base.copyWith(
          shape: MaterialStatePropertyAll(RoundedRectangleBorder(borderRadius: r)),
        );
      }
      // Fallbacks (falls Tokens fehlen)
      return ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: r),
        foregroundColor: active ? Colors.white : theme.colorScheme.primary,
        backgroundColor: active ? theme.colorScheme.primary : Colors.white,
        elevation: active ? 1.5 : 0,
      ).merge(
        active
            ? const ButtonStyle()
            : ButtonStyle(
          side: MaterialStatePropertyAll(
            BorderSide(color: theme.colorScheme.primary, width: 1.5),
          ),
        ),
      );
    }

    // Einheitliche Icon-Parameter (Material Symbols)
    const double iconSize = 18;
    const double weight = 400;
    const double grade = 0;
    const double optical = 48;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton.icon(
          style: _style(isAnon, leftR),
          onPressed: () =>
          ref.read(redactModeProvider.notifier).state = RedactMode.anonymize,
          icon: const Icon(
            Symbols.visibility_off,
            size: iconSize,
            weight: weight,
            grade: grade,
            opticalSize: optical,
          ),
          label: const Text('Anonymize'),
        ),
        // feine Mitteltrennung, damit die Innenkante nicht doppelt wirkt
        Container(width: 1, height: 36, color: theme.colorScheme.primary),
        ElevatedButton.icon(
          style: _style(!isAnon, rightR),
          onPressed: () =>
          ref.read(redactModeProvider.notifier).state = RedactMode.deanonymize,
          icon: const Icon(
            Symbols.visibility,
            size: iconSize,
            weight: weight,
            grade: grade,
            opticalSize: optical,
          ),
          label: const Text('De-Anonymize'),
        ),
      ],
    );
  }
}

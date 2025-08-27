import 'dart:io' show Platform;

import 'package:anonymizer/models/session.dart';
import 'package:anonymizer/providers/session_provider.dart';
import 'package:anonymizer/providers/settings_provider.dart';
import 'package:anonymizer/screens/widgets/redact_mode_pill.dart';
import 'package:anonymizer/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:window_manager/window_manager.dart';

import 'window_buttons_mac.dart';
import 'window_buttons_win.dart';

/// TitleBar mit Sidebar-Overlay & editorbündigem Titel.
/// [leftOverlayWidth]/[leftOverlayColor] färben den Bereich unter der Titlebar,
/// wenn die Sidebar offen ist.
/// [contentLeftInset] = exakter Editor-Content-Start (für bündigen Titel).
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

  // ↑ Links neben den Ampeln ein Tick größer
  static const double _macLeftPadding = 22;

  // ↑ Abstand zwischen Ampeln und Sidebar-Toggle spürbar größer
  static const double _gapAfterAmpel = 20;

  static double get _macButtonsBlockWidth =>
      _macLeftPadding + (_macDot * 3) + (_macGap * 2);

  // Sidebar-Toggle (größer als Ampeln)
  static const double _toggleIconSize = 22; // 20 → 22
  static const double _toggleTapTargetW = 30;
  static const double _toggleTapTargetH = 24;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionProvider);
    final activeId = ref.watch(activeSessionIdProvider);
    final theme = Theme.of(context);

    Session? active;
    for (final s in sessions) {
      if (s.id == activeId) { active = s; break; }
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
                left: 0, top: 0, bottom: 0, width: leftOverlayWidth,
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

                  // Breite der linken Controls: Toggle-Tap-Target + etwas Luft + evtl. leading
                  final double leftControlsEnd =
                      baseLeft + _toggleTapTargetW + 14 + (leading != null ? 24 : 0);

                  final double safeLeft =
                  contentLeftInset > leftControlsEnd ? contentLeftInset : leftControlsEnd;

                  return Padding(
                    padding: EdgeInsets.only(
                      left: safeLeft,
                      // rechts Platz für Pill / Win-Buttons
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
                          // vorher: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)
                          style: theme.textTheme.titleMedium, // jetzt nicht fett → eleganter
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Rechts: Actions + RedactModePill
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...actions,
                  Padding(
                    padding: EdgeInsets.only(right: Platform.isMacOS ? 8 : 56),
                    child: const RedactModePill(),
                  ),
                ],
              ),
            ),

            // Hairline unten: links Overlay-Farbe, rechts Stroke → wirkt durchgezogen
            Positioned(
              left: 0, right: 0, bottom: 0, height: 1,
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
    // Startpunkt links von den Ampeln + definierter Gap zum Toggle
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
              tapH: toggleTapTargetH,
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
    required this.tapH,
  });

  final double iconSize;
  final double tapW;
  final double tapH;

  @override
  ConsumerState<_SidebarToggleButton> createState() => _SidebarToggleButtonState();
}

class _SidebarToggleButtonState extends ConsumerState<_SidebarToggleButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPinned = ref.watch(sidebarPinnedProvider);

    // Material Symbols: Gewicht/Grade/OpticalSize für stimmige Strichstärke
    const double weight = 400;     // 100..700
    const double grade = 0;        // -25..200
    const double optical = 48;     // 20..48

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
            color: _hover ? theme.cHover : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            isPinned ? Symbols.left_panel_close : Symbols.left_panel_open,
            size: widget.iconSize,
            // bereitgestellt vom material_symbols_icons-Package
            weight: weight,
            grade: grade,
            opticalSize: optical,
          ),
        ),
      ),
    );
  }
}

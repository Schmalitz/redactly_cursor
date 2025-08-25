import 'dart:io' show Platform;
import 'package:anonymizer/models/session.dart';
import 'package:anonymizer/providers/session_provider.dart';
import 'package:anonymizer/providers/settings_provider.dart'; // sidebarPinnedProvider
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'window_buttons_mac.dart';
import 'window_buttons_win.dart';

class TitleBar extends ConsumerWidget implements PreferredSizeWidget {
  const TitleBar({
    super.key,
    this.height = 60,
    this.leftOverlayWidth = 0,
    this.leftOverlayColor,
  });

  final double height;

  /// Breite der Sidebar-Hintergrundfläche, die unter Ampeln/Toggle sichtbar sein soll
  final double leftOverlayWidth;
  final Color? leftOverlayColor;

  @override
  Size get preferredSize => Size.fromHeight(height);

  static const double _macDot = 12;
  static const double _macGap = 8;
  static const double _macLeftPadding = 6;

  // geschätzte Breite des Ampel-Clusters inkl. Padding
  static double get _macButtonsBlockWidth =>
      _macLeftPadding + (_macDot * 3) + (_macGap * 2);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionProvider);
    final activeId = ref.watch(activeSessionIdProvider);

    Session? activeSession;
    for (final s in sessions) {
      if (s.id == activeId) {
        activeSession = s;
        break;
      }
    }
    final activeTitle = activeSession?.title ?? 'No Session';

    final bg = Theme.of(context).scaffoldBackgroundColor;
    final overlay = leftOverlayColor ?? Colors.grey.shade100;

    final isPinned = ref.watch(sidebarPinnedProvider);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (_) => windowManager.startDragging(),
      onDoubleTap: () async {
        final isMax = await windowManager.isMaximized();
        if (isMax) {
          await windowManager.unmaximize();
        } else {
          await windowManager.maximize();
        }
      },
      child: Container(
        height: height,
        color: bg,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Linker Overlay-Streifen (Sidebar-Hintergrund) unter Ampeln & Toggle
            if (leftOverlayWidth > 0)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: leftOverlayWidth,
                child: Container(color: overlay),
              ),

            // Ampeln (macOS) oder Win-Buttons (Windows/Linux)
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

            // Sidebar-Toggle direkt rechts neben den Ampeln (macOS), sonst links
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(
                  left: Platform.isMacOS ? (_macButtonsBlockWidth + 8) : 10,
                ),
                child: const _SidebarToggleButton(),
              ),
            ),

            // Session-Titel wirklich zentriert (unbeeindruckt von links/rechts)
            IgnorePointer(
              ignoring: true,
              child: Text(
                activeTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium!
                    .copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarToggleButton extends ConsumerStatefulWidget {
  const _SidebarToggleButton({super.key});

  @override
  ConsumerState<_SidebarToggleButton> createState() => _SidebarToggleButtonState();
}

class _SidebarToggleButtonState extends ConsumerState<_SidebarToggleButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final isPinned = ref.watch(sidebarPinnedProvider);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () {
          ref.read(sidebarPinnedProvider.notifier).state = !isPinned;
        },
        child: Container(
          width: 28,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _hover ? Colors.grey.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          // macOS Notes nutzt ein „Sidebar einblenden“-Glyph; wir nehmen menu als klaren Toggle
          child: Icon(
            isPinned ? Icons.view_sidebar : Icons.menu,
            size: 16,
          ),
        ),
      ),
    );
  }
}

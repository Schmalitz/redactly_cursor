import 'dart:io' show Platform;

import 'package:anonymizer/models/session.dart';
import 'package:anonymizer/providers/session_provider.dart';
import 'package:anonymizer/providers/settings_provider.dart';
import 'package:anonymizer/screens/widgets/redact_mode_pill.dart';
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
    this.actions = const <Widget>[],
    this.leading,
  });

  final double height;
  final double leftOverlayWidth;
  final Color? leftOverlayColor;

  /// rechte Button-Leiste (z. B. New, Save, Export, Settings)
  final List<Widget> actions;

  /// optional zusätzlich links (neben Toggle), selten nötig
  final Widget? leading;

  @override
  Size get preferredSize => Size.fromHeight(height);

  static const double _macDot = 12;
  static const double _macGap = 8;
  static const double _macLeftPadding = 6;
  static double get _macButtonsBlockWidth =>
      _macLeftPadding + (_macDot * 3) + (_macGap * 2);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionProvider);
    final activeId = ref.watch(activeSessionIdProvider);

    Session? active;
    for (final s in sessions) {
      if (s.id == activeId) { active = s; break; }
    }
    final title = active?.title ?? 'No Session';

    final bg = Theme.of(context).scaffoldBackgroundColor;
    final overlay = leftOverlayColor ?? Colors.grey.shade100;

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
          alignment: Alignment.center,
          children: [
            if (leftOverlayWidth > 0)
              Positioned(left: 0, top: 0, bottom: 0, width: leftOverlayWidth, child: Container(color: overlay)),

            if (Platform.isMacOS)
              const Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: _macLeftPadding),
                  child: MacWindowButtons(),
                ),
              )
            else
              const Align(alignment: Alignment.centerRight, child: WinWindowButtons()),

            // Links: Toggle + optional leading
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: Platform.isMacOS ? (_macButtonsBlockWidth + 8) : 10),
                child: Row(mainAxisSize: MainAxisSize.min, children: const [_SidebarToggleButton()]),
              ),
            ),
            if (leading != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: Platform.isMacOS ? (_macButtonsBlockWidth + 46) : 46),
                  child: leading!,
                ),
              ),

            // Mitte: Titel
            IgnorePointer(
              ignoring: true,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w600),
              ),
            ),

            // Rechts: Actions
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.only(right: Platform.isMacOS ? 8 : 56),
                child: const RedactModePill(),
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
        onTap: () => ref.read(sidebarPinnedProvider.notifier).state = !isPinned,
        child: Container(
          width: 28,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _hover ? Colors.grey.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(isPinned ? Icons.view_sidebar : Icons.menu, size: 16),
        ),
      ),
    );
  }
}

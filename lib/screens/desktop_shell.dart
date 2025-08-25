import 'package:anonymizer/screens/session_sidebar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:anonymizer/widgets/title_bar.dart';
import 'package:anonymizer/providers/settings_provider.dart';

class DesktopShell extends ConsumerStatefulWidget {
  const DesktopShell({
    super.key,
    required this.editor,
    this.titleBarHeight = 60,
    this.sidebarWidth = 260,
    this.collapsedWidth = 0,
  });

  final Widget editor;
  final double titleBarHeight;
  final double sidebarWidth;
  final double collapsedWidth;

  @override
  ConsumerState<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends ConsumerState<DesktopShell> {
  @override
  Widget build(BuildContext context) {
    final isOpen = ref.watch(sidebarPinnedProvider);
    final double currentSidebarWidth = isOpen ? widget.sidebarWidth : widget.collapsedWidth;
    final sidebarBg = Colors.grey.shade100;
    final appBg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: appBg,
      body: Stack(
        children: [
          // 1) Hintergrund-Stripes: links Sidebar-Farbe über volle Höhe (inkl. TitleBar)
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            width: currentSidebarWidth,
            color: sidebarBg,
          ),

          // 2) Struktur: TitleBar oben, darunter Editor-Row mit Spacer
          Column(
            children: [
              // TitleBar bekommt die Info, wie breit links Sidebar-Hintergrund ist.
              TitleBar(
                height: widget.titleBarHeight,
                leftOverlayWidth: currentSidebarWidth,
                leftOverlayColor: sidebarBg,
              ),

              // Body: linker Spacer == Sidebarbreite, rechts Editor
              Expanded(
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      width: currentSidebarWidth,
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: widget.editor),
                  ],
                ),
              ),
            ],
          ),

          // 3) Sidebar-Content: unterhalb der TitleBar einfahren
          Positioned(
            top: widget.titleBarHeight,
            left: 0,
            bottom: 0,
            width: currentSidebarWidth,
            child: const SessionSidebar(),
          ),
        ],
      ),
    );
  }
}

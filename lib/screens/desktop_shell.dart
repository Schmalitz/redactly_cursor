import 'dart:io' show Platform;

import 'package:anonymizer/providers/settings_provider.dart';
import 'package:anonymizer/screens/session_sidebar.dart';
import 'package:anonymizer/screens/widgets/desktop_toolbar.dart';
import 'package:anonymizer/screens/widgets/title_bar.dart';
import 'package:anonymizer/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DesktopShell extends ConsumerWidget {
  const DesktopShell({
    super.key,
    required this.editor,
    this.titleBarHeight = 60,
    this.toolbarHeight = 44,
    this.sidebarWidth = 260,
    this.collapsedWidth = 0,
    this.actions = const <Widget>[],
    this.leading,
    this.editorLeftPadding = 16, // Editor-Content-Start innen
  });

  final Widget editor;
  final double titleBarHeight;
  final double toolbarHeight;
  final double sidebarWidth;
  final double collapsedWidth;
  final List<Widget> actions;
  final Widget? leading;

  /// Linker Innenabstand des Editor-Contents. Wird in die TitleBar gespiegelt,
  /// damit der Session-Titel exakt bündig mit dem Editor beginnt.
  final double editorLeftPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPinned = ref.watch(sidebarPinnedProvider);
    final currentSidebarWidth = isPinned ? sidebarWidth : collapsedWidth;

    final theme = Theme.of(context);
    final sidebarBg = theme.cSidebar; // EINHEITLICHE Sidebar-Farbe
    final appBg = theme.scaffoldBackgroundColor;
    final useMacCustomTitleBar = Platform.isMacOS;

    const double dividerWidth = 1;

    // Sidebar (variabel) + Divider + Editor-Innenpadding
    final double contentLeftInset =
        currentSidebarWidth + dividerWidth + editorLeftPadding;

    return Scaffold(
      backgroundColor: appBg,
      body: Stack(
        children: [
          // 1) Sidebar-Unterlage färbt bis GANZ OBEN
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            width: currentSidebarWidth,
            color: sidebarBg,
          ),

          // 2) Column: TitleBar + Content
          Column(
            children: [
              if (useMacCustomTitleBar)
                TitleBar(
                  height: titleBarHeight,
                  leftOverlayWidth: currentSidebarWidth, // exakt gleiche Breite
                  leftOverlayColor: sidebarBg,           // exakt gleiche Farbe
                  actions: actions,
                  leading: leading,
                  contentLeftInset: contentLeftInset,    // bündig mit Editor
                )
              else
                DesktopToolbar(
                  height: toolbarHeight,
                  actions: actions,
                  leading: leading,
                ),

              Expanded(
                child: Row(
                  children: [
                    // Platzhalter für Sidebar-Breite (nimmt keine Klicks weg)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      width: currentSidebarWidth,
                    ),
                    // keinen VerticalDivider hier – Linie zeichnen wir als Positioned
                    Expanded(child: editor),
                  ],
                ),
              ),
            ],
          ),

          // 3) Vertikale Linie (gleiche Farbe wie die Hairline unten)
          Positioned(
            left: currentSidebarWidth,
            top: 0,
            bottom: 0,
            width: dividerWidth,
            child: Container(color: theme.cStroke),
          ),

          // 4) Echte Sidebar obendrauf (für Interaktion)
          Positioned(
            top: useMacCustomTitleBar ? titleBarHeight : toolbarHeight,
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

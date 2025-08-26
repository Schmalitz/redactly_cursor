import 'dart:io' show Platform;

import 'package:anonymizer/providers/settings_provider.dart';
import 'package:anonymizer/screens/session_sidebar.dart';
import 'package:anonymizer/screens/widgets/desktop_toolbar.dart';
import 'package:anonymizer/screens/widgets/title_bar.dart';
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
  });

  final Widget editor;
  final double titleBarHeight;
  final double toolbarHeight;
  final double sidebarWidth;
  final double collapsedWidth;
  final List<Widget> actions;
  final Widget? leading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOpen = ref.watch(sidebarPinnedProvider);
    final currentSidebarWidth = isOpen ? sidebarWidth : collapsedWidth;
    final sidebarBg = Colors.grey.shade100;
    final appBg = Theme.of(context).scaffoldBackgroundColor;
    final useMacCustomTitleBar = Platform.isMacOS;

    return Scaffold(
      backgroundColor: appBg,
      body: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOut,
            width: currentSidebarWidth,
            color: sidebarBg,
          ),
          Column(
            children: [
              if (useMacCustomTitleBar)
                TitleBar(
                  height: titleBarHeight,
                  leftOverlayWidth: currentSidebarWidth,
                  leftOverlayColor: sidebarBg,
                  actions: actions,
                  leading: leading,
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
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      width: currentSidebarWidth,
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: editor),
                  ],
                ),
              ),
            ],
          ),
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

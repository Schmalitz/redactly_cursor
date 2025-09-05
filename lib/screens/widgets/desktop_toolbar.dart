import 'dart:io' show Platform;

import 'package:redactly/models/session.dart';
import 'package:redactly/providers/session_provider.dart';
import 'package:redactly/providers/settings_provider.dart';
import 'package:redactly/screens/widgets/redact_mode_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DesktopToolbar extends ConsumerWidget {
  const DesktopToolbar({
    super.key,
    this.height = 44,
    this.actions = const <Widget>[],
    this.leading,
  });

  final double height;
  final List<Widget> actions;
  final Widget? leading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Runtime-Guard statt assert: auf macOS keine separate DesktopToolbar rendern.
    if (Platform.isMacOS) {
      return const SizedBox.shrink();
    }

    final sessions = ref.watch(sessionProvider);
    final activeId = ref.watch(activeSessionIdProvider);

    final Session? active = sessions.cast<Session?>().firstWhere(
          (s) => s?.id == activeId,
      orElse: () => null,
    );

    final title = active?.title ?? 'No Session';
    final theme = Theme.of(context);
    final bg = theme.colorScheme.surface;

    return Material(
      color: bg,
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [_SidebarToggleButton()],
              ),
            ),
            if (leading != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 40),
                  child: leading!,
                ),
              ),
            IgnorePointer(
              ignoring: true,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Align(
              alignment: Alignment.centerRight,
              child: RedactModePill(),
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
    final theme = Theme.of(context);

    // nutze Theme-Hover statt hartes Grau -> wirkt in Dark/Light konsistent
    final hoverColor = theme.hoverColor.withOpacity(0.6);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit:  (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () => ref.read(sidebarPinnedProvider.notifier).state = !isPinned,
        child: Container(
          width: 36,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _hover ? hoverColor : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(isPinned ? Icons.view_sidebar : Icons.menu, size: 18),
        ),
      ),
    );
  }
}

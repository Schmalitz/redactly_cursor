import 'dart:io' show Platform;

import 'package:anonymizer/models/session.dart';
import 'package:anonymizer/providers/session_provider.dart';
import 'package:anonymizer/providers/settings_provider.dart';
import 'package:anonymizer/screens/widgets/redact_mode_pill.dart';
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
    assert(!Platform.isMacOS, 'DesktopToolbar ist für Win/Linux gedacht.');

    final sessions = ref.watch(sessionProvider);
    final activeId = ref.watch(activeSessionIdProvider);

    Session? active;
    for (final s in sessions) {
      if (s.id == activeId) { active = s; break; }
    }
    final title = active?.title ?? 'No Session';
    final bg = Theme.of(context).colorScheme.surface;

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
              child: Row(mainAxisSize: MainAxisSize.min, children: const [_SidebarToggleButton()]),
            ),
            if (leading != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(padding: const EdgeInsets.only(left: 40), child: leading!),
              ),
            IgnorePointer(
              ignoring: true,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: const RedactModePill(),
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
      onExit:  (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () => ref.read(sidebarPinnedProvider.notifier).state = !isPinned,
        child: Container(
          width: 36,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _hover ? Colors.grey.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(isPinned ? Icons.view_sidebar : Icons.menu, size: 18),
        ),
      ),
    );
  }
}

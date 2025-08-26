import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class WinWindowButtons extends StatelessWidget {
  const WinWindowButtons({super.key});

  @override
  Widget build(BuildContext context) {
    if (Platform.isMacOS) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        _Btn(icon: Icons.remove, action: _BtnAction.minimize),
        _Btn(icon: Icons.crop_square, action: _BtnAction.toggleMax),
        _Btn(icon: Icons.close, action: _BtnAction.close, destructive: true),
      ],
    );
  }
}

enum _BtnAction { minimize, toggleMax, close }

class _Btn extends StatefulWidget {
  const _Btn({
    required this.icon,
    required this.action,
    this.destructive = false,
  });

  final IconData icon;
  final _BtnAction action;
  final bool destructive;

  @override
  State<_Btn> createState() => _BtnState();
}

class _BtnState extends State<_Btn> {
  bool _hover = false;

  Future<void> _handle() async {
    switch (widget.action) {
      case _BtnAction.minimize:
        await windowManager.minimize();
        break;
      case _BtnAction.toggleMax:
        final isMax = await windowManager.isMaximized();
        if (isMax) {
          await windowManager.unmaximize();
        } else {
          await windowManager.maximize();
        }
        break;
      case _BtnAction.close:
        await windowManager.close();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = _hover
        ? (widget.destructive
        ? Colors.red.withOpacity(0.15)
        : Colors.grey.withOpacity(0.15))
        : Colors.transparent;

    final iconColor = widget.destructive
        ? (_hover ? Colors.red : Colors.red.withOpacity(0.85))
        : Theme.of(context).iconTheme.color;

    final btn = GestureDetector(
      onTapDown: (_) => _handle(),
      child: Container(
        width: 38,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(widget.icon, size: 16, color: iconColor),
      ),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: btn,
    );
  }
}

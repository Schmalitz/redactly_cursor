import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class MacWindowButtons extends StatefulWidget {
  const MacWindowButtons({super.key});

  @override
  State<MacWindowButtons> createState() => _MacWindowButtonsState();
}

class _MacWindowButtonsState extends State<MacWindowButtons>
    with WindowListener {
  bool _hover = false;
  bool _focused = true;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _initFocus();
  }

  Future<void> _initFocus() async {
    _focused = await windowManager.isFocused();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowFocus() {
    setState(() => _focused = true);
  }

  @override
  void onWindowBlur() {
    setState(() => _focused = false);
  }

  @override
  Widget build(BuildContext context) {
    // Standard-macOS-Größen etwas kleiner
    const double dotSize = 12;
    const double spacing = 8;

    // Inaktiv: gedimmt (Dots „aus“), Icons nicht sichtbar – wie macOS
    final bool showIcons = _hover && _focused;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MacDot(
            size: dotSize,
            color: _focused ? const Color(0xFFFF5F57) : Colors.grey.shade300,
            icon: Icons.close,
            showIcon: showIcons,
            onTap: () => windowManager.close(),
          ),
          const SizedBox(width: spacing),
          _MacDot(
            size: dotSize,
            color: _focused ? const Color(0xFFFEBC2E) : Colors.grey.shade300,
            icon: Icons.remove,
            showIcon: showIcons,
            onTap: () => windowManager.minimize(),
          ),
          const SizedBox(width: spacing),
          _MacDot(
            size: dotSize,
            color: _focused ? const Color(0xFF28C840) : Colors.grey.shade300,
            icon: Icons.open_in_full,
            showIcon: showIcons,
            onTap: () async {
              final isMax = await windowManager.isMaximized();
              if (isMax) {
                await windowManager.unmaximize();
              } else {
                await windowManager.maximize();
              }
            },
          ),
        ],
      ),
    );
  }
}

class _MacDot extends StatelessWidget {
  const _MacDot({
    required this.color,
    required this.icon,
    required this.showIcon,
    required this.onTap,
    required this.size,
  });

  final Color color;
  final IconData icon;
  final bool showIcon;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    // Icon etwas kleiner als Dot
    final double iconSize = size * 0.75;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => onTap(),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black.withOpacity(0.07)),
        ),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 120),
          opacity: showIcon ? 0.9 : 0.0,
          child: FittedBox(
            child: Icon(icon, size: iconSize, color: Colors.black.withOpacity(0.55)),
          ),
        ),
      ),
    );
  }
}

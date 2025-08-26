import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anonymizer/providers/mode_provider.dart';
import 'package:anonymizer/providers/text_state_provider.dart';

class RedactModePill extends ConsumerStatefulWidget {
  const RedactModePill({super.key});

  @override
  ConsumerState<RedactModePill> createState() => _RedactModePillState();
}

class _RedactModePillState extends ConsumerState<RedactModePill> {
  bool _hover = false;
  bool _focused = false;
  bool _pressed = false;

  void _setMode(RedactMode mode) {
    final current = ref.read(redactModeProvider);
    if (current == mode) return;
    ref.read(redactModeProvider.notifier).state = mode;
    if (mode == RedactMode.deanonymize) {
      ref.read(textInputProvider.notifier).state = '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(redactModeProvider);
    final scheme = Theme.of(context).colorScheme;
    final primary = scheme.primary; // lila Akzent
    final surface = scheme.surface;
    final border = Theme.of(context).dividerColor;

    final activeBg = primary.withOpacity(0.15);
    final activeFg = primary;
    final idleFg = scheme.onSurface.withOpacity(0.85);

    final tooltip = switch (mode) {
      RedactMode.anonymize   => 'Switch to De-Anonymize',
      RedactMode.deanonymize => 'Switch to Anonymize',
    };

    return FocusableActionDetector(
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      onShowHoverHighlight: (v) => setState(() => _hover = v),
      child: Tooltip(
        message: tooltip,
        waitDuration: const Duration(milliseconds: 400),
        child: Listener(
          onPointerDown: (_) => setState(() => _pressed = true),
          onPointerUp:   (_) => setState(() => _pressed = false),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 90),
            scale: _pressed ? 0.98 : 1.0,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Grundkörper
                Container(
                  height: 34,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Color.lerp(surface, Colors.white, 0.3),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: border),
                    boxShadow: _hover
                        ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]
                        : const [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Segment(
                        icon: Icons.blur_on,
                        label: 'Anonymize',
                        active: mode == RedactMode.anonymize,
                        activeBg: activeBg,
                        activeFg: activeFg,
                        idleFg: idleFg,
                        onTap: () => _setMode(RedactMode.anonymize),
                      ),
                      const SizedBox(width: 4),
                      _Segment(
                        icon: Icons.blur_off,
                        label: 'De-Anonymize',
                        active: mode == RedactMode.deanonymize,
                        activeBg: activeBg,
                        activeFg: activeFg,
                        idleFg: idleFg,
                        onTap: () => _setMode(RedactMode.deanonymize),
                      ),
                    ],
                  ),
                ),

                // Fokus-Ring (dezent, lila)
                if (_focused)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: primary.withOpacity(0.35),
                              blurRadius: 12,
                              spreadRadius: 0.2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.icon,
    required this.label,
    required this.active,
    required this.activeBg,
    required this.activeFg,
    required this.idleFg,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final Color activeBg;
  final Color activeFg;
  final Color idleFg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = active ? activeFg : idleFg;
    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: active ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:anonymizer/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anonymizer/models/session.dart';
import 'package:anonymizer/providers/session_provider.dart';
import 'package:anonymizer/providers/settings_provider.dart';

class SessionSidebar extends ConsumerStatefulWidget {
  const SessionSidebar({super.key});

  @override
  ConsumerState<SessionSidebar> createState() => _SessionSidebarState();
}

class _SessionSidebarState extends ConsumerState<SessionSidebar> {
  final TextEditingController _renameController = TextEditingController();
  String? _editingSessionId;

  @override
  void dispose() {
    _renameController.dispose();
    super.dispose();
  }

  void _startEditing(Session session) {
    setState(() {
      _editingSessionId = session.id;
      _renameController.text = session.title;
    });
  }

  void _submitRename(String sessionId) {
    if (_renameController.text.trim().isNotEmpty) {
      ref.read(sessionProvider.notifier).renameSession(
        sessionId,
        _renameController.text.trim(),
      );
    }
    setState(() => _editingSessionId = null);
  }

  @override
  Widget build(BuildContext context) {
    final sessions = ref.watch(sessionProvider);
    final isPinned = ref.watch(sidebarPinnedProvider);
    final activeSessionId = ref.watch(activeSessionIdProvider);

    // Breite rein aus "pinned" (kein Hover-Expand mehr)
    const collapsedWidth = 72.0;
    const expandedWidth  = 260.0;
    final sidebarWidth   = isPinned ? expandedWidth : collapsedWidth;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: sidebarWidth,
      // Sidebar-Farbe kommt von der Shell-Unterlage; hier transparent lassen
      color: Colors.transparent,
      child: Stack(
        children: [
          // Inhalt
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // New Session – identisches Padding wie "Settings", fett
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _HoverItem(
                  isExpanded: isPinned,
                  icon: Icons.add_circle_outline,
                  label: 'New Session',
                  onTap: () =>
                      ref.read(sessionProvider.notifier).createNewSession(),
                  boldLabel: true, // fett
                ),
              ),

              const Divider(indent: 16, endIndent: 16, height: 24),

              if (isPinned)
                Expanded(
                  child: ListView.builder(
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final session   = sessions[index];
                      final isActive  = session.id == activeSessionId;
                      final isEditing = _editingSessionId == session.id;

                      return _SessionListItem(
                        isActive: isActive,
                        isEditing: isEditing,
                        title: session.title,
                        controller: _renameController,
                        onTap: () {
                          if (!isEditing) {
                            ref.read(sessionProvider.notifier).loadSession(session.id);
                          }
                        },
                        onDoubleTap: () => _startEditing(session),
                        onSubmitRename: () => _submitRename(session.id),
                        onStartRename: () => _startEditing(session),
                        onDelete: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Session?'),
                              content: const Text('This cannot be undone.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                          if (ok == true) {
                            ref.read(sessionProvider.notifier).deleteSession(session.id);
                          }
                        },
                      );
                    },
                  ),
                )
              else
              // Collapsed Placeholder
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: SizedBox(
                    height: 44,
                    child: Center(
                      child: Icon(Icons.more_vert, color: Colors.grey.shade500),
                    ),
                  ),
                ),

              const SizedBox(height: 56), // Platz für Settings unten
            ],
          ),

          // Settings unten fixiert (nicht fett)
          Positioned(
            left: 8,
            right: 8,
            bottom: 10,
            child: _HoverItem(
              isExpanded: isPinned,
              icon: Icons.settings,
              label: 'Settings',
              onTap: () {
                // TODO: Settings-Dialog öffnen
              },
              boldLabel: false,
            ),
          ),
        ],
      ),
    );
  }
}

/// Einfache Hover-Zeile (wie Settings/New Session)
class _HoverItem extends StatefulWidget {
  const _HoverItem({
    required this.isExpanded,
    required this.icon,
    required this.label,
    required this.onTap,
    this.boldLabel = false,
  });

  final bool isExpanded;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool boldLabel;

  @override
  State<_HoverItem> createState() => _HoverItemState();
}

class _HoverItemState extends State<_HoverItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final textStyle = TextStyle(
      fontWeight: widget.boldLabel ? FontWeight.w600 : FontWeight.w400,
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit:  (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 40,
          padding: EdgeInsets.symmetric(horizontal: widget.isExpanded ? 12 : 0),
          decoration: BoxDecoration(
            color: _hover ? theme.cHover : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisAlignment: widget.isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 18),
              if (widget.isExpanded) ...[
                const SizedBox(width: 10),
                Text(widget.label, style: textStyle),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Session-Kachel mit konsistentem Hover wie _HoverItem
class _SessionListItem extends StatefulWidget {
  const _SessionListItem({
    required this.isActive,
    required this.isEditing,
    required this.title,
    required this.controller,
    required this.onTap,
    required this.onDoubleTap,
    required this.onSubmitRename,
    required this.onStartRename,
    required this.onDelete,
  });

  final bool isActive;
  final bool isEditing;
  final String title;
  final TextEditingController controller;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  final VoidCallback onSubmitRename;
  final VoidCallback onStartRename;
  final VoidCallback onDelete;

  @override
  State<_SessionListItem> createState() => _SessionListItemState();
}

class _SessionListItemState extends State<_SessionListItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Color hoverBg = theme.cHover; // gleicher Hover wie Settings
    final Color activeBg = Colors.deepPurple.withOpacity(0.10);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit:  (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        onDoubleTap: widget.onDoubleTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Container(
            height: 44,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: widget.isEditing
                  ? hoverBg
                  : (widget.isActive ? activeBg : (_hover ? hoverBg : Colors.transparent)),
              borderRadius: BorderRadius.circular(6), // gleiche Rundung wie _HoverItem
            ),
            child: Row(
              children: [
                Expanded(
                  child: widget.isEditing
                      ? TextField(
                    controller: widget.controller,
                    autofocus: true,
                    style: const TextStyle(fontSize: 14),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 2),
                      isDense: true,
                    ),
                    onSubmitted: (_) => widget.onSubmitRename(),
                    onTapOutside: (_) => widget.onSubmitRename(),
                  )
                      : Text(
                    widget.title, // <— zurückgesetzt
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                if (!widget.isEditing) ...[
                  IconButton(
                    icon: const Icon(Icons.edit, size: 16, color: Colors.grey),
                    onPressed: widget.onStartRename,
                    splashRadius: 18,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 16, color: Colors.grey),
                    onPressed: widget.onDelete,
                    splashRadius: 18,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

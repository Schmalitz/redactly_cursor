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
  bool _isHovering = false;
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
      ref.read(sessionProvider.notifier).renameSession(sessionId, _renameController.text.trim());
    }
    setState(() => _editingSessionId = null);
  }

  @override
  Widget build(BuildContext context) {
    final sessions = ref.watch(sessionProvider);
    final isPinned = ref.watch(sidebarPinnedProvider);
    final activeSessionId = ref.watch(activeSessionIdProvider);

    final isExpanded = isPinned || _isHovering;
    final collapsedWidth = 72.0;
    final expandedWidth = 260.0;
    final sidebarWidth = isExpanded ? expandedWidth : collapsedWidth;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: sidebarWidth,
        color: Colors.grey.shade100,
        child: Stack(
          children: [
            // Inhalt
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                // New Session (Burger-Style Hover)
                _HoverItem(
                  isExpanded: isExpanded,
                  icon: Icons.add_circle_outline,
                  label: 'New Session',
                  onTap: () => ref.read(sessionProvider.notifier).createNewSession(),
                ),
                const Divider(indent: 16, endIndent: 16, height: 24),

                if (isExpanded)
                  Expanded(
                    child: ListView.builder(
                      itemCount: sessions.length,
                      itemBuilder: (context, index) {
                        final session = sessions[index];
                        final isActive = session.id == activeSessionId;
                        final isEditing = _editingSessionId == session.id;

                        return InkWell(
                          onTap: () {
                            if (!isEditing) {
                              ref.read(sessionProvider.notifier).loadSession(session.id);
                            }
                          },
                          onDoubleTap: () => _startEditing(session),
                          child: Container(
                            height: 44,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(
                              color: isActive ? Colors.deepPurple.withOpacity(0.1) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: isEditing
                                      ? TextField(
                                    controller: _renameController,
                                    autofocus: true,
                                    style: const TextStyle(fontSize: 14),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(vertical: 2),
                                      isDense: true,
                                    ),
                                    onSubmitted: (_) => _submitRename(session.id),
                                    onTapOutside: (_) => _submitRename(session.id),
                                  )
                                      : Text(session.title,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 14)),
                                ),
                                if (!isEditing) ...[
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 16, color: Colors.grey),
                                    onPressed: () => _startEditing(session),
                                    splashRadius: 18,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 16, color: Colors.grey),
                                    onPressed: () async {
                                      final ok = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Delete Session?'),
                                          content: const Text('This cannot be undone.'),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                          ],
                                        ),
                                      );
                                      if (ok == true) {
                                        ref.read(sessionProvider.notifier).deleteSession(session.id);
                                      }
                                    },
                                    splashRadius: 18,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  )
                else
                // Collapsed Placeholder
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    child: Container(
                      height: 44,
                      alignment: Alignment.center,
                      child: const Icon(Icons.more_vert, color: Colors.grey),
                    ),
                  ),
                const SizedBox(height: 56), // Platz für Settings unten
              ],
            ),

            // Settings unten fixiert (Burger-Style Hover, schlicht)
            Positioned(
              left: 8,
              right: 8,
              bottom: 10,
              child: _HoverItem(
                isExpanded: isExpanded,
                icon: Icons.settings,
                label: 'Settings',
                onTap: () {
                  // TODO: Settings-Dialog öffnen
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HoverItem extends StatefulWidget {
  const _HoverItem({
    required this.isExpanded,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool isExpanded;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  State<_HoverItem> createState() => _HoverItemState();
}

class _HoverItemState extends State<_HoverItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 40,
          padding: EdgeInsets.symmetric(horizontal: widget.isExpanded ? 12 : 0),
          decoration: BoxDecoration(
            color: _hover ? Colors.grey.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisAlignment: widget.isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 18),
              if (widget.isExpanded) ...[
                const SizedBox(width: 10),
                Text(widget.label, style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

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
      ref
          .read(sessionProvider.notifier)
          .renameSession(sessionId, _renameController.text.trim());
    }
    setState(() {
      _editingSessionId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sessions = ref.watch(sessionProvider);
    final isPinned = ref.watch(sidebarPinnedProvider);
    final activeSessionId = ref.watch(activeSessionIdProvider);

    final isExpanded = isPinned || _isHovering;
    final sidebarWidth = isExpanded ? 250.0 : 70.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: sidebarWidth,
        color: Colors.grey.shade100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 60,
              alignment: isExpanded ? Alignment.centerLeft : Alignment.center,
              padding: EdgeInsets.only(left: isExpanded ? 16.0 : 0),
              child: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  ref.read(sidebarPinnedProvider.notifier).state = !isPinned;
                },
              ),
            ),
            InkWell(
              onTap: () {
                ref.read(sessionProvider.notifier).createNewSession();
              },
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: isExpanded
                    ? const Row(
                        children: [
                          Icon(Icons.add_circle_outline),
                          SizedBox(width: 16),
                          Text('New Session',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      )
                    : const Center(child: Icon(Icons.add_circle_outline)),
              ),
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
                        height: 48,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.deepPurple.withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
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
                                  : Text(
                                session.title,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            if (!isEditing) ...[
                              IconButton(
                                icon: const Icon(Icons.edit, size: 16, color: Colors.grey),
                                onPressed: () => _startEditing(session),
                                splashRadius: 20,
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    size: 16, color: Colors.grey),
                                onPressed: () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete Session?'),
                                      content: const Text(
                                          'Do you really want to delete this session? This cannot be undone.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(true),
                                          child: const Text('Delete',
                                              style: TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirmed == true) {
                                    ref
                                        .read(sessionProvider.notifier)
                                        .deleteSession(session.id);
                                  }
                                },
                                splashRadius: 20,
                              ),
                            ]
                          ],
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Container(
                  height: 48,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Icon(Icons.more_vert, color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

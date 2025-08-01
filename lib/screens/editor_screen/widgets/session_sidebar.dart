import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:redactly/providers/session_provider.dart';
import 'package:redactly/providers/settings_provider.dart';

class SessionSidebar extends ConsumerStatefulWidget {
  const SessionSidebar({super.key});

  @override
  ConsumerState<SessionSidebar> createState() => _SessionSidebarState();
}

class _SessionSidebarState extends ConsumerState<SessionSidebar> {
  bool _isHovering = false;

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
            Expanded(
              child: ListView.builder(
                itemCount: sessions.length,
                itemBuilder: (context, index) {
                  final session = sessions[index];
                  final isActive = session.id == activeSessionId;
                  return InkWell(
                    onTap: () {
                      ref
                          .read(sessionProvider.notifier)
                          .loadSession(session.id);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.deepPurple.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      margin:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      child: isExpanded
                          ? Row(
                        children: [
                          const Icon(Icons.history, size: 20),
                          const SizedBox(width: 16),
                          Expanded(
                              child: Text(
                                session.title,
                                overflow: TextOverflow.ellipsis,
                              )),
                        ],
                      )
                          : const Center(child: Icon(Icons.history, size: 20)),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'chat_folders_rail.dart';
import 'chat_list_screen.dart' show ChatListPane;
import 'chat_screen.dart';
import 'thread_screen.dart';
import 'workspace_nav_rail.dart';

/// Desktop multi-pane layout (как в веб-версии LighChat):
///
///   ┌──────┬──────┬──────────┬─────────────┬──────────┐
///   │ rail │ fld. │ chat list│  open chat  │ thread   │
///   │ 72dp │ 96dp │  360dp   │  flex       │ 420dp    │
///   │ nav  │ rail │  master  │  detail     │ opt.     │
///   └──────┴──────┴──────────┴─────────────┴──────────┘
///
/// Адаптация по ширине окна:
/// - **≥1440dp**: до 5 колонок (rail + folders + list + detail + thread).
/// - **1200–1440dp**: 4 колонки (rail + folders + list + detail).
/// - **1024–1200dp**: 3 колонки (rail + list + detail, без folders rail).
/// - **840–1024dp**: 2 колонки (list + detail).
/// - **<840dp**: одна панель (fallback на mobile-like compact).
///
/// Thread pane показывается только при `threadId != null` И ширине ≥1440dp.
/// На более узких экранах thread открывается push'ом на отдельный экран.
///
/// Mobile-маршруты `/chats`+`/chats/:id` не трогаются — этот экран только
/// на маршрутах `/workspace/*`.
class WorkspaceShellScreen extends StatelessWidget {
  const WorkspaceShellScreen({
    super.key,
    this.conversationId,
    this.threadParentMessageId,
  });

  final String? conversationId;

  /// Если задан — рендерим thread pane справа от ChatScreen.
  /// URL-маршрут: `/workspace/chats/:cid/thread/:tid`.
  final String? threadParentMessageId;

  static const double _twoPaneBreakpoint = 840;
  static const double _threePaneBreakpoint = 1024;
  static const double _fourPaneBreakpoint = 1200;
  static const double _fivePaneBreakpoint = 1440;
  static const double _masterWidth = 360;
  static const double _threadWidth = 420;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          if (w < _twoPaneBreakpoint) {
            return conversationId == null
                ? ChatListPane()
                : ChatScreen(conversationId: conversationId!);
          }

          final showRail = w >= _threePaneBreakpoint;
          final showFoldersRail = w >= _fourPaneBreakpoint;
          final showThreadPane = w >= _fivePaneBreakpoint &&
              threadParentMessageId != null &&
              conversationId != null;
          final detailPane = conversationId == null
              ? const _EmptyDetailPlaceholder()
              : ChatScreen(
                  key: ValueKey(conversationId),
                  conversationId: conversationId!,
                );
          final threadPane = showThreadPane
              ? _ThreadPane(
                  key: ValueKey(
                      '${conversationId!}_${threadParentMessageId!}'),
                  conversationId: conversationId!,
                  parentMessageId: threadParentMessageId!,
                )
              : null;

          return Row(
            children: [
              if (showRail) ...[
                WorkspaceNavRail(
                  activeRoute: conversationId == null
                      ? '/workspace'
                      : '/workspace/chats/$conversationId',
                ),
                const VerticalDivider(width: 1, thickness: 1),
              ],
              if (showFoldersRail) ...[
                const ChatFoldersRail(),
                const VerticalDivider(width: 1, thickness: 1),
              ],
              SizedBox(
                width: _masterWidth,
                child: ChatListPane(hideBottomNav: showRail),
              ),
              const VerticalDivider(width: 1, thickness: 1),
              Expanded(child: detailPane),
              if (threadPane != null) ...[
                const VerticalDivider(width: 1, thickness: 1),
                SizedBox(width: _threadWidth, child: threadPane),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ThreadPane extends StatelessWidget {
  const _ThreadPane({
    super.key,
    required this.conversationId,
    required this.parentMessageId,
  });

  final String conversationId;
  final String parentMessageId;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Theme.of(context).colorScheme.surfaceContainer,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Закрыть обсуждение',
                  onPressed: () =>
                      context.go('/workspace/chats/$conversationId'),
                ),
                Expanded(
                  child: Text(
                    'Обсуждение',
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ThreadScreen(
            conversationId: conversationId,
            parentMessageId: parentMessageId,
          ),
        ),
      ],
    );
  }
}

class _EmptyDetailPlaceholder extends StatelessWidget {
  const _EmptyDetailPlaceholder();

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      color: c.surface,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: c.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              'Выберите чат',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: c.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

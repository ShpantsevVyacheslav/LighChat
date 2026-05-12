import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lighchat_mobile/features/admin/ui/admin_shell_screen.dart';
import 'chat_calls_screen.dart';
import 'chat_contacts_screen.dart';
import 'chat_list_screen.dart' show ChatListPane;
import 'chat_meetings_screen.dart';
import 'chat_screen.dart';
import 'chat_settings_screen.dart';
import 'thread_screen.dart';
import 'workspace_unified_rail.dart';

/// Тип контента, отображаемого в правой (detail) панели workspace shell.
/// Master-pane (список чатов) при этом ОСТАЁТСЯ виден — переключается
/// только правая часть, повторяя layout web-версии LighChat.
enum WorkspaceDetailKind {
  /// Чат (открытый conversationId) или плейсхолдер «Выберите чат».
  chat,

  /// Контакты.
  contacts,

  /// Журнал звонков.
  calls,

  /// Видеоконференции.
  meetings,

  /// Настройки.
  settings,

  /// Админ-панель (role-gated на роутере).
  admin,
}

/// Desktop multi-pane layout (как в веб-версии LighChat):
///
///   ┌──────┬──────────┬─────────────┬──────────┐
///   │ rail │ chat list│   detail    │ thread   │
///   │ 64dp │ + bottom │             │ 420dp    │
///   │logo+ │   nav    │             │ opt.     │
///   │folde-│  master  │             │          │
///   │rs +  │          │             │          │
///   │ava   │          │             │          │
///   └──────┴──────────┴─────────────┴──────────┘
///
/// - Rail (64dp): logo (top), folders, avatar (bottom).
/// - Master (chat list, resizable 260–520dp): список диалогов + bottom-nav
///   с табами (Чаты / Контакты / Звонки / Видеоконф) под ним.
/// - Detail (flex): зависит от [detailKind] — открытый чат, contacts,
///   calls, meetings, settings или admin. Master при этом не пропадает.
/// - Thread (420dp, optional): обсуждение справа от чата при достаточной
///   ширине окна и активном thread route.
///
/// Кнопка collapse (по лого) сворачивает master — остаётся только rail +
/// detail (для фокус-режима).
///
/// Адаптация по ширине окна:
/// - **≥1440dp**: до 4 колонок (rail + list + detail + thread).
/// - **1024–1440dp**: 3 колонки (rail + list + detail).
/// - **840–1024dp**: 2 колонки (list + detail).
/// - **<840dp**: одна панель (fallback на mobile-like compact).
class WorkspaceShellScreen extends StatefulWidget {
  const WorkspaceShellScreen({
    super.key,
    this.conversationId,
    this.threadParentMessageId,
    this.detailKind = WorkspaceDetailKind.chat,
  });

  final String? conversationId;

  /// Если задан — рендерим thread pane справа от ChatScreen.
  /// URL-маршрут: `/workspace/chats/:cid/thread/:tid`.
  final String? threadParentMessageId;

  /// Какой экран рендерить в правой панели (master остаётся видимым).
  final WorkspaceDetailKind detailKind;

  static const double _twoPaneBreakpoint = 840;
  static const double _threePaneBreakpoint = 1024;
  static const double _fourPaneBreakpoint = 1440;

  // Master pane: ширина настраиваемая, в этих границах.
  static const double _masterDefaultWidth = 340;
  static const double _masterMinWidth = 260;
  static const double _masterMaxWidth = 520;

  // Thread pane: ширина настраиваемая, в этих границах.
  static const double _threadDefaultWidth = 420;
  static const double _threadMinWidth = 320;
  static const double _threadMaxWidth = 640;

  static const String _kMasterWidthKey = 'workspace.masterWidth';
  static const String _kThreadWidthKey = 'workspace.threadWidth';
  static const String _kCollapsedKey = 'workspace.masterCollapsed';

  @override
  State<WorkspaceShellScreen> createState() => _WorkspaceShellScreenState();
}

class _WorkspaceShellScreenState extends State<WorkspaceShellScreen> {
  double _masterWidth = WorkspaceShellScreen._masterDefaultWidth;
  double _threadWidth = WorkspaceShellScreen._threadDefaultWidth;
  bool _collapsed = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final w = prefs.getDouble(WorkspaceShellScreen._kMasterWidthKey);
    final tw = prefs.getDouble(WorkspaceShellScreen._kThreadWidthKey);
    final c = prefs.getBool(WorkspaceShellScreen._kCollapsedKey) ?? false;
    if (!mounted) return;
    setState(() {
      if (w != null) {
        _masterWidth = w.clamp(
          WorkspaceShellScreen._masterMinWidth,
          WorkspaceShellScreen._masterMaxWidth,
        );
      }
      if (tw != null) {
        _threadWidth = tw.clamp(
          WorkspaceShellScreen._threadMinWidth,
          WorkspaceShellScreen._threadMaxWidth,
        );
      }
      _collapsed = c;
      _loaded = true;
    });
  }

  Future<void> _persistWidth(double w) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(WorkspaceShellScreen._kMasterWidthKey, w);
  }

  Future<void> _persistThreadWidth(double w) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(WorkspaceShellScreen._kThreadWidthKey, w);
  }

  Future<void> _toggleCollapsed() async {
    setState(() => _collapsed = !_collapsed);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(WorkspaceShellScreen._kCollapsedKey, _collapsed);
  }

  Widget _buildDetailPane() {
    switch (widget.detailKind) {
      case WorkspaceDetailKind.contacts:
        return const ChatContactsScreen();
      case WorkspaceDetailKind.calls:
        return const ChatCallsScreen();
      case WorkspaceDetailKind.meetings:
        return const ChatMeetingsScreen();
      case WorkspaceDetailKind.settings:
        return const ChatSettingsScreen();
      case WorkspaceDetailKind.admin:
        return const AdminShellScreen();
      case WorkspaceDetailKind.chat:
        if (widget.conversationId == null) {
          return _EmptyDetailPlaceholder(
            onExpandMaster: _collapsed ? _toggleCollapsed : null,
          );
        }
        return ChatScreen(
          key: ValueKey(widget.conversationId),
          conversationId: widget.conversationId!,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          if (w < WorkspaceShellScreen._twoPaneBreakpoint) {
            // Compact: единственная панель. Detail приоритетнее — это
            // прямое поведение мобильного приложения, чтобы пользователь
            // мог легко вернуться через кнопку «назад» в детальном экране.
            if (widget.detailKind != WorkspaceDetailKind.chat) {
              return _buildDetailPane();
            }
            return widget.conversationId == null
                ? const ChatListPane()
                : ChatScreen(conversationId: widget.conversationId!);
          }

          final showRail = w >= WorkspaceShellScreen._threePaneBreakpoint;
          final showThreadPane = w >=
                  WorkspaceShellScreen._fourPaneBreakpoint &&
              widget.threadParentMessageId != null &&
              widget.conversationId != null &&
              widget.detailKind == WorkspaceDetailKind.chat;

          final detailPane = _buildDetailPane();
          final threadPane = showThreadPane
              ? _ThreadPane(
                  key: ValueKey(
                      '${widget.conversationId!}_${widget.threadParentMessageId!}'),
                  conversationId: widget.conversationId!,
                  parentMessageId: widget.threadParentMessageId!,
                )
              : null;

          return Row(
            children: [
              if (showRail) ...[
                WorkspaceUnifiedRail(
                  activeRoute: _activeRoute(),
                  onLogoTap: _toggleCollapsed,
                ),
                const VerticalDivider(width: 1, thickness: 1),
              ],
              if (!_collapsed) ...[
                SizedBox(
                  width: _masterWidth,
                  child: _MasterPane(
                    showCollapse: true,
                    onCollapse: _toggleCollapsed,
                    // Bottom-nav в chat list-е оставляем видимым — там
                    // живут tabs (Чаты / Контакты / Звонки / Видеоконф),
                    // как в web (`DashboardBottomNav variant=chatSidebar`).
                    hideBottomNav: false,
                  ),
                ),
                _ResizableSplitter(
                  onDrag: (delta) {
                    setState(() {
                      _masterWidth = (_masterWidth + delta).clamp(
                        WorkspaceShellScreen._masterMinWidth,
                        WorkspaceShellScreen._masterMaxWidth,
                      );
                    });
                  },
                  onDragEnd: () => _persistWidth(_masterWidth),
                ),
              ],
              Expanded(child: detailPane),
              if (threadPane != null) ...[
                _ResizableSplitter(
                  onDrag: (delta) {
                    setState(() {
                      // Перетаскивание влево уменьшает thread (расширяет
                      // detail) — поэтому вычитаем delta.dx.
                      _threadWidth = (_threadWidth - delta).clamp(
                        WorkspaceShellScreen._threadMinWidth,
                        WorkspaceShellScreen._threadMaxWidth,
                      );
                    });
                  },
                  onDragEnd: () => _persistThreadWidth(_threadWidth),
                ),
                SizedBox(
                  width: _threadWidth,
                  child: threadPane,
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  String _activeRoute() {
    switch (widget.detailKind) {
      case WorkspaceDetailKind.contacts:
        return '/workspace/contacts';
      case WorkspaceDetailKind.calls:
        return '/workspace/calls';
      case WorkspaceDetailKind.meetings:
        return '/workspace/meetings';
      case WorkspaceDetailKind.settings:
        return '/workspace/settings';
      case WorkspaceDetailKind.admin:
        return '/workspace/admin';
      case WorkspaceDetailKind.chat:
        return widget.conversationId == null
            ? '/workspace'
            : '/workspace/chats/${widget.conversationId}';
    }
  }
}

/// Обёртка над [ChatListPane] с кнопкой collapse в правом верхнем углу.
class _MasterPane extends StatelessWidget {
  const _MasterPane({
    required this.showCollapse,
    required this.onCollapse,
    required this.hideBottomNav,
  });

  final bool showCollapse;
  final VoidCallback onCollapse;
  final bool hideBottomNav;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ChatListPane(hideBottomNav: hideBottomNav),
        if (showCollapse)
          Positioned(
            top: 6,
            right: 6,
            child: Material(
              color: Colors.transparent,
              child: IconButton(
                tooltip: 'Свернуть список (focus mode)',
                icon: const Icon(Icons.chevron_left, size: 20),
                visualDensity: VisualDensity.compact,
                onPressed: onCollapse,
              ),
            ),
          ),
      ],
    );
  }
}

/// Вертикальный resizable splitter между master ↔ detail. Курсор меняется
/// на `resizeColumn`, при drag вызывает [onDrag] с дельтой по X.
class _ResizableSplitter extends StatefulWidget {
  const _ResizableSplitter({required this.onDrag, required this.onDragEnd});

  final ValueChanged<double> onDrag;
  final VoidCallback onDragEnd;

  @override
  State<_ResizableSplitter> createState() => _ResizableSplitterState();
}

class _ResizableSplitterState extends State<_ResizableSplitter> {
  bool _hover = false;
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final highlight = _hover || _dragging;
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: (_) => setState(() => _dragging = true),
        onHorizontalDragUpdate: (d) => widget.onDrag(d.delta.dx),
        onHorizontalDragEnd: (_) {
          setState(() => _dragging = false);
          widget.onDragEnd();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 6,
          color: highlight
              ? c.primary.withValues(alpha: 0.25)
              : c.outlineVariant.withValues(alpha: 0.3),
          child: Center(
            child: Container(
              width: 1,
              height: 32,
              color: highlight ? c.primary : c.outlineVariant,
            ),
          ),
        ),
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
  const _EmptyDetailPlaceholder({this.onExpandMaster});

  /// Если master свёрнут — даём кнопку «развернуть».
  final VoidCallback? onExpandMaster;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      color: c.surface,
      child: Stack(
        children: [
          if (onExpandMaster != null)
            Positioned(
              top: 6,
              left: 6,
              child: IconButton(
                tooltip: 'Показать список чатов',
                icon: const Icon(Icons.chevron_right),
                onPressed: onExpandMaster,
              ),
            ),
          Center(
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
        ],
      ),
    );
  }
}

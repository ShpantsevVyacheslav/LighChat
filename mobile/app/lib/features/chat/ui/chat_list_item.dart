import 'package:flutter/material.dart';
import 'package:lighchat_models/lighchat_models.dart';

import '../../../l10n/app_localizations.dart';
import 'chat_cached_network_image.dart';

class ChatListItem extends StatefulWidget {
  const ChatListItem({
    super.key,
    required this.conversation,
    required this.title,
    required this.subtitle,
    required this.unreadCount,
    required this.trailingTimeLabel,
    this.avatarUrl,
    this.isOnline = false,
    required this.onTap,
    this.onLongPress,
    this.onFoldersTap,
    this.onClearTap,
    this.onDeleteTap,
    this.enableSwipeActions = false,
    this.allowDelete = true,
    this.isPinned = false,
    this.unreadReactionEmoji,
  });

  final ConversationWithId conversation;
  final String title;
  final String subtitle;
  final int unreadCount;
  final String trailingTimeLabel;
  final String? avatarUrl;
  final bool isOnline;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onFoldersTap;
  final VoidCallback? onClearTap;
  final VoidCallback? onDeleteTap;
  final bool enableSwipeActions;
  final bool allowDelete;
  final bool isPinned;
  final String? unreadReactionEmoji;

  @override
  State<ChatListItem> createState() => _ChatListItemState();
}

class _ChatListItemState extends State<ChatListItem> {
  static const double _actionWidth = 84;
  double _swipeX = 0;

  double get _maxSwipe {
    final count = widget.allowDelete ? 3 : 2;
    return count * _actionWidth;
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    if (!widget.enableSwipeActions) return;
    final next = (_swipeX - details.delta.dx).clamp(0.0, _maxSwipe);
    setState(() => _swipeX = next);
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    if (!widget.enableSwipeActions) return;
    final shouldOpen = _swipeX > (_maxSwipe * 0.35);
    setState(() => _swipeX = shouldOpen ? _maxSwipe : 0);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        children: [
          if (widget.enableSwipeActions)
            Positioned(
              top: 0,
              right: 0,
              bottom: 0,
              width: _swipeX,
              child: ClipRect(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: _maxSwipe,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.onFoldersTap != null)
                          _SwipeActionButton(
                            width: _actionWidth,
                            background: const Color(0xFF6ED0D8),
                            icon: Icons.folder_open_rounded,
                            label: AppLocalizations.of(context)!.chat_list_swipe_folders,
                            onTap: () {
                              widget.onFoldersTap!.call();
                              setState(() => _swipeX = 0);
                            },
                          ),
                        if (widget.onClearTap != null)
                          _SwipeActionButton(
                            width: _actionWidth,
                            background: const Color(0xFFF0AA3C),
                            icon: Icons.auto_fix_off_rounded,
                            label: AppLocalizations.of(context)!.chat_list_swipe_clear,
                            onTap: () {
                              widget.onClearTap!.call();
                              setState(() => _swipeX = 0);
                            },
                          ),
                        if (widget.allowDelete && widget.onDeleteTap != null)
                          _SwipeActionButton(
                            width: _actionWidth,
                            background: const Color(0xFFE2554D),
                            icon: Icons.delete_outline_rounded,
                            label: AppLocalizations.of(context)!.chat_list_swipe_delete,
                            onTap: () {
                              widget.onDeleteTap!.call();
                              setState(() => _swipeX = 0);
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          GestureDetector(
            onHorizontalDragUpdate: _handleHorizontalDragUpdate,
            onHorizontalDragEnd: _handleHorizontalDragEnd,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              transform: Matrix4.translationValues(-_swipeX, 0, 0),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    if (_swipeX > 0) {
                      setState(() => _swipeX = 0);
                      return;
                    }
                    widget.onTap();
                  },
                  onLongPress: widget.onLongPress,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    color: Colors.transparent,
                    child: Row(
                      children: [
                        _AvatarCircle(
                          title: widget.title,
                          avatarUrl: widget.avatarUrl,
                          isOnline: widget.isOnline,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      widget.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  if (widget.isPinned) ...[
                                    const SizedBox(width: 6),
                                    Icon(
                                      Icons.push_pin_rounded,
                                      size: 14,
                                      color: const Color(0xFF2A79FF),
                                    ),
                                  ],
                                ],
                              ),
                              if (widget.subtitle.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  widget.subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: scheme.onSurface.withValues(
                                      alpha: dark ? 0.50 : 0.58,
                                    ),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              widget.trailingTimeLabel,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: scheme.onSurface.withValues(
                                  alpha: dark ? 0.45 : 0.52,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (widget.unreadReactionEmoji != null) ...[
                              Text(
                                widget.unreadReactionEmoji!,
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 2),
                            ],
                            if (widget.unreadCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2A79FF),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  widget.unreadCount > 99
                                      ? '99+'
                                      : '${widget.unreadCount}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwipeActionButton extends StatelessWidget {
  const _SwipeActionButton({
    required this.width,
    required this.background,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final double width;
  final Color background;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Material(
        color: background,
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
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

class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final initial = title.trim().isEmpty
        ? '?'
        : title.trim().characters.first.toUpperCase();
    final dark = Theme.of(context).colorScheme.brightness == Brightness.dark;
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [Color(0xFF18357C), Color(0xFF29133F)]
              : const [Color(0xFFE5ECFF), Color(0xFFDCE5FF)],
        ),
        border: Border.all(
          color: dark
              ? Colors.white.withValues(alpha: 0.18)
              : Colors.black.withValues(alpha: 0.10),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: dark ? Colors.white : const Color(0xFF23315F),
        ),
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({
    required this.title,
    required this.avatarUrl,
    required this.isOnline,
  });

  final String title;
  final String? avatarUrl;
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl;
    final canRender =
        url != null && url.trim().isNotEmpty && !_looksLikeSvg(url);
    if (canRender) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          ClipOval(
            child: SizedBox(
              width: 50,
              height: 50,
              child: ChatCachedNetworkImage(
                url: url,
                fit: BoxFit.cover,
                compact: true,
                errorOverride: _AvatarPlaceholder(title: title),
              ),
            ),
          ),
          if (isOnline) const _OnlineBadge(),
        ],
      );
    }
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _AvatarPlaceholder(title: title),
        if (isOnline) const _OnlineBadge(),
      ],
    );
  }

  bool _looksLikeSvg(String url) {
    final u = url.toLowerCase();
    if (u.contains('/svg')) return true;
    if (u.endsWith('.svg')) return true;
    if (u.contains('format=svg')) return true;
    return false;
  }
}

class _OnlineBadge extends StatelessWidget {
  const _OnlineBadge();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).colorScheme.brightness == Brightness.dark;
    return Positioned(
      right: -1,
      bottom: -1,
      child: Container(
        width: 13,
        height: 13,
        decoration: BoxDecoration(
          color: const Color(0xFF00C35F),
          shape: BoxShape.circle,
          border: Border.all(
            color: dark ? const Color(0xFF05070D) : Colors.white,
            width: 2,
          ),
        ),
      ),
    );
  }
}

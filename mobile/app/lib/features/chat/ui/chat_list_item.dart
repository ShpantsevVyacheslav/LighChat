import 'package:flutter/material.dart';
import 'package:lighchat_models/lighchat_models.dart';

import 'chat_cached_network_image.dart';

class ChatListItem extends StatelessWidget {
  const ChatListItem({
    super.key,
    required this.conversation,
    required this.title,
    required this.subtitle,
    required this.unreadCount,
    required this.trailingTimeLabel,
    this.avatarUrl,
    required this.onTap,
  });

  final ConversationWithId conversation;
  final String title;
  final String subtitle;
  final int unreadCount;
  final String trailingTimeLabel;
  final String? avatarUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withValues(alpha: dark ? 0.10 : 0.35),
          ),
          color: Colors.white.withValues(alpha: dark ? 0.06 : 0.22),
        ),
        child: Row(
          children: [
            _AvatarCircle(title: title, avatarUrl: avatarUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurface.withValues(alpha: 0.60),
                        fontWeight: FontWeight.w600,
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
                  trailingTimeLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 8),
                if (unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: scheme.onPrimary,
                      ),
                    ),
                  ),
              ],
            ),
          ],
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
    final scheme = Theme.of(context).colorScheme;
    final initial = title.trim().isEmpty
        ? '?'
        : title.trim().characters.first.toUpperCase();
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: scheme.primary.withValues(alpha: 0.18),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.22)),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          color: scheme.primary,
        ),
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({required this.title, required this.avatarUrl});

  final String title;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl;
    final canRender =
        url != null && url.trim().isNotEmpty && !_looksLikeSvg(url);
    if (canRender) {
      return ClipOval(
        child: SizedBox(
          width: 44,
          height: 44,
          child: ChatCachedNetworkImage(
            url: url,
            fit: BoxFit.cover,
            compact: true,
            errorOverride: _AvatarPlaceholder(title: title),
          ),
        ),
      );
    }
    return _AvatarPlaceholder(title: title);
  }

  bool _looksLikeSvg(String url) {
    final u = url.toLowerCase();
    if (u.contains('/svg')) return true;
    if (u.endsWith('.svg')) return true;
    if (u.contains('format=svg')) return true;
    return false;
  }
}

import 'package:flutter/material.dart';

import 'chat_avatar.dart';

class ChatHeader extends StatelessWidget {
  const ChatHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.avatarUrl,
    required this.onBack,
    required this.showCalls,
    required this.onThreadsTap,
    required this.onSearchTap,
    required this.onVideoCallTap,
    required this.onAudioCallTap,
    this.onProfileTap,
  });

  final String title;
  final String subtitle;
  final String? avatarUrl;
  final VoidCallback onBack;
  final bool showCalls;
  final VoidCallback onThreadsTap;
  final VoidCallback onSearchTap;
  final VoidCallback onVideoCallTap;
  final VoidCallback onAudioCallTap;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = scheme.onSurface;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Назад',
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
          GestureDetector(
            onTap: onProfileTap,
            behavior: HitTestBehavior.opaque,
            child: ChatAvatar(title: title, radius: 18, avatarUrl: avatarUrl),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: onProfileTap,
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: fg.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Треды',
            onPressed: onThreadsTap,
            icon: const Icon(Icons.forum_rounded),
          ),
          IconButton(
            tooltip: 'Поиск',
            onPressed: onSearchTap,
            icon: const Icon(Icons.search_rounded),
          ),
          if (showCalls) ...[
            IconButton(
              tooltip: 'Видеозвонок',
              onPressed: onVideoCallTap,
              icon: const Icon(Icons.videocam_rounded),
            ),
            IconButton(
              tooltip: 'Аудиозвонок',
              onPressed: onAudioCallTap,
              icon: const Icon(Icons.call_rounded),
            ),
          ],
        ],
      ),
    );
  }
}


import 'dart:ui';

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
    this.threadsUnreadCount = 0,
    required this.onSearchTap,
    required this.onVideoCallTap,
    required this.onAudioCallTap,
    this.onProfileTap,
    this.searchActive = false,
    this.searchController,
    this.searchFocusNode,
    this.onSearchClose,
  });

  final String title;
  final String subtitle;
  final String? avatarUrl;
  final VoidCallback onBack;
  final bool showCalls;
  final VoidCallback onThreadsTap;
  /// Сумма непрочитанных по веткам (`conversations.unreadThreadCounts[currentUser]`).
  final int threadsUnreadCount;
  final VoidCallback onSearchTap;
  final VoidCallback onVideoCallTap;
  final VoidCallback onAudioCallTap;
  final VoidCallback? onProfileTap;

  /// Режим поиска по сообщениям (как шапка веб-чата).
  final bool searchActive;
  final TextEditingController? searchController;
  final FocusNode? searchFocusNode;
  final VoidCallback? onSearchClose;

  @override
  Widget build(BuildContext context) {
    final fg = Colors.white.withValues(alpha: 0.96);

    if (searchActive &&
        searchController != null &&
        searchFocusNode != null &&
        onSearchClose != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.fromLTRB(4, 6, 10, 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.22),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.14),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Назад',
                  onPressed: onSearchClose,
                  color: fg,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                Expanded(
                  child: ListenableBuilder(
                    listenable: searchController!,
                    builder: (context, _) {
                      final q = searchController!.text;
                      return TextField(
                        controller: searchController,
                        focusNode: searchFocusNode,
                        style: TextStyle(color: fg, fontSize: 15),
                        cursorColor: fg,
                        decoration: InputDecoration(
                          hintText: 'Поиск сообщений…',
                          hintStyle: TextStyle(
                            color: fg.withValues(alpha: 0.55),
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          isDense: true,
                          suffixIcon: q.isNotEmpty
                              ? IconButton(
                                  tooltip: 'Очистить',
                                  onPressed: () => searchController!.clear(),
                                  icon: Icon(
                                    Icons.close_rounded,
                                    color: fg.withValues(alpha: 0.7),
                                    size: 20,
                                  ),
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget glassIcon({
      required IconData icon,
      required VoidCallback onTap,
      required String tooltip,
    }) {
      return Padding(
        padding: const EdgeInsets.only(left: 6),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: IconButton(
            tooltip: tooltip,
            onPressed: onTap,
            iconSize: 18,
            color: fg,
            padding: EdgeInsets.zero,
            icon: Icon(icon),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 6, 10, 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.22),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.14),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Назад',
                onPressed: onBack,
                color: fg,
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
              ),
              GestureDetector(
                onTap: onProfileTap,
                behavior: HitTestBehavior.opaque,
                child: ChatAvatar(
                  title: title,
                  radius: 18,
                  avatarUrl: avatarUrl,
                ),
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
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: fg,
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: fg.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Badge.count(
                  count: threadsUnreadCount,
                  isLabelVisible: threadsUnreadCount > 0,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                    ),
                    child: IconButton(
                      tooltip: 'Обсуждения',
                      onPressed: onThreadsTap,
                      iconSize: 18,
                      color: fg,
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.forum_rounded),
                    ),
                  ),
                ),
              ),
              glassIcon(
                tooltip: 'Поиск',
                onTap: onSearchTap,
                icon: Icons.search_rounded,
              ),
              if (showCalls) ...[
                glassIcon(
                  tooltip: 'Видеозвонок',
                  onTap: onVideoCallTap,
                  icon: Icons.videocam_rounded,
                ),
                glassIcon(
                  tooltip: 'Аудиозвонок',
                  onTap: onAudioCallTap,
                  icon: Icons.call_rounded,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

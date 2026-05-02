import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
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
    this.scheduledCount = 0,
    this.onScheduledTap,
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

  /// Количество запланированных сообщений текущего пользователя в этом чате.
  /// Иконка-будильник в шапке появляется только если > 0.
  final int scheduledCount;
  final VoidCallback? onScheduledTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fg = Colors.white.withValues(alpha: 0.96);

    if (searchActive &&
        searchController != null &&
        searchFocusNode != null &&
        onSearchClose != null) {
      return Container(
        padding: const EdgeInsets.fromLTRB(8, 7, 10, 7),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.28),
          border: Border(
            bottom: BorderSide(
              color: Colors.white.withValues(alpha: 0.10),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            IconButton(
              tooltip: l10n.partner_profile_tooltip_back,
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
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(
                      color: fg,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    cursorColor: fg,
                    decoration: InputDecoration(
                      hintText: l10n.chat_header_search_hint,
                      hintStyle: TextStyle(color: fg.withValues(alpha: 0.50)),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.08),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      isDense: true,
                      suffixIcon: q.isNotEmpty
                          ? IconButton(
                              tooltip: l10n.thread_search_tooltip_clear,
                              onPressed: () => searchController!.clear(),
                              icon: Icon(
                                Icons.close_rounded,
                                color: fg.withValues(alpha: 0.7),
                                size: 19,
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
      );
    }

    Widget iconButton({
      required IconData icon,
      required VoidCallback onTap,
      required String tooltip,
    }) {
      return Padding(
        padding: const EdgeInsets.only(left: 6),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.08),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
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

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 7, 10, 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.10),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: l10n.partner_profile_tooltip_back,
            onPressed: onBack,
            color: fg,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          ),
          GestureDetector(
            onTap: onProfileTap,
            behavior: HitTestBehavior.opaque,
            child: ChatAvatar(title: title, radius: 17, avatarUrl: avatarUrl),
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
                      fontWeight: FontWeight.w600,
                      color: fg,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: fg.withValues(alpha: 0.70),
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
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                ),
                child: IconButton(
                  tooltip: l10n.chat_header_tooltip_threads,
                  onPressed: onThreadsTap,
                  iconSize: 17,
                  color: fg,
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.forum_outlined),
                ),
              ),
            ),
          ),
          iconButton(
            tooltip: l10n.chat_header_tooltip_search,
            onTap: onSearchTap,
            icon: Icons.search_rounded,
          ),
          if (scheduledCount > 0 && onScheduledTap != null)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Badge.count(
                count: scheduledCount,
                isLabelVisible: scheduledCount > 0,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
                  ),
                  child: IconButton(
                    tooltip: 'Запланированные сообщения',
                    onPressed: onScheduledTap,
                    iconSize: 17,
                    color: fg,
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.schedule_send_rounded),
                  ),
                ),
              ),
            ),
          if (showCalls) ...[
            iconButton(
              tooltip: l10n.chat_header_tooltip_video_call,
              onTap: onVideoCallTap,
              icon: Icons.videocam_outlined,
            ),
            iconButton(
              tooltip: l10n.chat_header_tooltip_audio_call,
              onTap: onAudioCallTap,
              icon: Icons.call_outlined,
            ),
          ],
        ],
      ),
    );
  }
}

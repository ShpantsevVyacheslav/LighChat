import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lighchat_models/lighchat_models.dart';

import '../../../l10n/app_localizations.dart';
import '../data/chat_message_search.dart';
import '../data/user_profile.dart';
import 'chat_avatar.dart';

/// Панель результатов поиска по сообщениям (паритет `ChatSearchOverlay.tsx`).
class ChatMessageSearchOverlay extends StatelessWidget {
  const ChatMessageSearchOverlay({
    super.key,
    required this.results,
    required this.conversation,
    required this.profileMap,
    required this.onSelectMessageId,
    required this.onTapScrim,
    this.decryptedTextByMessageId,
    this.topInset = 0,
  });

  final List<ChatMessage> results;
  final Conversation? conversation;
  final Map<String, UserProfile> profileMap;
  final void Function(String messageId) onSelectMessageId;
  final VoidCallback onTapScrim;

  /// На iOS native nav bar — overlay, и тело чата рисуется под ним
  /// (`belowHeaderGap=0`). Передаём bottom edge native bar'а сюда,
  /// чтобы карточка результатов появлялась НИЖЕ шапки, а не вылезала
  /// в статус-bar. На Android/Windows/Linux 0 — Material AppBar
  /// занимает свою высоту в layout'е.
  final double topInset;

  /// Расшифрованный plaintext для E2EE-сообщений (`messageId → text`).
  /// Без этого мапа сниппет результата у E2EE-сообщений всегда деградировал
  /// бы до фолбэка `chat_search_snippet_message`. Опционально — для
  /// не-E2EE чатов передавать не обязательно.
  final Map<String, String>? decryptedTextByMessageId;

  String _senderName(String senderId, AppLocalizations l10n) {
    final p = profileMap[senderId];
    if (p != null && p.name.trim().isNotEmpty) return p.name.trim();
    final info = conversation?.participantInfo?[senderId];
    if (info != null && info.name.trim().isNotEmpty) return info.name.trim();
    return l10n.message_search_participant_fallback;
  }

  String? _senderAvatarUrl(String senderId) {
    final p = profileMap[senderId];
    if (p != null) {
      final u = p.avatarThumb ?? p.avatar;
      if (u != null && u.trim().isNotEmpty) return u.trim();
    }
    final info = conversation?.participantInfo?[senderId];
    final u = info?.avatarThumb ?? info?.avatar;
    if (u != null && u.trim().isNotEmpty) return u.trim();
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fg = Colors.white.withValues(alpha: 0.94);
    final fgMuted = fg.withValues(alpha: 0.62);

    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTapScrim,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.38),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.fromLTRB(12, topInset + 8, 12, 12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 672),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.28),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.16),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.45),
                            blurRadius: 28,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.search_rounded,
                                  size: 20,
                                  color: fg.withValues(alpha: 0.85),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    l10n.message_search_results_count(results.length),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.2,
                                      color: fg,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Divider(
                            height: 1,
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight:
                                  MediaQuery.sizeOf(context).height * 0.55,
                            ),
                            child: results.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 36,
                                      horizontal: 16,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.close_rounded,
                                          size: 40,
                                          color: fgMuted,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          l10n.message_search_not_found,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1.1,
                                            color: fgMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.separated(
                                    shrinkWrap: true,
                                    padding: const EdgeInsets.fromLTRB(
                                      10,
                                      10,
                                      10,
                                      12,
                                    ),
                                    itemCount: results.length,
                                    separatorBuilder: (_, _) =>
                                        const SizedBox(height: 8),
                                    itemBuilder: (context, i) {
                                      final m = results[i];
                                      final name = _senderName(m.senderId, l10n);
                                      final av = _senderAvatarUrl(m.senderId);
                                      return Material(
                                        color: Colors.white.withValues(
                                          alpha: 0.08,
                                        ),
                                        borderRadius: BorderRadius.circular(14),
                                        child: InkWell(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          onTap: () =>
                                              onSelectMessageId(m.id),
                                          child: Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                ChatAvatar(
                                                  title: name,
                                                  radius: 18,
                                                  avatarUrl: av,
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              name,
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style: TextStyle(
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: fg,
                                                              ),
                                                            ),
                                                          ),
                                                          Text(
                                                            formatChatSearchResultTimestamp(
                                                              m.createdAt,
                                                            ),
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color: fgMuted,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        chatSearchResultSnippet(
                                                          m,
                                                          l10n,
                                                          decryptedTextByMessageId:
                                                              decryptedTextByMessageId,
                                                        ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          height: 1.25,
                                                          color: fg.withValues(
                                                            alpha: 0.88,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
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

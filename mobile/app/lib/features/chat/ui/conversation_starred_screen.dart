import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lighchat_models/lighchat_models.dart';

import 'package:lighchat_mobile/app_providers.dart';

import '../../auth/ui/auth_glass.dart';
import 'message_html_text.dart';
import 'profile_subpage_header.dart';

class ConversationStarredScreen extends ConsumerWidget {
  const ConversationStarredScreen({
    super.key,
    required this.conversationId,
    required this.currentUserId,
    required this.conversation,
  });

  final String conversationId;
  final String currentUserId;
  final Conversation conversation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final starredAsync = ref.watch(
      starredMessagesInConversationProvider((
        userId: currentUserId,
        conversationId: conversationId,
      )),
    );
    // Cutoff "очистка чата для меня": если starred entry осталась после очистки
    // (race / старая запись) — не показываем её.
    final clearedAtCutoff = DateTime.tryParse(
      conversation.clearedAt?[currentUserId] ?? '',
    )?.toUtc();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuthBackground(
        child: SafeArea(
          child: Column(
            children: [
              _topBar(context),
              const SizedBox(height: 8),
              Expanded(
                child: starredAsync.when(
                  data: (rawEntries) {
                    final entries = clearedAtCutoff == null
                        ? rawEntries
                        : rawEntries
                              .where(
                                (e) => e.createdAt.toUtc().isAfter(
                                  clearedAtCutoff,
                                ),
                              )
                              .toList(growable: false);
                    if (entries.isEmpty) {
                      return _emptyState(context);
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      itemCount: entries.length,
                      itemBuilder: (context, i) {
                        final e = entries[i];
                        return _StarredMessageTile(
                          conversationId: conversationId,
                          currentUserId: currentUserId,
                          conversation: conversation,
                          entry: e,
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Text(
                      AppLocalizations.of(context)!.starred_load_error(e.toString()),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: scheme.onSurface.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return ChatProfileSubpageHeader(
      title: AppLocalizations.of(context)!.starred_title,
      onBack: () => Navigator.of(context).pop(),
    );
  }

  Widget _emptyState(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          AppLocalizations.of(context)!.starred_empty,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: scheme.onSurface.withValues(alpha: 0.82),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _StarredMessageTile extends ConsumerWidget {
  const _StarredMessageTile({
    required this.conversationId,
    required this.currentUserId,
    required this.conversation,
    required this.entry,
  });

  final String conversationId;
  final String currentUserId;
  final Conversation conversation;
  final StarredChatMessageEntry entry;

  static final Set<String> _purgedDocIds = <String>{};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final msgAsync = ref.watch(
      chatMessageByIdProvider((
        conversationId: conversationId,
        messageId: entry.messageId,
      )),
    );
    final l10n = AppLocalizations.of(context)!;
    final message = msgAsync.asData?.value;
    // Базовое сообщение soft-deleted — entry осталась сиротой. Скрываем и
    // подчищаем серверную запись, чтобы счётчик "Starred" в профиле
    // тоже схлопнулся.
    if (message != null && message.isDeleted) {
      if (_purgedDocIds.add(entry.docId)) {
        Future<void>.microtask(() async {
          try {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(currentUserId)
                .collection('starredChatMessages')
                .doc(entry.docId)
                .delete();
          } catch (_) {
            _purgedDocIds.remove(entry.docId);
          }
        });
      }
      return const SizedBox.shrink();
    }
    final senderName = _senderName(
      l10n: l10n,
      senderId: message?.senderId ?? '',
      conversation: conversation,
      currentUserId: currentUserId,
    );
    final preview = _previewText(l10n: l10n, entry: entry, message: message);
    final timeLabel = _formatTime(l10n: l10n, dt: entry.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).pop(entry.messageId),
        child: _glass(
          context,
          radius: 18,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: scheme.primary.withValues(alpha: 0.95),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        senderName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: scheme.onSurface.withValues(alpha: 0.95),
                        ),
                      ),
                    ),
                    Text(
                      timeLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface.withValues(alpha: 0.66),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  preview,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface.withValues(alpha: 0.78),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _glass(
    BuildContext context, {
    required Widget child,
    double radius = 20,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: (dark ? Colors.black : Colors.white).withValues(
              alpha: dark ? 0.24 : 0.42,
            ),
            border: Border.all(
              color: (dark ? Colors.white : Colors.black).withValues(
                alpha: dark ? 0.14 : 0.10,
              ),
            ),
            borderRadius: BorderRadius.circular(radius),
          ),
          child: child,
        ),
      ),
    );
  }

  String _senderName({
    required AppLocalizations l10n,
    required String senderId,
    required Conversation conversation,
    required String currentUserId,
  }) {
    if (senderId.trim().isEmpty) return l10n.starred_message_fallback;
    final info = conversation.participantInfo?[senderId];
    if ((info?.name ?? '').trim().isNotEmpty) return info!.name.trim();
    if (senderId == currentUserId) return l10n.starred_sender_you;
    return l10n.starred_sender_fallback;
  }

  String _previewText({
    required AppLocalizations l10n,
    required StarredChatMessageEntry entry,
    required ChatMessage? message,
  }) {
    final m = message;
    if (m == null) return entry.previewText ?? l10n.starred_message_fallback;
    final raw = (m.text ?? '').trim();
    var plain = raw;
    if (raw.contains('<')) {
      plain = messageHtmlToPlainText(raw);
    }
    plain = plain.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (plain.isNotEmpty) return plain;
    if ((m.chatPollId ?? '').trim().isNotEmpty) return l10n.starred_type_poll;
    if (m.locationShare != null) return l10n.starred_type_location;
    if (m.attachments.isNotEmpty) return l10n.starred_type_attachment;
    return entry.previewText ?? l10n.starred_message_fallback;
  }

  String _formatTime({required AppLocalizations l10n, required DateTime dt}) {
    final d = dt.toLocal();
    final now = DateTime.now();
    final isToday =
        d.year == now.year && d.month == now.month && d.day == now.day;
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    if (isToday) return l10n.starred_today_prefix("$hh:$mm");
    final dd = d.day.toString().padLeft(2, '0');
    final mo = d.month.toString().padLeft(2, '0');
    return '$dd.$mo $hh:$mm';
  }
}

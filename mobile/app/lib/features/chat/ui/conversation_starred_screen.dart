import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lighchat_models/lighchat_models.dart';

import 'package:lighchat_mobile/app_providers.dart';

import '../../auth/ui/auth_glass.dart';
import 'message_html_text.dart';

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
    final messagesAsync = ref.watch(
      messagesProvider((conversationId: conversationId, limit: 800)),
    );

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
                  data: (entries) {
                    if (entries.isEmpty) {
                      return _emptyState(context);
                    }
                    final byId = <String, ChatMessage>{
                      for (final m
                          in messagesAsync.value ?? const <ChatMessage>[])
                        m.id: m,
                    };
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      itemCount: entries.length,
                      itemBuilder: (context, i) {
                        final e = entries[i];
                        final m = byId[e.messageId];
                        return _starredTile(context, e, m);
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Text(
                      'Ошибка загрузки избранного: $e',
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
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      child: _glass(
        context,
        child: SizedBox(
          height: 52,
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: scheme.onSurface.withValues(alpha: 0.92),
                ),
              ),
              Expanded(
                child: Text(
                  'Избранное',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface.withValues(alpha: 0.95),
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          'В этом чате нет избранных сообщений',
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

  Widget _starredTile(
    BuildContext context,
    StarredChatMessageEntry entry,
    ChatMessage? message,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final senderId = message?.senderId ?? '';
    final senderName = _senderName(senderId);
    final preview = _previewText(entry, message);
    final timeLabel = _formatTime(entry.createdAt);

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

  String _senderName(String senderId) {
    if (senderId.trim().isEmpty) return 'Сообщение';
    final info = conversation.participantInfo?[senderId];
    if ((info?.name ?? '').trim().isNotEmpty) return info!.name.trim();
    if (senderId == currentUserId) return 'Вы';
    return 'Участник';
  }

  String _previewText(StarredChatMessageEntry entry, ChatMessage? m) {
    if (m == null) {
      return entry.previewText ?? 'Сообщение';
    }
    final raw = (m.text ?? '').trim();
    var plain = raw;
    if (raw.contains('<')) {
      plain = messageHtmlToPlainText(raw);
    }
    plain = plain.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (plain.isNotEmpty) return plain;
    if ((m.chatPollId ?? '').trim().isNotEmpty) return 'Опрос';
    if (m.locationShare != null) return 'Локация';
    if (m.attachments.isNotEmpty) return 'Вложение';
    return entry.previewText ?? 'Сообщение';
  }

  String _formatTime(DateTime dt) {
    final d = dt.toLocal();
    final now = DateTime.now();
    final isToday =
        d.year == now.year && d.month == now.month && d.day == now.day;
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    if (isToday) return 'Сегодня, $hh:$mm';
    final dd = d.day.toString().padLeft(2, '0');
    final mo = d.month.toString().padLeft(2, '0');
    return '$dd.$mo $hh:$mm';
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
}

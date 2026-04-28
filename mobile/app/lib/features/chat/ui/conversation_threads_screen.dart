import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lighchat_models/lighchat_models.dart';

import 'package:lighchat_mobile/app_providers.dart';

import '../../../l10n/app_localizations.dart';
import 'message_html_text.dart';

/// Список сообщений с непустой веткой (паритет `ConversationThreadsPanel`).
class ConversationThreadsScreen extends ConsumerWidget {
  const ConversationThreadsScreen({super.key, required this.conversationId});

  final String conversationId;

  static DateTime _parseThreadSortTime(ChatMessage m) {
    final s = m.lastThreadMessageTimestamp;
    if (s == null || s.isEmpty) {
      return m.createdAt;
    }
    return DateTime.tryParse(s) ?? m.createdAt;
  }

  static String _rootTitlePlain(ChatMessage m) {
    final t = (m.text ?? '').trim();
    if (t.isEmpty) {
      return '';
    }
    if (t.contains('<')) {
      final p = messageHtmlToPlainText(t).trim();
      return p;
    }
    return t;
  }

  static String _snippetLine({
    required ChatMessage m,
    required String currentUserId,
    required Conversation? conv,
    required AppLocalizations l10n,
  }) {
    final raw = (m.lastThreadMessageText ?? '').trim();
    if (raw.isEmpty) return '';
    final sid = m.lastThreadMessageSenderId ?? '';
    if (sid == currentUserId) return l10n.conversation_threads_snippet_you(raw);
    String? name;
    if (sid.isNotEmpty) {
      name = conv?.participantInfo?[sid]?.name;
    }
    if (name != null && name.isNotEmpty) {
      return '$name: $raw';
    }
    return raw;
  }

  static String _dayLabel(
    BuildContext context,
    AppLocalizations l10n,
    DateTime dt,
  ) {
    final local = dt.toLocal();
    final now = DateTime.now();
    final t0 = DateTime(now.year, now.month, now.day);
    final t1 = DateTime(local.year, local.month, local.day);
    final diff = t0.difference(t1).inDays;
    if (diff == 0) return l10n.conversation_threads_day_today;
    if (diff == 1) return l10n.conversation_threads_day_yesterday;
    return MaterialLocalizations.of(context).formatShortMonthDay(local);
  }

  // Replies label is localized via ARB ICU plural: `conversation_threads_replies_badge`.

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authUserProvider).asData?.value;
    if (user == null) {
      return Scaffold(body: Center(child: Text(l10n.forward_error_not_authorized)));
    }

    final convAsync = ref.watch(
      conversationsProvider((
        key: conversationIdsCacheKey([conversationId]),
      )),
    );
    final msgsAsync = ref.watch(
      messagesProvider((conversationId: conversationId, limit: 400)),
    );

    return convAsync.when(
      data: (list) {
        final conv = list.isNotEmpty ? list.first.data : null;
        return msgsAsync.when(
          data: (msgs) {
            final threads = msgs
                .where((m) => !m.isDeleted && (m.threadCount ?? 0) > 0)
                .toList(growable: false);
            threads.sort((a, b) {
              final ta = _parseThreadSortTime(a);
              final tb = _parseThreadSortTime(b);
              final c = tb.compareTo(ta);
              if (c != 0) return c;
              return b.id.compareTo(a.id);
            });

            return Scaffold(
              appBar: AppBar(
                title: Text(l10n.conversation_threads_title),
              ),
              body: threads.isEmpty
                  ? Center(
                      child: Text(
                        l10n.conversation_threads_empty,
                        style: TextStyle(
                          color: scheme.onSurface.withValues(alpha: 0.55),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                      itemCount: threads.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final m = threads[i];
                        final tc = m.threadCount ?? 0;
                        final rawTitle = _rootTitlePlain(m).trim();
                        final title = rawTitle.isNotEmpty
                            ? rawTitle
                            : (m.attachments.isNotEmpty
                                  ? l10n.conversation_threads_root_attachment
                                  : l10n.conversation_threads_root_message);
                        final snippet = _snippetLine(
                          m: m,
                          currentUserId: user.uid,
                          conv: conv,
                          l10n: l10n,
                        );
                        final sortT = _parseThreadSortTime(m);
                        return Material(
                          color: scheme.surfaceContainerHighest.withValues(
                            alpha: 0.35,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              context.push(
                                '/chats/$conversationId/thread/${m.id}',
                                extra: m,
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1B5E20)
                                          .withValues(alpha: 0.35),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.forum_rounded,
                                      color: Color(0xFF66BB6A),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16,
                                          ),
                                        ),
                                        if (snippet.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            snippet,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: scheme.onSurface
                                                  .withValues(alpha: 0.65),
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF2E7D32),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            l10n
                                                .conversation_threads_replies_badge(tc)
                                                .toUpperCase(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.4,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _dayLabel(context, l10n, sortT).toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: scheme.onSurface
                                          .withValues(alpha: 0.45),
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            );
          },
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) {
            final fbCode =
                (e is FirebaseException) ? e.code.toLowerCase().trim() : '';
            final isDenied = fbCode == 'permission-denied';
            final msg = isDenied
                ? 'Permission denied: you may have no access to this chat.'
                : l10n.chat_list_error_generic(e);
            return Scaffold(body: Center(child: Text(msg)));
          },
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text(l10n.chat_list_error_generic(e))),
      ),
    );
  }
}

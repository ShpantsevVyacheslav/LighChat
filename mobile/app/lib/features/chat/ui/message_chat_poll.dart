import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lighchat_models/lighchat_models.dart';

import 'chat_glass_panel.dart';
import 'chat_popup_menu_theme.dart';
import 'message_bubble_delivery_icons.dart';

String _pollMessageTimeHm(DateTime utcOrLocal) {
  final l = utcOrLocal.toLocal();
  final h = l.hour.toString().padLeft(2, '0');
  final m = l.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

bool _canModerateChatPoll(Conversation? conv, String uid, MeetingPoll poll) {
  if (poll.creatorId == uid) return true;
  if (conv == null || !conv.isGroup) return false;
  if (conv.createdByUserId == uid) return true;
  return conv.adminIds.contains(uid);
}

/// Встроенный опрос (паритет с веб `MessagePollInline`).
class MessageChatPoll extends StatelessWidget {
  const MessageChatPoll({
    super.key,
    required this.conversationId,
    required this.pollId,
    required this.conversation,
    this.embedMessageStatus = false,
    this.messageCreatedAt,
    this.isMine = false,
    this.deliveryStatus,
    this.readAt,
    this.metaFontSize = 11,
  });

  final String conversationId;
  final String pollId;
  final Conversation? conversation;
  /// Время и галочки внутри стеклянной карточки (нет отдельного текстового пузыря).
  final bool embedMessageStatus;
  final DateTime? messageCreatedAt;
  final bool isMine;
  final String? deliveryStatus;
  final DateTime? readAt;
  final double metaFontSize;

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId)
        .collection('polls')
        .doc(pollId);

    return StreamBuilder<DocumentSnapshot<Map<String, Object?>>>(
      stream: ref.snapshots(),
      builder: (context, snap) {
        Widget inner;
        if (snap.hasError) {
          inner = Text(
            'Опрос недоступен',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
          );
        } else if (!snap.hasData || !snap.data!.exists) {
          inner = const Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white70,
                ),
              ),
              SizedBox(width: 10),
              Text('Загрузка опроса…'),
            ],
          );
        } else {
          final poll = MeetingPoll.fromDoc(snap.data!);
          if (poll == null) {
            inner = const Text('Опрос недоступен');
          } else {
            inner = _MessageChatPollBody(
              pollRef: ref,
              poll: poll,
              conversation: conversation,
            );
          }
        }
        Widget panelChild = inner;
        if (embedMessageStatus && messageCreatedAt != null) {
          final timeStr = _pollMessageTimeHm(messageCreatedAt!);
          final metaColor = Colors.white.withValues(alpha: 0.62);
          panelChild = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              inner,
              Padding(
                padding: const EdgeInsets.only(top: 6, right: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: metaFontSize,
                        fontWeight: FontWeight.w800,
                        color: metaColor,
                      ),
                    ),
                    if (isMine) ...[
                      const SizedBox(width: 4),
                      MessageBubbleDeliveryIcons(
                        deliveryStatus: deliveryStatus,
                        readAt: readAt,
                        iconColor: metaColor,
                        size: 11,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        }
        return SizedBox(
          width: double.infinity,
          child: ChatGlassPanel(child: panelChild),
        );
      },
    );
  }
}

class _MessageChatPollBody extends StatefulWidget {
  const _MessageChatPollBody({
    required this.pollRef,
    required this.poll,
    required this.conversation,
  });

  final DocumentReference<Map<String, Object?>> pollRef;
  final MeetingPoll poll;
  final Conversation? conversation;

  @override
  State<_MessageChatPollBody> createState() => _MessageChatPollBodyState();
}

class _MessageChatPollBodyState extends State<_MessageChatPollBody> {
  bool _busy = false;
  bool _expandedVoters = false;

  Future<void> _vote(int optionIdx) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || widget.poll.status != 'active' || _busy) return;
    final votes = Map<String, int>.from(widget.poll.votes);
    if (votes[user.uid] != null) return;
    setState(() => _busy = true);
    try {
      votes[user.uid] = optionIdx;
      final participants = widget.conversation?.participantIds.length ?? 0;
      final shouldEnd =
          participants > 0 && votes.length >= participants;
      await widget.pollRef.update(<String, Object?>{
        'votes': votes,
        if (shouldEnd) 'status': 'ended',
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка при голосовании')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _revoteSelf() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _busy) return;
    setState(() => _busy = true);
    try {
      final v = Map<String, int>.from(widget.poll.votes)..remove(user.uid);
      await widget.pollRef.update({'votes': v});
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _moderate(String action) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _busy) return;
    final poll = widget.poll;
    if (!_canModerateChatPoll(widget.conversation, user.uid, poll)) return;
    setState(() => _busy = true);
    try {
      switch (action) {
        case 'end':
          await widget.pollRef.update({'status': 'ended'});
          break;
        case 'delete':
          await widget.pollRef.delete();
          break;
        case 'restart':
          await widget.pollRef.update({
            'status': 'active',
            'votes': <String, int>{},
          });
          break;
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? '';
    final poll = widget.poll;
    final votes = poll.votes;
    final total = votes.length;
    final hasVoted = uid.isNotEmpty && votes.containsKey(uid);
    final isEnded = poll.status == 'ended';
    final isDraft = poll.status == 'draft';
    final isCancelled = poll.status == 'cancelled';
    final canMod = uid.isNotEmpty && _canModerateChatPoll(widget.conversation, uid, poll);

    if (isDraft && poll.creatorId != uid && !canMod) {
      return const SizedBox.shrink();
    }

    String statusLabel;
    if (isCancelled) {
      statusLabel = 'Отменён';
    } else if (isEnded) {
      statusLabel = 'Завершён';
    } else if (isDraft) {
      statusLabel = 'Черновик';
    } else {
      statusLabel = 'Активен';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      poll.question,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _badge(context, statusLabel, isMuted: isEnded || isCancelled),
                        if (!poll.isAnonymous)
                          _badge(context, 'Публично', isPrimary: true),
                      ],
                    ),
                  ],
                ),
              ),
              if (canMod)
                chatDarkPopupMenuScope(
                  context,
                  PopupMenuButton<String>(
                    surfaceTintColor: Colors.transparent,
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: scheme.onSurface.withValues(alpha: 0.55),
                    ),
                    onSelected: (v) => unawaited(_moderate(v)),
                    itemBuilder: (context) {
                      final t = chatPopupMenuItemTextStyle();
                      return [
                        if (isEnded)
                          PopupMenuItem(
                            value: 'restart',
                            child: Text('Перезапустить', style: t),
                          ),
                        if (!isEnded && !isDraft)
                          PopupMenuItem(
                            value: 'end',
                            child: Text('Завершить', style: t),
                          ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Удалить', style: t),
                        ),
                      ];
                    },
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < poll.options.length; i++)
            _optionTile(
              context,
              label: poll.options[i],
              idx: i,
              votes: votes,
              total: total,
              uid: uid,
              isEnded: isEnded || isDraft || isCancelled,
              hasVoted: hasVoted,
              enabled: !_busy,
              onTap: () => _vote(i),
            ),
          if (hasVoted && !isEnded && !isDraft) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: _busy ? null : () => unawaited(_revoteSelf()),
                child: const Text('Переголосовать'),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            '$total голосов',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: scheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
          if (!poll.isAnonymous && total > 0) ...[
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => setState(() => _expandedVoters = !_expandedVoters),
              child: Text(_expandedVoters ? 'Скрыть' : 'Кто голосовал'),
            ),
            if (_expandedVoters) _votersList(context, poll),
          ],
        ],
    );
  }

  Widget _badge(
    BuildContext context,
    String text, {
    bool isMuted = false,
    bool isPrimary = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: isMuted
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.5)
            : isPrimary
            ? scheme.primary.withValues(alpha: 0.15)
            : scheme.primary.withValues(alpha: 0.12),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.4,
          color: isMuted
              ? scheme.onSurface.withValues(alpha: 0.55)
              : scheme.primary,
        ),
      ),
    );
  }

  Widget _optionTile(
    BuildContext context, {
    required String label,
    required int idx,
    required Map<String, int> votes,
    required int total,
    required String uid,
    required bool isEnded,
    required bool hasVoted,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final count = votes.values.where((v) => v == idx).length;
    final pct = total > 0 ? (100 * count / total).round() : 0;
    final mine = votes[uid] == idx;
    final tappable = enabled && !isEnded && !hasVoted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: mine
            ? scheme.primary.withValues(alpha: 0.24)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: tappable ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '$pct%',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: total > 0 ? count / total : 0,
                    minHeight: 4,
                    color: scheme.primary.withValues(alpha: 0.85),
                    backgroundColor: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _votersList(BuildContext context, MeetingPoll poll) {
    final scheme = Theme.of(context).colorScheme;
    final info = widget.conversation?.participantInfo;
    final lines = <String>[];
    for (final e in poll.votes.entries) {
      final row = info?[e.key];
      final name = row?.name;
      lines.add('${name != null && name.isNotEmpty ? name : e.key} → ${poll.options[e.value]}');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines
          .map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                s,
                style: TextStyle(
                  fontSize: 11,
                  color: scheme.onSurface.withValues(alpha: 0.75),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

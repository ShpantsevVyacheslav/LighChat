import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import 'package:lighchat_models/lighchat_models.dart';

import '../data/chat_poll_vote_utils.dart';
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
        final l10n = AppLocalizations.of(context)!;
        Widget inner;
        if (snap.hasError) {
          inner = Text(
            l10n.poll_unavailable,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
          );
        } else if (!snap.hasData) {
          inner = Row(
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
              Text(l10n.poll_loading),
            ],
          );
        } else if (!snap.data!.exists) {
          inner = Text(l10n.poll_not_found);
        } else {
          final poll = MeetingPoll.fromDoc(snap.data!);
          if (poll == null) {
            inner = Text(l10n.poll_unavailable);
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
  final List<int> _pendingMulti = [];
  final TextEditingController _newOptionCtrl = TextEditingController();
  Timer? _closesTimer;

  @override
  void initState() {
    super.initState();
    _scheduleClosesTimer();
  }

  @override
  void didUpdateWidget(covariant _MessageChatPollBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.poll.id != widget.poll.id ||
        oldWidget.poll.closesAt != widget.poll.closesAt ||
        oldWidget.poll.status != widget.poll.status) {
      _scheduleClosesTimer();
    }
    if (oldWidget.poll.id != widget.poll.id) {
      _pendingMulti.clear();
    }
  }

  @override
  void dispose() {
    _closesTimer?.cancel();
    _newOptionCtrl.dispose();
    super.dispose();
  }

  void _scheduleClosesTimer() {
    _closesTimer?.cancel();
    final poll = widget.poll;
    if (poll.status != 'active' || poll.closesAt == null) return;
    final end = poll.closesAt!;
    void tick() {
      if (!mounted) return;
      if (DateTime.now().isAfter(end)) {
        unawaited(_tryAutoEnd());
        _closesTimer?.cancel();
      }
    }

    tick();
    _closesTimer = Timer.periodic(const Duration(seconds: 2), (_) => tick());
  }

  Future<void> _tryAutoEnd() async {
    if (widget.poll.status != 'active') return;
    try {
      await widget.pollRef.update(<String, Object?>{'status': 'ended'});
    } catch (_) {}
  }

  Future<void> _commitVote(List<int> indices) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || widget.poll.status != 'active' || _busy) return;
    if (indices.isEmpty) return;
    final sorted = indices.toSet().toList()..sort();
    final votes = Map<String, List<int>>.from(
      widget.poll.votes.map((k, v) => MapEntry(k, List<int>.from(v))),
    );
    votes[user.uid] = sorted;
    setState(() => _busy = true);
    try {
      final fireVotes = <String, Object?>{};
      for (final e in votes.entries) {
        fireVotes[e.key] = e.value.length == 1 ? e.value.first : e.value;
      }
      final participants = widget.conversation?.participantIds.length ?? 0;
      final shouldEnd = participants > 0 && votes.length >= participants;
      await widget.pollRef.update(<String, Object?>{
        'votes': fireVotes,
        if (shouldEnd) 'status': 'ended',
      });
      _pendingMulti.clear();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.poll_vote_error)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _voteSingle(int optionIdx) async {
    await _commitVote([optionIdx]);
  }

  void _togglePending(int idx) {
    setState(() {
      if (_pendingMulti.contains(idx)) {
        _pendingMulti.remove(idx);
      } else {
        _pendingMulti.add(idx);
        _pendingMulti.sort();
      }
    });
  }

  Future<void> _submitMulti() async {
    await _commitVote(_pendingMulti);
  }

  Future<void> _revoteSelf() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _busy || !widget.poll.allowRevoting) return;
    setState(() => _busy = true);
    try {
      final v = widget.poll.votes.map(
        (k, val) => MapEntry(k, List<int>.from(val)),
      );
      v.remove(user.uid);
      final fireVotes = <String, Object?>{};
      for (final e in v.entries) {
        fireVotes[e.key] = e.value.length == 1 ? e.value.first : e.value;
      }
      await widget.pollRef.update(<String, Object?>{'votes': fireVotes});
      _pendingMulti.clear();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.poll_error)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addSuggestedOption() async {
    final t = _newOptionCtrl.text.trim();
    if (t.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      await widget.pollRef.update(<String, Object?>{
        'options': [...widget.poll.options, t],
      });
      _newOptionCtrl.clear();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.poll_add_option_error)),
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
            'votes': <String, Object?>{},
          });
          break;
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.poll_error)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? '';
    final poll = widget.poll;
    final votes = poll.votes;
    final total = votes.length;
    final hasVoted = userHasVoted(votes, uid);
    final isEnded = poll.status == 'ended';
    final isDraft = poll.status == 'draft';
    final isCancelled = poll.status == 'cancelled';
    final canMod =
        uid.isNotEmpty && _canModerateChatPoll(widget.conversation, uid, poll);
    final allowMulti = poll.allowMultipleAnswers;
    final showRevote = hasVoted && !isEnded && !isDraft && poll.allowRevoting;
    final displayIdxs = chatPollDisplayIndices(
      pollId: poll.id,
      userId: uid,
      optionCount: poll.options.length,
      shuffle: poll.shuffleOptions,
    );

    if (isDraft && poll.creatorId != uid && !canMod) {
      return const SizedBox.shrink();
    }

    String statusLabel;
    if (isCancelled) {
      statusLabel = l10n.poll_status_cancelled;
    } else if (isEnded) {
      statusLabel = l10n.poll_status_ended;
    } else if (isDraft) {
      statusLabel = l10n.poll_status_draft;
    } else {
      statusLabel = l10n.poll_status_active;
    }

    final quizReveal =
        poll.quizMode && hasVoted && poll.correctOptionIndex != null;

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
                  if (poll.description != null &&
                      poll.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      poll.description!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                        color: scheme.onSurface.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _badge(
                        context,
                        statusLabel,
                        isMuted: isEnded || isCancelled,
                      ),
                      if (!poll.isAnonymous)
                        _badge(context, l10n.poll_badge_public, isPrimary: true),
                      if (allowMulti) _badge(context, l10n.poll_badge_multi),
                      if (poll.quizMode)
                        _badge(context, l10n.poll_badge_quiz, isQuiz: true),
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
                          child: Text(l10n.poll_menu_restart, style: t),
                        ),
                      if (!isEnded && !isDraft)
                        PopupMenuItem(
                          value: 'end',
                          child: Text(l10n.poll_menu_end, style: t),
                        ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(l10n.poll_menu_delete, style: t),
                      ),
                    ];
                  },
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        for (final idx in displayIdxs)
          _optionTile(
            context,
            label: poll.options[idx],
            idx: idx,
            votes: votes,
            total: total,
            uid: uid,
            isEnded: isEnded || isDraft || isCancelled,
            hasVoted: hasVoted,
            allowMulti: allowMulti,
            pendingOn: _pendingMulti.contains(idx),
            enabled: !_busy,
            quizReveal: quizReveal,
            correctIdx: poll.correctOptionIndex,
            onTap: () {
              if (allowMulti && !hasVoted) {
                _togglePending(idx);
              } else if (!hasVoted) {
                unawaited(_voteSingle(idx));
              }
            },
          ),
        if (allowMulti &&
            !hasVoted &&
            !isEnded &&
            !isDraft &&
            !isCancelled) ...[
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _busy || _pendingMulti.isEmpty
                ? null
                : () => unawaited(_submitMulti()),
            child: Text(l10n.poll_submit_vote),
          ),
        ],
        if (quizReveal &&
            poll.quizExplanation != null &&
            poll.quizExplanation!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            poll.quizExplanation!,
            style: TextStyle(
              fontSize: 11,
              color: scheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
        if (poll.allowAddingOptions &&
            !isEnded &&
            !isDraft &&
            !isCancelled) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newOptionCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: l10n.poll_suggest_hint,
                    isDense: true,
                  ),
                  onSubmitted: (_) => unawaited(_addSuggestedOption()),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: _busy
                    ? null
                    : () => unawaited(_addSuggestedOption()),
                child: Text(l10n.poll_add_option),
              ),
            ],
          ),
        ],
        if (showRevote) ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: _busy ? null : () => unawaited(_revoteSelf()),
              child: Text(l10n.poll_revote),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          l10n.poll_votes_count(total),
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
            child: Text(_expandedVoters ? l10n.poll_voters_toggle_hide : l10n.poll_voters_toggle_show),
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
    bool isQuiz = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: isQuiz
            ? const Color(0x3322C55E)
            : isMuted
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
          color: isQuiz
              ? const Color(0xFF22C55E)
              : isMuted
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
    required Map<String, List<int>> votes,
    required int total,
    required String uid,
    required bool isEnded,
    required bool hasVoted,
    required bool allowMulti,
    required bool pendingOn,
    required bool enabled,
    required bool quizReveal,
    required int? correctIdx,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final count = countVotesForOption(votes, idx);
    final pct = total > 0 ? (100 * count / total).round() : 0;
    final mine = userSelectedOption(votes, uid, idx);
    final tappable = enabled && !isEnded && !hasVoted;
    final quizCorrect = quizReveal && correctIdx == idx;
    final quizWrong = quizReveal && mine && correctIdx != idx;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: mine || pendingOn
            ? scheme.primary.withValues(alpha: 0.24)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: tappable ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: quizCorrect
                    ? const Color(0xFF22C55E)
                    : quizWrong
                    ? scheme.error.withValues(alpha: 0.65)
                    : Colors.transparent,
                width: quizCorrect || quizWrong ? 2 : 0,
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    if (allowMulti && !hasVoted) ...[
                      SizedBox(
                        width: 22,
                        child: Icon(
                          pendingOn
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          size: 20,
                          color: scheme.onSurface.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
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
      final parts = e.value
          .map((i) {
            if (i >= 0 && i < poll.options.length) return poll.options[i];
            return '#$i';
          })
          .join(', ');
      lines.add('${name != null && name.isNotEmpty ? name : e.key} → $parts');
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

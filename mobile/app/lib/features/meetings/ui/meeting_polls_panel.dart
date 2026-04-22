import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lighchat_models/lighchat_models.dart';

import '../../chat/data/chat_poll_vote_utils.dart';
import '../data/meeting_models.dart';
import '../data/meeting_providers.dart';

/// Вкладка «Опросы» в сайдбаре митинга — паритет `MeetingPolls.tsx` на web.
class MeetingPollsPanel extends ConsumerStatefulWidget {
  const MeetingPollsPanel({
    super.key,
    required this.meetingId,
    required this.currentUserId,
    required this.participants,
    required this.isHostOrAdmin,
  });

  final String meetingId;
  final String currentUserId;
  final List<MeetingParticipant> participants;
  final bool isHostOrAdmin;

  @override
  ConsumerState<MeetingPollsPanel> createState() => _MeetingPollsPanelState();
}

class _MeetingPollsPanelState extends ConsumerState<MeetingPollsPanel> {
  bool _creating = false;
  bool _saving = false;
  final _question = TextEditingController();
  final _optionCtrls = <TextEditingController>[
    TextEditingController(),
    TextEditingController(),
  ];
  bool _isAnonymous = true;
  final Set<String> _expandedPollIds = {};

  int get _participantsCount => widget.participants.length;

  MeetingParticipant? _participantById(String id) {
    final i = widget.participants.indexWhere((p) => p.id == id);
    return i < 0 ? null : widget.participants[i];
  }

  @override
  void dispose() {
    _question.dispose();
    for (final c in _optionCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _resetCreateForm() {
    _question.clear();
    for (final c in _optionCtrls) {
      c.dispose();
    }
    _optionCtrls
      ..clear()
      ..addAll([
        TextEditingController(),
        TextEditingController(),
      ]);
    _isAnonymous = true;
    _creating = false;
  }

  Future<void> _submitCreate({required bool asDraft}) async {
    final q = _question.text.trim();
    if (q.isEmpty) return;
    final opts = _optionCtrls
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (opts.length < 2) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Минимум 2 варианта ответа')),
        );
      }
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(meetingPollRepositoryProvider).createPoll(
            meetingId: widget.meetingId,
            creatorId: widget.currentUserId,
            question: q,
            options: opts,
            isAnonymous: _isAnonymous,
            asDraft: asDraft,
          );
      if (mounted) {
        setState(_resetCreateForm);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(meetingPollsProvider(widget.meetingId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!_creating && widget.isHostOrAdmin)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: FilledButton.icon(
              onPressed: () => setState(() => _creating = true),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Создать опрос'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        Expanded(
          child: async.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.white54),
            ),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Не удалось загрузить опросы: $e',
                  style: const TextStyle(color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            data: (polls) {
              if (_creating) {
                return _buildCreateForm();
              }
              final visible = polls.where((poll) {
                final isDraft = poll.status == 'draft';
                if (isDraft &&
                    poll.creatorId != widget.currentUserId &&
                    !widget.isHostOrAdmin) {
                  return false;
                }
                return true;
              }).toList();
              if (visible.isEmpty) {
                return const Center(
                  child: Text(
                    'Пока нет опросов',
                    style: TextStyle(color: Colors.white54),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: visible.length,
                itemBuilder: (ctx, i) {
                  final poll = visible[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _PollCard(
                      poll: poll,
                      meetingId: widget.meetingId,
                      currentUserId: widget.currentUserId,
                      isHostOrAdmin: widget.isHostOrAdmin,
                      participantsCount: _participantsCount,
                      participantById: _participantById,
                      expanded: _expandedPollIds.contains(poll.id),
                      onToggleExpand: () => setState(() {
                        if (_expandedPollIds.contains(poll.id)) {
                          _expandedPollIds.remove(poll.id);
                        } else {
                          _expandedPollIds.add(poll.id);
                        }
                      }),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCreateForm() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        TextField(
          controller: _question,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Вопрос',
            labelStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: Colors.white10,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Варианты',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < _optionCtrls.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _optionCtrls[i],
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Вариант ${i + 1}',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                if (_optionCtrls.length > 2)
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline,
                        color: Colors.redAccent),
                    onPressed: () => setState(() {
                      _optionCtrls[i].dispose();
                      _optionCtrls.removeAt(i);
                    }),
                  ),
              ],
            ),
          ),
        TextButton.icon(
          onPressed: () => setState(() {
            _optionCtrls.add(TextEditingController());
          }),
          icon: const Icon(Icons.add, color: Colors.white54),
          label: const Text('Добавить вариант',
              style: TextStyle(color: Colors.white54)),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Анонимно', style: TextStyle(color: Colors.white)),
          subtitle: const Text(
            'Кто увидит выбор других',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
          value: _isAnonymous,
          onChanged: (v) => setState(() => _isAnonymous = v),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _saving ? null : () => setState(_resetCreateForm),
                child: const Text('Отмена'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: _saving ? null : () => _submitCreate(asDraft: true),
                child: const Text('В черновики'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: _saving ? null : () => _submitCreate(asDraft: false),
          child: _saving
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Опубликовать'),
        ),
      ],
    );
  }
}

class _PollCard extends ConsumerWidget {
  const _PollCard({
    required this.poll,
    required this.meetingId,
    required this.currentUserId,
    required this.isHostOrAdmin,
    required this.participantsCount,
    required this.participantById,
    required this.expanded,
    required this.onToggleExpand,
  });

  final MeetingPoll poll;
  final String meetingId;
  final String currentUserId;
  final bool isHostOrAdmin;
  final int participantsCount;
  final MeetingParticipant? Function(String id) participantById;
  final bool expanded;
  final VoidCallback onToggleExpand;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final votes = poll.votes;
    final totalVotes = votes.length;
    final hasVoted = userHasVoted(votes, currentUserId);
    final isEnded = poll.status == 'ended';
    final isDraft = poll.status == 'draft';
    final displayIdxs = chatPollDisplayIndices(
      pollId: poll.id,
      userId: currentUserId,
      optionCount: poll.options.length,
      shuffle: poll.shuffleOptions,
    );

    Future<void> action(String a) async {
      final repo = ref.read(meetingPollRepositoryProvider);
      try {
        switch (a) {
          case 'start':
            await repo.startPoll(meetingId, poll.id);
          case 'end':
            await repo.endPoll(meetingId, poll.id);
          case 'delete':
            await repo.deletePoll(meetingId, poll.id);
          case 'restart':
            await repo.restartPoll(meetingId, poll.id);
          case 'revote':
            await repo.revokeMyVote(
              meetingId: meetingId,
              poll: poll,
              userId: currentUserId,
            );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка: $e')),
          );
        }
      }
    }

    Future<void> vote(int optionIdx) async {
      try {
        await ref.read(meetingPollRepositoryProvider).vote(
              meetingId: meetingId,
              poll: poll,
              userId: currentUserId,
              optionIdx: optionIdx,
              participantsCount: participantsCount,
            );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Голос не засчитан: $e')),
          );
        }
      }
    }

    final borderColor = isEnded
        ? Colors.white12
        : isDraft
            ? Colors.amber.withValues(alpha: 0.35)
            : Colors.white24;

    final menuItems = <PopupMenuEntry<String>>[];
    if (isDraft && (poll.creatorId == currentUserId || isHostOrAdmin)) {
      menuItems.add(
        const PopupMenuItem(value: 'start', child: Text('Запустить')),
      );
    }
    if (hasVoted && !isEnded) {
      menuItems.add(
        const PopupMenuItem(value: 'revote', child: Text('Изменить голос')),
      );
    }
    if (isEnded && (isHostOrAdmin || poll.creatorId == currentUserId)) {
      menuItems.add(
        const PopupMenuItem(value: 'restart', child: Text('Перезапустить')),
      );
    }
    if (isHostOrAdmin && !isEnded && !isDraft) {
      menuItems.add(
        const PopupMenuItem(value: 'end', child: Text('Остановить')),
      );
    }
    if (isHostOrAdmin || poll.creatorId == currentUserId) {
      menuItems.add(
        const PopupMenuItem(
          value: 'delete',
          child: Text('Удалить', style: TextStyle(color: Colors.redAccent)),
        ),
      );
    }

    return Material(
      color: const Color(0xFF151B2E),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _StatusChip(
                            label: isEnded
                                ? 'Завершено'
                                : isDraft
                                    ? 'Черновик'
                                    : 'Активно',
                            color: isEnded
                                ? Colors.redAccent
                                : isDraft
                                    ? Colors.amber
                                    : Colors.greenAccent,
                          ),
                          if (!poll.isAnonymous)
                            const _StatusChip(
                              label: 'Публичное',
                              color: Color(0xFF60A5FA),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (menuItems.isNotEmpty)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded,
                        color: Colors.white54),
                    color: const Color(0xFF1F2937),
                    onSelected: (v) => action(v),
                    itemBuilder: (ctx) => menuItems,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            for (final displayPos in displayIdxs)
              Builder(
                builder: (ctx) {
                  final idx = displayPos;
                  final opt = poll.options[idx];
                  final count = countVotesForOption(votes, idx);
                  final percent =
                      totalVotes > 0 ? ((count / totalVotes) * 100).round() : 0;
                  final votedHere = userSelectedOption(votes, currentUserId, idx);
                  final voters = !poll.isAnonymous
                      ? votes.entries
                          .where((e) => userSelectedOption(votes, e.key, idx))
                          .map((e) => participantById(e.key))
                          .whereType<MeetingParticipant>()
                          .toList()
                      : const <MeetingParticipant>[];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: isEnded || isDraft || (hasVoted && !isEnded)
                              ? null
                              : () => vote(idx),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: votedHere
                                  ? const Color(0xFF2563EB).withValues(alpha: 0.25)
                                  : Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: votedHere
                                    ? const Color(0xFF2563EB)
                                    : Colors.white12,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        opt,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '$percent%',
                                      style: TextStyle(
                                        color: Colors.white
                                            .withValues(alpha: 0.45),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: totalVotes > 0 ? count / totalVotes : 0,
                                    minHeight: 4,
                                    backgroundColor: Colors.white10,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      votedHere
                                          ? const Color(0xFF60A5FA)
                                          : Colors.white38,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (expanded &&
                            !poll.isAnonymous &&
                            voters.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 4,
                            children: voters
                                .map(
                                  (p) => CircleAvatar(
                                    radius: 14,
                                    backgroundImage: p.avatarThumb != null
                                        ? NetworkImage(p.avatarThumb!)
                                        : null,
                                    child: p.avatarThumb == null
                                        ? Text(
                                            p.name.isNotEmpty
                                                ? p.name.characters.first
                                                : '?',
                                            style:
                                                const TextStyle(fontSize: 12),
                                          )
                                        : null,
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            Row(
              children: [
                Text(
                  '$totalVotes голосов',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (!isEnded && !isDraft) ...[
                  const SizedBox(width: 12),
                  Text(
                    'Цель: $participantsCount',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 11,
                    ),
                  ),
                ],
                const Spacer(),
                if (!poll.isAnonymous && totalVotes > 0)
                  TextButton(
                    onPressed: onToggleExpand,
                    child: Text(
                      expanded ? 'Скрыть' : 'Кто голосовал',
                      style: const TextStyle(fontSize: 12),
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

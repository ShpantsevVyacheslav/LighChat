import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../chat/ui/chat_avatar.dart';
import '../data/meeting_chat_message.dart';
import '../data/meeting_providers.dart';

/// TG-style временные баблы поверх UI звонка.
///
/// Показывает до 3 последних чужих сообщений; каждое исчезает через 5 сек.
/// Сообщения от текущего пользователя пропускаем — он их и так печатает сам.
/// Если чат-сайдбар открыт (`enabled = false`) — баблы не появляются:
/// пользователь и так видит ленту. По тапу — `onTap()` (открывает чат).
class MeetingFloatingMessages extends ConsumerStatefulWidget {
  const MeetingFloatingMessages({
    super.key,
    required this.meetingId,
    required this.selfUid,
    required this.enabled,
    required this.onTap,
  });

  final String meetingId;
  final String selfUid;
  final bool enabled;
  final VoidCallback onTap;

  @override
  ConsumerState<MeetingFloatingMessages> createState() =>
      _MeetingFloatingMessagesState();
}

class _MeetingFloatingMessagesState
    extends ConsumerState<MeetingFloatingMessages> {
  final List<_FloatingItem> _visible = <_FloatingItem>[];
  final Set<String> _seenIds = <String>{};
  final Map<String, Timer> _timers = <String, Timer>{};
  bool _firstSnapshot = true;

  @override
  void dispose() {
    for (final t in _timers.values) {
      t.cancel();
    }
    _timers.clear();
    super.dispose();
  }

  void _onMessages(List<MeetingChatMessage> list) {
    if (!mounted) return;
    if (_firstSnapshot) {
      _firstSnapshot = false;
      for (final m in list) {
        _seenIds.add(m.id);
      }
      return;
    }
    if (!widget.enabled) {
      for (final m in list) {
        _seenIds.add(m.id);
      }
      return;
    }
    for (final m in list) {
      if (_seenIds.contains(m.id)) continue;
      _seenIds.add(m.id);
      if (m.senderId == widget.selfUid) continue;
      if (m.isDeleted) continue;
      final text = m.text?.trim() ?? '';
      if (text.isEmpty) continue;
      final item = _FloatingItem(
        id: m.id,
        senderName: m.senderName,
        senderAvatar: m.senderAvatar,
        text: text,
      );
      _visible.add(item);
      while (_visible.length > 3) {
        final removed = _visible.removeAt(0);
        _timers.remove(removed.id)?.cancel();
      }
      _timers[m.id] = Timer(const Duration(seconds: 5), () {
        if (!mounted) return;
        setState(() {
          _visible.removeWhere((it) => it.id == m.id);
          _timers.remove(m.id);
        });
      });
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      meetingChatMessagesProvider(widget.meetingId),
      (prev, next) {
        next.whenData(_onMessages);
      },
    );

    if (_visible.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          for (final it in _visible)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _bubble(context, it),
            ),
        ],
      ),
    );
  }

  Widget _bubble(BuildContext context, _FloatingItem item) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ChatAvatar(
                  title: item.senderName,
                  radius: 14,
                  avatarUrl: item.senderAvatar,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.senderName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingItem {
  _FloatingItem({
    required this.id,
    required this.senderName,
    required this.senderAvatar,
    required this.text,
  });
  final String id;
  final String senderName;
  final String? senderAvatar;
  final String text;
}

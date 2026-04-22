import 'dart:math';

import 'package:flutter/material.dart';

import '../data/meeting_models.dart';

/// Поверх сетки участников проигрывает «летящие эмодзи» при изменении
/// `participant.reaction`. Эквивалент `flyingEmojis`/`animate-reaction-float`
/// из `src/components/meetings/MeetingRoom.tsx`.
///
/// Контракт:
///   - виджет следит за тем, как меняется `reaction` у каждого участника;
///     когда появляется новое непустое значение — запускает анимацию;
///   - повтор реакции того же эмодзи сразу после null — тоже триггер.
///
/// Не содержит бизнес-логики: не пишет в Firestore, не таймерит reset.
/// Reset делает `MeetingWebRtc.sendReaction` (см. wire-protocol §6).
class MeetingReactionsOverlay extends StatefulWidget {
  const MeetingReactionsOverlay({
    super.key,
    required this.participants,
  });

  final List<MeetingParticipant> participants;

  @override
  State<MeetingReactionsOverlay> createState() =>
      _MeetingReactionsOverlayState();
}

class _MeetingReactionsOverlayState extends State<MeetingReactionsOverlay>
    with TickerProviderStateMixin {
  final Map<String, String?> _lastSeen = <String, String?>{};
  final List<_FlyItem> _active = <_FlyItem>[];
  final Random _rnd = Random();

  @override
  void initState() {
    super.initState();
    _sync(widget.participants);
  }

  @override
  void didUpdateWidget(covariant MeetingReactionsOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync(widget.participants);
  }

  void _sync(List<MeetingParticipant> list) {
    for (final p in list) {
      final prev = _lastSeen[p.id];
      final next = p.reaction;
      _lastSeen[p.id] = next;
      if (next != null && next.isNotEmpty && next != prev) {
        _spawn(next);
      }
    }
  }

  void _spawn(String emoji) {
    final ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    final left = 4.0 + _rnd.nextDouble() * 92.0;
    final item = _FlyItem(emoji: emoji, controller: ctrl, leftPercent: left);
    _active.add(item);
    ctrl.addListener(() {
      if (mounted) setState(() {});
    });
    ctrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        _active.remove(item);
        ctrl.dispose();
        if (mounted) setState(() {});
      }
    });
    ctrl.forward();
  }

  @override
  void dispose() {
    for (final it in _active) {
      it.controller.dispose();
    }
    _active.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_active.isEmpty) return const SizedBox.shrink();
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (ctx, c) {
          final w = c.maxWidth;
          final h = c.maxHeight;
          return Stack(
            children: [
              for (final item in _active)
                Positioned(
                  left: (item.leftPercent / 100.0) * w - 28,
                  bottom: -60 + item.controller.value * (h + 120),
                  child: Opacity(
                    opacity: (1.0 - item.controller.value).clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: 0.8 + item.controller.value * 0.7,
                      child: Text(
                        item.emoji,
                        style: const TextStyle(fontSize: 56),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _FlyItem {
  _FlyItem({
    required this.emoji,
    required this.controller,
    required this.leftPercent,
  });
  final String emoji;
  final AnimationController controller;
  final double leftPercent;
}

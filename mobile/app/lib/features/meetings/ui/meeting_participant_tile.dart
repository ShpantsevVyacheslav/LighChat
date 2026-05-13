import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../../app_providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../chat/ui/chat_avatar.dart';
import '../data/meeting_models.dart';
import '../data/meeting_peer_stats.dart';

/// Одна плитка в сетке участников.
/// Рендерит либо живой видеопоток (`RTCVideoView`), либо плейсхолдер с аватаром.
/// Иконки статуса (mic/video/hand/quality) — в правом нижнем углу.
class MeetingParticipantTile extends ConsumerStatefulWidget {
  const MeetingParticipantTile({
    super.key,
    required this.participant,
    this.stream,
    this.isLocal = false,
    this.quality = PeerConnectionQuality.unknown,
    this.mirror = false,
    this.isActiveSpeaker = false,
  });

  final MeetingParticipant participant;
  final MediaStream? stream;
  final bool isLocal;
  final PeerConnectionQuality quality;

  /// Для локального фронтального превью зеркалим по X — привычный режим
  /// «селфи-камеры».
  final bool mirror;

  /// Подсветка по данным `getStats` (активный спикер).
  final bool isActiveSpeaker;

  @override
  ConsumerState<MeetingParticipantTile> createState() =>
      _MeetingParticipantTileState();
}

class _MeetingParticipantTileState extends ConsumerState<MeetingParticipantTile> {
  final _renderer = RTCVideoRenderer();
  bool _rendererInitialized = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _renderer.initialize();
    _rendererInitialized = true;
    _attachStream();
  }

  @override
  void didUpdateWidget(covariant MeetingParticipantTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stream != widget.stream) {
      _attachStream();
    }
  }

  void _attachStream() {
    if (!_rendererInitialized) return;
    _renderer.srcObject = widget.stream;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _renderer.srcObject = null;
    _renderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showVideo = !widget.participant.isVideoMuted &&
        widget.stream != null &&
        widget.stream!.getVideoTracks().isNotEmpty;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        border: widget.isActiveSpeaker
            ? Border.all(color: const Color(0xFF34D399), width: 3)
            : null,
        boxShadow: widget.isActiveSpeaker
            ? [
                BoxShadow(
                  color: const Color(0xFF34D399).withValues(alpha: 0.35),
                  blurRadius: 14,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: Stack(
          fit: StackFit.expand,
          children: [
            if (showVideo && _rendererInitialized)
              RTCVideoView(
                _renderer,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                mirror: widget.mirror,
              )
            else
              _avatarPlaceholder(context),
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: _overlay(context),
            ),
            if (widget.participant.reaction != null &&
                widget.participant.reaction!.isNotEmpty)
              Positioned(
                top: 8,
                right: 8,
                child: _ReactionBadge(emoji: widget.participant.reaction!),
              ),
            if (widget.participant.isScreenSharing)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.screen_share_rounded,
                          size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        AppLocalizations.of(context)!.meeting_participant_screen,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (widget.isActiveSpeaker)
              Positioned(
                top: 8,
                left: 8,
                right: 8,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF34D399).withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.mic_rounded, size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          AppLocalizations.of(context)!.meeting_participant_speaking,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
    );
  }

  /// Имя из глобального профиля `users/{uid}` — если есть, переопределяет
  /// никнейм, введённый при джойне.
  ({String name, String? avatar}) _displayFromProfile() {
    final doc = ref
            .watch(userChatSettingsDocProvider(widget.participant.id))
            .asData
            ?.value ??
        const <String, dynamic>{};
    String? str(dynamic v) {
      if (v is! String) return null;
      final t = v.trim();
      return t.isEmpty ? null : t;
    }

    final p = widget.participant;
    return (
      name: str(doc['name']) ?? p.name,
      avatar: str(doc['avatar']) ?? str(doc['avatarThumb']) ?? p.avatarThumb ?? p.avatar,
    );
  }

  Widget _avatarPlaceholder(BuildContext context) {
    final d = _displayFromProfile();
    return Container(
      color: const Color(0xFF111827),
      alignment: Alignment.center,
      child: ChatAvatar(
        title: d.name,
        radius: 40,
        avatarUrl: d.avatar,
      ),
    );
  }

  Widget _overlay(BuildContext context) {
    final p = widget.participant;
    final d = _displayFromProfile();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              widget.isLocal ? '${d.name} (Вы)' : d.name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (p.isAudioMuted) ...[
            const SizedBox(width: 6),
            const Icon(Icons.mic_off_rounded, size: 14, color: Colors.redAccent),
          ],
          if (p.isHandRaised) ...[
            const SizedBox(width: 6),
            const Icon(Icons.back_hand_rounded, size: 14, color: Colors.amber),
          ],
          if (!widget.isLocal &&
              widget.quality == PeerConnectionQuality.poor) ...[
            const SizedBox(width: 6),
            const Icon(
              Icons.signal_wifi_statusbar_connected_no_internet_4_rounded,
              size: 14,
              color: Colors.amber,
            ),
          ],
          if (!widget.isLocal &&
              widget.quality == PeerConnectionQuality.bad) ...[
            const SizedBox(width: 6),
            const Icon(
              Icons.signal_wifi_off_rounded,
              size: 14,
              color: Colors.redAccent,
            ),
          ],
        ],
      ),
    );
  }
}

/// Маленький «пузырёк» с эмодзи-реакцией. Показывается в правом верхнем
/// углу плитки, пока `participant.reaction` не `null`. Web-аналог —
/// `SmallReactionIndicator` в `src/components/meetings/ParticipantView.tsx`.
class _ReactionBadge extends StatelessWidget {
  const _ReactionBadge({required this.emoji});
  final String emoji;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(emoji, style: const TextStyle(fontSize: 20)),
    );
  }
}

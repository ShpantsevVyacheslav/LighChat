import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:go_router/go_router.dart';

import '../data/active_meeting_provider.dart';

/// Плавающая миниатюра локального стрима поверх любого экрана приложения.
/// Появляется, когда идёт звонок, и пользователь покинул экран комнаты
/// (например, открыл /chats через стрелку «Назад»). Это аналог
/// face-time-минивидео iOS: пользователь видит свою камеру и слышит
/// аудио конференции (звук тикает сам — peer connections митинга в
/// `MeetingRoomScreen` живут offstage).
class MeetingFloatingMiniStream extends ConsumerStatefulWidget {
  const MeetingFloatingMiniStream({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<MeetingFloatingMiniStream> createState() =>
      _MeetingFloatingMiniStreamState();
}

class _MeetingFloatingMiniStreamState
    extends ConsumerState<MeetingFloatingMiniStream> {
  // Позиция тайла на экране — сохраняется между перерисовками.
  Offset? _offset;

  @override
  Widget build(BuildContext context) {
    final info = ref.watch(activeMeetingProvider);
    // Маршруты, где митинг сам по себе уже на экране — миниатюру не нужно.
    final location = GoRouterState.of(context).uri.path;
    final onMeetingRoute = location.startsWith('/meetings/');
    final visible = info != null &&
        info.localStream != null &&
        !onMeetingRoute;

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (visible)
          _MiniStreamTile(
            stream: info.localStream!,
            mirror: info.frontCamera,
            meetingId: info.meetingId,
            offset: _offset,
            onOffsetChanged: (o) => setState(() => _offset = o),
          ),
      ],
    );
  }
}

class _MiniStreamTile extends StatefulWidget {
  const _MiniStreamTile({
    required this.stream,
    required this.mirror,
    required this.meetingId,
    required this.offset,
    required this.onOffsetChanged,
  });

  final MediaStream stream;
  final bool mirror;
  final String meetingId;
  final Offset? offset;
  final ValueChanged<Offset> onOffsetChanged;

  @override
  State<_MiniStreamTile> createState() => _MiniStreamTileState();
}

class _MiniStreamTileState extends State<_MiniStreamTile> {
  final _renderer = RTCVideoRenderer();
  bool _ready = false;

  static const double _width = 100;
  static const double _height = 140;
  static const double _margin = 16;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _renderer.initialize();
    if (!mounted) return;
    _renderer.srcObject = widget.stream;
    setState(() => _ready = true);
  }

  @override
  void didUpdateWidget(covariant _MiniStreamTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stream != widget.stream && _ready) {
      _renderer.srcObject = widget.stream;
    }
  }

  @override
  void dispose() {
    _renderer.srcObject = null;
    _renderer.dispose();
    super.dispose();
  }

  void _returnToMeeting(BuildContext context) {
    HapticFeedback.selectionClick();
    final nav = Navigator.of(context);
    // popUntil именно до именованного route 'meeting-room' — а не до
    // entry/лобби.
    nav.popUntil((r) => r.settings.name == 'meeting-room' || r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final pad = media.padding;
    // По умолчанию — нижний-правый угол, выше системной нижней панели.
    final defaultOffset = Offset(
      media.size.width - _width - _margin,
      media.size.height - _height - _margin - pad.bottom - 60,
    );
    final offset = widget.offset ?? defaultOffset;

    final hasVideo = widget.stream.getVideoTracks().any((t) => t.enabled);

    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: GestureDetector(
        onTap: () => _returnToMeeting(context),
        onPanUpdate: (d) {
          final next = Offset(
            (offset.dx + d.delta.dx).clamp(
              _margin,
              media.size.width - _width - _margin,
            ),
            (offset.dy + d.delta.dy).clamp(
              pad.top + _margin,
              media.size.height - _height - _margin - pad.bottom,
            ),
          );
          widget.onOffsetChanged(next);
        },
        child: Material(
          elevation: 12,
          borderRadius: BorderRadius.circular(14),
          color: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: _width,
              height: _height,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: const Color(0xFF101521)),
                  if (_ready && hasVideo)
                    RTCVideoView(
                      _renderer,
                      mirror: widget.mirror,
                      objectFit:
                          RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    )
                  else
                    const Center(
                      child: Icon(
                        Icons.videocam_off_rounded,
                        color: Colors.white54,
                        size: 24,
                      ),
                    ),
                  // Кнопка-крестик в углу — НЕ закрывает звонок, а
                  // прячет миниатюру до возврата в комнату вручную.
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.55),
                      ),
                      child: const Icon(Icons.videocam_rounded,
                          color: Colors.white, size: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

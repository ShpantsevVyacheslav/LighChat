import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/meeting_models.dart';
import '../data/meeting_providers.dart';
import 'meeting_room_screen.dart';

/// Pre-join screen: вход в приватный митинг (waiting room) или прямой джойн
/// в публичный. Поддерживает два сценария:
///
/// 1. Залогиненный пользователь (`FirebaseAuth.currentUser != null, isAnonymous == false`):
///    берём его имя/аватар из параметра `currentUser*`.
/// 2. Гость (`isAnonymous == true`): `MeetingJoinScreen` обязательно вызывается с
///    заранее подписанным анонимным `selfUid`, имя вводит пользователь; аватар
///    генерируется DiceBear-URL как в вебе.
///
/// В `initState` выбираем путь по `meeting.isPrivate`: для приватного открываем
/// waiting-room, для публичного — сразу пропускаем на `MeetingRoomScreen`.
class MeetingJoinScreen extends ConsumerStatefulWidget {
  const MeetingJoinScreen({
    super.key,
    required this.meetingId,
    required this.selfUid,
    required this.isGuest,
    this.initialName,
    this.initialAvatar,
    this.initialAvatarThumb,
    this.role,
  });

  final String meetingId;
  final String selfUid;
  final bool isGuest;
  final String? initialName;
  final String? initialAvatar;
  final String? initialAvatarThumb;
  final String? role;

  @override
  ConsumerState<MeetingJoinScreen> createState() => _MeetingJoinScreenState();
}

class _MeetingJoinScreenState extends ConsumerState<MeetingJoinScreen> {
  late final TextEditingController _nameCtrl;
  late final String _requestId;
  bool _requestSubmitted = false;
  bool _sendingRequest = false;
  String? _lastError;

  // Лобби: превью камеры + начальные mute-флаги, которые передадим в комнату.
  final RTCVideoRenderer _previewRenderer = RTCVideoRenderer();
  MediaStream? _previewStream;
  bool _previewReady = false;
  bool _previewDenied = false;
  bool _initialMicMuted = false;
  bool _initialCameraOff = false;
  bool _consumed = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName ?? '');
    _requestId = _generateRequestId();
    _bootstrapPreview();
  }

  Future<void> _bootstrapPreview() async {
    await _previewRenderer.initialize();
    try {
      final cam = await Permission.camera.request();
      final mic = await Permission.microphone.request();
      if (cam.isDenied || cam.isPermanentlyDenied) {
        if (mounted) {
          setState(() {
            _previewDenied = true;
            _initialCameraOff = true;
          });
        }
        return;
      }
      if (mic.isDenied || mic.isPermanentlyDenied) {
        // Микро может быть запрещено — это нормально, просто start с muted=true.
        _initialMicMuted = true;
      }
      final stream = await navigator.mediaDevices.getUserMedia(<String, dynamic>{
        'audio': true,
        'video': <String, dynamic>{'facingMode': 'user'},
      });
      if (!mounted) {
        for (final t in stream.getTracks()) {
          await t.stop();
        }
        await stream.dispose();
        return;
      }
      _previewStream = stream;
      _previewRenderer.srcObject = stream;
      setState(() {
        _previewReady = true;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('[meeting-lobby] preview failed: $e');
      if (mounted) {
        setState(() {
          _previewDenied = true;
          _initialCameraOff = true;
        });
      }
    }
  }

  Future<void> _stopPreview() async {
    final stream = _previewStream;
    _previewStream = null;
    _previewRenderer.srcObject = null;
    if (stream != null) {
      for (final t in stream.getTracks()) {
        try {
          await t.stop();
        } catch (_) {}
      }
      try {
        await stream.dispose();
      } catch (_) {}
    }
  }

  void _toggleMicLocal() {
    setState(() => _initialMicMuted = !_initialMicMuted);
    final s = _previewStream;
    if (s != null) {
      for (final t in s.getAudioTracks()) {
        t.enabled = !_initialMicMuted;
      }
    }
  }

  void _toggleCameraLocal() {
    setState(() => _initialCameraOff = !_initialCameraOff);
    final s = _previewStream;
    if (s != null) {
      for (final t in s.getVideoTracks()) {
        t.enabled = !_initialCameraOff;
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    if (!_consumed) {
      _stopPreview();
    }
    _previewRenderer.dispose();
    super.dispose();
  }

  String _generateRequestId() {
    const alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rnd = Random.secure();
    final buf = StringBuffer();
    for (var i = 0; i < 10; i++) {
      buf.write(alphabet[rnd.nextInt(alphabet.length)]);
    }
    return buf.toString();
  }

  String _avatarUrl() {
    return widget.initialAvatar ??
        'https://api.dicebear.com/7.x/avataaars/svg?seed=${widget.selfUid}';
  }

  Future<void> _submitRequest() async {
    final name = _resolveName();
    if (name.isEmpty) {
      setState(() => _lastError = AppLocalizations.of(context)!.meeting_join_enter_name);
      return;
    }
    setState(() {
      _sendingRequest = true;
      _lastError = null;
    });
    try {
      await ref.read(meetingCallablesProvider).requestMeetingAccess(
            meetingId: widget.meetingId,
            name: name,
            avatar: _avatarUrl(),
            requestId: _requestId,
          );
      if (!mounted) return;
      setState(() {
        _requestSubmitted = true;
        _sendingRequest = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sendingRequest = false;
        _lastError = e.toString();
      });
    }
  }

  String _resolveName() {
    if (!widget.isGuest) {
      return (widget.initialName ?? '').trim();
    }
    return _nameCtrl.text.trim();
  }

  void _goToRoom() {
    final resolved = _resolveName();
    final name = resolved.isEmpty
        ? (widget.initialName?.trim().isNotEmpty == true
            ? widget.initialName!.trim()
            : AppLocalizations.of(context)!.meeting_join_guest)
        : resolved;
    _consumed = true;
    // Стрим лобби-превью гасим перед заходом в комнату — там WebRtc
    // запросит свежий getUserMedia с теми же камерой/микрофоном.
    _stopPreview();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => MeetingRoomScreen(
          meetingId: widget.meetingId,
          selfUid: widget.selfUid,
          selfName: name,
          selfAvatar: _avatarUrl(),
          selfAvatarThumb: widget.initialAvatarThumb,
          selfRole: widget.role,
          initialMicMuted: _initialMicMuted,
          initialCameraOff: _initialCameraOff,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final meetingAsync = ref.watch(meetingDocProvider(widget.meetingId));
    final ownRequestAsync = ref.watch(
      meetingOwnRequestProvider(
        MeetingOwnRequestKey(
          meetingId: widget.meetingId,
          userId: widget.selfUid,
        ),
      ),
    );

    // Если гость уже одобрен — сразу переходим в комнату.
    final ownRequest = ownRequestAsync.asData?.value;
    if (_requestSubmitted && ownRequest?.status == 'approved') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _goToRoom();
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0B1020),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          AppLocalizations.of(context)!.meeting_join_button,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: meetingAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        error: (e, _) => _error(AppLocalizations.of(context)!.meeting_join_load_error(e.toString())),
        data: (meeting) {
          if (meeting == null) {
            return _error(AppLocalizations.of(context)!.meeting_not_found);
          }
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: _body(context, meeting, ownRequest),
            ),
          );
        },
      ),
    );
  }

  Widget _body(
    BuildContext context,
    MeetingDoc meeting,
    MeetingRequestDoc? ownRequest,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _previewCard(context),
        const SizedBox(height: 16),
        Text(
          meeting.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          meeting.isPrivate
              ? AppLocalizations.of(context)!.meeting_private_hint
              : AppLocalizations.of(context)!.meeting_public_hint,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 20),
        if (widget.isGuest)
          TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.meeting_name_label,
              labelStyle: const TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.08),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          )
        else
          _identityCard(context),
        if (_lastError != null) ...[
          const SizedBox(height: 8),
          Text(
            _lastError!,
            style: const TextStyle(color: Colors.redAccent, fontSize: 12),
          ),
        ],
        const SizedBox(height: 20),
        if (meeting.isPrivate && !meeting.isAdmin(widget.selfUid))
          _privateJoinFlow(ownRequest)
        else
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: _goToRoom,
            child: Text(
              AppLocalizations.of(context)!.meeting_enter_room,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }

  Widget _privateJoinFlow(MeetingRequestDoc? ownRequest) {
    if (!_requestSubmitted) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3B82F6),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: _sendingRequest ? null : _submitRequest,
        child: _sendingRequest
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                AppLocalizations.of(context)!.meeting_request_join,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
      );
    }
    final status = ownRequest?.status ?? 'pending';
    final l10n = AppLocalizations.of(context)!;
    if (status == 'approved') {
      return _StatusBanner(
        icon: Icons.check_circle_rounded,
        color: const Color(0xFF34D399),
        title: l10n.meeting_approved_title,
        subtitle: l10n.meeting_approved_subtitle,
      );
    }
    if (status == 'denied') {
      return Column(
        children: [
          _StatusBanner(
            icon: Icons.block_rounded,
            color: Colors.redAccent,
            title: l10n.meeting_denied_title,
            subtitle: l10n.meeting_denied_subtitle,
          ),
        ],
      );
    }
    return _StatusBanner(
      icon: Icons.hourglass_top_rounded,
      color: const Color(0xFFF59E0B),
      title: l10n.meeting_waiting_title,
      subtitle: l10n.meeting_waiting_subtitle,
    );
  }

  Widget _previewCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_previewReady && !_initialCameraOff)
              Transform(
                alignment: Alignment.center,
                // mirror — как в вебе и привычно для self-view фронтальной камерой.
                transform: Matrix4.identity()..scaleByDouble(-1.0, 1.0, 1.0, 1.0),
                child: RTCVideoView(
                  _previewRenderer,
                  objectFit:
                      RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
              )
            else
              Center(
                child: Icon(
                  _previewDenied
                      ? Icons.videocam_off_rounded
                      : Icons.videocam_rounded,
                  color: Colors.white24,
                  size: 64,
                ),
              ),
            if (_previewDenied)
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      l10n.meeting_lobby_camera_blocked,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _previewCircle(
                    icon: _initialMicMuted
                        ? Icons.mic_off_rounded
                        : Icons.mic_rounded,
                    bg: _initialMicMuted ? Colors.redAccent : Colors.black54,
                    onTap: _toggleMicLocal,
                  ),
                  const SizedBox(width: 14),
                  _previewCircle(
                    icon: _initialCameraOff
                        ? Icons.videocam_off_rounded
                        : Icons.videocam_rounded,
                    bg: _initialCameraOff ? Colors.redAccent : Colors.black54,
                    onTap: _previewDenied ? null : _toggleCameraLocal,
                    disabled: _previewDenied,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _previewCircle({
    required IconData icon,
    required Color bg,
    required VoidCallback? onTap,
    bool disabled = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkResponse(
        onTap: onTap,
        radius: 28,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: bg.withValues(alpha: disabled ? 0.4 : 0.85),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  Widget _identityCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = (widget.initialName ?? '').trim();
    final displayName = name.isEmpty ? l10n.meeting_join_guest : name;
    final avatar = widget.initialAvatar;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white.withValues(alpha: 0.12),
            backgroundImage:
                (avatar != null && avatar.isNotEmpty) ? NetworkImage(avatar) : null,
            child: (avatar == null || avatar.isEmpty)
                ? Text(
                    displayName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.meeting_join_as_label,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _error(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../data/chat_call_tones.dart';
import '../data/chat_call_status.dart';
import '../../../l10n/app_localizations.dart';
import 'chat_avatar.dart';
import 'in_app_call_mini_window_controller.dart';
import 'picture_in_picture_bridge.dart';

class ChatVideoCallScreen extends StatefulWidget {
  const ChatVideoCallScreen({
    super.key,
    required this.currentUserId,
    required this.currentUserName,
    required this.peerUserId,
    required this.peerUserName,
    this.currentUserAvatarUrl,
    this.peerAvatarUrl,
    this.existingCallId,
    this.autoAccept = false,
  });

  final String currentUserId;
  final String currentUserName;
  final String? currentUserAvatarUrl;
  final String peerUserId;
  final String peerUserName;
  final String? peerAvatarUrl;
  final String? existingCallId;
  final bool autoAccept;

  @override
  State<ChatVideoCallScreen> createState() => _ChatVideoCallScreenState();
}

class _ChatVideoCallScreenState extends State<ChatVideoCallScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _callSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _candidatesSub;

  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  String? _callId;
  String _status = 'connecting'; // calling | ringing | ongoing | ended
  bool _incoming = false;
  bool _remoteDescriptionSet = false;
  bool _answerApplied = false;
  bool _micMuted = false;
  bool _videoMuted = false;
  bool _busy = false;
  bool _frontCamera = true;
  int _seconds = 0;
  Timer? _timer;
  final List<RTCIceCandidate> _queuedCandidates = <RTCIceCandidate>[];
  final Set<String> _seenCandidateDocIds = <String>{};
  bool _closedByUser = false;
  final ChatCallToneController _callTones = ChatCallToneController();
  Timer? _outgoingCallTimeoutTimer;
  bool _pipBusy = false;

  /// Local preview draggable + resizable state.
  Offset _localPreviewOffset = const Offset(14, 180);
  double _localPreviewScale = 1.0;
  Offset? _localPreviewDragStart;
  Offset? _localPreviewOffsetAtDragStart;
  double? _localPreviewScaleAtStart;

  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onPause: _handleAppPaused,
      onInactive: _handleAppPaused,
    );
    _init();
  }

  void _handleAppPaused() {
    // Android: auto-enter PiP when an ongoing video call is backgrounded.
    if (_status != 'ongoing') return;
    unawaited(_enterPip(auto: true));
  }

  Future<void> _enterPip({required bool auto}) async {
    if (_pipBusy) return;
    // Only Android uses this bridge right now.
    final supported = await ChatPictureInPictureBridge.isSupported();
    if (!supported) return;

    // Use a sane aspect ratio for a remote video surface.
    const aspectW = 16;
    const aspectH = 9;
    _pipBusy = true;
    try {
      final ok = await ChatPictureInPictureBridge.enterAndroid(
        aspectW: aspectW,
        aspectH: aspectH,
      );
      if (!ok || !mounted) return;
      if (!auto) {
        // Non-blocking navigation: once PiP is active, return to the app.
        final nav = Navigator.of(context);
        if (nav.canPop()) {
          nav.pop();
        } else {
          context.go('/calls');
        }
      }
    } finally {
      _pipBusy = false;
    }
  }

  Future<void> _enterInAppMiniWindow() async {
    if (!mounted) return;
    if (_status != 'ongoing') return;
    if (_remoteRenderer.srcObject == null) return;

    InAppCallMiniWindowController.show(
      InAppCallMiniWindowPayload(
        remoteRenderer: _remoteRenderer,
        localRenderer: _localRenderer,
        title: widget.peerUserName,
        onReturnToCall: () {
          InAppCallMiniWindowController.hide();
          if (!mounted) return;
          final nav = Navigator.of(context);
          if (nav.canPop()) nav.pop();
        },
        onHangUp: () {
          InAppCallMiniWindowController.hide();
          _endCall();
        },
      ),
    );

    // Push a normal screen above the call so the user can navigate.
    if (!mounted) return;
    context.push('/calls');
  }

  Future<void> _init() async {
    await _remoteRenderer.initialize();
    await _localRenderer.initialize();
    unawaited(_callTones.prepare().then((_) => _syncCallTones()));
    try {
      if (widget.existingCallId == null || widget.existingCallId!.isEmpty) {
        final callId = await _createOutgoingCall();
        _callId = callId;
        _incoming = false;
        _status = 'calling';
      } else {
        _callId = widget.existingCallId;
        _incoming = true;
        _status = 'ringing';
      }
      if (!mounted) return;
      setState(() {});
      _syncCallTones();
      _watchCallDoc();
      await _ensurePeerReady();
      if (!_incoming) {
        await _makeOffer();
      } else if (widget.autoAccept) {
        await _acceptIncoming();
      }
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.video_call_error_init(e))),
      );
      Navigator.of(context).maybePop();
    }
  }

  Future<String> _createOutgoingCall() async {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final ref = await _firestore.collection('calls').add(<String, Object?>{
      'callerId': widget.currentUserId,
      'receiverId': widget.peerUserId,
      'callerName': widget.currentUserName,
      'receiverName': widget.peerUserName,
      'status': 'calling',
      'isVideo': true,
      'createdAt': nowIso,
    });
    return ref.id;
  }

  Future<void> _ensurePeerReady() async {
    if (_pc != null && _localStream != null) return;
    final pc = await createPeerConnection(<String, dynamic>{
      'iceServers': <Map<String, dynamic>>[
        <String, dynamic>{'urls': 'stun:stun.l.google.com:19302'},
      ],
      'sdpSemantics': 'unified-plan',
    });

    final stream = await navigator.mediaDevices.getUserMedia(<String, dynamic>{
      'audio': true,
      'video': <String, dynamic>{'facingMode': 'user'},
    });

    for (final track in stream.getTracks()) {
      await pc.addTrack(track, stream);
    }
    _localRenderer.srcObject = stream;

    pc.onIceCandidate = (candidate) async {
      final callId = _callId;
      if (callId == null) return;
      final map = candidate.toMap();
      if (map['candidate'] == null) return;
      await _firestore
          .collection('calls')
          .doc(callId)
          .collection('candidates')
          .add(<String, Object?>{
            ...map,
            'userId': widget.currentUserId,
            'createdAt': FieldValue.serverTimestamp(),
          });
    };

    pc.onTrack = (event) async {
      if (event.streams.isEmpty) return;
      _remoteStream = event.streams.first;
      await _remoteRenderer.srcObject?.dispose();
      _remoteRenderer.srcObject = _remoteStream;
      if (mounted) setState(() {});
    };

    _pc = pc;
    _localStream = stream;
    _watchCandidates();
  }

  Future<void> _watchCandidates() async {
    final callId = _callId;
    if (callId == null) return;
    await _candidatesSub?.cancel();
    _candidatesSub = _firestore
        .collection('calls')
        .doc(callId)
        .collection('candidates')
        .snapshots()
        .listen((snap) async {
          for (final ch in snap.docChanges) {
            if (ch.type != DocumentChangeType.added) continue;
            if (_seenCandidateDocIds.contains(ch.doc.id)) continue;
            _seenCandidateDocIds.add(ch.doc.id);
            final data = ch.doc.data();
            if (data == null) continue;
            if ((data['userId'] as String?) == widget.currentUserId) continue;
            final candStr = data['candidate'];
            if (candStr is! String || candStr.trim().isEmpty) continue;
            final candidate = RTCIceCandidate(
              candStr,
              data['sdpMid'] as String?,
              (data['sdpMLineIndex'] as num?)?.toInt(),
            );
            final pc = _pc;
            if (pc == null || !_remoteDescriptionSet) {
              _queuedCandidates.add(candidate);
              continue;
            }
            try {
              await pc.addCandidate(candidate);
            } catch (_) {}
          }
        });
  }

  DateTime? _parseFirestoreDate(dynamic raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  void _cancelOutgoingCallTimeout() {
    _outgoingCallTimeoutTimer?.cancel();
    _outgoingCallTimeoutTimer = null;
  }

  Future<void> _markOutgoingCallMissedIfNeeded() async {
    final callId = _callId;
    if (callId == null) return;
    try {
      final ref = _firestore.collection('calls').doc(callId);
      final snap = await ref.get();
      if (!snap.exists) return;
      final data = snap.data() ?? const <String, dynamic>{};
      if ((data['status'] as String?) != 'calling') return;
      if ((data['callerId'] as String?) != widget.currentUserId) return;
      await ref.update(<String, Object?>{
        'status': 'missed',
        'endedAt': DateTime.now().toUtc().toIso8601String(),
        'endedBy': widget.currentUserId,
      });
    } catch (_) {}
  }

  void _scheduleOutgoingCallTimeout(Map<String, dynamic> data) {
    if (_incoming) {
      _cancelOutgoingCallTimeout();
      return;
    }
    final status = (data['status'] as String?) ?? '';
    if (status != 'calling') {
      _cancelOutgoingCallTimeout();
      return;
    }
    final createdAt = _parseFirestoreDate(data['createdAt']);
    if (createdAt == null) return;
    final elapsed = DateTime.now().toUtc().difference(createdAt.toUtc());
    final remain = const Duration(seconds: 60) - elapsed;
    if (remain <= Duration.zero) {
      _cancelOutgoingCallTimeout();
      unawaited(_markOutgoingCallMissedIfNeeded());
      return;
    }
    _outgoingCallTimeoutTimer?.cancel();
    _outgoingCallTimeoutTimer = Timer(remain, () {
      unawaited(_markOutgoingCallMissedIfNeeded());
    });
  }

  void _watchCallDoc() {
    final callId = _callId;
    if (callId == null) return;
    _callSub = _firestore.collection('calls').doc(callId).snapshots().listen((
      snap,
    ) async {
      if (!snap.exists) {
        if (!mounted) return;
        await _close(AppLocalizations.of(context)!.video_call_ended);
        return;
      }
      final data = snap.data() ?? const <String, dynamic>{};
      final status = (data['status'] as String?) ?? 'calling';
      _scheduleOutgoingCallTimeout(data);

      if (isTerminalCallStatus(status)) {
        _cancelOutgoingCallTimeout();
        final viewerIsReceiver =
            (data['receiverId'] as String?) == widget.currentUserId;
        final resolvedStatus = resolveCallTerminalStatusForViewer(
          rawStatus: status,
          viewerIsReceiver: viewerIsReceiver,
          callerId: data['callerId'] as String?,
          receiverId: data['receiverId'] as String?,
          endedBy: data['endedBy'] as String?,
        );
        if (!mounted) return;
        final l10n = AppLocalizations.of(context)!;
        final txt = resolvedStatus == 'missed'
            ? l10n.video_call_status_missed
            : resolvedStatus == 'cancelled'
                ? l10n.video_call_status_cancelled
                : l10n.video_call_ended;
        await _close(txt);
        return;
      }

      if (_incoming && status == 'calling') {
        _setStatus('ringing');
      } else if (status == 'ongoing') {
        _startTimerIfNeeded();
        _setStatus('ongoing');
      } else {
        _setStatus('calling');
      }

      if (!_incoming && !_answerApplied) {
        final answer = data['answer'];
        if (answer is Map) {
          await _applyAnswer(answer);
        }
      }
    });
  }

  Future<void> _makeOffer() async {
    final pc = _pc;
    final callId = _callId;
    if (pc == null || callId == null) return;
    final offer = await pc.createOffer(<String, dynamic>{
      'offerToReceiveAudio': 1,
      'offerToReceiveVideo': 1,
    });
    await pc.setLocalDescription(offer);
    await _firestore.collection('calls').doc(callId).update(<String, Object?>{
      'offer': <String, Object?>{'type': offer.type, 'sdp': offer.sdp},
    });
  }

  Future<void> _applyAnswer(Map answer) async {
    final pc = _pc;
    if (pc == null || _answerApplied) return;
    final type = answer['type'];
    final sdp = answer['sdp'];
    if (type is! String || sdp is! String || sdp.trim().isEmpty) return;
    await pc.setRemoteDescription(RTCSessionDescription(sdp, type));
    _answerApplied = true;
    _remoteDescriptionSet = true;
    await _flushQueuedCandidates();
  }

  Future<void> _acceptIncoming() async {
    if (_busy) return;
    final callId = _callId;
    final pc = _pc;
    if (callId == null || pc == null) return;
    setState(() => _busy = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      final snap = await _firestore.collection('calls').doc(callId).get();
      final data = snap.data() ?? const <String, dynamic>{};
      final offer = data['offer'];
      if (offer is! Map) {
        throw l10n.video_call_error_offer_not_ready;
      }
      final type = offer['type'];
      final sdp = offer['sdp'];
      if (type is! String || sdp is! String || sdp.trim().isEmpty) {
        throw l10n.video_call_error_invalid_call_data;
      }
      await pc.setRemoteDescription(RTCSessionDescription(sdp, type));
      _remoteDescriptionSet = true;
      await _flushQueuedCandidates();

      final answer = await pc.createAnswer(<String, dynamic>{
        'offerToReceiveAudio': 1,
        'offerToReceiveVideo': 1,
      });
      await pc.setLocalDescription(answer);
      await _firestore.collection('calls').doc(callId).update(<String, Object?>{
        'answer': <String, Object?>{'type': answer.type, 'sdp': answer.sdp},
        'status': 'ongoing',
        'startedAt': DateTime.now().toUtc().toIso8601String(),
      });
      _cancelOutgoingCallTimeout();
      _startTimerIfNeeded();
      _setStatus('ongoing');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.video_call_error_accept_failed(e))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _flushQueuedCandidates() async {
    final pc = _pc;
    if (pc == null || !_remoteDescriptionSet) return;
    while (_queuedCandidates.isNotEmpty) {
      final c = _queuedCandidates.removeAt(0);
      try {
        await pc.addCandidate(c);
      } catch (_) {}
    }
  }

  void _startTimerIfNeeded() {
    if (_timer != null) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _seconds += 1);
    });
  }

  void _setStatus(String next) {
    if (_status == next) {
      _syncCallTones();
      return;
    }
    if (mounted) {
      setState(() => _status = next);
    } else {
      _status = next;
    }
    _syncCallTones();
  }

  void _syncCallTones() {
    final incomingRinging = _incoming && _status == 'ringing';
    final outgoingRinging = !_incoming && _status == 'calling';
    unawaited(
      _callTones.sync(
        playIncomingRingtone: incomingRinging,
        playOutgoingRingback: outgoingRinging,
      ),
    );
  }

  Future<void> _rejectIncoming() async {
    final callId = _callId;
    if (callId != null) {
      await _firestore.collection('calls').doc(callId).update(<String, Object?>{
        'status': 'cancelled',
        'endedAt': DateTime.now().toUtc().toIso8601String(),
        'endedBy': widget.currentUserId,
      });
    }
    await _close(null);
  }

  Future<void> _endCall() async {
    InAppCallMiniWindowController.hide();
    final callId = _callId;
    if (callId != null) {
      final nextStatus = _status == 'ongoing'
          ? 'ended'
          : (_incoming ? 'cancelled' : 'missed');
      await _firestore.collection('calls').doc(callId).update(<String, Object?>{
        'status': nextStatus,
        'endedAt': DateTime.now().toUtc().toIso8601String(),
        'endedBy': widget.currentUserId,
      });
    }
    await _close(null);
  }

  void _toggleMute() {
    final track = _localStream?.getAudioTracks().isEmpty == true
        ? null
        : _localStream?.getAudioTracks().first;
    if (track == null) return;
    final next = !_micMuted;
    track.enabled = !next;
    setState(() => _micMuted = next);
  }

  void _toggleVideo() {
    final track = _localStream?.getVideoTracks().isEmpty == true
        ? null
        : _localStream?.getVideoTracks().first;
    if (track == null) return;
    final next = !_videoMuted;
    track.enabled = !next;
    setState(() => _videoMuted = next);
  }

  Future<void> _switchCamera() async {
    final track = _localStream?.getVideoTracks().isEmpty == true
        ? null
        : _localStream?.getVideoTracks().first;
    if (track == null) return;
    try {
      await Helper.switchCamera(track);
      if (!mounted) return;
      setState(() => _frontCamera = !_frontCamera);
    } catch (_) {}
  }

  String _durationLabel() {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _close(String? message) async {
    if (_closedByUser) return;
    _closedByUser = true;
    await _callTones.stop();
    if (message != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
    if (mounted) {
      final nav = Navigator.of(context);
      if (nav.canPop()) {
        nav.pop();
      } else {
        context.go('/calls');
      }
    }
  }

  Future<void> _disposeRtc() async {
    _timer?.cancel();
    _timer = null;
    _cancelOutgoingCallTimeout();
    await _callSub?.cancel();
    await _candidatesSub?.cancel();
    try {
      await _pc?.close();
    } catch (_) {}
    _pc = null;
    if (_localStream != null) {
      for (final t in _localStream!.getTracks()) {
        await t.stop();
      }
      await _localStream!.dispose();
      _localStream = null;
    }
    if (_remoteStream != null) {
      await _remoteStream!.dispose();
      _remoteStream = null;
    }
    await _callTones.dispose();
    await _remoteRenderer.dispose();
    await _localRenderer.dispose();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    unawaited(_disposeRtc());
    super.dispose();
  }

  Offset _clampLocalPreviewOffset({
    required Offset candidate,
    required Size screen,
    required Size preview,
  }) {
    final left = 10.0;
    final top = 10.0;
    final right = screen.width - preview.width - 10.0;
    final bottom = screen.height - preview.height - 90.0; // avoid controls row
    return Offset(
      candidate.dx.clamp(left, right),
      candidate.dy.clamp(top, bottom),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isIncomingRinging = _incoming && _status == 'ringing';
    final hasRemote = _remoteRenderer.srcObject != null;
    final screen = MediaQuery.sizeOf(context);
    return Scaffold(
      backgroundColor: const Color(0xFF050A14),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: hasRemote
                  ? RTCVideoView(
                      _remoteRenderer,
                      objectFit:
                          RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    )
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF0A1622), Color(0xFF06090F)],
                        ),
                      ),
                      child: Center(
                        child: ChatAvatar(
                          title: widget.peerUserName,
                          radius: 72,
                          avatarUrl: widget.peerAvatarUrl,
                        ),
                      ),
                    ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.34),
                      Colors.black.withValues(alpha: 0.18),
                      Colors.black.withValues(alpha: 0.40),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  IconButton(
                    onPressed: _endCall,
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: Colors.white.withValues(alpha: 0.94),
                  ),
                  const Spacer(),
                  if (!isIncomingRinging)
                    IconButton(
                      onPressed: _switchCamera,
                      icon: Icon(
                        _frontCamera
                            ? Icons.cameraswitch_rounded
                            : Icons.flip_camera_ios_rounded,
                      ),
                      color: Colors.white.withValues(alpha: 0.94),
                    ),
                  if (!isIncomingRinging)
                    IconButton(
                      onPressed: _status == 'ongoing' ? () => _enterPip(auto: false) : null,
                      icon: const Icon(Icons.picture_in_picture_alt_rounded),
                      color: Colors.white.withValues(alpha: 0.94),
                      tooltip: l10n.video_call_pip_tooltip,
                    ),
                  if (!isIncomingRinging)
                    IconButton(
                      onPressed: _status == 'ongoing' ? _enterInAppMiniWindow : null,
                      icon: const Icon(Icons.open_in_new_rounded),
                      color: Colors.white.withValues(alpha: 0.94),
                      tooltip: l10n.video_call_mini_window_tooltip,
                    ),
                ],
              ),
            ),
            Positioned(
              top: 74,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Text(
                    widget.peerUserName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _status == 'ongoing'
                        ? _durationLabel()
                        : (isIncomingRinging
                              ? l10n.video_call_incoming
                              : l10n.video_call_connecting),
                    style: TextStyle(
                      color: Colors.cyanAccent.withValues(alpha: 0.88),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (_localRenderer.srcObject != null)
              Positioned(
                left: _localPreviewOffset.dx,
                top: _localPreviewOffset.dy,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 116 * _localPreviewScale,
                    height: 172 * _localPreviewScale,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 1.2,
                      ),
                    ),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onScaleStart: (d) {
                        _localPreviewDragStart = d.focalPoint;
                        _localPreviewOffsetAtDragStart = _localPreviewOffset;
                        _localPreviewScaleAtStart = _localPreviewScale;
                      },
                      onScaleUpdate: (d) {
                        final start = _localPreviewDragStart;
                        final baseOffset = _localPreviewOffsetAtDragStart;
                        final baseScale = _localPreviewScaleAtStart;
                        if (start == null || baseOffset == null || baseScale == null) return;
                        final delta = d.focalPoint - start;
                        final nextScale = (baseScale * d.scale).clamp(0.75, 2.1);
                        final previewSize = Size(116 * nextScale, 172 * nextScale);
                        final candidate = baseOffset + delta;
                        final clamped = _clampLocalPreviewOffset(
                          candidate: candidate,
                          screen: screen,
                          preview: previewSize,
                        );
                        setState(() {
                          _localPreviewScale = nextScale;
                          _localPreviewOffset = clamped;
                        });
                      },
                      onDoubleTap: () {
                        // Quick size cycle.
                        final next = _localPreviewScale < 1.05
                            ? 1.35
                            : (_localPreviewScale < 1.45 ? 1.8 : 1.0);
                        final previewSize = Size(116 * next, 172 * next);
                        final clamped = _clampLocalPreviewOffset(
                          candidate: _localPreviewOffset,
                          screen: screen,
                          preview: previewSize,
                        );
                        setState(() {
                          _localPreviewScale = next;
                          _localPreviewOffset = clamped;
                        });
                      },
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          RTCVideoView(
                            _localRenderer,
                            mirror: _frontCamera,
                            objectFit: RTCVideoViewObjectFit
                                .RTCVideoViewObjectFitCover,
                          ),
                          if (_videoMuted)
                            Container(
                              color: Colors.black.withValues(alpha: 0.55),
                              child: const Icon(
                                Icons.videocam_off_rounded,
                                color: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 24,
              child: isIncomingRinging
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _roundCallButton(
                          onTap: _busy ? null : _rejectIncoming,
                          icon: Icons.call_end_rounded,
                          bg: const Color(0xFFEF5350),
                        ),
                        const SizedBox(width: 30),
                        _roundCallButton(
                          onTap: _busy ? null : _acceptIncoming,
                          icon: Icons.videocam_rounded,
                          bg: const Color(0xFF26A69A),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _roundCallButton(
                          onTap: _toggleMute,
                          icon: _micMuted
                              ? Icons.mic_off_rounded
                              : Icons.mic_rounded,
                          bg: _micMuted
                              ? Colors.white.withValues(alpha: 0.24)
                              : Colors.white.withValues(alpha: 0.14),
                        ),
                        const SizedBox(width: 18),
                        _roundCallButton(
                          onTap: _toggleVideo,
                          icon: _videoMuted
                              ? Icons.videocam_off_rounded
                              : Icons.videocam_rounded,
                          bg: _videoMuted
                              ? Colors.white.withValues(alpha: 0.24)
                              : Colors.white.withValues(alpha: 0.14),
                        ),
                        const SizedBox(width: 18),
                        _roundCallButton(
                          onTap: _endCall,
                          icon: Icons.call_end_rounded,
                          bg: const Color(0xFFEF5350),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roundCallButton({
    required VoidCallback? onTap,
    required IconData icon,
    required Color bg,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          width: 66,
          height: 66,
          decoration: BoxDecoration(
            color: onTap == null ? bg.withValues(alpha: 0.5) : bg,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 30),
        ),
      ),
    );
  }
}

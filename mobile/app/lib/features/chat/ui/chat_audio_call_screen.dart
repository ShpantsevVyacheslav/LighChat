import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../data/chat_call_tones.dart';
import '../data/chat_call_status.dart';
import 'chat_avatar.dart';

class ChatAudioCallScreen extends StatefulWidget {
  const ChatAudioCallScreen({
    super.key,
    required this.currentUserId,
    required this.currentUserName,
    required this.peerUserId,
    required this.peerUserName,
    this.currentUserAvatarUrl,
    this.peerAvatarUrl,
    this.existingCallId,
  });

  final String currentUserId;
  final String currentUserName;
  final String? currentUserAvatarUrl;
  final String peerUserId;
  final String peerUserName;
  final String? peerAvatarUrl;
  final String? existingCallId;

  @override
  State<ChatAudioCallScreen> createState() => _ChatAudioCallScreenState();
}

class _ChatAudioCallScreenState extends State<ChatAudioCallScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

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
  bool _busy = false;
  int _seconds = 0;
  Timer? _timer;
  final List<RTCIceCandidate> _queuedCandidates = <RTCIceCandidate>[];
  final Set<String> _seenCandidateDocIds = <String>{};
  bool _closedByUser = false;
  final ChatCallToneController _callTones = ChatCallToneController();
  Timer? _outgoingCallTimeoutTimer;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _remoteRenderer.initialize();
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
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка звонка: $e')));
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
      'isVideo': false,
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
      'video': false,
    });

    for (final track in stream.getTracks()) {
      await pc.addTrack(track, stream);
    }

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
        await _close('Звонок завершён');
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
        );
        final txt = resolvedStatus == 'missed'
            ? 'Пропущенный звонок'
            : resolvedStatus == 'cancelled'
            ? 'Звонок отменен'
            : 'Звонок завершён';
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
    try {
      final snap = await _firestore.collection('calls').doc(callId).get();
      final data = snap.data() ?? const <String, dynamic>{};
      final offer = data['offer'];
      if (offer is! Map) {
        throw 'Оффер ещё не готов, попробуйте снова';
      }
      final type = offer['type'];
      final sdp = offer['sdp'];
      if (type is! String || sdp is! String || sdp.trim().isEmpty) {
        throw 'Некорректные данные звонка';
      }
      await pc.setRemoteDescription(RTCSessionDescription(sdp, type));
      _remoteDescriptionSet = true;
      await _flushQueuedCandidates();

      final answer = await pc.createAnswer(<String, dynamic>{
        'offerToReceiveAudio': 1,
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Не удалось принять звонок: $e')));
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
      });
    }
    await _close(null);
  }

  Future<void> _endCall() async {
    final callId = _callId;
    if (callId != null) {
      final nextStatus = _status == 'ongoing'
          ? 'ended'
          : (_incoming ? 'cancelled' : 'missed');
      await _firestore.collection('calls').doc(callId).update(<String, Object?>{
        'status': nextStatus,
        'endedAt': DateTime.now().toUtc().toIso8601String(),
      });
    }
    await _close(null);
  }

  void _toggleMute() {
    final stream = _localStream;
    if (stream == null) return;
    final track = stream.getAudioTracks().isEmpty
        ? null
        : stream.getAudioTracks().first;
    if (track == null) return;
    final next = !_micMuted;
    track.enabled = !next;
    setState(() => _micMuted = next);
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
      Navigator.of(context).maybePop();
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
  }

  @override
  void dispose() {
    unawaited(_disposeRtc());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isIncomingRinging = _incoming && _status == 'ringing';
    return Scaffold(
      backgroundColor: const Color(0xFF050A14),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Offstage(
                offstage: true,
                child: RTCVideoView(
                  _remoteRenderer,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF0A1622), Color(0xFF06090F)],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: _endCall,
                          icon: const Icon(Icons.arrow_back_ios_new_rounded),
                          color: Colors.white.withValues(alpha: 0.92),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    ChatAvatar(
                      title: widget.peerUserName,
                      radius: 62,
                      avatarUrl: widget.peerAvatarUrl,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.peerUserName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _status == 'ongoing'
                          ? _durationLabel()
                          : (isIncomingRinging
                                ? 'Входящий аудиозвонок'
                                : 'Аудиозвонок…'),
                      style: TextStyle(
                        color: Colors.cyanAccent.withValues(alpha: 0.88),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (isIncomingRinging) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _roundCallButton(
                            onTap: _busy ? null : _rejectIncoming,
                            icon: Icons.call_end_rounded,
                            bg: const Color(0xFFEF5350),
                          ),
                          const SizedBox(width: 28),
                          _roundCallButton(
                            onTap: _busy ? null : _acceptIncoming,
                            icon: Icons.call_rounded,
                            bg: const Color(0xFF26A69A),
                          ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _roundCallButton(
                            onTap: _toggleMute,
                            icon: _micMuted
                                ? Icons.mic_off_rounded
                                : Icons.mic_rounded,
                            bg: _micMuted
                                ? Colors.white.withValues(alpha: 0.22)
                                : Colors.white.withValues(alpha: 0.12),
                          ),
                          const SizedBox(width: 28),
                          _roundCallButton(
                            onTap: _endCall,
                            icon: Icons.call_end_rounded,
                            bg: const Color(0xFFEF5350),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                  ],
                ),
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

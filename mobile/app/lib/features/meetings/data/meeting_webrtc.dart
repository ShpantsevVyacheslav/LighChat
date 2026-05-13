import 'dart:async';
import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show MethodChannel;
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'meeting_active_speaker_sampler.dart';
import 'meeting_ice_servers.dart';
import 'meeting_peer_stats.dart';
import 'meeting_repository.dart';
import 'meeting_signaling.dart';
import 'package:lighchat_mobile/core/app_logger.dart';

/// Контроллер peer-to-peer mesh-комнаты митинга на стороне Flutter.
///
/// Архитектурные инварианты (совпадают с web — см. `docs/arcitecture/meetings-wire-protocol.md`):
///
/// 1. **Сеть**: полная mesh — по одному `RTCPeerConnection` на каждого удалённого участника.
/// 2. **Инициатор**: создатель offer — это сторона с лексикографически меньшим `uid`.
///    Это делает протокол симметричным между web и mobile и защищает от встречных offer.
/// 3. **Сигналинг**: Firestore `meetings/{id}/signals` — получатель удаляет документ после
///    применения. Фильтруем `where('to', '==', selfUid)` — совпадает с Firestore rules.
/// 4. **Trickle ICE** включён по умолчанию (`flutter_webrtc` шлёт кандидаты по мере появления).
/// 5. **Heartbeat**: раз в 20 сек обновляем `lastSeen`; scheduler чистит stale >90 сек.
/// 6. **Устойчивость**: на `disconnected` ждём 4 сек и (если мы инициатор) вызываем
///    `restartIce()` + повторный offer. На `failed` — полный пересоздание peer, не более
///    3 попыток в окне 60 сек.
/// 7. **Mute**: выключаем `track.enabled` локально + записываем в `participants/{uid}`.
/// 8. **Force-mute**: ловим флаги `forceMuteAudio/Video` на собственном документе участника
///    (их ставит host) → локально мьютим + сбрасываем флаг.
/// 9. **Active speaker**: каждые ~280 мс `getStats` — прирост inbound audio на каждом PC
///    и outbound audio на первом PC; UI через [MeetingSpeakingScoresEvent] подсвечивает
///    плитку (см. `meeting_active_speaker_resolve.dart`).
///
/// Модуль не зависит от UI, управляется из `MeetingRoomController`/провайдера.
class MeetingWebRtc {
  MeetingWebRtc({
    required this.meetingId,
    required this.selfUid,
    required this.firestore,
    required this.repository,
    MeetingIceServers? iceServers,
  }) : _signaling = MeetingSignaling(firestore, meetingId, selfUid),
       _ice = iceServers ?? MeetingIceServers();

  final String meetingId;
  final String selfUid;
  final FirebaseFirestore firestore;
  final MeetingRepository repository;
  final MeetingSignaling _signaling;
  final MeetingIceServers _ice;

  MediaStream? _localStream;
  MediaStream? _screenStream;
  MediaStreamTrack? _cameraVideoTrack;
  bool _screenSharing = false;
  bool _handRaised = false;
  Timer? _reactionResetTimer;
  Map<String, dynamic>? _cachedIceConfig;

  final Map<String, _PeerEntry> _peers = <String, _PeerEntry>{};

  /// Стрим событий для UI: обновления `remoteStreams`, `quality`, mute-state.
  final StreamController<MeetingWebRtcEvent> _events =
      StreamController<MeetingWebRtcEvent>.broadcast();
  Stream<MeetingWebRtcEvent> get events => _events.stream;

  StreamSubscription<List<IncomingSignal>>? _signalsSub;
  Timer? _heartbeatTimer;
  Timer? _speakingTimer;
  final MeetingActiveSpeakerSampler _speakingSampler =
      MeetingActiveSpeakerSampler();

  bool _disposed = false;
  bool _micMuted = false;
  bool _cameraMuted = false;
  bool _frontCamera = true;

  bool get micMuted => _micMuted;
  bool get cameraMuted => _cameraMuted;
  bool get frontCamera => _frontCamera;
  bool get screenSharing => _screenSharing;
  bool get handRaised => _handRaised;
  MediaStream? get localStream => _localStream;

  /// Запуск: захват медиа, подписка на signals, heartbeat.
  /// [otherParticipantIds] — те, кто уже в комнате: для них мы сразу создаём peer.
  /// [initialMicMuted]/[initialCameraOff] — состояние, выбранное в лобби.
  Future<void> start({
    required List<String> initialPeerIds,
    bool initialMicMuted = false,
    bool initialCameraOff = false,
  }) async {
    _cachedIceConfig = await _ice.fetchConfig();
    _micMuted = initialMicMuted;
    _cameraMuted = initialCameraOff;

    _localStream = await navigator.mediaDevices.getUserMedia(<String, dynamic>{
      'audio': true,
      'video': <String, dynamic>{
        'facingMode': _frontCamera ? 'user' : 'environment',
      },
    });
    if (initialMicMuted) {
      for (final t in _localStream!.getAudioTracks()) {
        t.enabled = false;
      }
    }
    if (initialCameraOff) {
      for (final t in _localStream!.getVideoTracks()) {
        t.enabled = false;
      }
    }

    // Сообщаем нативному PiP-плагину trackId локального video-track'а —
    // он подвесит свой RTCVideoRenderer, чтобы в PiP-окне шло реальное
    // видео, а не placeholder. См. AppDelegate.swift → LighChatPipVideoRenderer.
    await _notifyPipBindLocalTrack();

    _signalsSub = _signaling.watchIncoming().listen(_handleIncomingSignals);

    _heartbeatTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (_disposed) return;
      repository.heartbeat(meetingId, selfUid).catchError((_) {});
    });

    for (final remoteId in initialPeerIds) {
      if (remoteId == selfUid) continue;
      await _ensurePeer(remoteId);
    }

    _speakingTimer?.cancel();
    _speakingTimer =
        Timer.periodic(const Duration(milliseconds: 280), (_) => _tickSpeaking());
  }

  void _tickSpeaking() {
    if (_disposed) return;
    if (_peers.isEmpty) {
      _emit(MeetingSpeakingScoresEvent(<String, double>{}));
      return;
    }
    () async {
      try {
        final map = <String, RTCPeerConnection>{};
        for (final e in _peers.entries) {
          map[e.key] = e.value.pc;
        }
        final scores = await _speakingSampler.sample(
          peersByRemoteId: map,
          selfUid: selfUid,
          localMicMuted: _micMuted,
        );
        if (_disposed) return;
        _emit(MeetingSpeakingScoresEvent(scores));
      } catch (_) {}
    }();
  }

  /// UI сообщает контроллеру, что список участников поменялся: добавляем/убираем peer'ы.
  Future<void> syncPeers(List<String> remoteIds) async {
    if (_disposed) return;
    final currentRemotes = _peers.keys.toSet();
    final nextRemotes = remoteIds.where((id) => id != selfUid).toSet();

    for (final gone in currentRemotes.difference(nextRemotes)) {
      await _destroyPeer(gone);
    }
    for (final added in nextRemotes.difference(currentRemotes)) {
      await _ensurePeer(added);
    }
  }

  Future<void> _ensurePeer(String remoteId) async {
    if (_disposed) return;
    if (_peers.containsKey(remoteId)) return;
    final initiator = selfUid.compareTo(remoteId) < 0;
    final pc = await createPeerConnection(_cachedIceConfig!);
    final entry = _PeerEntry(remoteId: remoteId, pc: pc, initiator: initiator);
    _peers[remoteId] = entry;

    if (_localStream != null) {
      for (final track in _localStream!.getTracks()) {
        await pc.addTrack(track, _localStream!);
      }
    }

    pc.onIceCandidate = (cand) {
      if (cand.candidate == null) return;
      _signaling.send(to: remoteId, type: 'candidate', data: <String, dynamic>{
        'candidate': cand.candidate,
        'sdpMid': cand.sdpMid,
        'sdpMLineIndex': cand.sdpMLineIndex,
      }).catchError((e) {
        appLogger.w('[meeting-webrtc] send candidate failed', error: e);
      });
    };

    pc.onTrack = (event) {
      if (event.streams.isEmpty) return;
      final stream = event.streams.first;
      entry.remoteStream = stream;
      _emit(MeetingWebRtcEvent.remoteStream(remoteId, stream));
    };

    pc.onIceConnectionState = (state) {
      _handleIceState(entry, state);
    };

    entry.statsUnsub = watchPeerStats(pc, (sample) {
      _emit(MeetingWebRtcEvent.quality(remoteId, sample.quality));
    });

    if (initiator) {
      await _negotiate(entry, iceRestart: false);
    }
  }

  Future<void> _negotiate(_PeerEntry entry, {required bool iceRestart}) async {
    try {
      final offer = await entry.pc.createOffer(<String, dynamic>{
        if (iceRestart) 'iceRestart': true,
      });
      await entry.pc.setLocalDescription(offer);
      await _signaling.send(to: entry.remoteId, type: 'offer', data: <String, dynamic>{
        'type': offer.type,
        'sdp': offer.sdp,
      });
    } catch (e) {
      appLogger.w('[meeting-webrtc] negotiate(iceRestart=$iceRestart) failed', error: e);
    }
  }

  void _handleIceState(_PeerEntry entry, RTCIceConnectionState state) {
    if (_disposed) return;
    entry.lastIceState = state;
    if (state == RTCIceConnectionState.RTCIceConnectionStateConnected ||
        state == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
      entry.disconnectTimer?.cancel();
      entry.disconnectTimer = null;
      return;
    }
    if (state == RTCIceConnectionState.RTCIceConnectionStateDisconnected) {
      entry.disconnectTimer?.cancel();
      entry.disconnectTimer = Timer(const Duration(seconds: 4), () {
        if (_disposed || _peers[entry.remoteId] != entry) return;
        final cur = entry.lastIceState;
        if (cur == RTCIceConnectionState.RTCIceConnectionStateConnected ||
            cur == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
          return;
        }
        if (entry.initiator) {
          _negotiate(entry, iceRestart: true);
        }
      });
      return;
    }
    if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
      entry.disconnectTimer?.cancel();
      entry.disconnectTimer = null;
      _scheduleRecreate(entry.remoteId);
    }
  }

  static const _reconnectWindow = Duration(seconds: 60);
  static const _maxReconnects = 3;
  static const _failedBackoff = Duration(seconds: 1);
  final Map<String, _ReconnectTracker> _reconnectTrackers =
      <String, _ReconnectTracker>{};

  void _scheduleRecreate(String remoteId) {
    final now = DateTime.now();
    final tracker = _reconnectTrackers[remoteId] ?? _ReconnectTracker();
    if (now.difference(tracker.lastTriedAt) > _reconnectWindow) {
      tracker.count = 0;
    }
    if (tracker.count >= _maxReconnects) {
      if (kDebugMode) {
        appLogger.w('[meeting-webrtc] [$remoteId] reconnect limit reached, giving up');
      }
      return;
    }
    tracker.count += 1;
    tracker.lastTriedAt = now;
    _reconnectTrackers[remoteId] = tracker;
    Future<void>.delayed(_failedBackoff, () async {
      if (_disposed) return;
      await _destroyPeer(remoteId);
      await _ensurePeer(remoteId);
    });
  }

  Future<void> _handleIncomingSignals(List<IncomingSignal> signals) async {
    if (_disposed) return;
    for (final s in signals) {
      final doc = s.doc;
      await _ensurePeer(doc.from);
      final entry = _peers[doc.from];
      if (entry == null) {
        await _signaling.delete(s.ref);
        continue;
      }
      try {
        switch (doc.type) {
          case 'offer':
            final sdp = doc.data['sdp'];
            if (sdp is String) {
              await entry.pc.setRemoteDescription(
                RTCSessionDescription(sdp, 'offer'),
              );
              final answer = await entry.pc.createAnswer();
              await entry.pc.setLocalDescription(answer);
              await _signaling.send(
                to: doc.from,
                type: 'answer',
                data: <String, dynamic>{
                  'type': answer.type,
                  'sdp': answer.sdp,
                },
              );
            }
            break;
          case 'answer':
            final sdp = doc.data['sdp'];
            if (sdp is String) {
              await entry.pc.setRemoteDescription(
                RTCSessionDescription(sdp, 'answer'),
              );
            }
            break;
          case 'candidate':
            final raw = doc.data;
            final candStr = raw['candidate'];
            if (candStr is String) {
              final candidate = RTCIceCandidate(
                candStr,
                raw['sdpMid'] is String ? raw['sdpMid'] as String : null,
                raw['sdpMLineIndex'] is num
                    ? (raw['sdpMLineIndex'] as num).toInt()
                    : null,
              );
              await entry.pc.addCandidate(candidate);
            }
            break;
        }
      } catch (e) {
        if (kDebugMode) {
          appLogger.w('[meeting-webrtc] apply signal ${doc.type} from ${doc.from} failed', error: e);
        }
      } finally {
        await _signaling.delete(s.ref);
      }
    }
  }

  Future<void> toggleMic() async {
    _micMuted = !_micMuted;
    _speakingSampler.resetLocalOutbound();
    final audio = _localStream?.getAudioTracks();
    if (audio != null) {
      for (final t in audio) {
        t.enabled = !_micMuted;
      }
    }
    await repository.updateOwnParticipant(meetingId, selfUid, <String, Object?>{
      'isAudioMuted': _micMuted,
    });
    _emit(MeetingWebRtcEvent.localMic(_micMuted));
  }

  Future<void> toggleCamera() async {
    _cameraMuted = !_cameraMuted;
    final video = _localStream?.getVideoTracks();
    if (video != null) {
      for (final t in video) {
        t.enabled = !_cameraMuted;
      }
    }
    await repository.updateOwnParticipant(meetingId, selfUid, <String, Object?>{
      'isVideoMuted': _cameraMuted,
    });
    _emit(MeetingWebRtcEvent.localCamera(_cameraMuted));
  }

  Future<void> switchCamera() async {
    final video = _localStream?.getVideoTracks();
    if (video == null || video.isEmpty) return;
    try {
      await Helper.switchCamera(video.first);
      _frontCamera = !_frontCamera;
      await repository.updateOwnParticipant(meetingId, selfUid, <String, Object?>{
        'facingMode': _frontCamera ? 'user' : 'environment',
      });
    } catch (e) {
      appLogger.w('[meeting-webrtc] switchCamera failed', error: e);
    }
  }

  /// Поднять/опустить руку. Источник правды — Firestore
  /// `participants/{uid}.isHandRaised`; web-клиент использует тот же флаг.
  Future<void> toggleHandRaised() async {
    _handRaised = !_handRaised;
    await repository.setHandRaised(meetingId, selfUid, _handRaised);
    _emit(MeetingWebRtcEvent.localHand(_handRaised));
  }

  /// Отправить реакцию-эмодзи. Web держит реакцию ~3с и сбрасывает в `null`;
  /// мы делаем то же самое таймером.
  Future<void> sendReaction(String emoji, {Duration? clearAfter}) async {
    _reactionResetTimer?.cancel();
    await repository.setReaction(meetingId, selfUid, emoji);
    _reactionResetTimer = Timer(clearAfter ?? const Duration(seconds: 3), () {
      if (_disposed) return;
      repository.setReaction(meetingId, selfUid, null).catchError((_) {});
    });
  }

  /// Включить/выключить демонстрацию экрана.
  ///
  /// **Android:** использует `getDisplayMedia()` из `flutter_webrtc`,
  /// который поднимает `MediaProjection` (`FOREGROUND_SERVICE_MEDIA_PROJECTION`
  /// — уже в манифесте). При остановке публикация возвращается на камеру.
  ///
  /// **iOS:** требует отдельный ReplayKit Broadcast Extension — реализация
  /// вне скоупа этого PR, поэтому вызов вернёт [UnimplementedError]. Web
  /// при этом продолжает принимать поток без изменений.
  ///
  /// Wire-контракт идентичен web (`src/hooks/use-meeting-webrtc.ts`):
  /// `participants/{uid}.isScreenSharing: true` во время демонстрации.
  Future<void> toggleScreenShare() async {
    if (_screenSharing) {
      await _stopScreenShare();
      return;
    }
    await _startScreenShare();
  }

  Future<void> _startScreenShare() async {
    try {
      final screen = await navigator.mediaDevices.getDisplayMedia(
        <String, dynamic>{
          'video': true,
          // audio в display-media на Android 11+ возможен только как
          // app-audio; оставляем false, чтобы не ломать старые девайсы.
          'audio': false,
        },
      );
      final videoTracks = screen.getVideoTracks();
      if (videoTracks.isEmpty) {
        await screen.dispose();
        throw StateError('display media returned no video track');
      }
      final screenTrack = videoTracks.first;
      // Запоминаем текущий камер-трек, чтобы вернуть его обратно при стопе.
      _cameraVideoTrack ??= _localStream?.getVideoTracks().isNotEmpty == true
          ? _localStream!.getVideoTracks().first
          : null;
      await _replaceOutgoingVideoTrack(screenTrack);
      _screenStream = screen;
      _screenSharing = true;
      // Пользователь может остановить демонстрацию из системного UI —
      // слушаем событие onEnded и откатываемся на камеру.
      screenTrack.onEnded = () {
        if (_disposed || !_screenSharing) return;
        _stopScreenShare().catchError((_) {});
      };
      await repository.updateOwnParticipant(meetingId, selfUid, <String, Object?>{
        'isScreenSharing': true,
      });
      _emit(MeetingWebRtcEvent.localScreen(true));
    } catch (e) {
      appLogger.w('[meeting-webrtc] startScreenShare failed', error: e);
      _screenSharing = false;
      rethrow;
    }
  }

  Future<void> _stopScreenShare() async {
    final screen = _screenStream;
    try {
      final camera = _cameraVideoTrack;
      if (camera != null) {
        await _replaceOutgoingVideoTrack(camera);
      }
      if (screen != null) {
        for (final t in screen.getTracks()) {
          try {
            await t.stop();
          } catch (_) {}
        }
        try {
          await screen.dispose();
        } catch (_) {}
      }
    } finally {
      _screenStream = null;
      _screenSharing = false;
      await repository.updateOwnParticipant(meetingId, selfUid, <String, Object?>{
        'isScreenSharing': false,
      }).catchError((_) {});
      _emit(MeetingWebRtcEvent.localScreen(false));
    }
  }

  /// Заменить исходящий video-трек во всех peer'ах без renegotiation.
  /// Использует `RTCRtpSender.replaceTrack` — SDP остаётся прежним, задержка
  /// переключения ~50мс. Аналог web-функции `safeReplaceTrack`.
  Future<void> _replaceOutgoingVideoTrack(MediaStreamTrack track) async {
    for (final entry in _peers.values) {
      try {
        final senders = await entry.pc.getSenders();
        for (final s in senders) {
          final kind = s.track?.kind;
          if (kind == 'video') {
            await s.replaceTrack(track);
          }
        }
      } catch (e) {
        if (kDebugMode) {
          appLogger.w('[meeting-webrtc] replaceTrack for ${entry.remoteId} failed', error: e);
        }
      }
    }
  }

  /// Реакция на `forceMuteAudio/Video`, выставленные хостом.
  /// Локально мьютим + сбрасываем флаг, чтобы не зациклиться.
  Future<void> applyForceMute({bool audio = false, bool video = false}) async {
    if (audio && !_micMuted) await toggleMic();
    if (video && !_cameraMuted) await toggleCamera();
    final patch = <String, Object?>{};
    if (audio) patch['forceMuteAudio'] = false;
    if (video) patch['forceMuteVideo'] = false;
    if (patch.isNotEmpty) {
      await repository.updateOwnParticipant(meetingId, selfUid, patch);
    }
  }

  Future<void> _destroyPeer(String remoteId) async {
    _speakingSampler.removePeer(remoteId);
    final entry = _peers.remove(remoteId);
    if (entry == null) return;
    entry.disconnectTimer?.cancel();
    try {
      entry.statsUnsub?.call();
    } catch (_) {}
    try {
      await entry.pc.close();
    } catch (_) {}
    _emit(MeetingWebRtcEvent.peerClosed(remoteId));
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _heartbeatTimer?.cancel();
    _speakingTimer?.cancel();
    _speakingSampler.clear();
    _reactionResetTimer?.cancel();
    await _notifyPipUnbindLocalTrack();
    await _signalsSub?.cancel();
    for (final id in _peers.keys.toList()) {
      await _destroyPeer(id);
    }
    final screen = _screenStream;
    if (screen != null) {
      for (final t in screen.getTracks()) {
        try {
          await t.stop();
        } catch (_) {}
      }
      try {
        await screen.dispose();
      } catch (_) {}
      _screenStream = null;
    }
    final local = _localStream;
    if (local != null) {
      for (final t in local.getTracks()) {
        try {
          await t.stop();
        } catch (_) {}
      }
      try {
        await local.dispose();
      } catch (_) {}
    }
    _localStream = null;
    await _events.close();
    _ice.dispose();
  }

  void _emit(MeetingWebRtcEvent e) {
    if (_events.isClosed) return;
    _events.add(e);
  }

  /// Кросс-платформенный safety: рассказываем нативному PiP-плагину про
  /// trackId локального video-track'а. На iOS native side через
  /// `LocalVideoTrack.addRenderer(...)` подвесит свой
  /// `LighChatPipVideoRenderer`, который форвардит RTCVideoFrame в
  /// AVSampleBufferDisplayLayer PiP-окна.
  ///
  /// На Android — no-op (Android Activity PiP сворачивает Flutter UI
  /// целиком, ему не нужен отдельный канал кадров).
  Future<void> _notifyPipBindLocalTrack() async {
    if (!Platform.isIOS) return;
    final tracks = _localStream?.getVideoTracks() ?? const [];
    if (tracks.isEmpty) return;
    final trackId = tracks.first.id;
    if (trackId == null || trackId.isEmpty) return;
    try {
      await const MethodChannel('lighchat/meeting_pip')
          .invokeMethod<bool>('bindLocalTrack', <String, Object?>{
        'trackId': trackId,
      });
    } catch (e) {
      appLogger.w('[meeting-pip] bindLocalTrack failed', error: e);
    }
  }

  Future<void> _notifyPipUnbindLocalTrack() async {
    if (!Platform.isIOS) return;
    try {
      await const MethodChannel('lighchat/meeting_pip')
          .invokeMethod<bool>('unbindLocalTrack');
    } catch (_) {}
  }
}

class _PeerEntry {
  _PeerEntry({
    required this.remoteId,
    required this.pc,
    required this.initiator,
  });

  final String remoteId;
  final RTCPeerConnection pc;
  final bool initiator;
  MediaStream? remoteStream;
  Timer? disconnectTimer;
  RTCIceConnectionState? lastIceState;
  Function? statsUnsub;
}

class _ReconnectTracker {
  int count = 0;
  DateTime lastTriedAt = DateTime.fromMillisecondsSinceEpoch(0);
}

/// События контроллера для UI.
sealed class MeetingWebRtcEvent {
  const MeetingWebRtcEvent();
  factory MeetingWebRtcEvent.remoteStream(String remoteId, MediaStream stream) =
      MeetingRemoteStreamEvent;
  factory MeetingWebRtcEvent.quality(String remoteId, PeerConnectionQuality q) =
      MeetingPeerQualityEvent;
  factory MeetingWebRtcEvent.peerClosed(String remoteId) = MeetingPeerClosedEvent;
  factory MeetingWebRtcEvent.localMic(bool muted) = MeetingLocalMicEvent;
  factory MeetingWebRtcEvent.localCamera(bool muted) = MeetingLocalCameraEvent;
  factory MeetingWebRtcEvent.localHand(bool raised) = MeetingLocalHandEvent;
  factory MeetingWebRtcEvent.localScreen(bool sharing) =
      MeetingLocalScreenEvent;
  factory MeetingWebRtcEvent.speakingScores(Map<String, double> scores) =
      MeetingSpeakingScoresEvent;
}

class MeetingRemoteStreamEvent extends MeetingWebRtcEvent {
  const MeetingRemoteStreamEvent(this.remoteId, this.stream);
  final String remoteId;
  final MediaStream stream;
}

class MeetingPeerQualityEvent extends MeetingWebRtcEvent {
  const MeetingPeerQualityEvent(this.remoteId, this.quality);
  final String remoteId;
  final PeerConnectionQuality quality;
}

class MeetingPeerClosedEvent extends MeetingWebRtcEvent {
  const MeetingPeerClosedEvent(this.remoteId);
  final String remoteId;
}

class MeetingLocalMicEvent extends MeetingWebRtcEvent {
  const MeetingLocalMicEvent(this.muted);
  final bool muted;
}

class MeetingLocalCameraEvent extends MeetingWebRtcEvent {
  const MeetingLocalCameraEvent(this.muted);
  final bool muted;
}

class MeetingLocalHandEvent extends MeetingWebRtcEvent {
  const MeetingLocalHandEvent(this.raised);
  final bool raised;
}

class MeetingLocalScreenEvent extends MeetingWebRtcEvent {
  const MeetingLocalScreenEvent(this.sharing);
  final bool sharing;
}

/// Дельты пакетов аудио за тик (~280 мс); UI выбирает активного спикера.
class MeetingSpeakingScoresEvent extends MeetingWebRtcEvent {
  MeetingSpeakingScoresEvent(this.scores);
  final Map<String, double> scores;
}

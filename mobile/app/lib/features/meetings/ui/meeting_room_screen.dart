import 'dart:async';
import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../l10n/app_localizations.dart';

import '../data/meeting_invite_link.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../data/meeting_active_speaker_resolve.dart';
import '../data/meeting_models.dart';
import '../data/meeting_peer_stats.dart';
import '../data/meeting_pip_controller.dart';
import '../data/meeting_providers.dart';
import '../data/meeting_webrtc.dart';
import '../data/virtual_background_controller.dart';
import 'meeting_controls.dart';
import 'meeting_floating_messages.dart';
import 'meeting_participant_tile.dart';
import 'meeting_reactions_overlay.dart';
import 'meeting_sidebar.dart';

/// Экран активной видеовстречи.
///
/// Содержит:
///   - сетку участников (локальный + удалённые, 1..N);
///   - панель управления (mic/video/switch/sidebar/leave);
///   - сайдбар с списком участников и заявок (только host/admin).
///
/// Контракт: конструктор получает уже-отмоделированного `currentUser`
/// (id — обязательный), имя и аватар пробрасываются в `participants/{uid}`.
/// Попадание сюда без созданного участника — баг роутинга.
class MeetingRoomScreen extends ConsumerStatefulWidget {
  const MeetingRoomScreen({
    super.key,
    required this.meetingId,
    required this.selfUid,
    required this.selfName,
    this.selfAvatar,
    this.selfAvatarThumb,
    this.selfRole,
    this.initialMicMuted = false,
    this.initialCameraOff = false,
  });

  final String meetingId;
  final String selfUid;
  final String selfName;
  final String? selfAvatar;
  final String? selfAvatarThumb;
  final String? selfRole;
  final bool initialMicMuted;
  final bool initialCameraOff;

  @override
  ConsumerState<MeetingRoomScreen> createState() => _MeetingRoomScreenState();
}

class _MeetingRoomScreenState extends ConsumerState<MeetingRoomScreen> {
  MeetingWebRtc? _webrtc;
  StreamSubscription<MeetingWebRtcEvent>? _eventsSub;

  final Map<String, MediaStream> _remoteStreams = <String, MediaStream>{};
  final Map<String, PeerConnectionQuality> _remoteQuality =
      <String, PeerConnectionQuality>{};

  bool _sidebarOpen = false;
  bool _initialized = false;
  bool _leaving = false;
  String? _initError;

  /// Сколько chat-сообщений уже «увидел» пользователь (синхронизируется
  /// при открытии сайдбара). Разница с текущей длиной ленты — это unread,
  /// который попадёт в общий счётчик «Уведомления» на нижней панели.
  int _chatSeenCount = -1;

  /// Таймер ребилда UI каждые 15 сек, чтобы фильтрация по `lastSeen`
  /// «снимала» отвалившихся участников даже когда Firestore не присылает
  /// новых snapshot'ов. Cron на сервере чистит документы за 90 сек,
  /// а мы скрываем участника локально уже через 60 сек.
  Timer? _staleSweepTimer;

  /// Окно «свежести» heartbeat'а. Heartbeat пишется раз в 20 сек
  /// (см. [MeetingWebRtc]); 60-секундный буфер покрывает 2-3 пропуска.
  static const Duration _staleThreshold = Duration(seconds: 60);

  List<MeetingParticipant> _filterFresh(List<MeetingParticipant> all) {
    final now = DateTime.now().toUtc();
    final cutoff = now.subtract(_staleThreshold);
    return all.where((p) {
      // Самого себя никогда не скрываем — даже если heartbeat встал
      // (например, мы в фоне).
      if (p.id == widget.selfUid) return true;
      final ls = p.lastSeen;
      if (ls == null) return true;
      return ls.toUtc().isAfter(cutoff);
    }).toList(growable: false);
  }

  /// Режим раскладки. Эквивалент `viewMode` из
  /// `src/components/meetings/MeetingRoom.tsx`.
  _MeetingViewMode _viewMode = _MeetingViewMode.grid;

  /// Участник, которого пользователь вручную вывел в фокус тапом по плитке.
  /// Приоритет фокуса: screen-sharer > manualFocus > self.
  String? _manualFocusId;

  /// Кэш участников для разрешения активного спикера по `getStats` (тик WebRTC).
  List<MeetingParticipant> _participantsSnapshot = const [];

  /// Участник с максимальной аудио-активностью (подсветка плитки).
  String? _activeSpeakerId;

  StreamSubscription<VirtualBackgroundModeUpdate>? _vbSub;
  VirtualBackgroundMode _vbMode = VirtualBackgroundMode.none;

  final MeetingPipController _pipController = MeetingPipController();
  late final PipLifecycleObserver _pipLifecycle =
      PipLifecycleObserver(_pipController);
  bool _pipSupported = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final repo = ref.read(meetingRepositoryProvider);
      await repo.joinMeeting(
        meetingId: widget.meetingId,
        userId: widget.selfUid,
        name: widget.selfName,
        avatar: widget.selfAvatar,
        avatarThumb: widget.selfAvatarThumb,
        role: widget.selfRole,
      );

      final webrtc = MeetingWebRtc(
        meetingId: widget.meetingId,
        selfUid: widget.selfUid,
        firestore: FirebaseFirestore.instance,
        repository: repo,
      );
      _eventsSub = webrtc.events.listen(_onWebRtcEvent);

      // Подписка на локальный контроллер виртуального фона; он может быть
      // noop (тогда isPlatformBacked == false и UI-кнопку мы не покажем).
      final vb = ref.read(virtualBackgroundControllerProvider);
      _vbMode = vb.currentMode;
      _vbSub = vb.modeStream.listen((update) {
        if (!mounted) return;
        setState(() => _vbMode = update.mode);
      });

      // Первые remoteIds возьмём из текущего snapshot'а; далее syncPeers
      // будет дёргаться из build() когда список участников меняется.
      await webrtc.start(
        initialPeerIds: const <String>[],
        initialMicMuted: widget.initialMicMuted,
        initialCameraOff: widget.initialCameraOff,
      );
      if (!mounted) {
        await webrtc.dispose();
        return;
      }
      setState(() {
        _webrtc = webrtc;
        _initialized = true;
      });
      _staleSweepTimer ??= Timer.periodic(const Duration(seconds: 15), (_) {
        if (mounted) setState(() {});
      });

      _pipLifecycle.attach();
      _pipController.isSupported().then((ok) {
        if (!mounted) return;
        setState(() => _pipSupported = ok);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _initError = e.toString());
    }
  }

  void _onWebRtcEvent(MeetingWebRtcEvent e) {
    if (!mounted) return;
    switch (e) {
      case MeetingRemoteStreamEvent(:final remoteId, :final stream):
        setState(() {
          _remoteStreams[remoteId] = stream;
        });
      case MeetingPeerQualityEvent(:final remoteId, :final quality):
        setState(() {
          _remoteQuality[remoteId] = quality;
        });
      case MeetingPeerClosedEvent(:final remoteId):
        setState(() {
          _remoteStreams.remove(remoteId);
          _remoteQuality.remove(remoteId);
          if (_activeSpeakerId == remoteId) {
            _activeSpeakerId = null;
          }
        });
      case MeetingSpeakingScoresEvent(:final scores):
        final next = resolveActiveSpeaker(
          scores: scores,
          participants: _participantsSnapshot,
          previous: _activeSpeakerId,
        );
        if (next != _activeSpeakerId) {
          setState(() => _activeSpeakerId = next);
        }
      case MeetingLocalMicEvent() ||
            MeetingLocalCameraEvent() ||
            MeetingLocalHandEvent() ||
            MeetingLocalScreenEvent():
        setState(() {});
    }
  }

  /// Screen-share работает на Android (MediaProjection), macOS
  /// (ScreenCaptureKit через flutter_webrtc) и Windows (DXGI desktop
  /// duplication). На iOS требуется Broadcast Extension —
  /// см. `meetings-wire-protocol.md` §8. На Linux flutter_webrtc может
  /// захватывать через X11/Wayland (pipewire), но требует runtime-проверки.
  bool get _screenShareSupported {
    if (kIsWeb) return false;
    return Platform.isAndroid ||
        Platform.isMacOS ||
        Platform.isWindows ||
        Platform.isLinux;
  }

  Future<void> _syncPeersFromParticipants(
    List<MeetingParticipant> participants,
  ) async {
    final webrtc = _webrtc;
    if (webrtc == null) return;
    final remoteIds =
        participants.map((p) => p.id).where((id) => id != widget.selfUid).toList();
    await webrtc.syncPeers(remoteIds);
  }

  Future<void> _applyForceMuteFlags(MeetingParticipant self) async {
    final webrtc = _webrtc;
    if (webrtc == null) return;
    if (self.forceMuteAudio || self.forceMuteVideo) {
      await webrtc.applyForceMute(
        audio: self.forceMuteAudio,
        video: self.forceMuteVideo,
      );
    }
  }

  Future<void> _cycleVirtualBackground() async {
    final vb = ref.read(virtualBackgroundControllerProvider);
    if (!vb.isPlatformBacked) return;
    const order = <VirtualBackgroundMode>[
      VirtualBackgroundMode.none,
      VirtualBackgroundMode.blur,
      VirtualBackgroundMode.image,
    ];
    final next = order[(order.indexOf(_vbMode) + 1) % order.length];
    try {
      await vb.setMode(
        next,
        imageAssetPath: next == VirtualBackgroundMode.image
            ? 'assets/images/meeting_bg_default.jpg'
            : null,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.meeting_bg_unavailable(e.toString()))),
      );
    }
  }

  Future<void> _leave() async {
    if (_leaving) return;
    _leaving = true;
    try {
      final webrtc = _webrtc;
      _webrtc = null;
      await _eventsSub?.cancel();
      await _vbSub?.cancel();
      await webrtc?.dispose();
      await ref
          .read(meetingRepositoryProvider)
          .leaveMeeting(widget.meetingId, widget.selfUid);
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _staleSweepTimer?.cancel();
    _staleSweepTimer = null;
    _pipLifecycle.detach();
    // Подстраховка, если пользователь ушёл через systemback (pop).
    _eventsSub?.cancel();
    _vbSub?.cancel();
    final webrtc = _webrtc;
    if (webrtc != null) {
      webrtc.dispose();
      ref
          .read(meetingRepositoryProvider)
          .leaveMeeting(widget.meetingId, widget.selfUid)
          .catchError((_) {});
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final meetingAsync = ref.watch(meetingDocProvider(widget.meetingId));
    final participantsAsync =
        ref.watch(meetingParticipantsProvider(widget.meetingId));
    final requestsAsync = ref.watch(meetingRequestsProvider(widget.meetingId));

    return Scaffold(
      backgroundColor: Colors.black,
      body: meetingAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        error: (e, _) => _errorBody(AppLocalizations.of(context)!.meeting_join_load_error(e.toString())),
        data: (meeting) {
          if (meeting == null) {
            return _errorBody(AppLocalizations.of(context)!.meeting_not_found);
          }
          if (_initError != null) {
            return _errorBody(AppLocalizations.of(context)!.meeting_init_error(_initError!));
          }
          final isHostOrAdmin = meeting.isAdmin(widget.selfUid);

          return participantsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            error: (e, _) => _errorBody(AppLocalizations.of(context)!.meeting_participants_error(e.toString())),
            data: (participants) {
              final fresh = _filterFresh(participants);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _syncPeersFromParticipants(fresh);
                final self = fresh.firstWhere(
                  (p) => p.id == widget.selfUid,
                  orElse: () => MeetingParticipant(
                    id: widget.selfUid,
                    name: widget.selfName,
                  ),
                );
                _applyForceMuteFlags(self);
              });
              return _roomBody(
                context,
                meeting: meeting,
                participants: fresh,
                requests: requestsAsync.asData?.value ??
                    const <MeetingRequestDoc>[],
                isHostOrAdmin: isHostOrAdmin,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildControls(
    List<MeetingParticipant> participants,
    List<MeetingRequestDoc> requests,
    bool isHostOrAdmin,
  ) {
    final vb = ref.read(virtualBackgroundControllerProvider);

    final chatAsync = ref.watch(meetingChatMessagesProvider(widget.meetingId));
    final chatList = chatAsync.asData?.value ?? const [];
    final pollsList =
        ref.watch(meetingPollsProvider(widget.meetingId)).asData?.value ??
            const [];
    final activePollsCount =
        pollsList.where((p) => p.status == 'active').length;
    final pendingRequestsCount = isHostOrAdmin
        ? requests.where((r) => r.status == 'pending').length
        : 0;

    // Стартовое значение «прочитано до этой длины» можно ставить ТОЛЬКО когда
    // stream уже отдал начальный snapshot. Иначе поставим 0 при пустом
    // chatList → подгрузка истории даст ложный unread = N.
    if (chatAsync is AsyncData) {
      if (_chatSeenCount < 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() => _chatSeenCount = chatList.length);
        });
      } else if (_sidebarOpen && _chatSeenCount != chatList.length) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() => _chatSeenCount = chatList.length);
        });
      }
    }

    final chatUnread = _chatSeenCount < 0
        ? 0
        : (chatList.length - _chatSeenCount).clamp(0, 99999);
    final notificationsCount =
        chatUnread + activePollsCount + pendingRequestsCount;

    return MeetingControls(
      micMuted: _webrtc?.micMuted ?? false,
      cameraMuted: _webrtc?.cameraMuted ?? false,
      handRaised: _webrtc?.handRaised ?? false,
      screenSharing: _webrtc?.screenSharing ?? false,
      screenShareSupported: _screenShareSupported,
      participantsCount: participants.length,
      notificationsCount: notificationsCount,
      onOpenNotifications: () => setState(() => _sidebarOpen = true),
      onEnterPip: _pipSupported
          ? () {
              _pipLifecycle.suppressAutoOnce();
              _pipController.enterPip();
            }
          : null,
      virtualBackgroundMode: vb.isPlatformBacked ? _vbMode : null,
      onToggleVirtualBackground:
          vb.isPlatformBacked ? _cycleVirtualBackground : null,
      onToggleMic: () async {
        await _webrtc?.toggleMic();
        if (mounted) setState(() {});
      },
      onToggleCamera: () async {
        await _webrtc?.toggleCamera();
        if (mounted) setState(() {});
      },
      onSwitchCamera: () async {
        await _webrtc?.switchCamera();
      },
      onToggleHand: _webrtc == null
          ? null
          : () async {
              await _webrtc?.toggleHandRaised();
              if (mounted) setState(() {});
            },
      onSendReaction: _webrtc == null
          ? null
          : (emoji) async {
              try {
                await _webrtc?.sendReaction(emoji);
              } catch (_) {}
            },
      onToggleScreenShare: _webrtc == null
          ? null
          : () => _onToggleScreenShare(),
      onOpenSidebar: () => setState(() => _sidebarOpen = !_sidebarOpen),
      onLeave: _leave,
    );
  }

  Future<void> _onToggleScreenShare() async {
    if (!_screenShareSupported) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.meeting_screen_share_ios_hint,
          ),
        ),
      );
      return;
    }
    try {
      await _webrtc?.toggleScreenShare();
      if (mounted) setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.meeting_screen_share_error(e.toString()))),
      );
    }
  }

  Widget _errorBody(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.redAccent, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _leave,
              child: Text(AppLocalizations.of(context)!.meeting_leave),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roomBody(
    BuildContext context, {
    required MeetingDoc meeting,
    required List<MeetingParticipant> participants,
    required List<MeetingRequestDoc> requests,
    required bool isHostOrAdmin,
  }) {
    _participantsSnapshot = participants;
    final self = participants.firstWhere(
      (p) => p.id == widget.selfUid,
      orElse: () =>
          MeetingParticipant(id: widget.selfUid, name: widget.selfName),
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        Column(
          children: [
            _header(meeting),
            Expanded(child: _layoutBody(participants, self)),
            _buildControls(participants, requests, isHostOrAdmin),
          ],
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: MeetingReactionsOverlay(participants: participants),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 110,
          child: MeetingFloatingMessages(
            meetingId: widget.meetingId,
            selfUid: widget.selfUid,
            enabled: !_sidebarOpen,
          ),
        ),
        if (_sidebarOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _sidebarOpen = false),
              child: Container(color: Colors.black54),
            ),
          ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          right: _sidebarOpen ? 0 : -340,
          top: 0,
          bottom: 0,
          width: 340,
          child: Material(
            elevation: 12,
            color: Colors.transparent,
            child: MeetingSidebar(
              currentUserId: widget.selfUid,
              currentUserName: widget.selfName,
              meeting: meeting,
              participants: participants,
              requests: requests,
              isHostOrAdmin: isHostOrAdmin,
              onClose: () => setState(() => _sidebarOpen = false),
              onForceMuteAudio: (userId) async {
                await ref
                    .read(meetingRepositoryProvider)
                    .updateOwnParticipant(
                      widget.meetingId,
                      userId,
                      {'forceMuteAudio': true},
                    )
                    .catchError((_) {});
              },
              onForceMuteVideo: (userId) async {
                await ref
                    .read(meetingRepositoryProvider)
                    .updateOwnParticipant(
                      widget.meetingId,
                      userId,
                      {'forceMuteVideo': true},
                    )
                    .catchError((_) {});
              },
              onKick: (userId) async {
                await FirebaseFirestore.instance
                    .collection('meetings/${widget.meetingId}/participants')
                    .doc(userId)
                    .delete()
                    .catchError((_) {});
              },
              onApproveRequest: (userId) async {
                try {
                  await ref
                      .read(meetingCallablesProvider)
                      .respondToMeetingRequest(
                        meetingId: widget.meetingId,
                        userId: userId,
                        approve: true,
                      );
                } catch (_) {}
              },
              onDenyRequest: (userId) async {
                try {
                  await ref
                      .read(meetingCallablesProvider)
                      .respondToMeetingRequest(
                        meetingId: widget.meetingId,
                        userId: userId,
                        approve: false,
                      );
                } catch (_) {}
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _header(MeetingDoc meeting) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  meeting.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            if (!_initialized)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white54,
                  ),
                ),
              ),
            IconButton(
              tooltip: _viewMode == _MeetingViewMode.grid
                  ? AppLocalizations.of(context)!.meeting_speaker_mode
                  : AppLocalizations.of(context)!.meeting_grid_mode,
              onPressed: _toggleViewMode,
              icon: Icon(
                _viewMode == _MeetingViewMode.grid
                    ? Icons.view_agenda_rounded
                    : Icons.grid_view_rounded,
                color: Colors.white,
              ),
            ),
            IconButton(
              tooltip: AppLocalizations.of(context)!.meeting_copy_link_tooltip,
              onPressed: () async {
                final link = meetingWebJoinLink(widget.meetingId);
                await Clipboard.setData(ClipboardData(text: link));
              },
              icon: const Icon(Icons.link_rounded, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleViewMode() {
    setState(() {
      _viewMode = _viewMode == _MeetingViewMode.grid
          ? _MeetingViewMode.speaker
          : _MeetingViewMode.grid;
      // При возврате в grid сбрасываем ручной фокус, чтобы следующий
      // вход в speaker начинался с дефолтного приоритета (screen-sharer/self).
      if (_viewMode == _MeetingViewMode.grid) {
        _manualFocusId = null;
      }
    });
  }

  /// Выбор «главного» участника в speaker-mode. Порядок совпадает с web
  /// (`src/components/meetings/MeetingRoom.tsx` — focusedParticipantId):
  /// `screen-sharing participant > manualFocusId > self`.
  MeetingParticipant _focusedParticipant(
    List<MeetingParticipant> participants,
    MeetingParticipant self,
  ) {
    final screen =
        participants.where((p) => p.isScreenSharing).toList(growable: false);
    if (screen.isNotEmpty) return screen.first;
    final manualId = _manualFocusId;
    if (manualId != null) {
      for (final p in participants) {
        if (p.id == manualId) return p;
      }
    }
    return self;
  }

  /// Главный роутер раскладки: в зависимости от `_viewMode` возвращает либо
  /// привычную сетку, либо «спикер» (большой тайл + горизонтальная лента).
  Widget _layoutBody(
    List<MeetingParticipant> participants,
    MeetingParticipant self,
  ) {
    if (_viewMode == _MeetingViewMode.speaker) {
      return _speakerBody(participants, self);
    }
    return _grid(participants, self);
  }

  Widget _participantTileFor(
    MeetingParticipant p, {
    required bool isLocal,
    String slot = 'main',
  }) {
    // Ключ включает id участника + «слот» (main/strip). Это не даёт Flutter
    // переиспользовать один и тот же `RTCVideoRenderer` в разных местах
    // (при свапе в speaker-mode) и предотвращает «перепутывание» потоков.
    return MeetingParticipantTile(
      key: ValueKey<String>('tile-$slot-${p.id}'),
      participant: p,
      stream: isLocal ? _webrtc?.localStream : _remoteStreams[p.id],
      isLocal: isLocal,
      mirror: isLocal && (_webrtc?.frontCamera ?? true),
      quality: isLocal
          ? PeerConnectionQuality.unknown
          : (_remoteQuality[p.id] ?? PeerConnectionQuality.unknown),
      isActiveSpeaker: p.id == _activeSpeakerId,
    );
  }

  /// Тап по плитке: если мы в сетке — переходим в speaker с выбранным
  /// фокусом; если уже в speaker — просто меняем фокус.
  void _onTileTap(MeetingParticipant p) {
    setState(() {
      _manualFocusId = p.id;
      _viewMode = _MeetingViewMode.speaker;
    });
  }

  Widget _speakerBody(
    List<MeetingParticipant> participants,
    MeetingParticipant self,
  ) {
    final focused = _focusedParticipant(participants, self);
    // Остальные — в ленту. Сохраняем относительный порядок участников.
    final strip = <MeetingParticipant>[
      if (focused.id != self.id) self,
      for (final p in participants)
        if (p.id != focused.id && p.id != self.id) p,
    ];
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            child: GestureDetector(
              onTap: () => _onTileTap(focused),
              child: _participantTileFor(
                focused,
                isLocal: focused.id == self.id,
                slot: 'focused',
              ),
            ),
          ),
        ),
        SizedBox(
          height: 104,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            scrollDirection: Axis.horizontal,
            itemCount: strip.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (ctx, i) {
              final p = strip[i];
              final isLocal = p.id == self.id;
              return GestureDetector(
                onTap: () => _onTileTap(p),
                child: SizedBox(
                  width: 140,
                  child: _participantTileFor(
                    p,
                    isLocal: isLocal,
                    slot: 'strip',
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _grid(List<MeetingParticipant> participants, MeetingParticipant self) {
    final remote = participants.where((p) => p.id != widget.selfUid).toList();
    final ordered = <MeetingParticipant>[self, ...remote];
    final tiles = <Widget>[
      for (final p in ordered)
        GestureDetector(
          onTap: () => _onTileTap(p),
          child: _participantTileFor(
            p,
            isLocal: p.id == self.id,
            slot: 'grid',
          ),
        ),
    ];

    final count = tiles.length;
    int cols;
    if (count <= 1) {
      cols = 1;
    } else if (count <= 4) {
      cols = 2;
    } else {
      cols = 3;
    }
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GridView.count(
        crossAxisCount: cols,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: count == 1 ? 0.62 : 0.9,
        physics: const BouncingScrollPhysics(),
        children: tiles,
      ),
    );
  }
}

/// Режим раскладки сетки участников в комнате. Повторяет `viewMode`
/// из web (`src/components/meetings/MeetingRoom.tsx`).
enum _MeetingViewMode { grid, speaker }

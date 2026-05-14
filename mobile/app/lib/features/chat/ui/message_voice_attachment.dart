import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lighchat_models/lighchat_models.dart';

import 'message_audio_waveform.dart';
import 'chat_glass_panel.dart';
import 'chat_vlc_network_media.dart';
import '../../../l10n/app_localizations.dart';
import '../data/local_voice_transcriber.dart';

/// Один активный голосовой плеер (паритет с вебом: остальные ставятся на паузу).
final class _VoicePlaybackExclusive {
  _VoicePlaybackExclusive._();

  static State<StatefulWidget>? _owner;
  static Future<void> Function()? _pause;

  static Future<void> beforeStartOther(
    State<StatefulWidget> owner,
    Future<void> Function() pause,
  ) async {
    if (_owner != null && !identical(_owner, owner) && _pause != null) {
      await _pause!();
    }
    _owner = owner;
    _pause = pause;
  }

  static void clear(State<StatefulWidget> owner) {
    if (identical(_owner, owner)) {
      _owner = null;
      _pause = null;
    }
  }
}

/// Голосовое / аудио вложение (паритет с вебом `AudioMessagePlayer`).
/// Для неподдерживаемых на iOS форматов показываем статус server-side нормализации.
class MessageVoiceAttachment extends StatelessWidget {
  const MessageVoiceAttachment({
    super.key,
    required this.attachment,
    required this.attachmentIndex,
    required this.alignRight,
    this.conversationId,
    this.messageId,
    this.transcript,
    this.mediaNorm,
    this.onRetryNorm,
  });

  final ChatAttachment attachment;
  final int attachmentIndex;
  final bool alignRight;
  final String? conversationId;
  final String? messageId;
  final String? transcript;
  final ChatMediaNorm? mediaNorm;
  final Future<void> Function()? onRetryNorm;

  @override
  Widget build(BuildContext context) {
    final normState = chatMediaNormUiStateForAttachment(
      attachment: attachment,
      attachmentIndex: attachmentIndex,
      mediaNorm: mediaNorm,
    );
    if (normState != ChatMediaNormUiState.none) {
      final l10n = AppLocalizations.of(context)!;
      return ChatMediaNormStatusWidget(
        state: normState,
        mediaKindLabel: l10n.voice_attachment_media_kind_audio,
        onRetry: onRetryNorm,
      );
    }
    return _VoiceJustAudioBar(
      key: ValueKey<String>('ja-voice-${attachment.url}'),
      attachment: attachment,
      alignRight: alignRight,
      conversationId: conversationId,
      messageId: messageId,
      transcript: transcript,
    );
  }
}

class _WebStyleVoiceRow extends StatelessWidget {
  const _WebStyleVoiceRow({
    required this.isMine,
    required this.failed,
    required this.ready,
    required this.playing,
    required this.progressPercent,
    required this.seedUrl,
    required this.displayTime,
    required this.sizeBytes,
    required this.playbackRate,
    required this.onToggle,
    required this.onCycleRate,
    this.onWaveformSeekFromLocal,
    this.footer,
  });

  final bool isMine;
  final bool failed;
  final bool ready;
  final bool playing;
  final double progressPercent;
  final String seedUrl;
  final Duration displayTime;
  final int? sizeBytes;
  final double playbackRate;
  final VoidCallback onToggle;
  final VoidCallback onCycleRate;
  /// `localX` — по ширине волны; `width` — maxWidth из [LayoutBuilder].
  final void Function(double localX, double width)? onWaveformSeekFromLocal;
  /// Опциональный блок внутри того же стеклянного пузыря (под плеером) —
  /// например, контролы транскрипта.
  final Widget? footer;

  String _format(Duration d) {
    if (d.inMilliseconds <= 0) return '0:00';
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  static String _rateButtonLabel(double r) {
    final t = r.truncateToDouble();
    if ((r - t).abs() < 0.001) return '${t.toInt()}x';
    return '${r}x';
  }

  String _sizeLabel() {
    final b = sizeBytes;
    if (b == null || b <= 0) return '—';
    final kb = b / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    return '${(kb / 1024).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    // Метатекст внутри стеклянного пузыря на ярких обоях должен оставаться
    // читаемым — поднимаем alpha до уровня, на котором цвет уверенно выигрывает
    // у фона. 0.55/0.7 раньше «сливались» с цветными обоями.
    final metaColor = isMine
        ? scheme.onPrimary.withValues(alpha: 0.92)
        : scheme.onSurface.withValues(alpha: 0.85);

    final playerRow = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
              const SizedBox(width: 10),
              Material(
                color: scheme.primary,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: failed || !ready ? null : onToggle,
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(
                      failed
                          ? Icons.error_outline_rounded
                          : (playing
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded),
                      color: scheme.onPrimary,
                      size: failed ? 22 : 26,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!failed)
                        LayoutBuilder(
                          builder: (context, cons) {
                            final seek = onWaveformSeekFromLocal;
                            final wave = AudioMessageWaveformBars(
                              progressPercent: progressPercent.clamp(0.0, 100.0),
                              isMine: isMine,
                              seedUrl: seedUrl,
                            );
                            if (seek == null) return wave;
                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTapUp: (d) {
                                seek(d.localPosition.dx, cons.maxWidth);
                              },
                              onHorizontalDragStart: (d) {
                                seek(d.localPosition.dx, cons.maxWidth);
                              },
                              onHorizontalDragUpdate: (d) {
                                seek(d.localPosition.dx, cons.maxWidth);
                              },
                              child: wave,
                            );
                          },
                        )
                      else
                        Text(
                          l10n.voice_attachment_load_failed,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: metaColor,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        failed
                            ? l10n.voice_attachment_title_voice_message
                            : '${_format(displayTime)} · ${_sizeLabel()}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                          color: metaColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              TextButton(
                onPressed: failed || !ready ? null : onCycleRate,
                style: TextButton.styleFrom(
                  minimumSize: const Size(44, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  _rateButtonLabel(playbackRate),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isMine
                        ? scheme.onPrimary
                        : scheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
          );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: ChatGlassPanel(
          padding: EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              playerRow,
              if (footer != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Divider(
                    height: 1,
                    thickness: 0.5,
                    color: (isMine ? scheme.onPrimary : scheme.onSurface)
                        .withValues(alpha: 0.18),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                  child: footer!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TranscriptControls extends StatefulWidget {
  const _TranscriptControls({
    required this.conversationId,
    required this.messageId,
    required this.audioUrl,
    required this.isMine,
    required this.transcript,
  });

  final String conversationId;
  final String messageId;
  final String audioUrl;
  final bool isMine;
  final String? transcript;

  @override
  State<_TranscriptControls> createState() => _TranscriptControlsState();
}

class _TranscriptControlsState extends State<_TranscriptControls> {
  bool _open = false;
  bool _busy = false;
  String? _localTranscript;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _localTranscript =
        LocalVoiceTranscriber.instance.cachedFor(widget.messageId);
  }

  Future<void> _ensureTranscript() async {
    if (_busy) return;
    final existing = (widget.transcript ?? _localTranscript ?? '').trim();
    if (existing.isNotEmpty) return;
    setState(() {
      _busy = true;
      _errorText = null;
    });
    try {
      final lang = Localizations.localeOf(context).languageCode.toLowerCase();
      final text = await LocalVoiceTranscriber.instance.transcribeAttachment(
        messageId: widget.messageId,
        audioUrl: widget.audioUrl,
        languageHint: lang,
      );
      if (!mounted) return;
      setState(() => _localTranscript = text);
    } catch (e) {
      if (!mounted) return;
      final friendly = _friendlyError(e);
      setState(() => _errorText = friendly);

      final l10nErr = AppLocalizations.of(context);
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (l10nErr != null && messenger != null) {
        try {
          messenger.showSnackBar(
            SnackBar(content: Text(l10nErr.voice_transcript_error(friendly))),
          );
        } catch (_) {
          // If the messenger is in an invalid state, fall back to inline UI.
        }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _friendlyError(Object e) {
    final l10n = AppLocalizations.of(context);
    if (e is VoiceTranscriptionException && l10n != null) {
      switch (e.code) {
        case 'permission_denied':
        case 'permission_restricted':
          return l10n.voice_transcript_permission_denied;
        case 'no_model':
        case 'unsupported_os':
          return l10n.voice_transcript_no_model;
        case 'unsupported_lang':
          return l10n.voice_transcript_unsupported_lang;
      }
    }
    return e.toString();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isMine = widget.isMine;
    // Адаптивные цвета: на «моих» пузырях фон = primary, текст = onPrimary.
    // На входящих и в media-tab фон — surface-glass, текст = onSurface.
    final metaColor = isMine
        ? scheme.onPrimary.withValues(alpha: 0.82)
        : scheme.onSurface.withValues(alpha: 0.72);
    final textColor = isMine
        ? scheme.onPrimary
        : scheme.onSurface;

    final current = (widget.transcript ?? _localTranscript ?? '').trim();
    final hasTranscript = current.isNotEmpty;

    final l10n = AppLocalizations.of(context)!;
    final showLabel = l10n.voice_transcript_show;
    final hideLabel = l10n.voice_transcript_hide;
    final copyLabel = l10n.voice_transcript_copy;
    final loadingLabel = l10n.voice_transcript_loading;
    final failedLabel = l10n.voice_transcript_failed;
    final inlineError = _errorText;

    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 2, right: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () async {
                setState(() => _open = !_open);
                if (_open) {
                  await _ensureTranscript();
                }
              },
              style: TextButton.styleFrom(
                minimumSize: const Size(44, 32),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: metaColor,
              ),
              icon: Icon(
                _open
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: metaColor,
              ),
              label: Text(
                _open ? hideLabel : showLabel,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: metaColor,
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topLeft,
            child: !_open
                ? const SizedBox(width: double.infinity)
                : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: _busy
                        ? Padding(
                            key: const ValueKey('loading'),
                            padding: const EdgeInsets.fromLTRB(8, 2, 8, 6),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: metaColor,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  loadingLabel,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: metaColor,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : hasTranscript
                            ? Padding(
                                key: const ValueKey('text'),
                                padding: const EdgeInsets.fromLTRB(8, 2, 4, 4),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    SelectableText(
                                      current,
                                      style: TextStyle(
                                        fontSize: 14,
                                        height: 1.32,
                                        fontWeight: FontWeight.w500,
                                        color: textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton.icon(
                                        onPressed: () async {
                                          final messenger =
                                              ScaffoldMessenger.maybeOf(
                                                  context);
                                          await Clipboard.setData(
                                              ClipboardData(text: current));
                                          messenger?.showSnackBar(
                                            SnackBar(
                                              duration: const Duration(
                                                  milliseconds: 1200),
                                              content: Text(copyLabel),
                                            ),
                                          );
                                        },
                                        style: TextButton.styleFrom(
                                          minimumSize: const Size(44, 30),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8),
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          foregroundColor: metaColor,
                                        ),
                                        icon: Icon(
                                          Icons.copy_all_outlined,
                                          size: 16,
                                          color: metaColor,
                                        ),
                                        label: Text(
                                          copyLabel,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: metaColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Padding(
                                key: const ValueKey('error'),
                                padding: const EdgeInsets.fromLTRB(8, 2, 8, 6),
                                child: Text(
                                  inlineError?.trim().isNotEmpty == true
                                      ? l10n.voice_transcript_error(
                                          inlineError!)
                                      : failedLabel,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: textColor.withValues(alpha: 0.88),
                                  ),
                                ),
                              ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _VoiceJustAudioBar extends StatefulWidget {
  const _VoiceJustAudioBar({
    super.key,
    required this.attachment,
    required this.alignRight,
    this.conversationId,
    this.messageId,
    this.transcript,
  });

  final ChatAttachment attachment;
  final bool alignRight;
  final String? conversationId;
  final String? messageId;
  final String? transcript;

  @override
  State<_VoiceJustAudioBar> createState() => _VoiceJustAudioBarState();
}

class _VoiceJustAudioBarState extends State<_VoiceJustAudioBar> {
  late final AudioPlayer _player;
  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<Duration?>? _durSub;
  StreamSubscription<Duration>? _posSub;
  bool _ready = false;
  bool _failed = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _playing = false;
  int _rateIndex = 0;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    unawaited(_load());
  }

  Future<void> _load() async {
    final uri = Uri.tryParse(widget.attachment.url);
    if (uri == null || !uri.hasScheme) {
      if (mounted) setState(() => _failed = true);
      return;
    }
    try {
      await _player.setAudioSource(AudioSource.uri(uri));
      await _player.setSpeed(kAudioMessagePlaybackRates[_rateIndex]);
      _durSub = _player.durationStream.listen((d) {
        if (!mounted || d == null) return;
        setState(() {
          _duration = d;
          _ready = true;
        });
      });
      _posSub = _player.positionStream.listen((p) {
        if (!mounted) return;
        setState(() => _position = p);
      });
      _stateSub = _player.playerStateStream.listen((s) {
        if (!mounted) return;
        if (s.processingState == ProcessingState.completed) {
          _VoicePlaybackExclusive.clear(this);
          setState(() {
            _playing = false;
            _position = _duration;
          });
          unawaited(_player.seek(Duration.zero));
          return;
        }
        setState(() => _playing = s.playing);
      });
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _toggle() async {
    if (_failed || !_ready) return;
    try {
      if (_playing) {
        await _player.pause();
        _VoicePlaybackExclusive.clear(this);
      } else {
        await _VoicePlaybackExclusive.beforeStartOther(
          this,
          () => _player.pause(),
        );
        await _player.play();
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _seekFromWaveformLocal(double localX, double width) {
    if (_failed || !_ready || width <= 0) return;
    final d = _duration;
    if (d <= Duration.zero) return;
    final f = (localX / width).clamp(0.0, 1.0);
    final ms = (f * d.inMilliseconds).round();
    unawaited(_player.seek(Duration(milliseconds: ms)));
  }

  void _cycleRate() {
    if (_failed || !_ready) return;
    setState(() {
      _rateIndex = (_rateIndex + 1) % kAudioMessagePlaybackRates.length;
    });
    unawaited(_player.setSpeed(kAudioMessagePlaybackRates[_rateIndex]));
  }

  @override
  void dispose() {
    _VoicePlaybackExclusive.clear(this);
    unawaited(_durSub?.cancel());
    unawaited(_posSub?.cancel());
    unawaited(_stateSub?.cancel());
    unawaited(_player.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mine = widget.alignRight;
    final progressPct = _duration.inMilliseconds > 0
        ? (_position.inMilliseconds / _duration.inMilliseconds) * 100.0
        : 0.0;
    final displayTime = _playing ? _position : _duration;

    final cid = (widget.conversationId ?? '').trim();
    final mid = (widget.messageId ?? '').trim();
    final hasIds = cid.isNotEmpty && mid.isNotEmpty;

    return _WebStyleVoiceRow(
      isMine: mine,
      failed: _failed,
      ready: _ready,
      playing: _playing,
      progressPercent: progressPct,
      seedUrl: widget.attachment.url,
      displayTime: displayTime,
      sizeBytes: widget.attachment.size,
      playbackRate: kAudioMessagePlaybackRates[_rateIndex],
      onToggle: () {
        unawaited(_toggle());
      },
      onCycleRate: _cycleRate,
      onWaveformSeekFromLocal: _seekFromWaveformLocal,
      footer: hasIds
          ? _TranscriptControls(
              conversationId: cid,
              messageId: mid,
              audioUrl: widget.attachment.url,
              isMine: mine,
              transcript: widget.transcript,
            )
          : null,
    );
  }
}

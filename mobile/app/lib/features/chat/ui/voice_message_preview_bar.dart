import 'dart:async';
import 'dart:io';

import 'package:ffmpeg_kit_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_min_gpl/return_code.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import '../../../l10n/app_localizations.dart';
import '../data/local_voice_transcriber.dart';
import 'message_audio_waveform.dart';
import 'voice_message_record_sheet.dart';

/// Telegram‑style preview bar for a just‑recorded voice message.
///
/// Matches the visual spec in the product screenshots:
///   [trash]   [▶ / ⏸]   ─── waveform ───   0:02   [send]
///
/// Fully self‑contained:
///   * plays back the file at [filePath] via `just_audio`
///   * draws a progress waveform using the shared [AudioMessageWaveformBars]
///   * invokes [onCancel] when the user taps the trash icon
///   * invokes [onSend] when the user taps the send icon
///
/// The widget does **not** delete the source file on cancel / send — the
/// caller owns the lifecycle of [filePath]. This keeps the widget reusable
/// and easy to unit test.
class VoiceMessagePreviewBar extends StatefulWidget {
  const VoiceMessagePreviewBar({
    super.key,
    required this.filePath,
    required this.duration,
    required this.onCancel,
    required this.onSend,
    this.onContinueRecording,
    this.busy = false,
  });

  final String filePath;
  final Duration duration;
  final VoidCallback onCancel;
  final Future<void> Function(VoiceMessageRecordResult result) onSend;
  final Future<void> Function(VoiceMessageRecordResult result)?
  onContinueRecording;

  /// If true — "send" is displayed as a spinner and both actions are disabled.
  /// Used by the caller during async upload to prevent double‑sends.
  final bool busy;

  @override
  State<VoiceMessagePreviewBar> createState() => _VoiceMessagePreviewBarState();
}

class _VoiceMessagePreviewBarState extends State<VoiceMessagePreviewBar> {
  late final AudioPlayer _player;
  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration?>? _durSub;

  bool _ready = false;
  bool _failed = false;
  bool _playing = false;
  bool _trimBusy = false;
  Duration _position = Duration.zero;
  Duration _effectiveDuration = Duration.zero;
  double _trimStart = 0;
  double _trimEnd = 1;

  // On-device транскрибация полученной записи. Начинается в [initState],
  // результат показывается над playback-row'ой и пробрасывается в send-result
  // как `transcript`. При ошибке (нет permission / не поддерживается локаль)
  // полоска просто молча скрывается — войс всё равно можно отправить без
  // транскрипта, не блокируем поток.
  bool _transcribing = false;
  String? _transcript;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _effectiveDuration = widget.duration;
    unawaited(_load());
    unawaited(_kickOffTranscription());
  }

  Future<void> _kickOffTranscription() async {
    if (!mounted) return;
    setState(() {
      _transcribing = true;
      _transcript = null;
    });
    try {
      // Локаль системы — приоритетная подсказка. Двухпроходный auto-detect
      // на iOS сам перепроверит через NLLanguageRecognizer и перезапустится
      // с правильной локалью при необходимости.
      final lang = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      final fileUri = Uri.file(widget.filePath).toString();
      final res = await LocalVoiceTranscriber.instance.transcribeAttachment(
        messageId: 'preview_${DateTime.now().microsecondsSinceEpoch}',
        audioUrl: fileUri,
        languageHint: lang,
      );
      if (!mounted) return;
      setState(() {
        _transcribing = false;
        _transcript = res.text.trim().isEmpty ? null : res.text.trim();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _transcribing = false;
        _transcript = null;
      });
    }
  }

  Future<void> _load() async {
    try {
      await _player.setAudioSource(AudioSource.file(widget.filePath));
      _durSub = _player.durationStream.listen((d) {
        if (!mounted || d == null) return;
        setState(() {
          if (d > Duration.zero) _effectiveDuration = d;
          _ready = true;
        });
      });
      _posSub = _player.positionStream.listen((p) {
        if (!mounted) return;
        setState(() => _position = p);
      });
      _stateSub = _player.playerStateStream.listen((s) {
        if (!mounted) return;
        setState(() => _playing = s.playing);
        if (s.processingState == ProcessingState.completed) {
          unawaited(_player.seek(Duration.zero));
          unawaited(_player.pause());
        }
      });
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    unawaited(_durSub?.cancel());
    unawaited(_posSub?.cancel());
    unawaited(_stateSub?.cancel());
    unawaited(_player.dispose());
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_failed || !_ready || widget.busy) return;
    try {
      if (_playing) {
        await _player.pause();
      } else {
        if (_player.processingState == ProcessingState.completed) {
          await _player.seek(Duration.zero);
        }
        await _player.play();
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _seekFromLocal(double localX, double width) {
    if (_failed || !_ready || width <= 0) return;
    final d = _effectiveDuration;
    if (d <= Duration.zero) return;
    final f = (localX / width).clamp(0.0, 1.0);
    unawaited(
      _player.seek(Duration(milliseconds: (f * d.inMilliseconds).round())),
    );
  }

  String _fmt(Duration d) {
    final total = d.inSeconds.clamp(0, 99 * 3600);
    final m = total ~/ 60;
    final s = total % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  bool get _hasTrim =>
      _trimStart > 0.005 || _trimEnd < 0.995 || (_trimEnd - _trimStart) < 0.99;

  Duration get _trimStartDuration => Duration(
    milliseconds: (_effectiveDuration.inMilliseconds * _trimStart).round(),
  );

  Duration get _trimEndDuration => Duration(
    milliseconds: (_effectiveDuration.inMilliseconds * _trimEnd).round(),
  );

  Duration get _trimmedDuration {
    final d = _trimEndDuration - _trimStartDuration;
    return d > Duration.zero ? d : _effectiveDuration;
  }

  double get _minTrimFraction {
    final ms = _effectiveDuration.inMilliseconds;
    if (ms <= 0) return 0.02;
    return (350 / ms).clamp(0.02, 0.24);
  }

  String _ffQuote(String path) => '"${path.replaceAll('"', r'\"')}"';

  void _setTrimStart(double value) {
    final max = _trimEnd - _minTrimFraction;
    setState(() => _trimStart = value.clamp(0.0, max.clamp(0.0, 1.0)));
  }

  void _setTrimEnd(double value) {
    final min = _trimStart + _minTrimFraction;
    setState(() => _trimEnd = value.clamp(min.clamp(0.0, 1.0), 1.0));
  }

  Future<VoiceMessageRecordResult> _selectedResult() async {
    if (!_hasTrim || _effectiveDuration <= Duration.zero) {
      return VoiceMessageRecordResult(
        filePath: widget.filePath,
        duration: _effectiveDuration > Duration.zero
            ? _effectiveDuration
            : widget.duration,
        transcript: _transcript,
      );
    }

    final dir = await getTemporaryDirectory();
    final outPath =
        '${dir.path}/audio_trim_${DateTime.now().microsecondsSinceEpoch}.m4a';
    final start = _trimStartDuration.inMilliseconds / 1000.0;
    final len = _trimmedDuration.inMilliseconds / 1000.0;
    final cmd = <String>[
      '-y',
      '-i',
      _ffQuote(widget.filePath),
      '-ss',
      start.toStringAsFixed(3),
      '-t',
      len.toStringAsFixed(3),
      '-vn',
      '-c:a',
      'aac',
      '-b:a',
      '96k',
      '-movflags',
      '+faststart',
      _ffQuote(outPath),
    ].join(' ');
    final session = await FFmpegKit.execute(cmd);
    final code = await session.getReturnCode();
    if (!ReturnCode.isSuccess(code) || !await File(outPath).exists()) {
      return VoiceMessageRecordResult(
        filePath: widget.filePath,
        duration: _effectiveDuration,
        transcript: _transcript,
      );
    }
    unawaited(_deleteSilently(widget.filePath));
    // После trim'а файл и его длина изменились, но содержимое речи —
    // подмножество исходного. Транскрипт исходника всё ещё ценен как
    // approx. Дешевле передать его, чем перезапускать ASR на trim'е.
    return VoiceMessageRecordResult(
      filePath: outPath,
      duration: _trimmedDuration,
      transcript: _transcript,
    );
  }

  Future<void> _deleteSilently(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  /// Полоса с транскриптом над playback-row.
  /// Состояния:
  ///  - `_transcribing` → spinner + «Распознаю…»
  ///  - `_transcript != null` → серая карточка с самим текстом
  ///  - иначе (включая ошибки) → SizedBox.shrink (AnimatedSize сворачивает)
  Widget _buildTranscriptionStrip({
    required bool dark,
    required Color fg,
    required Color meta,
    required AppLocalizations l10n,
  }) {
    if (_transcribing) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(52, 0, 54, 6),
        child: Row(
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: meta,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              l10n.voice_preview_transcribing,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: meta,
              ),
            ),
          ],
        ),
      );
    }
    final text = _transcript;
    if (text == null || text.isEmpty) return const SizedBox.shrink();
    final bg = dark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.04);
    final border = dark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08);
    return Padding(
      padding: const EdgeInsets.fromLTRB(52, 0, 54, 6),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 96),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: SingleChildScrollView(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: fg.withValues(alpha: 0.86),
              height: 1.32,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendSelected() async {
    if (_trimBusy || widget.busy) return;
    setState(() => _trimBusy = true);
    try {
      final result = await _selectedResult();
      await widget.onSend(result);
    } finally {
      if (mounted) setState(() => _trimBusy = false);
    }
  }

  Future<void> _continueAfterTrim() async {
    final cb = widget.onContinueRecording;
    if (cb == null || !_hasTrim || _trimBusy || widget.busy) return;
    final confirmed = await _showContinueConfirmDialog();
    if (confirmed != true || !mounted) return;
    setState(() => _trimBusy = true);
    try {
      await _player.pause();
      final result = await _selectedResult();
      await cb(result);
    } finally {
      if (mounted) setState(() => _trimBusy = false);
    }
  }

  Future<bool?> _showContinueConfirmDialog() {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.38),
      builder: (ctx) {
        return Dialog(
          backgroundColor: const Color(0xFF17191D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppLocalizations.of(context)!.voice_preview_trim_confirm_title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16.5,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.voice_preview_trim_confirm_body,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                    height: 1.25,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 46,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF37C8EF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(23),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Text(AppLocalizations.of(context)!.voice_preview_continue),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 44,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.11),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text(AppLocalizations.of(context)!.common_cancel),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dark = Theme.of(context).colorScheme.brightness == Brightness.dark;
    final fg = dark ? Colors.white : const Color(0xFF0F172A);
    final meta = fg.withValues(alpha: 0.62);
    final bg = dark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.04);
    final border = dark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08);
    final accent = const Color(0xFF2A79FF);

    final busy = widget.busy || _trimBusy;
    final displayDuration = _playing || _position > Duration.zero
        ? _position
        : (_hasTrim ? _trimmedDuration : _effectiveDuration);
    final progressPct = _effectiveDuration.inMilliseconds > 0
        ? (_position.inMilliseconds / _effectiveDuration.inMilliseconds) * 100.0
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: _buildTranscriptionStrip(
              dark: dark,
              fg: fg,
              meta: meta,
              l10n: l10n,
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: _hasTrim && widget.onContinueRecording != null
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(52, 0, 54, 6),
                    child: SizedBox(
                      height: 32,
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: fg.withValues(alpha: 0.92),
                          side: BorderSide(
                            color: const Color(
                              0xFF37C8EF,
                            ).withValues(alpha: 0.55),
                            width: 1.1,
                          ),
                          backgroundColor: const Color(
                            0xFF37C8EF,
                          ).withValues(alpha: 0.12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        onPressed: busy ? null : _continueAfterTrim,
                        icon: Icon(
                          Icons.keyboard_voice_rounded,
                          size: 15,
                          color: fg.withValues(alpha: 0.9),
                        ),
                        label: Text(AppLocalizations.of(context)!.voice_preview_continue_recording),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _CircleIconButton(
                icon: Icons.delete_outline_rounded,
                tooltip: l10n.voice_preview_tooltip_cancel,
                onTap: busy ? null : widget.onCancel,
                color: fg.withValues(alpha: 0.82),
                background: Colors.transparent,
                size: 40,
                iconSize: 22,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
                      child: Row(
                        children: [
                          Material(
                            color: accent,
                            shape: const CircleBorder(),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: busy ? null : _toggle,
                              child: SizedBox(
                                width: 34,
                                height: 34,
                                child: Icon(
                                  _failed
                                      ? Icons.error_outline_rounded
                                      : (_playing
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded),
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _VoiceTrimTimeline(
                              trimStart: _trimStart,
                              trimEnd: _trimEnd,
                              progress: (progressPct / 100).clamp(0.0, 1.0),
                              seed: widget.filePath,
                              onSeekFraction: (f) => _seekFromLocal(f, 1),
                              onTrimStartChanged: (f) {
                                unawaited(_player.pause());
                                _setTrimStart(f);
                              },
                              onTrimEndChanged: (f) {
                                unawaited(_player.pause());
                                _setTrimEnd(f);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _fmt(displayDuration),
                            style: TextStyle(
                              color: meta,
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5,
                              decoration: TextDecoration.none,
                              decorationThickness: 0,
                              fontFeatures: const <FontFeature>[
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _CircleIconButton(
                icon: Icons.send_rounded,
                tooltip: l10n.voice_preview_tooltip_send,
                onTap: busy ? null : _sendSelected,
                color: Colors.white,
                background: accent,
                size: 44,
                iconSize: 20,
                busy: busy,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VoiceTrimTimeline extends StatelessWidget {
  const _VoiceTrimTimeline({
    required this.trimStart,
    required this.trimEnd,
    required this.progress,
    required this.seed,
    required this.onSeekFraction,
    required this.onTrimStartChanged,
    required this.onTrimEndChanged,
  });

  final double trimStart;
  final double trimEnd;
  final double progress;
  final String seed;
  final ValueChanged<double> onSeekFraction;
  final ValueChanged<double> onTrimStartChanged;
  final ValueChanged<double> onTrimEndChanged;

  @override
  Widget build(BuildContext context) {
    final bars = audioMessageWaveformBarFactors(seed);
    const height = 34.0;
    const radius = 17.0;
    return LayoutBuilder(
      builder: (context, cons) {
        final w = cons.maxWidth.isFinite ? cons.maxWidth : 160.0;
        double fractionFromDx(double dx) => (dx / w).clamp(0.0, 1.0);
        return SizedBox(
          height: height,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => onSeekFraction(fractionFromDx(d.localPosition.dx)),
            onHorizontalDragStart: (d) =>
                onSeekFraction(fractionFromDx(d.localPosition.dx)),
            onHorizontalDragUpdate: (d) =>
                onSeekFraction(fractionFromDx(d.localPosition.dx)),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D2429),
                      borderRadius: BorderRadius.circular(radius),
                    ),
                  ),
                ),
                Positioned(
                  left: w * trimStart,
                  width: (w * (trimEnd - trimStart)).clamp(1.0, w),
                  top: 0,
                  bottom: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFF35C3E8),
                      borderRadius: BorderRadius.circular(radius),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: List<Widget>.generate(bars.length, (i) {
                        final f = bars.length <= 1
                            ? 0.0
                            : i / (bars.length - 1);
                        final selected = f >= trimStart && f <= trimEnd;
                        final played = f <= progress;
                        final color = selected
                            ? Colors.white.withValues(
                                alpha: played ? 0.98 : 0.72,
                              )
                            : Colors.white.withValues(alpha: 0.26);
                        return Expanded(
                          child: Center(
                            child: Container(
                              width: 2,
                              height: 7 + bars[i] * 20,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                Positioned(
                  left: (w * progress).clamp(0.0, w) - 1,
                  top: 5,
                  bottom: 5,
                  child: Container(
                    width: 2,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
                _TimelineHandle(
                  x: w * trimStart,
                  alignRight: false,
                  onChanged: onTrimStartChanged,
                  width: w,
                ),
                _TimelineHandle(
                  x: w * trimEnd,
                  alignRight: true,
                  onChanged: onTrimEndChanged,
                  width: w,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TimelineHandle extends StatelessWidget {
  const _TimelineHandle({
    required this.x,
    required this.alignRight,
    required this.onChanged,
    required this.width,
  });

  final double x;
  final bool alignRight;
  final ValueChanged<double> onChanged;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: x - 18,
      top: -4,
      bottom: -4,
      width: 36,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragStart: (d) {
          final box = context.findRenderObject() as RenderBox?;
          if (box == null) return;
          final local = box.globalToLocal(d.globalPosition);
          onChanged(((x - 18 + local.dx) / width).clamp(0.0, 1.0));
        },
        onHorizontalDragUpdate: (d) {
          final box = context.findRenderObject() as RenderBox?;
          if (box == null) return;
          final local = box.globalToLocal(d.globalPosition);
          onChanged(((x - 18 + local.dx) / width).clamp(0.0, 1.0));
        },
        child: Align(
          alignment: alignRight ? Alignment.centerLeft : Alignment.centerRight,
          child: Container(
            width: 6,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.24),
                  blurRadius: 8,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    required this.color,
    required this.background,
    required this.size,
    required this.iconSize,
    this.tooltip,
    this.busy = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final Color color;
  final Color background;
  final double size;
  final double iconSize;
  final String? tooltip;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: background,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: busy
              ? Center(
                  child: SizedBox(
                    width: iconSize * 0.9,
                    height: iconSize * 0.9,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: color,
                    ),
                  ),
                )
              : Icon(icon, color: color, size: iconSize),
        ),
      ),
    );
    if (tooltip == null || tooltip!.isEmpty) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

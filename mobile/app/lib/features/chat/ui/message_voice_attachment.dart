import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lighchat_models/lighchat_models.dart';

import 'message_audio_waveform.dart';
import 'chat_glass_panel.dart';
import 'chat_vlc_network_media.dart';
import 'karaoke_screen.dart';
import '../../../l10n/app_localizations.dart';
import '../data/apple_intelligence.dart';
import '../data/local_message_translator.dart';
import '../data/local_text_language_detector.dart';
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
    this.senderName,
    this.senderAvatarUrl,
  });

  final ChatAttachment attachment;
  final int attachmentIndex;
  final bool alignRight;
  final String? conversationId;
  final String? messageId;
  final String? transcript;
  final ChatMediaNorm? mediaNorm;
  final Future<void> Function()? onRetryNorm;

  /// Имя отправителя — для karaoke-экрана и т.п. Если `null` —
  /// karaoke использует «?» в качестве letter-аватара.
  final String? senderName;

  /// URL аватара отправителя для karaoke-экрана.
  final String? senderAvatarUrl;

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
      senderName: senderName,
      senderAvatarUrl: senderAvatarUrl,
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
    this.skipSilenceAvailable = false,
    this.skipSilenceEnabled = false,
    this.onToggleSkipSilence,
    this.onLongPressPlay,
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

  /// Доступен ли skip-silence (есть ли распознанные silence-интервалы).
  /// Если `false`, кнопка не рисуется.
  final bool skipSilenceAvailable;
  final bool skipSilenceEnabled;
  final VoidCallback? onToggleSkipSilence;

  /// Долгий тап по play-кнопке — для входа в режим karaoke.
  final VoidCallback? onLongPressPlay;

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
    // ChatGlassPanel принудительно делает фон тёмным стеклом и оверрайдит
    // onSurface → белый. Цвета mine/onPrimary не подходят: на тёмном стекле
    // они сливаются. Используем светлые цвета всегда — это адаптивно к
    // любым обоям и темам, потому что подложка под текстом известная (стекло).
    final metaColor = Colors.white.withValues(alpha: 0.88);
    final rateColor = Colors.white;

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
                  onLongPress: onLongPressPlay,
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
                  // Низ оставляем минимальным, чтобы кнопка «Show text» под
                  // плеером прижалась почти вплотную к меткам времени/размера.
                  padding: const EdgeInsets.only(top: 10, bottom: 2),
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
              if (skipSilenceAvailable && onToggleSkipSilence != null)
                IconButton(
                  onPressed: onToggleSkipSilence,
                  tooltip: l10n.voice_attachment_skip_silence,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  visualDensity: VisualDensity.compact,
                  iconSize: 16,
                  color: skipSilenceEnabled
                      ? rateColor
                      : metaColor,
                  icon: Icon(
                    skipSilenceEnabled
                        ? Icons.fast_forward_rounded
                        : Icons.fast_forward_outlined,
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
                    fontWeight: FontWeight.w700,
                    color: rateColor,
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
              if (footer != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
                  child: footer!,
                ),
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
    required this.audioDuration,
    this.positionStream,
    this.onSeek,
    this.onSegmentsLoaded,
  });

  final String conversationId;
  final String messageId;
  final String audioUrl;
  final bool isMine;
  final String? transcript;
  final Duration audioDuration;

  /// Stream позиции плеера — для karaoke-подсветки текущего слова.
  final Stream<Duration>? positionStream;

  /// Callback при тапе на слово в karaoke-режиме.
  final void Function(Duration target)? onSeek;

  /// Callback после первого получения сегментов транскрипта — родитель
  /// (player) использует их для skip-silence.
  final void Function(List<TranscriptSegment> segments)? onSegmentsLoaded;

  @override
  State<_TranscriptControls> createState() => _TranscriptControlsState();
}

class _TranscriptControlsState extends State<_TranscriptControls> {
  bool _open = false;
  bool _busy = false;
  VoiceTranscriptionResult? _localResult;
  String? _errorText;

  // Translation state.
  bool _translating = false;
  bool _showTranslation = false;
  String? _translation;
  TranslationPhase? _translatePhase;

  // TL;DR state.
  bool _showSummary = false;
  String? _summary;
  bool _summarizing = false;

  // Сентимент (NLTagger / Android-эвристика): эмодзи 😊/😕/etc или null.
  String? _sentimentEmoji;

  @override
  void initState() {
    super.initState();
    _localResult =
        LocalVoiceTranscriber.instance.cachedFor(widget.messageId);
    if (_localResult != null) {
      // Если транскрипт уже в кэше — сразу прокинуть сегменты родителю
      // (для skip-silence).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _localResult != null) {
          widget.onSegmentsLoaded?.call(_localResult!.segments);
        }
      });
    }
  }

  Future<void> _ensureTranscript() async {
    if (_busy) return;
    final existing =
        (widget.transcript ?? _localResult?.text ?? '').trim();
    if (existing.isNotEmpty) return;
    setState(() {
      _busy = true;
      _errorText = null;
    });
    try {
      final lang = Localizations.localeOf(context).languageCode.toLowerCase();
      final res = await LocalVoiceTranscriber.instance.transcribeAttachment(
        messageId: widget.messageId,
        audioUrl: widget.audioUrl,
        languageHint: lang,
      );
      if (!mounted) return;
      setState(() => _localResult = res);
      widget.onSegmentsLoaded?.call(res.segments);
      // Сентимент считаем после транскрипции — короткая операция, можно
      // не блокировать UI.
      if (res.text.trim().isNotEmpty) {
        unawaited(_resolveSentiment(res.text));
      }
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

  /// Полный сброс: чистим кэш транскрипции и перевода для этого сообщения,
  /// сбрасываем локальный state и перезапрашиваем распознавание. Нужно на
  /// случай, если в кэше «осело» что-то странное (старая модель, ошибочный
  /// язык и т.п.).
  Future<void> _retryTranscript() async {
    if (_busy || _translating) return;
    LocalVoiceTranscriber.instance.clearCache(widget.messageId);
    unawaited(
      LocalMessageTranslator.instance.invalidateContaining(widget.messageId),
    );
    setState(() {
      _localResult = null;
      _translation = null;
      _showTranslation = false;
      _summary = null;
      _summarizing = false;
      _showSummary = false;
      _sentimentEmoji = null;
      _errorText = null;
    });
    await _ensureTranscript();
  }

  /// Запрашивает резюме. Сначала пробует Apple Intelligence Foundation
  /// Models (iOS 18.1+/26+). Если недоступно — heuristic-fallback.
  Future<String> _computeSummary(String text) async {
    final fromLlm = await AppleIntelligence.instance.summarize(text);
    if (fromLlm != null && fromLlm.trim().isNotEmpty) return fromLlm.trim();
    return _generateHeuristicSummary(text);
  }

  /// Эвристическая сводка: первое предложение + предложение с наибольшей
  /// плотностью «редких» слов (отфильтровав короткие стоп-слова). Работает
  /// на любом языке без LLM.
  String _generateHeuristicSummary(String text) {
    final sentences = _splitSentences(text);
    if (sentences.length <= 2) return text.trim();
    final first = sentences.first;
    final scored = <MapEntry<String, double>>[];
    for (var i = 1; i < sentences.length; i++) {
      final words = sentences[i]
          .toLowerCase()
          .split(RegExp(r'[\s,.;:!?…—-]+'))
          .where((w) => w.length >= 4)
          .toList();
      if (words.isEmpty) continue;
      final density = words.length / sentences[i].length;
      scored.add(MapEntry(sentences[i], density * words.length));
    }
    scored.sort((a, b) => b.value.compareTo(a.value));
    final picks = <String>[first];
    for (final e in scored) {
      if (picks.length >= 3) break;
      if (!picks.contains(e.key)) picks.add(e.key);
    }
    return picks.join(' ');
  }

  List<String> _splitSentences(String text) {
    final parts = text.split(RegExp(r'(?<=[.!?…])\s+'));
    return parts.map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  }

  Future<void> _resolveSentiment(String text) async {
    final s = await LocalTextSentimentDetector.instance.score(text);
    if (!mounted) return;
    setState(() => _sentimentEmoji = sentimentEmojiFor(s));
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

  /// Должна ли отображаться кнопка «Translate». Условия:
  /// - есть распознанный текст,
  /// - детект языка от Apple Speech есть и отличается от UI-локали,
  /// - ML Kit поддерживает пару исходный→целевой.
  bool _canOfferTranslation(String text) {
    if (text.isEmpty) return false;
    final detected = _localResult?.detectedLanguage;
    if (detected == null || detected.isEmpty) return false;
    final ui = Localizations.localeOf(context).languageCode.toLowerCase();
    if (detected == ui) return false;
    return LocalMessageTranslator.instance
        .supportsPair(from: detected, to: ui);
  }

  Future<void> _toggleTranslation() async {
    if (_translating) return;
    final original =
        (widget.transcript ?? _localResult?.text ?? '').trim();
    final detected = _localResult?.detectedLanguage;
    if (original.isEmpty || detected == null) return;

    // Если перевод уже есть в локальном state — просто переключаем view.
    if (_translation != null) {
      setState(() => _showTranslation = !_showTranslation);
      return;
    }

    final ui = Localizations.localeOf(context).languageCode.toLowerCase();
    setState(() {
      _translating = true;
      _translatePhase = TranslationPhase.translating;
      _errorText = null;
    });
    try {
      final result = await LocalMessageTranslator.instance.translate(
        cacheKey: '${widget.messageId}|$detected→$ui',
        text: original,
        from: detected,
        to: ui,
        onPhase: (phase) {
          if (!mounted) return;
          setState(() => _translatePhase = phase);
        },
      );
      if (!mounted) return;
      setState(() {
        _translation = result;
        _showTranslation = true;
      });
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      final msg = e is UnsupportedTranslationException
          ? (l10n?.voice_translate_unsupported ?? 'Translation not available')
          : (l10n?.voice_translate_failed(e.toString()) ??
              'Translation failed');
      setState(() => _errorText = msg);
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          content: Text(msg),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _translating = false;
          _translatePhase = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // _TranscriptControls всегда рендерится внутри ChatGlassPanel
    // (фон = тёмное стекло). Цвет текста — белый с разной альфой; так он
    // адаптивен ко всем обоям и темам, потому что подложка фиксирована.
    final metaColor = Colors.white.withValues(alpha: 0.78);
    final textColor = Colors.white.withValues(alpha: 0.96);

    final original =
        (widget.transcript ?? _localResult?.text ?? '').trim();
    final hasTranscript = original.isNotEmpty;
    final canTranslate = _canOfferTranslation(original);
    final segments = _localResult?.segments ?? const <TranscriptSegment>[];
    final canKaraoke = segments.isNotEmpty &&
        !_showTranslation &&
        !_showSummary &&
        widget.positionStream != null;
    final wordsCount = segments.isEmpty
        ? original.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length
        : segments.length;
    final durationSec = widget.audioDuration.inMilliseconds / 1000.0;
    final wpm = (durationSec > 0.5 && wordsCount > 0)
        ? (wordsCount / durationSec * 60).round()
        : null;
    // TL;DR имеет смысл только для достаточно длинных голосовых.
    final canSummarize = original.length > 180 && wordsCount >= 25;
    final displayed = _showSummary && _summary != null
        ? _summary!
        : (_showTranslation && _translation != null
            ? _translation!
            : original);

    final l10n = AppLocalizations.of(context)!;
    final showLabel = l10n.voice_transcript_show;
    final hideLabel = l10n.voice_transcript_hide;
    final copyLabel = l10n.voice_transcript_copy;
    final retryLabel = l10n.voice_transcript_retry;
    final loadingLabel = l10n.voice_transcript_loading;
    final failedLabel = l10n.voice_transcript_failed;
    final translateLabel = l10n.voice_translate_action;
    final showOriginalLabel = l10n.voice_translate_show_original;
    final translatingLabel = l10n.voice_translate_in_progress;
    final downloadingLabel = l10n.voice_translate_downloading_model;
    final inlineError = _errorText;

    final translateActiveLabel = _translatePhase == TranslationPhase.downloading
        ? downloadingLabel
        : translatingLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
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
              minimumSize: const Size(44, 28),
              padding: const EdgeInsets.symmetric(horizontal: 6),
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
                                    if (canKaraoke)
                                      _KaraokeTranscript(
                                        segments: segments,
                                        positionStream:
                                            widget.positionStream!,
                                        onSeek: widget.onSeek,
                                        baseColor: textColor,
                                        highlightColor: textColor,
                                        highlightBg: Colors.white
                                            .withValues(alpha: 0.16),
                                      )
                                    else
                                      SelectableText(
                                        displayed,
                                        style: TextStyle(
                                          fontSize: 14,
                                          height: 1.32,
                                          fontWeight: FontWeight.w500,
                                          color: textColor,
                                        ),
                                      ),
                                    if (wpm != null ||
                                        _sentimentEmoji != null) ...[
                                      const SizedBox(height: 6),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (wpm != null) ...[
                                            _TranscriptStatsChip(
                                              wpm: wpm,
                                              wordsCount: wordsCount,
                                              color: metaColor,
                                              label: l10n
                                                  .voice_transcript_stats(
                                                wordsCount,
                                                wpm,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                          ],
                                          if (_sentimentEmoji != null)
                                            _SentimentChip(
                                              emoji: _sentimentEmoji!,
                                              color: metaColor,
                                            ),
                                        ],
                                      ),
                                    ],
                                    const SizedBox(height: 2),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.end,
                                      children: [
                                        if (canSummarize) ...[
                                          IconButton(
                                            onPressed: _summarizing
                                                ? null
                                                : () async {
                                                    if (_showSummary) {
                                                      setState(() =>
                                                          _showSummary = false);
                                                      return;
                                                    }
                                                    if (_summary == null) {
                                                      setState(() =>
                                                          _summarizing = true);
                                                      final r =
                                                          await _computeSummary(
                                                              original);
                                                      if (!mounted) return;
                                                      setState(() {
                                                        _summary = r;
                                                        _summarizing = false;
                                                        _showSummary = true;
                                                        _showTranslation =
                                                            false;
                                                      });
                                                    } else {
                                                      setState(() {
                                                        _showSummary = true;
                                                        _showTranslation =
                                                            false;
                                                      });
                                                    }
                                                  },
                                            tooltip: _showSummary
                                                ? l10n.voice_transcript_summary_hide
                                                : l10n.voice_transcript_summary_show,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(
                                              minWidth: 32,
                                              minHeight: 30,
                                            ),
                                            visualDensity:
                                                VisualDensity.compact,
                                            iconSize: 16,
                                            color: metaColor,
                                            icon: _summarizing
                                                ? SizedBox(
                                                    width: 14,
                                                    height: 14,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: metaColor,
                                                    ),
                                                  )
                                                : Icon(
                                                    _showSummary
                                                        ? Icons
                                                            .subject_rounded
                                                        : Icons
                                                            .short_text_rounded,
                                                  ),
                                          ),
                                        ],
                                        if (canTranslate) ...[
                                          TextButton.icon(
                                            onPressed: _translating
                                                ? null
                                                : _toggleTranslation,
                                            style: TextButton.styleFrom(
                                              minimumSize: const Size(44, 30),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8),
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              foregroundColor: metaColor,
                                            ),
                                            icon: _translating
                                                ? SizedBox(
                                                    width: 14,
                                                    height: 14,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: metaColor,
                                                    ),
                                                  )
                                                : Icon(
                                                    _showTranslation
                                                        ? Icons
                                                            .restart_alt_rounded
                                                        : Icons
                                                            .translate_rounded,
                                                    size: 16,
                                                    color: metaColor,
                                                  ),
                                            label: Text(
                                              _translating
                                                  ? translateActiveLabel
                                                  : (_showTranslation
                                                      ? showOriginalLabel
                                                      : translateLabel),
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: metaColor,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                        ],
                                        IconButton(
                                          onPressed: () async {
                                            final messenger =
                                                ScaffoldMessenger.maybeOf(
                                                    context);
                                            await Clipboard.setData(
                                                ClipboardData(text: displayed));
                                            messenger?.showSnackBar(
                                              SnackBar(
                                                duration: const Duration(
                                                    milliseconds: 1200),
                                                content: Text(copyLabel),
                                              ),
                                            );
                                          },
                                          tooltip: copyLabel,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(
                                            minWidth: 32,
                                            minHeight: 30,
                                          ),
                                          visualDensity: VisualDensity.compact,
                                          iconSize: 16,
                                          color: metaColor,
                                          icon: const Icon(
                                            Icons.copy_all_outlined,
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: _translating
                                              ? null
                                              : _retryTranscript,
                                          tooltip: retryLabel,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(
                                            minWidth: 32,
                                            minHeight: 30,
                                          ),
                                          visualDensity: VisualDensity.compact,
                                          iconSize: 16,
                                          color: metaColor,
                                          icon: const Icon(
                                            Icons.refresh_rounded,
                                          ),
                                        ),
                                      ],
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
    this.senderName,
    this.senderAvatarUrl,
  });

  final ChatAttachment attachment;
  final bool alignRight;
  final String? conversationId;
  final String? messageId;
  final String? transcript;
  final String? senderName;
  final String? senderAvatarUrl;

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

  // Skip-silence: лист silence-интервалов (пары [start, end]) и тогл.
  // Минимальная пауза для пропуска — 600 мс, иначе UX рваный.
  static const Duration _kMinSilenceGap = Duration(milliseconds: 600);
  List<({Duration start, Duration end})> _silences =
      const <({Duration start, Duration end})>[];
  bool _skipSilence = false;

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
        // Skip-silence: если плеер играет и попал в silence-интервал —
        // прыгаем в конец паузы. Сразу проверяем что плеер именно играет,
        // чтобы не мешать ручному seek/паузе.
        if (!_skipSilence || !_playing || _silences.isEmpty) return;
        for (final gap in _silences) {
          if (p >= gap.start && p < gap.end) {
            unawaited(_player.seek(gap.end));
            return;
          }
        }
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

  /// Принимаем сегменты от `_TranscriptControls` после успешной транскрипции
  /// и считаем silence-интервалы — паузы > 600 мс между концом одного слова
  /// и началом следующего, плюс паузы в начале и конце записи.
  void _onSegmentsLoaded(List<TranscriptSegment> segments) {
    if (segments.isEmpty) {
      if (mounted) setState(() => _silences = const []);
      return;
    }
    final gaps = <({Duration start, Duration end})>[];
    if (segments.first.start > _kMinSilenceGap) {
      gaps.add((start: Duration.zero, end: segments.first.start));
    }
    for (var i = 0; i < segments.length - 1; i++) {
      final endOfCurrent = segments[i].end;
      final startOfNext = segments[i + 1].start;
      final gap = startOfNext - endOfCurrent;
      if (gap >= _kMinSilenceGap) {
        gaps.add((start: endOfCurrent, end: startOfNext));
      }
    }
    if (mounted) setState(() => _silences = gaps);
  }

  void _toggleSkipSilence() {
    if (_silences.isEmpty) return;
    setState(() => _skipSilence = !_skipSilence);
  }

  /// Long-press на кнопку play → подтверждение → fullscreen karaoke.
  /// Если транскрипт ещё не получен — сначала пробуем достать его (тихо).
  Future<void> _onLongPressPlay() async {
    final cid = (widget.conversationId ?? '').trim();
    final mid = (widget.messageId ?? '').trim();
    if (cid.isEmpty || mid.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.voice_karaoke_prompt_title),
        content: Text(l10n.voice_karaoke_prompt_body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.chat_list_action_close),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.voice_karaoke_prompt_open),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    var cached = LocalVoiceTranscriber.instance.cachedFor(mid);
    if (cached == null || cached.segments.isEmpty) {
      try {
        final lang =
            Localizations.localeOf(context).languageCode.toLowerCase();
        cached = await LocalVoiceTranscriber.instance.transcribeAttachment(
          messageId: mid,
          audioUrl: widget.attachment.url,
          languageHint: lang,
        );
      } catch (_) {/* всё равно открываем — экран сам покажет «—» */}
    }
    if (!mounted) return;

    // Перед открытием — паузим текущий inline-плеер.
    if (_playing) {
      unawaited(_player.pause());
      _VoicePlaybackExclusive.clear(this);
    }

    await KaraokeScreen.push(
      context,
      audioUrl: widget.attachment.url,
      segments: cached?.segments ?? const <TranscriptSegment>[],
      senderName: (widget.senderName ?? '').trim().isNotEmpty
          ? widget.senderName!.trim()
          : '?',
      senderAvatarUrl: widget.senderAvatarUrl,
    );
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
      skipSilenceAvailable: _silences.isNotEmpty,
      skipSilenceEnabled: _skipSilence,
      onToggleSkipSilence: _silences.isEmpty ? null : _toggleSkipSilence,
      onLongPressPlay: hasIds ? () => unawaited(_onLongPressPlay()) : null,
      footer: hasIds
          ? _TranscriptControls(
              conversationId: cid,
              messageId: mid,
              audioUrl: widget.attachment.url,
              isMine: mine,
              transcript: widget.transcript,
              audioDuration: _duration,
              positionStream: _player.positionStream,
              onSeek: (target) => unawaited(_player.seek(target)),
              onSegmentsLoaded: _onSegmentsLoaded,
            )
          : null,
    );
  }
}

/// Karaoke-рендер транскрипта: каждое слово — `WidgetSpan` с подсветкой
/// текущего по позиции плеера. Тап по слову → seek.
class _KaraokeTranscript extends StatelessWidget {
  const _KaraokeTranscript({
    required this.segments,
    required this.positionStream,
    required this.baseColor,
    required this.highlightColor,
    required this.highlightBg,
    this.onSeek,
  });

  final List<TranscriptSegment> segments;
  final Stream<Duration> positionStream;
  final Color baseColor;
  final Color highlightColor;
  final Color highlightBg;
  final void Function(Duration target)? onSeek;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: positionStream,
      initialData: Duration.zero,
      builder: (context, snapshot) {
        final pos = snapshot.data ?? Duration.zero;
        var activeIdx = -1;
        for (var i = 0; i < segments.length; i++) {
          if (pos >= segments[i].start && pos < segments[i].end) {
            activeIdx = i;
            break;
          }
          if (pos < segments[i].start) break;
        }
        return Wrap(
          spacing: 0,
          runSpacing: 2,
          children: List<Widget>.generate(segments.length, (i) {
            final seg = segments[i];
            final isActive = i == activeIdx;
            final hasTrailingSpace = i < segments.length - 1;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onSeek == null ? null : () => onSeek!(seg.start),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: const EdgeInsets.symmetric(
                    horizontal: 2, vertical: 1),
                decoration: BoxDecoration(
                  color: isActive ? highlightBg : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  hasTrailingSpace ? '${seg.text} ' : seg.text,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.32,
                    fontWeight:
                        isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? highlightColor : baseColor,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Эмодзи-чип сентимента (NLTagger / Android-эвристика). Показывается
/// только если сигнал достаточно сильный (см. `sentimentEmojiFor`).
class _SentimentChip extends StatelessWidget {
  const _SentimentChip({required this.emoji, required this.color});
  final String emoji;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        emoji,
        style: const TextStyle(fontSize: 13, height: 1),
      ),
    );
  }
}

/// Маленький чип со статистикой транскрипта — словам/мин и общее число
/// слов. Сейчас показываем под текстом, после строки с действиями.
class _TranscriptStatsChip extends StatelessWidget {
  const _TranscriptStatsChip({
    required this.wpm,
    required this.wordsCount,
    required this.color,
    required this.label,
  });

  final int wpm;
  final int wordsCount;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.speed_rounded, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


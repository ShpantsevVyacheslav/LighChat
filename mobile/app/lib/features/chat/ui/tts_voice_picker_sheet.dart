import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../data/chat_haptics.dart';
import '../data/local_text_to_speech.dart';

/// Bottom-sheet выбора голоса для функции «Прочитать вслух».
///
/// Показывает все установленные голоса для конкретного языка (по короткому
/// коду — `ru`, `en`, ...). Голоса сгруппированы по качеству: premium →
/// enhanced → default. Внутри группы — алфавитный порядок. Не-серьёзные
/// голоса (Albert/Bahh/Whisper и т.п.) скрыты за переключателем «Show all».
///
/// Выбор сохраняется через `LocalTextToSpeech.setPreferredVoiceIdentifier`
/// под ключом `chat.tts_voice.<lang>`. Сразу после выбора проигрывается
/// короткий sample-фраза этим голосом для подтверждения.
///
/// Открывается из `chat_screen` через [showTtsVoicePickerSheet] — обычно
/// из snackbar'а, который появляется после первого read-aloud.
Future<void> showTtsVoicePickerSheet(
  BuildContext context, {
  required String languageTag,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (_) => _TtsVoicePickerSheet(languageTag: languageTag),
  );
}

class _TtsVoicePickerSheet extends StatefulWidget {
  const _TtsVoicePickerSheet({required this.languageTag});

  final String languageTag;

  @override
  State<_TtsVoicePickerSheet> createState() => _TtsVoicePickerSheetState();
}

class _TtsVoicePickerSheetState extends State<_TtsVoicePickerSheet> {
  List<TtsVoice> _voices = const <TtsVoice>[];
  String? _currentIdentifier;
  bool _loading = true;
  bool _showAll = false;
  String? _busyVoice; // identifier — звучит sample, блокирует ре-тап

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final list =
        await LocalTextToSpeech.instance.listVoices(languageTag: widget.languageTag);
    final current =
        await LocalTextToSpeech.instance.getPreferredVoiceIdentifier(widget.languageTag);
    if (!mounted) return;
    setState(() {
      _voices = _sortVoices(list);
      _currentIdentifier = current;
      _loading = false;
    });
  }

  List<TtsVoice> _sortVoices(List<TtsVoice> input) {
    int qrank(TtsVoice v) {
      switch (v.quality) {
        case 'premium':
          return 3;
        case 'enhanced':
          return 2;
        default:
          return 1;
      }
    }

    final copy = [...input];
    copy.sort((a, b) {
      final dq = qrank(b) - qrank(a);
      if (dq != 0) return dq;
      return a.name.compareTo(b.name);
    });
    return copy;
  }

  String _qualityLabel(String q, AppLocalizations l10n) {
    switch (q) {
      case 'premium':
        return l10n.tts_voice_quality_premium;
      case 'enhanced':
        return l10n.tts_voice_quality_enhanced;
      default:
        return l10n.tts_voice_quality_default;
    }
  }

  Color _qualityColor(String q) {
    switch (q) {
      case 'premium':
        return const Color(0xFFFFC940); // gold
      case 'enhanced':
        return const Color(0xFF7C8DFF); // accent
      default:
        return const Color(0xFF8A93A1); // neutral
    }
  }

  Future<void> _pick(TtsVoice v) async {
    if (_busyVoice == v.identifier) return;
    setState(() => _busyVoice = v.identifier);
    await LocalTextToSpeech.instance
        .setPreferredVoiceIdentifier(widget.languageTag, v.identifier);
    if (!mounted) return;
    setState(() => _currentIdentifier = v.identifier);
    unawaited(ChatHaptics.instance.tick());
    // Проигрываем короткий sample — пользователь сразу слышит, что выбрал.
    final l10n = AppLocalizations.of(context)!;
    await LocalTextToSpeech.instance.speak(
      text: l10n.tts_voice_sample_phrase,
      languageTag: widget.languageTag,
      voiceIdentifier: v.identifier,
    );
    if (mounted) setState(() => _busyVoice = null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1B1E25) : Colors.white;
    final fg = isDark ? const Color(0xFFE6E7EA) : const Color(0xFF1A1C22);
    final divider =
        isDark ? const Color(0x14FFFFFF) : const Color(0x12000000);

    final visible = _showAll
        ? _voices
        : _voices.where((v) => !v.isNoveltyOrEloquence).toList(growable: false);
    final hasHiddenNovelty = _voices.any((v) => v.isNoveltyOrEloquence);

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: divider, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.30),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.record_voice_over_rounded,
                        size: 18,
                        color: Color(0xFF7C8DFF),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.tts_voice_picker_title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: fg,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.close_rounded, size: 20),
                        color: fg.withValues(alpha: 0.62),
                      ),
                    ],
                  ),
                ),
                if (_loading)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: fg.withValues(alpha: 0.5),
                      ),
                    ),
                  )
                else if (_voices.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    child: Text(
                      l10n.tts_voice_picker_empty,
                      style: TextStyle(
                        fontSize: 14,
                        color: fg.withValues(alpha: 0.62),
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: visible.length,
                      itemBuilder: (ctx, i) {
                        final v = visible[i];
                        final selected = v.identifier == _currentIdentifier;
                        final busy = _busyVoice == v.identifier;
                        return InkWell(
                          onTap: busy ? null : () => _pick(v),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: _qualityColor(v.quality)
                                        .withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  alignment: Alignment.center,
                                  child: busy
                                      ? SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 1.5,
                                            color: _qualityColor(v.quality),
                                          ),
                                        )
                                      : Icon(
                                          Icons.graphic_eq_rounded,
                                          size: 17,
                                          color: _qualityColor(v.quality),
                                        ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        v.name,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: selected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: fg,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${_qualityLabel(v.quality, l10n)} · ${v.language}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: fg.withValues(alpha: 0.62),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (selected)
                                  const Icon(
                                    Icons.check_rounded,
                                    size: 18,
                                    color: Color(0xFF7C8DFF),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                if (hasHiddenNovelty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: TextButton.icon(
                      onPressed: () => setState(() => _showAll = !_showAll),
                      icon: Icon(
                        _showAll
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 16,
                      ),
                      label: Text(
                        _showAll
                            ? l10n.tts_voice_picker_hide_novelty
                            : l10n.tts_voice_picker_show_novelty,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Text(
                    l10n.tts_voice_picker_install_hint,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: fg.withValues(alpha: 0.5),
                      height: 1.32,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

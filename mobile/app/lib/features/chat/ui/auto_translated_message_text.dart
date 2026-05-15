import 'dart:async';

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../data/local_message_translator.dart';
import '../data/local_text_language_detector.dart';

/// Обёртка над оригинальным `RichText` сообщения, которая при включённом
/// в настройках авто-переводе:
///  1. Детектит язык первого появления (через NLLanguageRecognizer).
///  2. Если язык ≠ языку UI — асинхронно переводит через `LocalMessageTranslator`
///     (ML Kit on-device, кэш в SQLite).
///  3. Показывает переведённый текст + мини-плашку «Переведено · Показать
///     оригинал». По тапу плашки можно переключиться обратно.
///
/// Если фича выключена или сообщение от меня — просто рендерит [original].
class AutoTranslatedMessageText extends StatefulWidget {
  const AutoTranslatedMessageText({
    super.key,
    required this.messageId,
    required this.originalPlainText,
    required this.original,
    required this.enabled,
    required this.isMine,
    required this.targetLanguage,
    required this.subtleColor,
    required this.accentColor,
  });

  /// Уникальный id сообщения — используется как cacheKey.
  final String messageId;

  /// Текст для детектора языка / переводчика (plain, без HTML).
  final String originalPlainText;

  /// Сам widget оригинального сообщения (RichText со spans). Показываем
  /// его если: фича off / своё сообщение / язык совпадает / перевод ещё
  /// идёт / пользователь нажал «Показать оригинал».
  final Widget original;

  /// Включён ли авто-перевод в настройках пользователя.
  final bool enabled;

  /// `true` — сообщение от меня, никогда не переводим.
  final bool isMine;

  /// Куда переводить — короткий ISO-код языка UI (`ru`, `en` итп).
  final String targetLanguage;

  /// Цвет «Переведено · ...» плашки.
  final Color subtleColor;

  /// Цвет линка «Показать оригинал».
  final Color accentColor;

  @override
  State<AutoTranslatedMessageText> createState() =>
      _AutoTranslatedMessageTextState();
}

class _AutoTranslatedMessageTextState extends State<AutoTranslatedMessageText> {
  String? _translated;
  bool _showingOriginal = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _maybeTranslate();
  }

  @override
  void didUpdateWidget(covariant AutoTranslatedMessageText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled ||
        oldWidget.originalPlainText != widget.originalPlainText ||
        oldWidget.targetLanguage != widget.targetLanguage) {
      _translated = null;
      _failed = false;
      _maybeTranslate();
    }
  }

  Future<void> _maybeTranslate() async {
    if (!widget.enabled || widget.isMine) return;
    final text = widget.originalPlainText.trim();
    if (text.length < 4) return;
    try {
      final det = await LocalTextLanguageDetector.instance.detect(text);
      if (!mounted) return;
      if (!det.isReliable) return;
      if (det.language.isEmpty || det.language == widget.targetLanguage) {
        return;
      }
      if (!LocalMessageTranslator.instance
          .supportsPair(from: det.language, to: widget.targetLanguage)) {
        return;
      }
      final result = await LocalMessageTranslator.instance.translate(
        cacheKey:
            'auto|${widget.messageId}|${det.language}→${widget.targetLanguage}',
        text: text,
        from: det.language,
        to: widget.targetLanguage,
      );
      if (!mounted) return;
      setState(() {
        _translated = result.trim();
        _failed = result.trim().isEmpty;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final translated = _translated;
    final shouldShowTranslated = widget.enabled &&
        !widget.isMine &&
        !_showingOriginal &&
        translated != null &&
        translated.isNotEmpty &&
        !_failed;

    if (!shouldShowTranslated) {
      // Если авто-перевод был применён, но юзер тапнул «оригинал», всё
      // равно показываем под текстом маленькую кнопку «Показать перевод»
      // чтобы можно было вернуться.
      final canToggleBack = widget.enabled &&
          !widget.isMine &&
          translated != null &&
          translated.isNotEmpty;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          widget.original,
          if (canToggleBack) ...[
            const SizedBox(height: 4),
            _toggleRow(
              icon: Icons.translate_rounded,
              label: AppLocalizations.of(context)!.message_show_translation,
              onTap: () => setState(() => _showingOriginal = false),
            ),
          ],
        ],
      );
    }

    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Сам переведённый текст. Стиль наследуется через DefaultTextStyle
        // (так же как и в исходном RichText), мы только переопределяем
        // содержимое.
        DefaultTextStyle.merge(
          style: const TextStyle(height: 1.32),
          child: SelectableText(translated),
        ),
        const SizedBox(height: 4),
        _toggleRow(
          icon: Icons.translate_rounded,
          label:
              '${l10n.message_auto_translated_label} · ${l10n.message_show_original}',
          onTap: () => setState(() => _showingOriginal = true),
        ),
      ],
    );
  }

  Widget _toggleRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: widget.subtleColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: widget.subtleColor,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

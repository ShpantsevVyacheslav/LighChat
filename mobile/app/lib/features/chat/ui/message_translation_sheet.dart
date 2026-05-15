import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';
import '../data/chat_haptics.dart';
import '../data/local_message_translator.dart';

/// Bottom sheet с переводом текстового сообщения. On-device через ML Kit;
/// кэшируется в SQLite, повторный показ — мгновенный.
///
/// Сценарии:
///  - язык сообщения != UI → переводим на UI
///  - язык сообщения == UI → переводим на «второй язык» (для русского/прочих
///    это `en`, для английского — `ru`)
///  - в любом случае пользователь может вручную поменять source/target
///    через picker-чипы и кнопку swap
class MessageTranslationSheet extends StatefulWidget {
  const MessageTranslationSheet({
    super.key,
    required this.messageId,
    required this.originalText,
    required this.from,
    required this.to,
  });

  final String messageId;
  final String originalText;
  final String from;
  final String to;

  static Future<void> show(
    BuildContext context, {
    required String messageId,
    required String originalText,
    required String from,
    required String to,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => MessageTranslationSheet(
        messageId: messageId,
        originalText: originalText,
        from: from,
        to: to,
      ),
    );
  }

  @override
  State<MessageTranslationSheet> createState() =>
      _MessageTranslationSheetState();
}

class _MessageTranslationSheetState extends State<MessageTranslationSheet> {
  late String _from;
  late String _to;
  // Текущий source-текст. На старте = `widget.originalText`; после swap'а
  // становится бывшим переводом (т.е. тем, что лежало в нижней карточке).
  // Так swap правильно «переворачивает» и направление, и контент.
  late String _sourceText;
  String? _translated;
  String? _error;
  TranslationPhase? _phase;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _from = widget.from;
    _to = widget.to;
    _sourceText = widget.originalText;
    WidgetsBinding.instance.addPostFrameCallback((_) => _translate());
  }

  Future<void> _translate() async {
    setState(() {
      _busy = true;
      _phase = TranslationPhase.translating;
      _error = null;
      _translated = null;
    });
    try {
      final result = await LocalMessageTranslator.instance.translate(
        cacheKey: 'text|${widget.messageId}|$_from→$_to|${_sourceText.hashCode}',
        text: _sourceText,
        from: _from,
        to: _to,
        onPhase: (p) {
          if (!mounted) return;
          setState(() => _phase = p);
        },
      );
      if (!mounted) return;
      setState(() => _translated = result);
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      setState(() {
        _error = e is UnsupportedTranslationException
            ? (l10n?.voice_translate_unsupported ?? e.toString())
            : (l10n?.voice_translate_failed(e.toString()) ?? e.toString());
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _phase = null;
        });
      }
    }
  }

  void _changeFrom(String code) {
    if (code == _from) return;
    if (code == _to) {
      // Выбор source == текущему target — это и есть swap. Делегируем,
      // чтобы единообразно обновить и `_sourceText` / `_translated`.
      _swap();
      return;
    }
    setState(() => _from = code);
    unawaited(ChatHaptics.instance.selectionChanged());
    _translate();
  }

  void _changeTo(String code) {
    if (code == _to) return;
    if (code == _from) {
      _swap();
      return;
    }
    setState(() => _to = code);
    unawaited(ChatHaptics.instance.selectionChanged());
    _translate();
  }

  void _swap() {
    if (_from == _to) return;
    final prevTranslated = _translated;
    final prevSource = _sourceText;
    setState(() {
      final tmpLang = _from;
      _from = _to;
      _to = tmpLang;
      // Если перевод уже посчитан — он становится новым source,
      // а старый source — мгновенный «перевод» (тот же текст, что и
      // лежал в нижней карточке до свопа). Это даёт мгновенный
      // визуальный отклик, без второго прохода ML Kit.
      if (prevTranslated != null && prevTranslated.trim().isNotEmpty) {
        _sourceText = prevTranslated;
        _translated = prevSource;
      } else {
        // Перевод ещё не успел посчитаться — просто свапаем направление,
        // source остаётся прежним, target пересчитаем.
        _translated = null;
      }
    });
    unawaited(ChatHaptics.instance.tick());
    // После свопа translated уже корректен (prevSource), повторный вызов
    // переводчика не нужен — он бы дал тот же текст, что мы уже показали.
    // Запускаем только если результат не был готов.
    if (_translated == null) _translate();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final isDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final palette = _SheetPalette.forBrightness(isDark);
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Container(
          color: palette.sheetBg,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DragHandle(color: palette.dragHandle),
                  const SizedBox(height: 14),
                  _Header(palette: palette, title: l10n.voice_translate_action),
                  const SizedBox(height: 16),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _LanguageCard(
                            palette: palette,
                            languageCode: _from,
                            text: _sourceText,
                            muted: true,
                            onTapPill: () => _showLanguagePicker(
                              context: context,
                              palette: palette,
                              current: _from,
                              onPick: _changeFrom,
                            ),
                          ),
                          _SwapButton(palette: palette, onTap: _swap),
                          _LanguageCard(
                            palette: palette,
                            languageCode: _to,
                            text: _translated ?? '',
                            placeholder: _busyOrErrorPlaceholder(l10n),
                            muted: false,
                            onTapPill: () => _showLanguagePicker(
                              context: context,
                              palette: palette,
                              current: _to,
                              onPick: _changeTo,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _Actions(
                    palette: palette,
                    canCopy: _translated != null && _translated!.isNotEmpty,
                    copyLabel: l10n.voice_transcript_copy,
                    closeLabel: l10n.chat_list_action_close,
                    onCopy: () async {
                      final messenger = ScaffoldMessenger.maybeOf(context);
                      await Clipboard.setData(
                          ClipboardData(text: _translated ?? ''));
                      unawaited(ChatHaptics.instance.success());
                      messenger?.showSnackBar(
                        SnackBar(
                          duration: const Duration(milliseconds: 1200),
                          content: Text(l10n.voice_transcript_copy),
                        ),
                      );
                    },
                    onClose: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget? _busyOrErrorPlaceholder(AppLocalizations l10n) {
    if (_busy) {
      return _InlineStatus(
        label: _phase == TranslationPhase.downloading
            ? l10n.voice_translate_downloading_model
            : l10n.voice_translate_in_progress,
        spinner: true,
      );
    }
    if (_error != null) {
      return _InlineStatus(label: _error!, isError: true);
    }
    return null;
  }

  Future<void> _showLanguagePicker({
    required BuildContext context,
    required _SheetPalette palette,
    required String current,
    required void Function(String) onPick,
  }) async {
    final langs = LocalMessageTranslator.instance.supportedLanguageCodes();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Container(
            color: palette.sheetBg,
            child: SafeArea(
              top: false,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.6,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    _DragHandle(color: palette.dragHandle),
                    const SizedBox(height: 8),
                    Flexible(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        itemCount: langs.length,
                        itemBuilder: (_, i) {
                          final code = langs[i];
                          final selected = code == current;
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.of(ctx).maybePop();
                                onPick(code);
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? palette.accent.withValues(alpha: 0.12)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 38,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 3,
                                      ),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: palette.langPillBg,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        code.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                          color: palette.langPillText,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _languageDisplayName(code),
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: palette.bodyColor,
                                        ),
                                      ),
                                    ),
                                    if (selected)
                                      Icon(
                                        Icons.check_rounded,
                                        size: 20,
                                        color: palette.accent,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static String _languageDisplayName(String code) {
    const names = <String, String>{
      'en': 'English',
      'ru': 'Русский',
      'es': 'Español',
      'pt': 'Português',
      'tr': 'Türkçe',
      'id': 'Indonesia',
      'de': 'Deutsch',
      'fr': 'Français',
      'it': 'Italiano',
      'zh': '中文',
      'ja': '日本語',
      'ar': 'العربية',
      'uk': 'Українська',
      'be': 'Беларуская',
      'pl': 'Polski',
      'cs': 'Čeština',
      'nl': 'Nederlands',
      'sv': 'Svenska',
      'no': 'Norsk',
      'fi': 'Suomi',
      'da': 'Dansk',
      'el': 'Ελληνικά',
      'he': 'עברית',
      'th': 'ไทย',
      'vi': 'Tiếng Việt',
      'hi': 'हिन्दी',
      'ko': '한국어',
      'ro': 'Română',
      'hu': 'Magyar',
      'bg': 'Български',
      'ca': 'Català',
      'hr': 'Hrvatski',
      'sk': 'Slovenčina',
      'sl': 'Slovenščina',
      'lv': 'Latviešu',
      'lt': 'Lietuvių',
      'et': 'Eesti',
    };
    return names[code] ?? code.toUpperCase();
  }
}

class _SheetPalette {
  const _SheetPalette({
    required this.sheetBg,
    required this.cardBg,
    required this.cardBgMuted,
    required this.cardBorder,
    required this.dragHandle,
    required this.titleColor,
    required this.bodyColor,
    required this.mutedTextColor,
    required this.langPillBg,
    required this.langPillText,
    required this.accent,
    required this.accentSoft,
    required this.accentOn,
    required this.divider,
    required this.errorColor,
    required this.iconColor,
  });

  static _SheetPalette forBrightness(bool isDark) {
    if (isDark) {
      const accent = Color(0xFF7C8DFF);
      return _SheetPalette(
        sheetBg: const Color(0xFF15171C),
        cardBg: const Color(0xFF1E2127),
        cardBgMuted: const Color(0xFF1A1C22),
        cardBorder: const Color(0x14FFFFFF),
        dragHandle: const Color(0x33FFFFFF),
        titleColor: const Color(0xFFEDEEF2),
        bodyColor: const Color(0xFFE6E7EA),
        mutedTextColor: const Color(0xFFA0A4AD),
        langPillBg: const Color(0xFF262A33),
        langPillText: const Color(0xFFB5BBC6),
        accent: accent,
        accentSoft: accent.withValues(alpha: 0.14),
        accentOn: const Color(0xFF0E1115),
        divider: const Color(0x1AFFFFFF),
        errorColor: const Color(0xFFFF8A80),
        iconColor: const Color(0xFFB5BBC6),
      );
    }
    const accent = Color(0xFF4F5BD5);
    return _SheetPalette(
      sheetBg: const Color(0xFFF5F6F8),
      cardBg: const Color(0xFFFFFFFF),
      cardBgMuted: const Color(0xFFEFF1F4),
      cardBorder: const Color(0x0F000000),
      dragHandle: const Color(0x33000000),
      titleColor: const Color(0xFF14161A),
      bodyColor: const Color(0xFF1A1C22),
      mutedTextColor: const Color(0xFF5C6470),
      langPillBg: const Color(0xFFE7EAF0),
      langPillText: const Color(0xFF454B57),
      accent: accent,
      accentSoft: accent.withValues(alpha: 0.12),
      accentOn: Colors.white,
      divider: const Color(0x14000000),
      errorColor: const Color(0xFFD32F2F),
      iconColor: const Color(0xFF5C6470),
    );
  }

  final Color sheetBg;
  final Color cardBg;
  final Color cardBgMuted;
  final Color cardBorder;
  final Color dragHandle;
  final Color titleColor;
  final Color bodyColor;
  final Color mutedTextColor;
  final Color langPillBg;
  final Color langPillText;
  final Color accent;
  final Color accentSoft;
  final Color accentOn;
  final Color divider;
  final Color errorColor;
  final Color iconColor;
}

class _DragHandle extends StatelessWidget {
  const _DragHandle({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 38,
        height: 4,
        decoration:
            BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.palette, required this.title});
  final _SheetPalette palette;
  final String title;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: palette.accentSoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.translate_rounded,
            size: 18,
            color: palette.accent,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: palette.titleColor,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.palette,
    required this.languageCode,
    required this.text,
    required this.muted,
    required this.onTapPill,
    this.placeholder,
  });

  final _SheetPalette palette;
  final String languageCode;
  final String text;
  final bool muted;
  final VoidCallback onTapPill;
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: muted ? palette.cardBgMuted : palette.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.cardBorder, width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTapPill,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: palette.langPillBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      languageCode.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: palette.langPillText,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.expand_more_rounded,
                      size: 14,
                      color: palette.langPillText,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (placeholder != null)
            placeholder!
          else
            SelectableText(
              text,
              style: TextStyle(
                fontSize: 15.5,
                height: 1.4,
                fontWeight: muted ? FontWeight.w500 : FontWeight.w600,
                color: muted
                    ? palette.mutedTextColor
                    : palette.bodyColor,
              ),
            ),
        ],
      ),
    );
  }
}

class _SwapButton extends StatelessWidget {
  const _SwapButton({required this.palette, required this.onTap});
  final _SheetPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: palette.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: palette.cardBorder, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: palette.accent.withValues(alpha: 0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.swap_vert_rounded,
                size: 22,
                color: palette.accent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineStatus extends StatelessWidget {
  const _InlineStatus({
    required this.label,
    this.spinner = false,
    this.isError = false,
  });

  final String label;
  final bool spinner;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final palette = _SheetPalette.forBrightness(
      MediaQuery.platformBrightnessOf(context) == Brightness.dark,
    );
    return Row(
      children: [
        if (spinner) ...[
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(palette.accent),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isError ? palette.errorColor : palette.mutedTextColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.palette,
    required this.canCopy,
    required this.copyLabel,
    required this.closeLabel,
    required this.onCopy,
    required this.onClose,
  });

  final _SheetPalette palette;
  final bool canCopy;
  final String copyLabel;
  final String closeLabel;
  final Future<void> Function() onCopy;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: _PrimaryActionButton(
            palette: palette,
            label: copyLabel,
            icon: Icons.copy_all_rounded,
            enabled: canCopy,
            onTap: canCopy ? () => onCopy() : null,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 4,
          child: _GhostActionButton(
            palette: palette,
            label: closeLabel,
            onTap: onClose,
          ),
        ),
      ],
    );
  }
}

/// Premium «filled-glass» кнопка: gradient + soft shadow + scale on press.
/// Используется как primary CTA («Скопировать»).
class _PrimaryActionButton extends StatefulWidget {
  const _PrimaryActionButton({
    required this.palette,
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final _SheetPalette palette;
  final String label;
  final IconData icon;
  final bool enabled;
  final Future<void> Function()? onTap;

  @override
  State<_PrimaryActionButton> createState() => _PrimaryActionButtonState();
}

class _PrimaryActionButtonState extends State<_PrimaryActionButton> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed == v) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    final disabled = !widget.enabled || widget.onTap == null;
    return AnimatedScale(
      duration: const Duration(milliseconds: 110),
      scale: _pressed && !disabled ? 0.97 : 1,
      curve: Curves.easeOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled ? null : () => widget.onTap!.call(),
          onTapDown: (_) => _setPressed(true),
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: disabled
                  ? null
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        p.accent.withValues(alpha: 0.92),
                        p.accent,
                      ],
                    ),
              color: disabled ? p.cardBgMuted : null,
              boxShadow: disabled
                  ? null
                  : [
                      BoxShadow(
                        color: p.accent.withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.icon,
                  size: 18,
                  color: disabled ? p.mutedTextColor : p.accentOn,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.1,
                    color: disabled ? p.mutedTextColor : p.accentOn,
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

/// Тонкая «ghost» кнопка для secondary action («Закрыть»). Без фона, только
/// контур + лёгкий accent text. Premium-look за счёт отсутствия лишнего.
class _GhostActionButton extends StatefulWidget {
  const _GhostActionButton({
    required this.palette,
    required this.label,
    required this.onTap,
  });

  final _SheetPalette palette;
  final String label;
  final VoidCallback onTap;

  @override
  State<_GhostActionButton> createState() => _GhostActionButtonState();
}

class _GhostActionButtonState extends State<_GhostActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    return AnimatedScale(
      duration: const Duration(milliseconds: 110),
      scale: _pressed ? 0.97 : 1,
      curve: Curves.easeOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: p.cardBg,
              border: Border.all(color: p.cardBorder, width: 1),
            ),
            alignment: Alignment.center,
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.1,
                color: p.bodyColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

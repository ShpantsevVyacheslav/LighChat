import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';
import '../data/local_message_translator.dart';

/// Bottom sheet с переводом текстового сообщения. On-device через ML Kit;
/// кэшируется в SQLite, повторный показ — мгновенный.
///
/// Дизайн намеренно использует **собственную нейтральную палитру** и не
/// наследует цвета чат-обоев/темы. Это сделано для того, чтобы шторка
/// читалась одинаково в любом чате с любыми обоями.
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

  /// Показать как modal bottom sheet с принудительно прозрачным фоном —
  /// мы рисуем свой rounded-контейнер с собственной палитрой.
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
  String? _translated;
  String? _error;
  TranslationPhase? _phase;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _translate());
  }

  Future<void> _translate() async {
    setState(() {
      _busy = true;
      _phase = TranslationPhase.translating;
      _error = null;
    });
    try {
      final result = await LocalMessageTranslator.instance.translate(
        cacheKey: 'text|${widget.messageId}|${widget.from}→${widget.to}',
        text: widget.originalText,
        from: widget.from,
        to: widget.to,
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
                            languageCode: widget.from,
                            text: widget.originalText,
                            muted: true,
                          ),
                          _Arrow(palette: palette),
                          _LanguageCard(
                            palette: palette,
                            languageCode: widget.to,
                            text: _translated ?? '',
                            placeholder: _busyOrErrorPlaceholder(l10n),
                            muted: false,
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
    required this.accentOn,
    required this.divider,
    required this.errorColor,
    required this.iconColor,
  });

  /// Нейтральные палитры — не наследуют тон от чата/обоев.
  /// Для светлой темы: cool gray; для тёмной: near-black с акцентом цвета.
  static _SheetPalette forBrightness(bool isDark) {
    if (isDark) {
      const accent = Color(0xFF7C8DFF); // спокойный нейтральный синий-индиго
      return const _SheetPalette(
        sheetBg: Color(0xFF15171C),
        cardBg: Color(0xFF1E2127),
        cardBgMuted: Color(0xFF1A1C22),
        cardBorder: Color(0x14FFFFFF),
        dragHandle: Color(0x33FFFFFF),
        titleColor: Color(0xFFEDEEF2),
        bodyColor: Color(0xFFE6E7EA),
        mutedTextColor: Color(0xFFA0A4AD),
        langPillBg: Color(0xFF262A33),
        langPillText: Color(0xFFB5BBC6),
        accent: accent,
        accentOn: Color(0xFF0E1115),
        divider: Color(0x1AFFFFFF),
        errorColor: Color(0xFFFF8A80),
        iconColor: Color(0xFFB5BBC6),
      );
    }
    const accent = Color(0xFF4F5BD5);
    return const _SheetPalette(
      sheetBg: Color(0xFFF5F6F8),
      cardBg: Color(0xFFFFFFFF),
      cardBgMuted: Color(0xFFEFF1F4),
      cardBorder: Color(0x0F000000),
      dragHandle: Color(0x33000000),
      titleColor: Color(0xFF14161A),
      bodyColor: Color(0xFF1A1C22),
      mutedTextColor: Color(0xFF5C6470),
      langPillBg: Color(0xFFE7EAF0),
      langPillText: Color(0xFF454B57),
      accent: accent,
      accentOn: Colors.white,
      divider: Color(0x14000000),
      errorColor: Color(0xFFD32F2F),
      iconColor: Color(0xFF5C6470),
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
            color: palette.accent.withValues(alpha: 0.12),
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
    this.placeholder,
  });

  final _SheetPalette palette;
  final String languageCode;
  final String text;
  final bool muted;
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
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: palette.langPillBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              languageCode.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: palette.langPillText,
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

class _Arrow extends StatelessWidget {
  const _Arrow({required this.palette});
  final _SheetPalette palette;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Center(
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: palette.cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: palette.cardBorder, width: 1),
          ),
          child: Icon(
            Icons.arrow_downward_rounded,
            size: 16,
            color: palette.iconColor,
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
              valueColor:
                  AlwaysStoppedAnimation<Color>(palette.accent),
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
          child: TextButton.icon(
            onPressed: canCopy ? () => onCopy() : null,
            style: TextButton.styleFrom(
              foregroundColor: palette.bodyColor,
              disabledForegroundColor: palette.mutedTextColor.withValues(
                alpha: 0.5,
              ),
              backgroundColor: palette.cardBg,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: palette.cardBorder, width: 1),
              ),
            ),
            icon: Icon(
              Icons.copy_all_outlined,
              size: 18,
              color: canCopy ? palette.iconColor : palette.mutedTextColor,
            ),
            label: Text(
              copyLabel,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton(
            onPressed: onClose,
            style: FilledButton.styleFrom(
              backgroundColor: palette.accent,
              foregroundColor: palette.accentOn,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            child: Text(closeLabel),
          ),
        ),
      ],
    );
  }
}

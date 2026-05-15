import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';
import '../data/apple_intelligence.dart';
import '../data/chat_haptics.dart';

/// Premium bottom-sheet для AI-действий (TL;DR / Rewrite / Digest).
/// Универсальный: принимает заголовок, источник (`original`), задачу
/// (`task` — async-функция, возвращающая строку результата) и набор
/// быстрых вариантов стиля для re-run.
///
/// UX:
///  - sheet открывается со spinner-ом + статусом «Пишу…»
///  - по завершении показывает результат в premium-карточке
///  - снизу: «Скопировать», «Заменить» (опц.) и «Закрыть»
///  - если `styleVariants` задан — над результатом показываем pill-row
///    с вариантами, тап → перезапуск task с новым стилем
class AiTextActionSheet extends StatefulWidget {
  const AiTextActionSheet({
    super.key,
    required this.title,
    required this.original,
    required this.run,
    this.applyLabel,
    this.onApply,
    this.styleVariants = const [],
    this.initialStyleId,
  });

  /// Заголовок шторки (например «Краткое содержание» / «Переписать»).
  final String title;

  /// Исходный текст — показывается в muted-карточке сверху для контекста.
  final String original;

  /// Сама работа. Получает `styleId` (или `null` если стиля нет) и возвращает
  /// результат-строку или `null` при ошибке/недоступности модели.
  final Future<String?> Function(String? styleId) run;

  /// Текст кнопки «Заменить» (опц.). Если `null` — кнопка скрыта.
  final String? applyLabel;

  /// Колбэк когда юзер тапнул «Заменить». Получает финальный результат.
  final void Function(String result)? onApply;

  /// Доступные стили для переключения сверху (pill-row). Если пуст —
  /// строки не будет, run будет вызвана один раз с `null`.
  final List<AiStyleVariant> styleVariants;

  /// Id первоначально выбранного стиля. Если `null` и styleVariants
  /// непустой — берём первый.
  final String? initialStyleId;

  static Future<void> show({
    required BuildContext context,
    required String title,
    required String original,
    required Future<String?> Function(String? styleId) run,
    String? applyLabel,
    void Function(String result)? onApply,
    List<AiStyleVariant> styleVariants = const [],
    String? initialStyleId,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => AiTextActionSheet(
        title: title,
        original: original,
        run: run,
        applyLabel: applyLabel,
        onApply: onApply,
        styleVariants: styleVariants,
        initialStyleId: initialStyleId,
      ),
    );
  }

  @override
  State<AiTextActionSheet> createState() => _AiTextActionSheetState();
}

class AiStyleVariant {
  const AiStyleVariant({required this.id, required this.label, required this.icon});
  final String id;
  final String label;
  final IconData icon;
}

class _AiTextActionSheetState extends State<AiTextActionSheet> {
  String? _styleId;
  String? _result;
  bool _busy = false;
  bool _failed = false;
  String? _failureStatus;

  @override
  void initState() {
    super.initState();
    if (widget.styleVariants.isNotEmpty) {
      _styleId = widget.initialStyleId ?? widget.styleVariants.first.id;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    setState(() {
      _busy = true;
      _failed = false;
      _failureStatus = null;
      _result = null;
    });
    final out = await widget.run(_styleId);
    String? status;
    if (out == null) {
      // Узнаём детальную причину — модель ещё качается / выключено в
      // Настройках / устройство не поддерживает.
      status = await AppleIntelligence.instance.availabilityStatus();
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _failed = out == null;
      _failureStatus = status;
      _result = out;
    });
  }

  String _failureMessage(AppLocalizations l10n) {
    switch (_failureStatus) {
      case 'modelNotReady':
        return l10n.ai_status_model_not_ready;
      case 'appleIntelligenceNotEnabled':
        return l10n.ai_status_not_enabled;
      case 'deviceNotEligible':
        return l10n.ai_status_device_not_eligible;
      case 'unsupportedOs':
      case 'sdkMissing':
        return l10n.ai_status_unsupported_os;
      case 'available':
        // Модель доступна, но run вернул null — значит run-метод сам
        // упал. Показываем общую ошибку.
        return l10n.ai_action_failed;
      default:
        return l10n.ai_status_unknown;
    }
  }

  void _changeStyle(String id) {
    if (_busy) return;
    if (id == _styleId) return;
    unawaited(ChatHaptics.instance.selectionChanged());
    setState(() => _styleId = id);
    _run();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final palette = _Palette.forBrightness(isDark);
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
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
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: palette.dragHandle,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _Header(palette: palette, title: widget.title),
                    const SizedBox(height: 16),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (widget.styleVariants.isNotEmpty) ...[
                              _StyleRow(
                                palette: palette,
                                variants: widget.styleVariants,
                                selectedId: _styleId,
                                onPick: _changeStyle,
                                busy: _busy,
                              ),
                              const SizedBox(height: 14),
                            ],
                            _OriginalCard(
                              palette: palette,
                              text: widget.original,
                            ),
                            const SizedBox(height: 10),
                            _ResultCard(
                              palette: palette,
                              text: _result,
                              busy: _busy,
                              failed: _failed,
                              busyLabel: l10n.ai_action_thinking,
                              failedLabel: _failureMessage(l10n),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _Actions(
                      palette: palette,
                      canCopy: (_result ?? '').isNotEmpty,
                      copyLabel: l10n.voice_transcript_copy,
                      applyLabel: widget.applyLabel,
                      closeLabel: l10n.chat_list_action_close,
                      onCopy: () async {
                        final m = ScaffoldMessenger.maybeOf(context);
                        await Clipboard.setData(
                          ClipboardData(text: _result ?? ''),
                        );
                        unawaited(ChatHaptics.instance.success());
                        m?.showSnackBar(
                          SnackBar(
                            duration: const Duration(milliseconds: 1200),
                            content: Text(l10n.voice_transcript_copy),
                          ),
                        );
                      },
                      onApply: (widget.applyLabel != null &&
                              widget.onApply != null)
                          ? () {
                              final r = _result;
                              if (r == null || r.isEmpty) return;
                              widget.onApply!(r);
                              Navigator.of(context).maybePop();
                            }
                          : null,
                      onClose: () => Navigator.of(context).maybePop(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Palette {
  const _Palette({
    required this.sheetBg,
    required this.cardBg,
    required this.cardBgMuted,
    required this.cardBorder,
    required this.dragHandle,
    required this.titleColor,
    required this.bodyColor,
    required this.mutedTextColor,
    required this.accent,
    required this.accentSoft,
    required this.accentOn,
    required this.errorColor,
    required this.iconColor,
  });

  static _Palette forBrightness(bool isDark) {
    if (isDark) {
      const accent = Color(0xFF7C8DFF);
      return _Palette(
        sheetBg: const Color(0xFF15171C).withValues(alpha: 0.94),
        cardBg: const Color(0xFF1E2127),
        cardBgMuted: const Color(0xFF1A1C22),
        cardBorder: const Color(0x14FFFFFF),
        dragHandle: const Color(0x33FFFFFF),
        titleColor: const Color(0xFFEDEEF2),
        bodyColor: const Color(0xFFE6E7EA),
        mutedTextColor: const Color(0xFFA0A4AD),
        accent: accent,
        accentSoft: accent.withValues(alpha: 0.14),
        accentOn: const Color(0xFF0E1115),
        errorColor: const Color(0xFFFF8A80),
        iconColor: const Color(0xFFB5BBC6),
      );
    }
    const accent = Color(0xFF4F5BD5);
    return _Palette(
      sheetBg: const Color(0xFFF5F6F8).withValues(alpha: 0.94),
      cardBg: const Color(0xFFFFFFFF),
      cardBgMuted: const Color(0xFFEFF1F4),
      cardBorder: const Color(0x0F000000),
      dragHandle: const Color(0x33000000),
      titleColor: const Color(0xFF14161A),
      bodyColor: const Color(0xFF1A1C22),
      mutedTextColor: const Color(0xFF5C6470),
      accent: accent,
      accentSoft: accent.withValues(alpha: 0.12),
      accentOn: Colors.white,
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
  final Color accent;
  final Color accentSoft;
  final Color accentOn;
  final Color errorColor;
  final Color iconColor;
}

class _Header extends StatelessWidget {
  const _Header({required this.palette, required this.title});
  final _Palette palette;
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
            Icons.auto_awesome_rounded,
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

class _StyleRow extends StatelessWidget {
  const _StyleRow({
    required this.palette,
    required this.variants,
    required this.selectedId,
    required this.onPick,
    required this.busy,
  });

  final _Palette palette;
  final List<AiStyleVariant> variants;
  final String? selectedId;
  final void Function(String id) onPick;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: variants.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final v = variants[i];
          final selected = v.id == selectedId;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: busy ? null : () => onPick(v.id),
              borderRadius: BorderRadius.circular(18),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: selected ? palette.accent : palette.cardBgMuted,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: selected
                        ? palette.accent
                        : palette.cardBorder,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      v.icon,
                      size: 14,
                      color:
                          selected ? palette.accentOn : palette.iconColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      v.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? palette.accentOn
                            : palette.bodyColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OriginalCard extends StatelessWidget {
  const _OriginalCard({required this.palette, required this.text});
  final _Palette palette;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: palette.cardBgMuted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.cardBorder, width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          height: 1.4,
          fontWeight: FontWeight.w500,
          color: palette.mutedTextColor,
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.palette,
    required this.text,
    required this.busy,
    required this.failed,
    required this.busyLabel,
    required this.failedLabel,
  });

  final _Palette palette;
  final String? text;
  final bool busy;
  final bool failed;
  final String busyLabel;
  final String failedLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: palette.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.accentSoft, width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      constraints: const BoxConstraints(minHeight: 56),
      child: _content(),
    );
  }

  Widget _content() {
    if (busy) {
      return Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(palette.accent),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              busyLabel,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: palette.mutedTextColor,
              ),
            ),
          ),
        ],
      );
    }
    if (failed) {
      return Text(
        failedLabel,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: palette.errorColor,
        ),
      );
    }
    return SelectableText(
      text ?? '',
      style: TextStyle(
        fontSize: 15.5,
        height: 1.4,
        fontWeight: FontWeight.w600,
        color: palette.bodyColor,
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.palette,
    required this.canCopy,
    required this.copyLabel,
    required this.applyLabel,
    required this.closeLabel,
    required this.onCopy,
    required this.onApply,
    required this.onClose,
  });

  final _Palette palette;
  final bool canCopy;
  final String copyLabel;
  final String? applyLabel;
  final String closeLabel;
  final Future<void> Function() onCopy;
  final VoidCallback? onApply;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (applyLabel != null && onApply != null) ...[
          Expanded(
            flex: 5,
            child: _PrimaryActionButton(
              palette: palette,
              label: applyLabel!,
              icon: Icons.check_rounded,
              enabled: canCopy,
              onTap: canCopy ? () async => onApply!() : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 4,
            child: _GhostActionButton(
              palette: palette,
              label: copyLabel,
              icon: Icons.copy_all_rounded,
              onTap: canCopy ? () => onCopy() : null,
            ),
          ),
        ] else ...[
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
              icon: null,
              onTap: () async => onClose(),
            ),
          ),
        ],
      ],
    );
  }
}

class _PrimaryActionButton extends StatefulWidget {
  const _PrimaryActionButton({
    required this.palette,
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final _Palette palette;
  final String label;
  final IconData icon;
  final bool enabled;
  final Future<void> Function()? onTap;

  @override
  State<_PrimaryActionButton> createState() => _PrimaryActionButtonState();
}

class _PrimaryActionButtonState extends State<_PrimaryActionButton> {
  bool _pressed = false;

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
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
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
                      colors: [p.accent.withValues(alpha: 0.92), p.accent],
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

class _GhostActionButton extends StatefulWidget {
  const _GhostActionButton({
    required this.palette,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final _Palette palette;
  final String label;
  final IconData? icon;
  final Future<void> Function()? onTap;

  @override
  State<_GhostActionButton> createState() => _GhostActionButtonState();
}

class _GhostActionButtonState extends State<_GhostActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    final disabled = widget.onTap == null;
    return AnimatedScale(
      duration: const Duration(milliseconds: 110),
      scale: _pressed && !disabled ? 0.97 : 1,
      curve: Curves.easeOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled ? null : () => widget.onTap!.call(),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    size: 18,
                    color: disabled ? p.mutedTextColor : p.bodyColor,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                    color: disabled ? p.mutedTextColor : p.bodyColor,
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

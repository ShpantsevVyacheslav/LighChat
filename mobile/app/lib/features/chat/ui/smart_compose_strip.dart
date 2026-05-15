import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../l10n/app_localizations.dart';
import '../data/apple_intelligence.dart';
import '../data/chat_haptics.dart';

/// Идентификаторы стилей, которые передаём в Foundation Models через
/// [AppleIntelligence.rewrite]. Имена синхронизированы со switch'ем в
/// `AppleIntelligenceBridge.swift::rewritePrompt` — менять только парно.
class _RewriteStyle {
  const _RewriteStyle({
    required this.id,
    required this.icon,
    required this.label,
  });
  final String id;
  final IconData icon;
  final String Function(AppLocalizations l10n) label;
}

final List<_RewriteStyle> _kRewriteStyles = [
  _RewriteStyle(
    id: 'friendly',
    icon: Icons.sentiment_satisfied_alt_rounded,
    label: (l) => l.ai_style_friendly,
  ),
  _RewriteStyle(
    id: 'formal',
    icon: Icons.business_center_rounded,
    label: (l) => l.ai_style_formal,
  ),
  _RewriteStyle(
    id: 'youth',
    icon: Icons.flash_on_rounded,
    label: (l) => l.ai_style_youth,
  ),
  _RewriteStyle(
    id: 'strict',
    icon: Icons.gavel_rounded,
    label: (l) => l.ai_style_strict,
  ),
  _RewriteStyle(
    id: 'blatnoy',
    icon: Icons.local_bar_rounded,
    label: (l) => l.ai_style_blatnoy,
  ),
  _RewriteStyle(
    id: 'funny',
    icon: Icons.emoji_emotions_rounded,
    label: (l) => l.ai_style_funny,
  ),
  _RewriteStyle(
    id: 'romantic',
    icon: Icons.favorite_rounded,
    label: (l) => l.ai_style_romantic,
  ),
  _RewriteStyle(
    id: 'sarcastic',
    icon: Icons.theater_comedy_rounded,
    label: (l) => l.ai_style_sarcastic,
  ),
  _RewriteStyle(
    id: 'shorter',
    icon: Icons.compress_rounded,
    label: (l) => l.ai_style_shorter,
  ),
  _RewriteStyle(
    id: 'longer',
    icon: Icons.expand_rounded,
    label: (l) => l.ai_style_longer,
  ),
  _RewriteStyle(
    id: 'proofread',
    icon: Icons.spellcheck_rounded,
    label: (l) => l.ai_style_proofread,
  ),
];

const String _kLastStyleKey = 'chat.smart_compose_last_style';

/// On-demand AI rewrite над композером. **Не автоматически** — модель
/// дёргается только когда пользователь явно нажимает sparkle-иконку. Без
/// этого виджет тихо стоит, накладных нет.
///
/// Состояния:
///  - **idle** — есть текст ≥4 символов: показываем маленькую sparkle-иконку.
///  - **loading** — после тапа: вместо иконки spinner, фоновый запрос к
///    Foundation Models (`rewrite`, style: friendly).
///  - **preview** — модель ответила: pill с переписанным текстом. Тап = заменить
///    текст в композере, long-press / крестик = отменить.
///  - **undo** — после первого применения AI-правки в композере появляется
///    кнопка «↶ Undo» рядом с sparkle. Она НЕ ограничена таймером: всегда
///    возвращает к исходному тексту, который пользователь набрал до первой
///    AI-замены. Сбрасывается только когда композер очищается (например,
///    после отправки сообщения). Между тапами Undo пользователь может
///    редактировать текст и снова жать sparkle — AI пересчитает rewrite с
///    учётом правок, но undo-цель остаётся та же.
///
/// На устройствах без Apple Intelligence (`aiAvailable=false`) иконка не
/// показывается, listener'ы не вешаются.
class SmartComposeStrip extends StatefulWidget {
  const SmartComposeStrip({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.aiAvailable,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool aiAvailable;

  @override
  State<SmartComposeStrip> createState() => _SmartComposeStripState();
}

class _SmartComposeStripState extends State<SmartComposeStrip> {
  String? _preview; // candidate replacement waiting for user accept
  String? _undoOriginal; // pre-AI text — НЕ ограничено таймером
  int _requestId = 0;
  bool _loading = false;
  bool _hasText = false;
  String _style = 'friendly';

  @override
  void initState() {
    super.initState();
    _hasText = _computeHasText();
    widget.controller.addListener(_onTextChanged);
    unawaited(_loadLastStyle());
  }

  Future<void> _loadLastStyle() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getString(_kLastStyleKey);
      if (!mounted || v == null || v.isEmpty) return;
      if (_kRewriteStyles.any((s) => s.id == v)) {
        setState(() => _style = v);
      }
    } catch (_) {}
  }

  Future<void> _persistStyle(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLastStyleKey, id);
    } catch (_) {}
  }

  @override
  void didUpdateWidget(covariant SmartComposeStrip old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  bool _computeHasText() => widget.controller.text.trim().length >= 4;

  void _onTextChanged() {
    final next = _computeHasText();
    final changedFlag = next != _hasText;
    final hadPreview = _preview != null;
    // Любое ручное изменение текста invalidates preview — оно строилось
    // под другой prefix и больше не релевантно. Undo НЕ сбрасываем при
    // ручных правках: пользователь может править AI-результат и всё
    // равно иметь возможность вернуться к своему исходнику. Сбрасываем
    // только когда композер целиком очищен — это сигнал отправки или
    // явного reset (см. также _onTextChanged ниже).
    final emptiedComposer =
        widget.controller.text.trim().isEmpty && _undoOriginal != null;
    if (!changedFlag && !hadPreview && !emptiedComposer) return;
    if (!mounted) return;
    setState(() {
      _hasText = next;
      if (hadPreview) _preview = null;
      if (emptiedComposer) _undoOriginal = null;
    });
  }

  Future<void> _activate({String? styleOverride}) async {
    if (_loading) return;
    final text = widget.controller.text;
    if (text.trim().length < 4) return;
    final style = styleOverride ?? _style;
    setState(() {
      _loading = true;
      if (styleOverride != null) _style = styleOverride;
    });
    if (styleOverride != null) unawaited(_persistStyle(styleOverride));
    final reqId = ++_requestId;
    try {
      final s = await AppleIntelligence.instance
          .rewrite(text, style: style);
      if (!mounted || reqId != _requestId) return;
      if (widget.controller.text != text) {
        setState(() => _loading = false);
        return;
      }
      var clean = (s ?? '').trim();
      if (clean.startsWith('"') && clean.endsWith('"') && clean.length > 2) {
        clean = clean.substring(1, clean.length - 1).trim();
      }
      setState(() {
        _loading = false;
        // Если модель вернула идентичный текст / пустоту — нечего показывать.
        _preview = (clean.isEmpty || clean == text.trim()) ? null : clean;
      });
    } catch (_) {
      if (!mounted || reqId != _requestId) return;
      setState(() {
        _loading = false;
        _preview = null;
      });
    }
  }

  void _accept() {
    final s = _preview;
    if (s == null) return;
    final preAi = widget.controller.text;
    widget.controller.value = TextEditingValue(
      text: s,
      selection: TextSelection.collapsed(offset: s.length),
    );
    setState(() {
      _preview = null;
      // НЕ перезаписываем `_undoOriginal` если он уже выставлен предыдущим
      // accept — undo всегда возвращает к самому первому пре-AI тексту.
      // Если же это первый accept в текущей сессии композера — фиксируем.
      _undoOriginal ??= preAi;
    });
    unawaited(ChatHaptics.instance.tick());
    widget.focusNode.requestFocus();
  }

  void _dismissPreview() {
    if (_preview == null) return;
    setState(() => _preview = null);
  }

  void _undo() {
    final original = _undoOriginal;
    if (original == null) return;
    widget.controller.value = TextEditingValue(
      text: original,
      selection: TextSelection.collapsed(offset: original.length),
    );
    setState(() => _undoOriginal = null);
    unawaited(ChatHaptics.instance.tick());
    widget.focusNode.requestFocus();
  }

  Future<void> _openStylePicker() async {
    if (_loading) return;
    if (widget.controller.text.trim().length < 4) return;
    unawaited(ChatHaptics.instance.tick());
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _StylePickerSheet(currentStyle: _style),
    );
    if (picked == null || !mounted) return;
    await _activate(styleOverride: picked);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.aiAvailable) return const SizedBox.shrink();
    final showUndo = _undoOriginal != null;
    // Полоска нужна когда есть: текст ≥4 символов (sparkle/preview), либо
    // живой undo (даже если пользователь укоротил композер ниже порога —
    // должен иметь возможность вернуть исходник).
    if (!_hasText && !showUndo) return const SizedBox.shrink();
    final preview = _preview;
    final isDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final accent = const Color(0xFF7C8DFF);
    final bg = isDark ? const Color(0xFF1E2127) : Colors.white;
    final fg = isDark ? const Color(0xFFE6E7EA) : const Color(0xFF1A1C22);
    final border = isDark ? const Color(0x14FFFFFF) : const Color(0x0F000000);

    if (preview != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _accept,
            onLongPress: _dismissPreview,
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: border, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.18),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      size: 13,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      preview,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: fg.withValues(alpha: 0.86),
                        height: 1.32,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _dismissPreview,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: fg.withValues(alpha: 0.54),
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

    // idle / loading + опциональная undo-кнопка справа от sparkle-иконки.
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (showUndo) ...[
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _undo,
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: border, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.undo_rounded,
                        size: 14,
                        color: fg.withValues(alpha: 0.86),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Undo',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: fg.withValues(alpha: 0.86),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_hasText) const SizedBox(width: 6),
          ],
          // Sparkle-иконка скрыта, когда текста меньше 4 символов — даже
          // если undo доступен, AI-rewrite на «При» бесполезен.
          if (_hasText) Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _loading ? null : () => _activate(),
              onLongPress: _loading ? null : _openStylePicker,
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: border, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: _loading
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: accent,
                        ),
                      )
                    : Icon(
                        Icons.auto_awesome_rounded,
                        size: 16,
                        color: accent,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom-sheet выбора стиля переписывания. Возвращает `style.id` или null
/// при отмене. Список стилей синхронизирован с native `rewritePrompt`.
class _StylePickerSheet extends StatelessWidget {
  const _StylePickerSheet({required this.currentStyle});

  final String currentStyle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final accent = const Color(0xFF7C8DFF);
    final bg = isDark ? const Color(0xFF1B1E25) : Colors.white;
    final fg = isDark ? const Color(0xFFE6E7EA) : const Color(0xFF1A1C22);
    final divider = isDark
        ? const Color(0x14FFFFFF)
        : const Color(0x12000000);

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: divider, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, size: 18, color: accent),
                  const SizedBox(width: 8),
                  Text(
                    l10n.ai_rewrite_picker_title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: _kRewriteStyles.length,
                itemBuilder: (ctx, i) {
                  final style = _kRewriteStyles[i];
                  final selected = style.id == currentStyle;
                  return InkWell(
                    onTap: () => Navigator.of(ctx).pop(style.id),
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
                              color: (selected ? accent : fg)
                                  .withValues(alpha: selected ? 0.18 : 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              style.icon,
                              size: 17,
                              color: selected
                                  ? accent
                                  : fg.withValues(alpha: 0.86),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              style.label(l10n),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: fg,
                              ),
                            ),
                          ),
                          if (selected)
                            Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: accent,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}


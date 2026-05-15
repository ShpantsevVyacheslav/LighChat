import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/apple_intelligence.dart';
import '../data/chat_haptics.dart';

/// Smart Compose: AI-подсказки продолжения частично набранного сообщения
/// (как в Gmail). Виджет вставляется поверх composer-а, слушает изменения
/// `controller` и через debounce запрашивает у Apple Intelligence
/// продолжение. Пилюля над инпутом показывает sparkle + suggestion, тап
/// на неё дописывает текст в composer и закрывает подсказку.
///
/// Дополнительно: hardware Tab / Cmd+→ принимают подсказку (для физических
/// клавиатур на iPad/Mac).
///
/// На устройствах без Apple Intelligence — `null` от модели, виджет
/// не показывается, накладных нет.
class SmartComposeStrip extends StatefulWidget {
  const SmartComposeStrip({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.aiAvailable,
  });

  final TextEditingController controller;
  final FocusNode focusNode;

  /// Доступен ли Foundation Models. Если `false` — виджет не дёргает
  /// модель и не подписывается на изменения.
  final bool aiAvailable;

  @override
  State<SmartComposeStrip> createState() => _SmartComposeStripState();
}

class _SmartComposeStripState extends State<SmartComposeStrip> {
  Timer? _debounce;
  String _lastRequestedPrefix = '';
  String? _suggestion;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    if (widget.aiAvailable) {
      widget.controller.addListener(_onTextChanged);
    }
  }

  @override
  void didUpdateWidget(covariant SmartComposeStrip old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onTextChanged);
      if (widget.aiAvailable) {
        widget.controller.addListener(_onTextChanged);
      }
    }
    if (old.aiAvailable != widget.aiAvailable) {
      if (widget.aiAvailable) {
        widget.controller.addListener(_onTextChanged);
      } else {
        widget.controller.removeListener(_onTextChanged);
      }
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _debounce?.cancel();
    super.dispose();
  }

  void _onTextChanged() {
    if (!widget.aiAvailable) return;
    final text = widget.controller.text;
    final trimmed = text.trim();
    // Меньше 4 символов — не запрашиваем, AI всё равно даст мусор.
    if (trimmed.length < 4) {
      if (_suggestion != null) {
        setState(() => _suggestion = null);
      }
      return;
    }
    // Если новый текст — это уже принятая подсказка целиком, не
    // делаем re-request (юзер мог нажать «принять» и продолжить печатать).
    final current = _suggestion;
    if (current != null) {
      final accepted = _lastRequestedPrefix + current;
      if (text == accepted) return;
      // Текст изменился — старая подсказка больше не валидна.
      setState(() => _suggestion = null);
    }
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () => _fetch(text));
  }

  Future<void> _fetch(String text) async {
    final reqId = ++_requestId;
    try {
      final s = await AppleIntelligence.instance.suggestContinuation(text);
      if (!mounted || reqId != _requestId) return;
      // Проверяем что текст composer-а не изменился пока модель думала.
      if (widget.controller.text != text) {
        return;
      }
      var clean = (s ?? '').trim();
      // Иногда модель возвращает «\"продолжение\"» в кавычках — снимаем.
      if (clean.startsWith('"') && clean.endsWith('"') && clean.length > 2) {
        clean = clean.substring(1, clean.length - 1).trim();
      }
      setState(() {
        _suggestion = clean.isEmpty ? null : clean;
        _lastRequestedPrefix = text;
      });
    } catch (_) {
      if (!mounted || reqId != _requestId) return;
      setState(() {
        _suggestion = null;
      });
    }
  }

  void _accept() {
    final s = _suggestion;
    if (s == null) return;
    final prefix = _lastRequestedPrefix;
    // Решаем нужен ли пробел между prefix и suggestion.
    final needsSpace = prefix.isNotEmpty &&
        !prefix.endsWith(' ') &&
        !s.startsWith(' ') &&
        !s.startsWith('.') &&
        !s.startsWith(',') &&
        !s.startsWith('!') &&
        !s.startsWith('?');
    final glued = needsSpace ? '$prefix $s' : '$prefix$s';
    widget.controller.value = TextEditingValue(
      text: glued,
      selection: TextSelection.collapsed(offset: glued.length),
    );
    setState(() {
      _suggestion = null;
      _lastRequestedPrefix = glued;
    });
    unawaited(ChatHaptics.instance.tick());
    widget.focusNode.requestFocus();
  }

  void _dismiss() {
    if (_suggestion == null) return;
    setState(() => _suggestion = null);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.aiAvailable) return const SizedBox.shrink();
    final suggestion = _suggestion;
    if (suggestion == null) return const SizedBox.shrink();
    final isDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final accent = const Color(0xFF7C8DFF);
    final bg = isDark
        ? const Color(0xFF1E2127)
        : Colors.white;
    final fg = isDark
        ? const Color(0xFFE6E7EA)
        : const Color(0xFF1A1C22);
    final border = isDark
        ? const Color(0x14FFFFFF)
        : const Color(0x0F000000);

    // Перехват Tab / →-стрелка для accept на физической клавиатуре.
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.tab): _accept,
        },
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _accept,
            onLongPress: _dismiss,
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
                      suggestion,
                      maxLines: 2,
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.keyboard_tab_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

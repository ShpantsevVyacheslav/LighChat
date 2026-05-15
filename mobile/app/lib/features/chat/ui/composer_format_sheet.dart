import 'package:flutter/material.dart';

import '../data/chat_haptics.dart';

/// Bottom sheet форматирования в стиле Apple Notes: одна строка с
/// большими кнопками **B** *I* U S `</>` — каждая мгновенно переключает
/// формат на выделенном фрагменте (или на typingAttributes, если
/// selection пуст).
///
/// Вызывается из chat_composer при тапе на «Aa»-кнопку, работает с
/// нативным UITextView через [NativeIosComposerField.toggleFormat]
/// (Phase 4). На Android/desktop (где нативного composer нет)
/// sheet не показывается — там остаётся inline Flutter
/// `ComposerFormattingToolbar`.
///
/// Sheet не закрывается автоматически при тапе на кнопку — пользователь
/// может последовательно применить B+I+U. Закрывается вручную крестиком
/// или свайпом вниз.
Future<void> showComposerFormatSheet({
  required BuildContext context,
  required void Function(String tag) onToggle,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.32),
    builder: (_) => _FormatSheetBody(onToggle: onToggle),
  );
}

class _FormatSheetBody extends StatelessWidget {
  const _FormatSheetBody({required this.onToggle});
  final void Function(String tag) onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final bg = dark
        ? const Color(0xFF1B1E25)
        : Colors.white;
    final fg = dark ? const Color(0xFFE6E7EA) : const Color(0xFF1A1C22);
    final divider = dark
        ? const Color(0x14FFFFFF)
        : const Color(0x12000000);
    final accent = const Color(0xFFFFC93C); // тёплый жёлтый «highlight» как в Notes

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
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
              child: Row(
                children: [
                  Text(
                    'Format',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    color: fg.withValues(alpha: 0.62),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  _Btn(
                    label: 'B',
                    bold: true,
                    bgActive: accent,
                    fg: fg,
                    onTap: () => _emit('bold'),
                  ),
                  const SizedBox(width: 8),
                  _Btn(
                    label: 'I',
                    italic: true,
                    bgActive: accent,
                    fg: fg,
                    onTap: () => _emit('italic'),
                  ),
                  const SizedBox(width: 8),
                  _Btn(
                    label: 'U',
                    underline: true,
                    bgActive: accent,
                    fg: fg,
                    onTap: () => _emit('underline'),
                  ),
                  const SizedBox(width: 8),
                  _Btn(
                    label: 'S',
                    strike: true,
                    bgActive: accent,
                    fg: fg,
                    onTap: () => _emit('strikethrough'),
                  ),
                  const SizedBox(width: 8),
                  _Btn(
                    label: '</>',
                    mono: true,
                    bgActive: accent,
                    fg: fg,
                    onTap: () => _emit('code'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _emit(String tag) {
    onToggle(tag);
    ChatHaptics.instance.selectionChanged();
  }
}

class _Btn extends StatelessWidget {
  const _Btn({
    required this.label,
    required this.bgActive,
    required this.fg,
    required this.onTap,
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strike = false,
    this.mono = false,
  });
  final String label;
  final Color bgActive;
  final Color fg;
  final VoidCallback onTap;
  final bool bold;
  final bool italic;
  final bool underline;
  final bool strike;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: fg.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: mono ? 14 : 18,
                fontFamily: mono ? 'Menlo' : null,
                fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
                fontStyle: italic ? FontStyle.italic : FontStyle.normal,
                decoration: underline
                    ? TextDecoration.underline
                    : (strike ? TextDecoration.lineThrough : null),
                color: fg,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

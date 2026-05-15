import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'animated_text_span.dart';
import '../data/chat_haptics.dart';

/// Format-popover для нативного композера (Phase 9). Раньше был
/// `showModalBottomSheet`, который перекрывал поле ввода — юзер не видел
/// что печатает. Теперь это overlay-popover **над композером** в стиле
/// Apple Messages «Text Effects»: компактный пузырь с blur background,
/// две строки кнопок (B/I/U/S/code и Big/Small/Shake/Nod/Ripple/Bloom/
/// Jitter с реальным preview-эффектом).
///
/// Popover не закрывает клавиатуру и НЕ перекрывает композер — садится
/// прямо над input-баром. Закрывается тапом по barrier'у или крестиком.
/// Тап на кнопку НЕ закрывает popover — юзер может последовательно
/// применить B+I+U или сменить эффект.
///
/// `anchorKey` — GlobalKey виджета, **над** которым нужно показать
/// popover. Обычно это контейнер композера (`_composerColumnKey`).
Future<void> showComposerFormatSheet({
  required BuildContext context,
  required GlobalKey anchorKey,
  required void Function(String tag) onToggle,
}) async {
  final overlay = Overlay.of(context);
  final anchorBox =
      anchorKey.currentContext?.findRenderObject() as RenderBox?;
  final overlayBox = overlay.context.findRenderObject() as RenderBox?;
  if (anchorBox == null || overlayBox == null || !anchorBox.hasSize) return;

  final anchorTop = anchorBox.localToGlobal(
    Offset.zero,
    ancestor: overlayBox,
  );
  final overlaySize = overlayBox.size;
  // Bottom-offset overlay'а: расстояние от низа экрана до верха
  // композера. Сам popover ляжет immediately above composer'а с 8px
  // gap'ом (как iOS callout).
  final bottomFromOverlay = overlaySize.height - anchorTop.dy + 8;

  late OverlayEntry entry;
  void dismiss() {
    if (entry.mounted) entry.remove();
  }

  entry = OverlayEntry(
    builder: (_) {
      return Stack(
        children: [
          // Tap-outside dismiss. Прозрачный barrier — клавиатура и
          // композер видны под popover'ом.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: dismiss,
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            left: 8,
            right: 8,
            bottom: bottomFromOverlay,
            child: _FormatPopoverBody(
              onToggle: onToggle,
              onClose: dismiss,
            ),
          ),
        ],
      );
    },
  );
  overlay.insert(entry);
}

class _FormatPopoverBody extends StatelessWidget {
  const _FormatPopoverBody({required this.onToggle, required this.onClose});
  final void Function(String tag) onToggle;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final fg = dark ? const Color(0xFFE6E7EA) : const Color(0xFF1A1C22);
    final bgFill = (dark ? const Color(0xFF12141A) : Colors.white)
        .withValues(alpha: dark ? 0.78 : 0.92);
    final border = (dark ? Colors.white : Colors.black)
        .withValues(alpha: dark ? 0.10 : 0.08);

    return Material(
      type: MaterialType.transparency,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            decoration: BoxDecoration(
              color: bgFill,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: border, width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: dark ? 0.4 : 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header строка: «Format» + крестик. Минимально, чтобы
                  // popover был компактным.
                  Row(
                    children: [
                      const SizedBox(width: 6),
                      Text(
                        'Format',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: fg.withValues(alpha: 0.78),
                          letterSpacing: 0.2,
                        ),
                      ),
                      const Spacer(),
                      _CloseBtn(fg: fg, onTap: onClose),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Top row: B / I / U / S / code (5 равных)
                  Row(
                    children: [
                      _BtnSmall(
                        label: 'B',
                        fg: fg,
                        bold: true,
                        onTap: () => _emit('bold'),
                      ),
                      const SizedBox(width: 6),
                      _BtnSmall(
                        label: 'I',
                        fg: fg,
                        italic: true,
                        onTap: () => _emit('italic'),
                      ),
                      const SizedBox(width: 6),
                      _BtnSmall(
                        label: 'U',
                        fg: fg,
                        underline: true,
                        onTap: () => _emit('underline'),
                      ),
                      const SizedBox(width: 6),
                      _BtnSmall(
                        label: 'S',
                        fg: fg,
                        strike: true,
                        onTap: () => _emit('strikethrough'),
                      ),
                      const SizedBox(width: 6),
                      _BtnSmall(
                        label: '</>',
                        fg: fg,
                        mono: true,
                        onTap: () => _emit('code'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Bottom row: animated effects + Big/Small с **живым
                  // preview**. Каждая кнопка показывает реальный эффект
                  // на своём label'е (как в Apple Messages Text Effects).
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.start,
                    children: [
                      _EffectBtnPreview(
                        label: 'Big',
                        effect: 'big',
                        fg: fg,
                        onTap: () => _emit('big'),
                      ),
                      _EffectBtnPreview(
                        label: 'Small',
                        effect: 'small',
                        fg: fg,
                        onTap: () => _emit('small'),
                      ),
                      _EffectBtnPreview(
                        label: 'Shake',
                        effect: 'shake',
                        fg: fg,
                        onTap: () => _emit('shake'),
                      ),
                      _EffectBtnPreview(
                        label: 'Nod',
                        effect: 'nod',
                        fg: fg,
                        onTap: () => _emit('nod'),
                      ),
                      _EffectBtnPreview(
                        label: 'Ripple',
                        effect: 'ripple',
                        fg: fg,
                        onTap: () => _emit('ripple'),
                      ),
                      _EffectBtnPreview(
                        label: 'Bloom',
                        effect: 'bloom',
                        fg: fg,
                        onTap: () => _emit('bloom'),
                      ),
                      _EffectBtnPreview(
                        label: 'Jitter',
                        effect: 'jitter',
                        fg: fg,
                        onTap: () => _emit('jitter'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _emit(String tag) {
    onToggle(tag);
    ChatHaptics.instance.selectionChanged();
  }
}

class _CloseBtn extends StatelessWidget {
  const _CloseBtn({required this.fg, required this.onTap});
  final Color fg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 16,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          Icons.close_rounded,
          size: 18,
          color: fg.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}

class _BtnSmall extends StatelessWidget {
  const _BtnSmall({
    required this.label,
    required this.fg,
    required this.onTap,
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strike = false,
    this.mono = false,
  });
  final String label;
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
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: fg.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: mono ? 12 : 16,
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

/// Кнопка эффекта с **живым preview**: внутри сидит [AnimatedTextSpan],
/// который проигрывает соответствующий эффект на label'е (Big/Small/
/// Shake/Nod/Ripple/Bloom/Jitter). Это и есть «Apple Messages Text
/// Effects» UX — юзер видит как именно эффект будет выглядеть до того
/// как применить.
class _EffectBtnPreview extends StatelessWidget {
  const _EffectBtnPreview({
    required this.label,
    required this.effect,
    required this.fg,
    required this.onTap,
  });
  final String label;
  final String effect;
  final Color fg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: fg.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(10),
          ),
          // AnimatedTextSpan ожидает, что его передают inside RichText/
          // WidgetSpan. У нас он сам — Widget, поэтому просто оборачиваем
          // в фиксированный baseline и отдаём строку.
          child: AnimatedTextSpan(
            text: label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
            effect: effect,
          ),
        ),
      ),
    );
  }
}

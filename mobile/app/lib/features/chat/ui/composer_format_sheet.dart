import 'dart:async' show unawaited;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
  // ВАЖНО (Phase 14.6, fix): Используем кастомный `PageRouteBuilder`
  // с `opaque: false` и НЕ root navigator. Прежний showGeneralDialog
  // делал full-screen opaque route и chat AppBar пропадал. Этот
  // вариант:
  //   - opaque: false → background сквозь видно (chat screen остаётся);
  //   - barrierColor: transparent → composer не темнится;
  //   - Material(transparency) wrapper → child рендерится без default
  //     opaque background материала;
  //   - useRootNavigator не нужен — route на текущем Navigator'е
  //     корректно поднимается над body, и AppBar остаётся видимым
  //     (потому что AppBar в Scaffold body, не в Navigator).
  // Sentinel: явно отмечает версию popover-логики. Если в логах
  // видно `POPOVER_BUILD=Phase14.6`, значит используется PageRouteBuilder
  // (opaque:false, AppBar остаётся виден). Если `dialog dismissed` без
  // sentinel'а — это старый Phase14.5 showGeneralDialog (opaque route,
  // AppBar исчезает).
  debugPrint('[format-popover] POPOVER_BUILD=Phase14.6');
  final anchorBox =
      anchorKey.currentContext?.findRenderObject() as RenderBox?;
  debugPrint(
    '[format-popover] open: anchorBox=${anchorBox != null} '
    'hasSize=${anchorBox?.hasSize}',
  );
  if (anchorBox == null || !anchorBox.hasSize) {
    debugPrint('[format-popover] open: bail — invalid anchor');
    return;
  }
  final mq = MediaQuery.of(context);
  final screenH = mq.size.height;
  final anchorGlobalTop = anchorBox.localToGlobal(Offset.zero);
  final bottomRaw = screenH - anchorGlobalTop.dy + 8;
  final bottomFromScreenBottom = bottomRaw.isFinite
      ? bottomRaw.clamp(60.0, screenH - 100)
      : 60.0;
  debugPrint(
    '[format-popover] anchorGlobalTop=$anchorGlobalTop '
    'bottomFromScreenBottom=$bottomFromScreenBottom screenH=$screenH',
  );

  final navigator = Navigator.of(context);
  await navigator.push<void>(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.transparent,
      barrierDismissible: true,
      barrierLabel: 'format-popover-barrier',
      transitionDuration: const Duration(milliseconds: 180),
      reverseTransitionDuration: const Duration(milliseconds: 140),
      pageBuilder: (dialogContext, anim, _) {
        return Material(
          type: MaterialType.transparency,
          child: SafeArea(
            child: Stack(
              children: [
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: bottomFromScreenBottom,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {}, // блок tap-through на popover
                    child: _FormatPopoverBody(
                      onToggle: onToggle,
                      onClose: () => Navigator.of(dialogContext).pop(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      transitionsBuilder: (_, anim, _, child) {
        return FadeTransition(opacity: anim, child: child);
      },
    ),
  );
  debugPrint('[format-popover] route popped');
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
    final border = (dark ? Colors.white : Colors.black)
        .withValues(alpha: dark ? 0.10 : 0.08);

    // ВАЖНО (Phase 14, fix): убран BackdropFilter (ImageFilter.blur).
    // Popover рендерится поверх hybrid-composition PlatformView
    // (нативный UITextView). BackdropFilter создаёт save-layer, который
    // конфликтует с iOS render pipeline'ом и валит в консоль
    // `[ERROR:flutter/flow/layers/transform_layer.cc] invalid matrix`,
    // а сам popover при этом иногда не появляется на экране (рендер
    // обрывается). Solid bgFill (с увеличенной непрозрачностью) даёт
    // тот же визуальный «glass» эффект без save-layer'а.
    final solidBg = dark
        ? const Color(0xFF1B1E26).withValues(alpha: 0.96)
        : Colors.white.withValues(alpha: 0.98);
    return Material(
      type: MaterialType.transparency,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
            decoration: BoxDecoration(
              color: solidBg,
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
                  // Phase 13: block-level форматы — Quote / Spoiler /
                  // Link. Lin'ка прокидывается в onToggle как
                  // `link:<url>` (или просто `link` для очистки).
                  Row(
                    children: [
                      _BtnLabeled(
                        label: 'Quote',
                        icon: Icons.format_quote_rounded,
                        fg: fg,
                        onTap: () => _emit('quote'),
                      ),
                      const SizedBox(width: 6),
                      _BtnLabeled(
                        label: 'Spoiler',
                        icon: Icons.visibility_off_outlined,
                        fg: fg,
                        onTap: () => _emit('spoiler'),
                      ),
                      const SizedBox(width: 6),
                      _BtnLabeled(
                        label: 'Link',
                        icon: Icons.link_rounded,
                        fg: fg,
                        onTap: () =>
                            unawaited(_handleLinkTap(context, onToggle)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Bottom: animated effects + Big/Small в 2 колонки
                  // (паритет Apple Messages Text Effects). Каждая
                  // кнопка показывает живой preview-эффект на своём
                  // label'е через `AnimatedTextSpan`.
                  ..._buildEffectRows(fg),
                ],
              ),
            ),
          ),
        ),
    );
  }

  void _emit(String tag) {
    debugPrint('[format-popover] _emit tag=$tag → onToggle');
    onToggle(tag);
    ChatHaptics.instance.selectionChanged();
  }

  /// Тап на «Link» — Cupertino-диалог с TextField для URL. Если юзер
  /// ввёл валидный URL и нажал «Применить» → onToggle('link:URL').
  /// Если оставил пустым (или нажал «Удалить») → onToggle('link') с
  /// пустым href, что в Swift означает «снять link attribute».
  Future<void> _handleLinkTap(
    BuildContext context,
    void Function(String tag) onToggle,
  ) async {
    ChatHaptics.instance.selectionChanged();
    final controller = TextEditingController();
    final result = await showCupertinoDialog<String>(
      context: context,
      builder: (ctx) {
        return CupertinoAlertDialog(
          title: const Text('Ссылка'),
          content: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: CupertinoTextField(
              controller: controller,
              autofocus: true,
              placeholder: 'https://',
              keyboardType: TextInputType.url,
              autocorrect: false,
              textCapitalization: TextCapitalization.none,
            ),
          ),
          actions: [
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.of(ctx).pop('__remove__'),
              child: const Text('Удалить'),
            ),
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Отмена'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
              child: const Text('Применить'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (result == null) return; // отмена
    if (result == '__remove__' || result.isEmpty) {
      onToggle('link'); // пустой href → Swift снимет атрибут
      return;
    }
    // Дополним «http://» если юзер не указал scheme.
    final hasScheme = RegExp(r'^[a-zA-Z][a-zA-Z0-9+\-.]*://').hasMatch(result);
    final href = hasScheme ? result : 'https://$result';
    onToggle('link:$href');
  }

  /// 7 effects в 2-колоночной сетке как в Apple Messages: 4 полных
  /// строки, последняя строка (Jitter) — растянута на всю ширину
  /// (либо в одной колонке если хочется идеальный квадрат — у Apple
  /// одиночная кнопка обычно растянута, оставляем тот же стиль).
  List<Widget> _buildEffectRows(Color fg) {
    const effects = <(String, String)>[
      ('Big', 'big'),
      ('Small', 'small'),
      ('Shake', 'shake'),
      ('Nod', 'nod'),
      ('Ripple', 'ripple'),
      ('Bloom', 'bloom'),
      ('Jitter', 'jitter'),
    ];
    final rows = <Widget>[];
    for (var i = 0; i < effects.length; i += 2) {
      final left = effects[i];
      final right = i + 1 < effects.length ? effects[i + 1] : null;
      rows.add(
        Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _EffectBtnPreview(
                  label: left.$1,
                  effect: left.$2,
                  fg: fg,
                  onTap: () => _emit(left.$2),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: right == null
                    ? const SizedBox.shrink()
                    : _EffectBtnPreview(
                        label: right.$1,
                        effect: right.$2,
                        fg: fg,
                        onTap: () => _emit(right.$2),
                      ),
              ),
            ],
          ),
        ),
      );
    }
    return rows;
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

/// Кнопка с иконкой и подписью (Quote / Spoiler / Link block-row).
class _BtnLabeled extends StatelessWidget {
  const _BtnLabeled({
    required this.label,
    required this.icon,
    required this.fg,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color fg;
  final VoidCallback onTap;

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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: fg.withValues(alpha: 0.9)),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: fg,
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

/// Кнопка эффекта с **живым preview**: внутри сидит [AnimatedTextSpan],
/// который проигрывает соответствующий эффект на label'е (Big/Small/
/// Shake/Nod/Ripple/Bloom/Jitter). Это и есть «Apple Messages Text
/// Effects» UX. ВАЖНО (Phase 14, fix): live preview-эффекты убраны.
/// `AnimatedTextSpan` использует `Transform.scale/translate/rotate`
/// внутри, и каждый `Transform` поверх hybrid-composition
/// PlatformView (native UITextView, который сидит прямо под popover'ом)
/// создаёт новый transform-layer. iOS render pipeline валит в консоль
/// поток `[ERROR:flutter/flow/layers/transform_layer.cc] invalid matrix`
/// и иногда popover вообще не дорисовывается. Текст label'а теперь
/// статичный — пользователь применяет эффект тапом и видит результат
/// на своём тексте в композере (где AnimatedTextSpan живёт без проблем,
/// потому что message-list рендерится Skia без PlatformView под).
class _EffectBtnPreview extends StatelessWidget {
  const _EffectBtnPreview({
    required this.label,
    // ignore: unused_element_parameter
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
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}

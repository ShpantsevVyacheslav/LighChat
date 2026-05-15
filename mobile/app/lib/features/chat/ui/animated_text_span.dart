import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Анимированные эффекты текста в чате (паритет Apple Messages
/// «Text Effects»). На входе — кусок plain-text + style + имя эффекта.
/// Эффект работает на receiver-side: postcards mobile/desktop рендерят
/// Flutter `AnimationController`. Web-side не покрыт этой версией —
/// там текст будет показан статически (graceful fallback).
///
/// Эффекты:
///  - `shake` — горизонтальная sin-вибрация
///  - `nod` — вертикальный «качок» головой
///  - `ripple` — волна opacity+y-offset по буквам
///  - `bloom` — пульсирующее увеличение scale
///  - `jitter` — мелкие случайные смещения (на детерминированном hash'е,
///    чтобы не делать новый seed на каждый кадр)
///  - `big` — статическое 1.4× увеличение размера
///  - `small` — статическое 0.7× уменьшение
class AnimatedTextSpan extends StatefulWidget {
  const AnimatedTextSpan({
    super.key,
    required this.text,
    required this.style,
    required this.effect,
  });

  final String text;
  final TextStyle style;

  /// Один из: shake / nod / ripple / bloom / jitter / big / small.
  /// Неизвестное значение → text рендерится без эффекта.
  final String effect;

  /// Whitelist эффектов — используется парсером HTML чтобы не строить
  /// AnimatedTextSpan на мусоре в `data-anim`.
  static const knownEffects = <String>{
    'shake', 'nod', 'ripple', 'bloom', 'jitter', 'big', 'small',
  };

  static bool isKnown(String? raw) =>
      raw != null && knownEffects.contains(raw.toLowerCase());

  @override
  State<AnimatedTextSpan> createState() => _AnimatedTextSpanState();
}

class _AnimatedTextSpanState extends State<AnimatedTextSpan>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  bool get _isStaticSize =>
      widget.effect == 'big' || widget.effect == 'small';

  @override
  void initState() {
    super.initState();
    _ensureController();
  }

  @override
  void didUpdateWidget(covariant AnimatedTextSpan old) {
    super.didUpdateWidget(old);
    if (old.effect != widget.effect) {
      _ensureController();
    }
  }

  void _ensureController() {
    if (_isStaticSize) {
      _controller?.dispose();
      _controller = null;
      return;
    }
    if (_controller != null) return;
    // Длительность подобрана под визуальный темп: shake/jitter быстрые,
    // bloom/ripple медленнее. Контроллер всегда 0..1, конкретный эффект
    // сам интерпретирует прогресс.
    final dur = switch (widget.effect) {
      'shake' || 'jitter' => const Duration(milliseconds: 600),
      'nod' => const Duration(milliseconds: 1000),
      'ripple' => const Duration(milliseconds: 1800),
      'bloom' => const Duration(milliseconds: 1400),
      _ => const Duration(milliseconds: 1000),
    };
    _controller = AnimationController(vsync: this, duration: dur)..repeat();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Big/Small — статика, без AnimationController.
    if (widget.effect == 'big') {
      return Text(
        widget.text,
        style: widget.style.copyWith(
          fontSize: (widget.style.fontSize ?? 14) * 1.4,
          fontWeight: FontWeight.w700,
        ),
      );
    }
    if (widget.effect == 'small') {
      return Text(
        widget.text,
        style: widget.style.copyWith(
          fontSize: (widget.style.fontSize ?? 14) * 0.72,
        ),
      );
    }

    final ctrl = _controller!;
    return AnimatedBuilder(
      animation: ctrl,
      builder: (context, _) {
        return _buildEffect(ctrl.value);
      },
    );
  }

  Widget _buildEffect(double t) {
    switch (widget.effect) {
      case 'shake':
        return _wholeWord(
          Transform.translate(
            offset: Offset(math.sin(t * math.pi * 8) * 1.8, 0),
            child: _plain(),
          ),
        );
      case 'nod':
        return _wholeWord(
          Transform.translate(
            offset: Offset(0, math.sin(t * math.pi * 2) * 2.4),
            child: Transform.rotate(
              angle: math.sin(t * math.pi * 2) * 0.04,
              child: _plain(),
            ),
          ),
        );
      case 'bloom':
        // 1.0 → 1.18 → 1.0 синусоидально + лёгкое изменение weight'а
        final scale = 1.0 + 0.18 * math.sin(t * math.pi * 2).abs();
        return _wholeWord(
          Transform.scale(scale: scale, child: _plain()),
        );
      case 'ripple':
        return _perLetter((letter, i, n) {
          // Волна opacity + y-offset, проходящая через буквы.
          final phase = (t * 2) - (i / math.max(1, n));
          final pulse = math.max(0.0, math.sin(phase * math.pi * 2));
          return Transform.translate(
            offset: Offset(0, -pulse * 3),
            child: Opacity(
              opacity: 0.55 + 0.45 * pulse,
              child: Text(letter, style: widget.style),
            ),
          );
        });
      case 'jitter':
        return _perLetter((letter, i, _) {
          // Псевдослучайный детерминированный seed на букву + фаза.
          final seed = i * 9301 + 49297;
          final px = math.sin(t * math.pi * 6 + seed) * 0.9;
          final py = math.cos(t * math.pi * 5 + seed + 1) * 0.9;
          return Transform.translate(
            offset: Offset(px, py),
            child: Text(letter, style: widget.style),
          );
        });
      default:
        return _plain();
    }
  }

  Widget _plain() => Text(widget.text, style: widget.style);

  Widget _wholeWord(Widget child) => child;

  /// Помощник: рендерим текст побуквенно. [builder] получает букву,
  /// её индекс и общее число букв, возвращает уже отрисованный widget
  /// для этой буквы (transform + Text внутри).
  Widget _perLetter(Widget Function(String letter, int i, int n) builder) {
    final letters = widget.text.split('');
    final n = letters.length;
    return RichText(
      text: TextSpan(
        children: [
          for (var i = 0; i < n; i++)
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: builder(letters[i], i, n),
            ),
        ],
      ),
    );
  }
}

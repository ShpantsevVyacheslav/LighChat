import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/features_data.dart';

// =====================================================================
//  Анимационные хелперы
// =====================================================================

/// Бесконечно «пульсирующий» виджет — масштаб + прозрачность.
class _RepeatingPulse extends StatefulWidget {
  const _RepeatingPulse({
    required this.child,
    this.minScale = 1.0,
    this.maxScale = 2.4,
    this.delay = Duration.zero,
  });
  final Widget child;
  final double minScale;
  final double maxScale;
  final Duration delay;

  static const Duration _duration = Duration(milliseconds: 2200);

  @override
  State<_RepeatingPulse> createState() => _RepeatingPulseState();
}

class _RepeatingPulseState extends State<_RepeatingPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: _RepeatingPulse._duration);
    Future<void>.delayed(widget.delay, () {
      if (mounted) _c.repeat();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final t = _c.value;
        final scale = widget.minScale + (widget.maxScale - widget.minScale) * t;
        final opacity = (1.0 - t).clamp(0.0, 1.0);
        return Transform.scale(scale: scale, child: Opacity(opacity: opacity, child: child));
      },
    );
  }
}

/// «Дыхание» — лёгкое колебание прозрачности.
class _Breathing extends StatefulWidget {
  const _Breathing({required this.child});
  final Widget child;

  @override
  State<_Breathing> createState() => _BreathingState();
}

class _BreathingState extends State<_Breathing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) =>
          Opacity(opacity: 0.55 + 0.45 * _c.value, child: child),
    );
  }
}

// `_Equalizer` удалён: реальный `AudioCallOverlay` не имеет визуального
// эквалайзера, он был моей выдумкой.

/// Появление снизу + fade-in.
class _FadeInUp extends StatefulWidget {
  const _FadeInUp({
    required this.child,
    this.delay = Duration.zero,
  });
  final Widget child;
  final Duration delay;

  static const Duration _duration = Duration(milliseconds: 500);

  @override
  State<_FadeInUp> createState() => _FadeInUpState();
}

class _FadeInUpState extends State<_FadeInUp>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: _FadeInUp._duration);
    Future<void>.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final t = Curves.easeOut.transform(_c.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(offset: Offset(0, (1 - t) * 8), child: child),
        );
      },
    );
  }
}

/// Постепенное затухание — для «исчезающих сообщений», цикл 4с.
class _FadeVanish extends StatefulWidget {
  const _FadeVanish({required this.child, this.delay = Duration.zero});
  final Widget child;
  final Duration delay;

  @override
  State<_FadeVanish> createState() => _FadeVanishState();
}

class _FadeVanishState extends State<_FadeVanish>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 4));
    Future<void>.delayed(widget.delay, () {
      if (mounted) _c.repeat();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final t = _c.value;
        // 0..0.6 — opacity 0.55, 0.6..1 — линейно к 0.05.
        final opacity = t < 0.6 ? 0.55 : 0.55 - (t - 0.6) / 0.4 * 0.50;
        return Opacity(opacity: opacity.clamp(0.05, 1.0), child: child);
      },
    );
  }
}

/// Бегущий поток (для шифр-канала и QR-pairing connector'а).
class _MarqueeStream extends StatefulWidget {
  const _MarqueeStream({required this.child});
  final Widget child;
  static const Duration _duration = Duration(seconds: 6);

  @override
  State<_MarqueeStream> createState() => _MarqueeStreamState();
}

class _MarqueeStreamState extends State<_MarqueeStream>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: _MarqueeStream._duration)..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: LayoutBuilder(builder: (context, constraints) {
        return AnimatedBuilder(
          animation: _c,
          child: widget.child,
          builder: (context, child) {
            final dx = -_c.value * constraints.maxWidth;
            return Transform.translate(offset: Offset(dx, 0), child: child);
          },
        );
      }),
    );
  }
}

/// Сообщение «отлетает вправо» (sender) и «прилетает слева» (receiver).
class _MessageFly extends StatefulWidget {
  const _MessageFly({required this.child, required this.toRight});
  final Widget child;
  final bool toRight;

  @override
  State<_MessageFly> createState() => _MessageFlyState();
}

class _MessageFlyState extends State<_MessageFly>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final t = _c.value;
        double opacity;
        double dx;
        if (widget.toRight) {
          if (t < 0.25) {
            opacity = 1;
            dx = 0;
          } else if (t < 0.40) {
            final p = (t - 0.25) / 0.15;
            opacity = 1 - p;
            dx = p * 16;
          } else {
            opacity = 0;
            dx = 16;
          }
        } else {
          if (t < 0.60) {
            opacity = 0;
            dx = -16;
          } else if (t < 0.75) {
            final p = (t - 0.60) / 0.15;
            opacity = p;
            dx = (1 - p) * -16;
          } else {
            opacity = 1;
            dx = 0;
          }
        }
        return Opacity(
          opacity: opacity,
          child: Transform.translate(offset: Offset(dx, 0), child: child),
        );
      },
    );
  }
}

// =====================================================================
//  Внешняя «рамка-экран» для мокапов
// =====================================================================

class FeatureMockFrame extends StatelessWidget {
  const FeatureMockFrame({
    super.key,
    required this.child,
    this.aspectRatio = 16 / 10,
    this.padding = EdgeInsets.zero,
  });
  final Widget child;
  final double aspectRatio;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: (dark ? Colors.white : Colors.black)
                .withValues(alpha: dark ? 0.10 : 0.06),
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.surface.withValues(alpha: dark ? 0.55 : 0.85),
              scheme.surface.withValues(alpha: dark ? 0.30 : 0.65),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.30),
              blurRadius: 30,
              offset: const Offset(0, 18),
              spreadRadius: -10,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.6, -0.8),
                    radius: 1.2,
                    colors: [
                      featureAccentPrimary.withValues(alpha: 0.10),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
//  Шапка чата + бабл — без выдуманных индикаторов
// =====================================================================

/// Шапка чата в стиле реального `ChatWindow` LighChat:
///  - стрелка-back в стеклянном `rounded-xl` chip (НЕ круглом),
///  - аватар ~36px с online-точкой,
///  - имя + статус под ним,
///  - rounded-xl glass-chip иконки: треды (синий), видео (зелёный), телефон (зелёный).
///  Никаких круглых `bg-black/30` чипов — реальный header использует
///  `chatHeaderIconGlass = rounded-xl bg-background/28 backdrop-blur shadow-sm`
///  и палитру SF Symbols-style.
class _MockChatHeader extends StatelessWidget {
  const _MockChatHeader({required this.name, required this.status});
  final String name;
  final String status;

  static const Color _iosThreads = Color(0xFF007AFF);
  static const Color _iosCall = Color(0xFF34C759);

  static Widget _chip(BuildContext context, IconData icon, {Color? iconColor}) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 32,
      height: 32,
      margin: const EdgeInsets.only(left: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: scheme.surface.withValues(alpha: 0.28),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 17, color: iconColor ?? scheme.onSurface.withValues(alpha: 0.85)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: scheme.onSurface.withValues(alpha: 0.08)),
        ),
        color: scheme.surface.withValues(alpha: 0.5),
      ),
      child: Row(children: [
        // Back — тот же rounded-xl glass chip, не круглый
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: scheme.surface.withValues(alpha: 0.28),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.chevron_left_rounded,
            size: 20,
            color: scheme.onSurface.withValues(alpha: 0.85),
          ),
        ),
        const SizedBox(width: 8),
        // Avatar
        Stack(clipBehavior: Clip.none, children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [featureAccentPrimary, featureAccentPrimary.withValues(alpha: 0.7)],
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              name.isEmpty ? '?' : name.characters.first.toUpperCase(),
              style: const TextStyle(
                  color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ),
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF22C55E),
                border: Border.all(color: scheme.surface, width: 1.5),
              ),
            ),
          ),
        ]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface)),
              Text(status,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 10, color: scheme.onSurface.withValues(alpha: 0.6))),
            ],
          ),
        ),
        _chip(context, Icons.chat_bubble_outline_rounded, iconColor: _iosThreads),
        _chip(context, Icons.videocam_outlined, iconColor: _iosCall),
        _chip(context, Icons.phone_outlined, iconColor: _iosCall),
      ]),
    );
  }
}

/// Реалистичный бабл: outgoing — primary, incoming — surface; tail-clip
/// через `topRight`/`topLeft = 0`; meta (время + check) ВНЕ пузыря, под ним.
class _MockBubble extends StatelessWidget {
  const _MockBubble({
    required this.text,
    required this.outgoing,
    this.time = '12:34',
  });
  final String text;
  final bool outgoing;
  final String time;
  static const bool _read = true;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = outgoing ? featureAccentPrimary : scheme.surface.withValues(alpha: 0.85);
    final fg = outgoing ? Colors.white : scheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Column(
        crossAxisAlignment:
            outgoing ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 220),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: bg,
              border: outgoing
                  ? null
                  : Border.all(color: scheme.onSurface.withValues(alpha: 0.06)),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(outgoing ? 14 : 0),
                topRight: Radius.circular(outgoing ? 0 : 14),
                bottomLeft: const Radius.circular(14),
                bottomRight: const Radius.circular(14),
              ),
            ),
            child: Text(text, style: TextStyle(fontSize: 11, color: fg, height: 1.3)),
          ),
          // Meta под пузырём, как в реальном LighChat.
          Padding(
            padding: const EdgeInsets.only(top: 1, left: 4, right: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(time,
                    style: TextStyle(
                        fontSize: 9,
                        color: scheme.onSurface.withValues(alpha: 0.55))),
                if (outgoing) ...[
                  const SizedBox(width: 2),
                  Icon(
                    _MockBubble._read ? Icons.done_all_rounded : Icons.done_rounded,
                    size: 11,
                    color: _MockBubble._read
                        ? featureAccentPrimary
                        : scheme.onSurface.withValues(alpha: 0.55),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatLikeMock extends StatelessWidget {
  const _ChatLikeMock({
    required this.header,
    required this.bubbles,
    this.footer,
  });
  final Widget header;
  final List<Widget> bubbles;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      header,
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < bubbles.length; i++)
                _FadeInUp(delay: Duration(milliseconds: i * 250), child: bubbles[i]),
              if (footer != null) ...[const Spacer(), footer!],
            ],
          ),
        ),
      ),
    ]);
  }
}

// =====================================================================
//  Helper для получения `mockText` из контекста
// =====================================================================

FeaturesMockText _mockText(BuildContext context) =>
    featuresContentFor(Localizations.localeOf(context)).mockText;

// =====================================================================
//  12 МОКАПОВ
// =====================================================================

// --- 1. Encryption: анимированный E2EE-explainer (Алиса → шифр → Боб) ---

class _CipherStream extends StatefulWidget {
  const _CipherStream();

  @override
  State<_CipherStream> createState() => _CipherStreamState();
}

class _CipherStreamState extends State<_CipherStream>
    with SingleTickerProviderStateMixin {
  static const List<String> _hex = [
    '9F2A', '8B71', '4CC8', '3DEA', '5F02', 'A1B4', '0E77', 'C9D5',
    '6F12', 'B83C', '7E0A', '21FE', 'D4A8', '5C19', 'E370', '08BD',
  ];

  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          return LayoutBuilder(builder: (context, constraints) {
            final w = constraints.maxWidth;
            final shift = -t * w;
            return Stack(children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      featureAccentEmerald.withValues(alpha: 0.18),
                      featureAccentEmerald.withValues(alpha: 0.06),
                      featureAccentEmerald.withValues(alpha: 0.18),
                    ],
                  ),
                  border: Border.all(color: featureAccentEmerald.withValues(alpha: 0.30)),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              Positioned(
                left: shift,
                top: 0,
                bottom: 0,
                child: Row(
                  children: [
                    for (var i = 0; i < _hex.length * 2; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Center(
                          child: Opacity(
                            opacity: 0.45 + 0.55 * ((math.sin((t * 6) + i * 0.6) + 1) / 2),
                            child: Text(
                              _hex[i % _hex.length],
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: featureAccentEmerald,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ]);
          });
        },
      ),
    );
  }
}

class MockEncryption extends StatelessWidget {
  const MockEncryption({super.key});

  Widget _peerBubble(BuildContext context, {required bool outgoing, required String text}) {
    final scheme = Theme.of(context).colorScheme;
    final bg = outgoing ? featureAccentPrimary : scheme.surface.withValues(alpha: 0.85);
    final fg = outgoing ? Colors.white : scheme.onSurface;
    return Container(
      constraints: const BoxConstraints(maxWidth: 110),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        border: outgoing
            ? null
            : Border.all(color: scheme.onSurface.withValues(alpha: 0.06)),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(outgoing ? 14 : 0),
          topRight: Radius.circular(outgoing ? 0 : 14),
          bottomLeft: const Radius.circular(14),
          bottomRight: const Radius.circular(14),
        ),
      ),
      child: Text(text, style: TextStyle(color: fg, fontSize: 11, height: 1.25)),
    );
  }

  Widget _avatar(String letter, List<Color> colors) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.20), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      alignment: Alignment.center,
      child: Text(letter,
          style: const TextStyle(
              color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _mockText(context);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: featureAccentEmerald.withValues(alpha: 0.12),
              border: Border.all(color: featureAccentEmerald.withValues(alpha: 0.35)),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.lock_rounded, size: 12, color: featureAccentEmerald),
              const SizedBox(width: 4),
              Text(t.e2eeBadge,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: featureAccentEmerald)),
            ]),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Stack(children: [
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              SizedBox(
                width: 78,
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _avatar(t.peerAlice.characters.first,
                      [const Color(0xFFF87171), const Color(0xFFB91C5C)]),
                  const SizedBox(height: 4),
                  Text(t.peerAlice,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  _MessageFly(
                    toRight: true,
                    child: _peerBubble(context, outgoing: true, text: t.peerHello),
                  ),
                ]),
              ),
              const SizedBox(width: 6),
              const Expanded(child: SizedBox(height: 44, child: _CipherStream())),
              const SizedBox(width: 6),
              SizedBox(
                width: 78,
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _avatar(t.peerBob.characters.first,
                      [featureAccentPrimary, const Color(0xFF7C3AED)]),
                  const SizedBox(height: 4),
                  Text(t.peerBob,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  _MessageFly(
                    toRight: false,
                    child: _peerBubble(context, outgoing: false, text: t.peerHello),
                  ),
                ]),
              ),
            ]),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Center(
                child: _Breathing(
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
                      border: Border.all(color: featureAccentEmerald.withValues(alpha: 0.50)),
                      boxShadow: [
                        BoxShadow(
                            color: featureAccentEmerald.withValues(alpha: 0.35),
                            blurRadius: 8,
                            spreadRadius: 1),
                      ],
                    ),
                    child: Icon(Icons.shield_rounded, size: 16, color: featureAccentEmerald),
                  ),
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 6),
        // Реальный `E2eeFingerprintBadge`: Fingerprint-иконка + двухстрочный
        // блок (hint сверху, monospace ниже). Здесь — пара для обеих сторон
        // и пилюля «совпали» между ними.
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Expanded(child: _FingerprintBadge(label: t.peerAlice)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: featureAccentEmerald.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(t.fingerprintMatch.toUpperCase(),
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: featureAccentEmerald)),
          ),
          const SizedBox(width: 6),
          Expanded(child: _FingerprintBadge(label: t.peerBob, alignRight: true)),
        ]),
      ]),
    );
  }
}

/// Точная мини-копия `E2eeFingerprintBadge` (web): иконка `Fingerprint` +
/// uppercase-hint сверху + monospace-код снизу.
class _FingerprintBadge extends StatelessWidget {
  const _FingerprintBadge({required this.label, this.alignRight = false});
  final String label;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    final body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text('E2EE · $label',
            style: TextStyle(
                fontSize: 7,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55))),
        Text('5f2a · 8b91',
            style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: featureAccentEmerald)),
      ],
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: featureAccentEmerald.withValues(alpha: 0.05),
        border: Border.all(color: featureAccentEmerald.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
          mainAxisSize: MainAxisSize.min,
          textDirection: alignRight ? TextDirection.rtl : TextDirection.ltr,
          children: [
            Icon(Icons.fingerprint_rounded,
                size: 11, color: featureAccentEmerald),
            const SizedBox(width: 4),
            // Принудительно вернуть LTR внутри текста, чтобы цифры не
            // зеркалились.
            Directionality(textDirection: TextDirection.ltr, child: body),
          ]),
    );
  }
}

// --- 2. Secret chats: чат + 3 плашки-«правила» снизу ---

/// Реалистичный мокап секретного чата: обычный чат + миниатюра
/// `SecretChatSettingsDialog` (три switch-row) вместо «трёх таблеток».
/// В реальном чате никаких иконок-плашек правил снизу нет — настройки
/// живут в отдельном диалоге, который и показан здесь.
class MockSecretChats extends StatelessWidget {
  const MockSecretChats({super.key});
  @override
  Widget build(BuildContext context) {
    final t = _mockText(context);
    return _ChatLikeMock(
      header: _MockChatHeader(name: t.groupProject, status: t.secretStatus),
      bubbles: [
        _MockBubble(text: t.secretMsg1, outgoing: false, time: '14:02'),
        _MockBubble(text: t.secretMsg2, outgoing: true, time: '14:03'),
      ],
      footer: Container(
        decoration: BoxDecoration(
          color: featureAccentViolet.withValues(alpha: 0.05),
          border: Border.all(color: featureAccentViolet.withValues(alpha: 0.25)),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.all(6),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 2, bottom: 4),
            child: Text(t.secretSettingsTitle,
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: featureAccentViolet)),
          ),
          _SecretSettingRow(
              icon: Icons.timer_outlined,
              label: t.secretSettingTtl,
              value: t.secretSettingTtlValue,
              on: true),
          _SecretSettingRow(
              icon: Icons.visibility_off_outlined,
              label: t.secretSettingNoForward,
              on: true),
          _SecretSettingRow(
              icon: Icons.lock_outline_rounded,
              label: t.secretSettingLock,
              on: false),
        ]),
      ),
    );
  }
}

class _SecretSettingRow extends StatelessWidget {
  const _SecretSettingRow({
    required this.icon,
    required this.label,
    this.value,
    required this.on,
  });
  final IconData icon;
  final String label;
  final String? value;
  final bool on;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        Icon(icon, size: 13, color: featureAccentViolet),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
              if (value != null)
                Text(value!,
                    style: TextStyle(
                        fontSize: 9,
                        color: scheme.onSurface.withValues(alpha: 0.55))),
            ],
          ),
        ),
        // Статичный switch (визуал).
        Container(
          width: 22,
          height: 12,
          decoration: BoxDecoration(
            color: on ? featureAccentPrimary : scheme.onSurface.withValues(alpha: 0.30),
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: on ? Alignment.centerRight : Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 1.5),
          child: Container(
            width: 9,
            height: 9,
            decoration: const BoxDecoration(
                color: Colors.white, shape: BoxShape.circle),
          ),
        ),
      ]),
    );
  }
}

// --- 3. Disappearing: обычные баблы, старые тают сверху ---

class MockDisappearing extends StatelessWidget {
  const MockDisappearing({super.key});
  @override
  Widget build(BuildContext context) {
    final t = _mockText(context);
    return Column(children: [
      _MockChatHeader(name: t.teamDesign, status: t.disappearingStatus),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _FadeVanish(
                child: _MockBubble(
                    text: t.disappearingMsg4, outgoing: true, time: '09:18'),
              ),
              _FadeVanish(
                delay: const Duration(milliseconds: 600),
                child: _MockBubble(
                    text: t.disappearingMsg3, outgoing: false, time: '09:16'),
              ),
              _FadeInUp(child: _MockBubble(text: t.disappearingMsg2, outgoing: true, time: '09:15')),
              _FadeInUp(
                delay: const Duration(milliseconds: 250),
                child: _MockBubble(text: t.disappearingMsg1, outgoing: false, time: '09:14'),
              ),
            ],
          ),
        ),
      ),
    ]);
  }
}

// --- 4. Scheduled: чат + панель «Запланированные» ---

/// Чат + наезжающий снизу `ScheduledMessagesSheet` (Bottom Sheet с
/// drag-handle сверху). Точка входа в реальном UI — иконка
/// `CalendarClock` с бейджем-счётчиком в шапке чата; повторяем оба.
class MockScheduled extends StatelessWidget {
  const MockScheduled({super.key});
  @override
  Widget build(BuildContext context) {
    final t = _mockText(context);
    return Column(children: [
      _MockChatHeader(name: t.peerMikhail, status: t.mikhailStatus),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _FadeInUp(
                child: _MockBubble(
                    text: t.scheduledMsg1, outgoing: false, time: '20:11'),
              ),
              _FadeInUp(
                delay: const Duration(milliseconds: 250),
                child: _MockBubble(
                    text: t.scheduledMsg2, outgoing: true, time: '20:12'),
              ),
            ],
          ),
        ),
      ),
      // Bottom Sheet — наезжает снизу с drag-handle.
      _FadeInUp(
        delay: const Duration(milliseconds: 500),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.96),
            border: Border(
              top: BorderSide(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08)),
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 14,
                  offset: const Offset(0, -6),
                  spreadRadius: -4),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(children: [
              Text(t.scheduledQueueTitle,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: featureAccentPrimary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('1',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: featureAccentPrimary)),
              ),
            ]),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: featureAccentPrimary.withValues(alpha: 0.15),
                  ),
                  child: Icon(Icons.schedule_rounded,
                      size: 14, color: featureAccentPrimary),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(t.scheduledMsg3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600)),
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.event_outlined,
                            size: 9,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55)),
                        const SizedBox(width: 3),
                        Text(t.scheduledQueueDate,
                            style: TextStyle(
                                fontSize: 9,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55))),
                      ]),
                    ],
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    ]);
  }
}

// --- 5. Games: реальный стол «Дурака» ---

/// Игральная карта в стиле реального `DurakCardWidget`.
/// Игральная карта в стиле реального `DurakCardWidget`:
///  – face-up: off-white фон `#F6F7FB`, ОДИН большой символ масти по центру;
///    в углу — `rank+suit` одной строкой («7♠»), и тот же блок повёрнут на 180°
///    в нижнем-правом углу.
///  – козырь: жёлтая обводка `#FBBF24` + лёгкая жёлтая тень.
///  – face-down: тёмно-синий градиент `#2C3E66 → #1A2540` с белым кружком.
class _DurakCard extends StatelessWidget {
  const _DurakCard({
    this.rank,
    this.suit,
    this.red = false,
    this.trump = false,
    this.faceDown = false,
    this.width = 44,
    this.height = 64,
  });
  final String? rank;
  final String? suit;
  final bool red;
  final bool trump;
  final bool faceDown;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (faceDown) {
      return Container(
        width: width,
        height: height,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.40),
                blurRadius: 6,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2C3E66), Color(0xFF1A2540)],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          alignment: Alignment.center,
          child: Container(
            width: width * 0.30,
            height: width * 0.30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.32)),
            ),
          ),
        ),
      );
    }
    final fg = red ? const Color(0xFFDC2626) : const Color(0xFF111827);
    final cornerLabel = '${rank ?? ''}${suit ?? ''}';
    final cornerStyle = TextStyle(
      color: fg,
      fontWeight: FontWeight.w900,
      fontSize: (width * 0.22).clamp(9.0, 13.0),
      height: 1,
    );
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: trump
              ? const Color(0xFFFBBF24).withValues(alpha: 0.85)
              : Colors.black.withValues(alpha: 0.15),
          width: trump ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.30),
              blurRadius: 6,
              offset: const Offset(0, 4)),
          if (trump)
            BoxShadow(
                color: const Color(0xFFFBBF24).withValues(alpha: 0.30), blurRadius: 8),
        ],
      ),
      child: Stack(children: [
        Positioned(left: 3, top: 2, child: Text(cornerLabel, style: cornerStyle)),
        Center(
          child: Text(
            suit ?? '',
            style: TextStyle(
              color: fg.withValues(alpha: 0.92),
              fontWeight: FontWeight.w900,
              fontSize: (width * 0.55).clamp(16.0, 28.0),
              height: 1,
            ),
          ),
        ),
        Positioned(
          right: 3,
          bottom: 2,
          child: RotatedBox(
            quarterTurns: 2,
            child: Text(cornerLabel, style: cornerStyle),
          ),
        ),
      ]),
    );
  }
}

/// Анимированный мокап «Дурака» в стиле реального экрана LighChat:
///  – фон стола: радиальный сине-серый градиент `#5F86A1 → #253F52 → black`
///    (палитра `DurakFeltBackground`);
///  – сверху аватар оппонента с зелёным ringом «ход» и счётчиком карт;
///  – слева колода-стопка + козырь (горизонтально, лицом вверх) НАД ней;
///  – справа сброс (стопка рубашек);
///  – по центру 3 пары атак-защит, появляются по очереди и в финале улетают
///    к проигравшему оппоненту (он «забирает»);
///  – внизу — рука игрока (8 карт ровным рядом, с лёгким overlap, козыри
///    подсвечены жёлтым).
class MockGames extends StatefulWidget {
  const MockGames({super.key});
  @override
  State<MockGames> createState() => _MockGamesState();
}

class _MockGamesState extends State<MockGames> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 10))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _mockText(context);

    // Пары на столе. Каждая пара появляется по timeline с отдельным delay.
    // На фазе collect (>0.80) все улетают к аватару проигравшего сверху.
    final pairs = <_DurakPair>[
      _DurakPair(
        atk: _CardData('7', '♣'),
        def: _CardData('9', '♣'),
        atkAt: 0.04,
        defAt: 0.14,
      ),
      _DurakPair(
        atk: _CardData('10', '♦', red: true),
        def: _CardData('Q', '♦', red: true),
        atkAt: 0.26,
        defAt: 0.36,
      ),
      _DurakPair(
        atk: _CardData('J', '♠'),
        def: _CardData('K', '♠'),
        atkAt: 0.48,
        defAt: 0.58,
      ),
    ];

    final hand = <_CardData>[
      _CardData('6', '♠'),
      _CardData('8', '♥', red: true),
      _CardData('9', '♥', red: true, trump: true),
      _CardData('J', '♥', red: true, trump: true),
      _CardData('Q', '♣'),
      _CardData('K', '♠'),
      _CardData('10', '♦', red: true),
      _CardData('A', '♦', red: true),
    ];

    return Stack(fit: StackFit.expand, children: [
      // Реальный сине-серый стол (как DurakFeltBackground)
      Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.2, -0.3),
            radius: 1.2,
            colors: [Color(0xFF5F86A1), Color(0xFF253F52), Color(0xFF0B121B)],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
      ),
      // Лёгкая виньетка
      Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.15,
            colors: [Colors.transparent, Color(0x59000000)],
            stops: [0.55, 1.0],
          ),
        ),
      ),

      AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final p = _c.value;

          return Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
            child: Column(children: [
              // Top: аватар оппонента + бейдж счётчика + имя/«ход»
              _OpponentHeader(
                name: t.peerAlice,
                cards: 5,
                yourTurnLabel: t.gamesYourTurn,
                pulse: _opponentPulse(p),
              ),
              const SizedBox(height: 4),

              // Middle: deck/trump слева, пары по центру, сброс справа
              Expanded(
                child: Stack(children: [
                  // Колода + козырь слева
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: SizedBox(
                        width: 56,
                        height: 56,
                        child: Stack(clipBehavior: Clip.none, children: [
                          // Стопка-колода (3 рубашки, лёгкий offset)
                          const Positioned(
                            left: 4,
                            top: 8,
                            child: _DurakCard(faceDown: true, width: 26, height: 38),
                          ),
                          const Positioned(
                            left: 2,
                            top: 6,
                            child: _DurakCard(faceDown: true, width: 26, height: 38),
                          ),
                          const Positioned(
                            left: 0,
                            top: 4,
                            child: _DurakCard(faceDown: true, width: 26, height: 38),
                          ),
                          // Козырь — лежит горизонтально НАД стопкой
                          // (визуально выше по экрану), лицом вверх.
                          Positioned(
                            top: -6,
                            left: 14,
                            child: Transform.rotate(
                              angle: 1.5708,
                              child: const _DurakCard(
                                rank: '7',
                                suit: '♥',
                                red: true,
                                trump: true,
                                width: 26,
                                height: 38,
                              ),
                            ),
                          ),
                          // Бейдж счётчика
                          Positioned(
                            left: -4,
                            bottom: -4,
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text('${t.gamesDeck} · 12',
                                  style: const TextStyle(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white)),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ),

                  // Сброс справа (стопка рубашек)
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: SizedBox(
                        width: 36,
                        height: 50,
                        child: Stack(clipBehavior: Clip.none, children: [
                          for (var i = 0; i < 3; i++)
                            Positioned(
                              top: i * 1.5,
                              left: i * 1.5,
                              child: const _DurakCard(
                                  faceDown: true, width: 26, height: 38),
                            ),
                        ]),
                      ),
                    ),
                  ),

                  // Пары на столе по центру (анимированы через `p`)
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < pairs.length; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: SizedBox(
                              width: 42,
                              height: 60,
                              child: Stack(clipBehavior: Clip.none, children: [
                                // Слот-плейсхолдер «+» — виден на финальной фазе.
                                Positioned.fill(
                                  child: Opacity(
                                    opacity: _slotEmptyOpacity(p),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color: Colors.white.withValues(alpha: 0.30),
                                            style: BorderStyle.solid),
                                      ),
                                      alignment: Alignment.center,
                                      child: Icon(Icons.add_rounded,
                                          size: 14,
                                          color: Colors.white.withValues(alpha: 0.55)),
                                    ),
                                  ),
                                ),
                                // Атакующая карта
                                _AnimatedTableCard(
                                  card: pairs[i].atk,
                                  appearAt: pairs[i].atkAt,
                                  collectStart: 0.80,
                                  collectDx: 0,
                                  collectDy: -90,
                                ),
                                // Защитная карта со смещением
                                Positioned(
                                  left: 6,
                                  top: 6,
                                  child: _AnimatedTableCard(
                                    card: pairs[i].def,
                                    appearAt: pairs[i].defAt,
                                    collectStart: 0.80,
                                    collectDx: 0,
                                    collectDy: -96,
                                    rotateRad: 0.15,
                                  ),
                                ),
                              ]),
                            ),
                          ),
                      ],
                    ),
                  ),
                ]),
              ),

              // Bottom: рука игрока — 8 карт ровно
              SizedBox(
                height: 50,
                child: Stack(alignment: Alignment.center, children: [
                  for (var i = 0; i < hand.length; i++)
                    Transform.translate(
                      offset: Offset((i - (hand.length - 1) / 2) * 22, 0),
                      child: _DurakCard(
                        rank: hand[i].rank,
                        suit: hand[i].suit,
                        red: hand[i].red,
                        trump: hand[i].trump,
                        width: 28,
                        height: 42,
                      ),
                    ),
                ]),
              ),
            ]),
          );
        },
      ),
    ]);
  }

  /// Подсветка аватара проигравшего на финальной фазе (>0.85).
  double _opponentPulse(double p) {
    if (p < 0.82) return 0.0;
    if (p < 0.92) return (p - 0.82) / 0.10;
    return ((1.0 - p) / 0.08).clamp(0.0, 1.0);
  }

  /// Прозрачность слота-плейсхолдера: видим только во время «забора» (>0.85).
  double _slotEmptyOpacity(double p) {
    if (p < 0.84) return 0.0;
    return ((p - 0.84) / 0.10).clamp(0.0, 1.0);
  }
}

class _CardData {
  const _CardData(this.rank, this.suit, {this.red = false, this.trump = false});
  final String rank;
  final String suit;
  final bool red;
  final bool trump;
}

class _DurakPair {
  const _DurakPair({
    required this.atk,
    required this.def,
    required this.atkAt,
    required this.defAt,
  });
  final _CardData atk;
  final _CardData def;
  final double atkAt;
  final double defAt;
}

/// Карта на столе с анимацией: появляется в `appearAt`, висит, на
/// `collectStart` улетает к аватару проигравшего (collectDx/Dy — конечный
/// сдвиг). Использует `AnimationController` родителя через `AnimatedBuilder`.
class _AnimatedTableCard extends StatelessWidget {
  const _AnimatedTableCard({
    required this.card,
    required this.appearAt,
    required this.collectStart,
    required this.collectDx,
    required this.collectDy,
    this.rotateRad = 0,
  });
  final _CardData card;
  final double appearAt;
  final double collectStart;
  final double collectDx;
  final double collectDy;
  final double rotateRad;

  @override
  Widget build(BuildContext context) {
    // p берётся из родительского AnimatedBuilder через ScopedTransitions —
    // но у нас есть удобный путь: смотрим на _MockGamesState через
    // `context.findAncestorStateOfType`. Чтобы не лазать, используем
    // `MediaQuery`-подобный паттерн: родитель уже rebuild'ит этот виджет
    // на каждом тике, потому что весь поддерев пересобирается внутри
    // AnimatedBuilder.
    final state = context.findAncestorStateOfType<_MockGamesState>()!;
    final p = state._c.value;

    double opacity;
    double dx = 0;
    double dy = 0;
    double scale = 1.0;
    double rot = rotateRad;

    if (p < appearAt) {
      // До появления — невидима, у руки внизу.
      opacity = 0;
      dy = 30;
      scale = 0.85;
    } else if (p < appearAt + 0.06) {
      // Появление: летит снизу к слоту.
      final k = (p - appearAt) / 0.06;
      opacity = k;
      dy = (1 - k) * 30;
      scale = 0.85 + 0.15 * k;
    } else if (p < collectStart) {
      // Лежит на столе.
      opacity = 1;
      dy = 0;
      scale = 1.0;
    } else if (p < collectStart + 0.10) {
      // Сборка: улетает к проигравшему.
      final k = (p - collectStart) / 0.10;
      final ease = Curves.easeIn.transform(k);
      opacity = 1 - ease;
      dx = collectDx * ease;
      dy = collectDy * ease;
      rot = rotateRad + ease * 0.4;
      scale = 1.0 - ease * 0.4;
    } else {
      opacity = 0;
    }

    return Opacity(
      opacity: opacity,
      child: Transform.translate(
        offset: Offset(dx, dy),
        child: Transform.rotate(
          angle: rot,
          child: Transform.scale(
            scale: scale,
            child: _DurakCard(
              rank: card.rank,
              suit: card.suit,
              red: card.red,
              trump: card.trump,
              width: 30,
              height: 44,
            ),
          ),
        ),
      ),
    );
  }
}

/// Аватар оппонента сверху + бейдж счётчика + ринг на финальной фазе.
class _OpponentHeader extends StatelessWidget {
  const _OpponentHeader({
    required this.name,
    required this.cards,
    required this.yourTurnLabel,
    required this.pulse,
  });
  final String name;
  final int cards;
  final String yourTurnLabel;
  final double pulse;

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Stack(clipBehavior: Clip.none, children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF87171), Color(0xFFB91C5C)],
            ),
            border: Border.all(
                color: const Color(0xFF6EE7B7).withValues(alpha: 0.85), width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF87171)
                    .withValues(alpha: (pulse * 0.55).clamp(0.0, 0.55)),
                blurRadius: 14 * pulse,
                spreadRadius: 4 * pulse,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(name.characters.first.toUpperCase(),
              style: const TextStyle(
                  color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
        ),
        Positioned(
          right: -4,
          top: -2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withValues(alpha: 0.20))),
            child: Text('$cards',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800)),
          ),
        ),
      ]),
      const SizedBox(height: 2),
      Text(name,
          style: const TextStyle(
              fontSize: 9.5, fontWeight: FontWeight.w800, color: Colors.white)),
      Text(yourTurnLabel,
          style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF6EE7B7).withValues(alpha: 0.95))),
    ]);
  }
}

// --- 6. Meetings: 4 тайла встречи ---

class MockMeetings extends StatelessWidget {
  const MockMeetings({super.key});
  @override
  Widget build(BuildContext context) {
    final t = _mockText(context);
    final tiles = [
      ('A', const Color(0xFFB91C5C), false, false),
      ('M', featureAccentPrimary, true, false),
      ('J', featureAccentEmerald, false, true),
      ('K', featureAccentViolet, false, false),
    ];
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.55),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(children: [
            Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(t.meetingDuration,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
            const Spacer(),
            const Icon(Icons.people_alt_outlined, size: 12),
            const SizedBox(width: 3),
            const Text('4', style: TextStyle(fontSize: 10)),
          ]),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.4,
            children: [
              for (var i = 0; i < tiles.length; i++)
                _FadeInUp(
                  delay: Duration(milliseconds: i * 120),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [tiles[i].$2.withValues(alpha: 0.85), tiles[i].$2.withValues(alpha: 0.55)],
                      ),
                      // Активный спикер — синий ring (`ring-primary` на web),
                      // как в реальном `MeetingRoom`. Никаких emerald.
                      border: Border.all(
                          color: tiles[i].$4
                              ? featureAccentPrimary.withValues(alpha: 0.95)
                              : Colors.white.withValues(alpha: 0.10),
                          width: tiles[i].$4 ? 2 : 1),
                    ),
                    child: Stack(children: [
                      Center(
                        child: tiles[i].$4
                            ? _Breathing(
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.30),
                                      shape: BoxShape.circle),
                                  alignment: Alignment.center,
                                  child: Text(tiles[i].$1,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700)),
                                ),
                              )
                            : Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.20),
                                    shape: BoxShape.circle),
                                alignment: Alignment.center,
                                child: Text(tiles[i].$1,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700)),
                              ),
                      ),
                      Positioned(
                        bottom: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(
                            tiles[i].$3 ? Icons.mic_off_rounded : Icons.mic_rounded,
                            size: 9,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      // Текстовых label-ов «Speaking» нет в реальном UI —
                      // активный спикер обозначается только border-ом
                      // тайла (см. ниже).
                    ]),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        // Реальный `MeetingControls`: pill с группами по 2-3 кнопки,
        // разделёнными `bg-white/10` separator'ами. Leave-кнопка красная,
        // отделена от остальных.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.40),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _meetCtrl(Icons.videocam_outlined),
            _meetCtrl(Icons.mic),
            _meetSep(),
            _meetCtrl(Icons.back_hand_outlined),
            _meetCtrl(Icons.emoji_emotions_outlined),
            _meetSep(),
            _meetCtrl(Icons.people_alt_outlined),
            _meetCtrl(Icons.bar_chart_rounded),
            _meetCtrl(Icons.chat_bubble_outline_rounded),
            _meetCtrl(Icons.screen_share_outlined),
            _meetSep(),
            _meetCtrl(Icons.call_end_rounded,
                bg: const Color(0xFFEF4444), iconColor: Colors.white),
          ]),
        ),
      ]),
    );
  }
}

/// Одиночная круглая кнопка контрол-бара встречи. По умолчанию —
/// полупрозрачный белый фон с белой иконкой.
Widget _meetCtrl(IconData icon, {Color? bg, Color? iconColor}) {
  return Container(
    width: 22,
    height: 22,
    margin: const EdgeInsets.symmetric(horizontal: 1.5),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: bg ?? Colors.white.withValues(alpha: 0.10),
      boxShadow: bg == const Color(0xFFEF4444)
          ? [
              BoxShadow(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.5),
                  blurRadius: 6),
            ]
          : null,
    ),
    alignment: Alignment.center,
    child: Icon(icon, size: 11, color: iconColor ?? Colors.white),
  );
}

Widget _meetSep() {
  return Container(
    width: 1,
    height: 12,
    margin: const EdgeInsets.symmetric(horizontal: 3),
    color: Colors.white.withValues(alpha: 0.10),
  );
}

// --- 7. Calls: pill аудио-звонка + видео-кружок ---

/// Реалистичный мокап звонков: fullscreen-overlay стиль `AudioCallOverlay`
/// (тёмный фон, большой аватар по центру, кнопки mic/end) + видео-кружок
/// в стиле `VideoCirclePlayer` с SVG progress-кольцом вокруг.
/// Никакого эквалайзера — в реальном `AudioCallOverlay` его нет.
class MockCalls extends StatelessWidget {
  const MockCalls({super.key});
  @override
  Widget build(BuildContext context) {
    final t = _mockText(context);
    return Stack(fit: StackFit.expand, children: [
      // Fullscreen `bg-slate-950` как у реального overlay.
      Container(color: const Color(0xFF02060F)),
      Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              featureAccentPrimary.withValues(alpha: 0.18),
              Colors.transparent,
            ],
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(14),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          // Большой аватар + свечение
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  featureAccentEmerald,
                  featureAccentEmerald.withValues(alpha: 0.7),
                ],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10), width: 3),
              boxShadow: [
                BoxShadow(
                    color: featureAccentEmerald.withValues(alpha: 0.45),
                    blurRadius: 24,
                    spreadRadius: 2),
              ],
            ),
            alignment: Alignment.center,
            child: Text(t.peerAlice.characters.first,
                style: const TextStyle(
                    color: Color(0xFF0F2D24), fontSize: 22, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 6),
          Text(t.peerAlice,
              style: const TextStyle(
                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
          Text(t.callsAudioMeta,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 10)),
          const SizedBox(height: 8),
          // Круглые кнопки mic / end / cam
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _callBtn(Icons.mic_rounded),
            const SizedBox(width: 12),
            _callBtn(Icons.call_end_rounded,
                bg: const Color(0xFFEF4444),
                glow: const Color(0xFFEF4444).withValues(alpha: 0.5)),
            const SizedBox(width: 12),
            _callBtn(Icons.videocam_outlined),
          ]),
          const SizedBox(height: 12),
          // Видео-кружок с SVG progress (как реальный VideoCirclePlayer)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              _VideoCircleWithProgress(
                initial: t.peerMikhail.characters.first,
                progress: 0.42,
                duration: '0:25 / 1:00',
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(t.callsCircleTitle,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                  Text(t.callsCircleMeta,
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.65))),
                ],
              ),
            ]),
          ),
        ]),
      ),
    ]);
  }
}

Widget _callBtn(IconData icon, {Color? bg, Color? glow}) {
  return Container(
    width: 28,
    height: 28,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: bg ?? Colors.white.withValues(alpha: 0.10),
      boxShadow: glow == null
          ? null
          : [BoxShadow(color: glow, blurRadius: 10, spreadRadius: 1)],
    ),
    alignment: Alignment.center,
    child: Icon(icon, size: 14, color: Colors.white),
  );
}

/// SVG-кольцо progress вокруг видео-кружка. 0..1 = прогресс воспроизведения.
class _VideoCircleWithProgress extends StatelessWidget {
  const _VideoCircleWithProgress({
    required this.initial,
    required this.progress,
    required this.duration,
  });
  final String initial;
  final double progress;
  final String duration;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(children: [
        // Progress ring через CustomPaint (Flutter эквивалент SVG-arc).
        Positioned.fill(
          child: CustomPaint(
            painter: _ProgressRingPainter(
              progress: progress,
              trackColor: Colors.white.withValues(alpha: 0.15),
              progressColor: featureAccentPrimary,
            ),
          ),
        ),
        // Сам кружок
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [featureAccentViolet, featureAccentPrimary],
                ),
                border: Border.all(color: const Color(0xFF02060F), width: 2),
              ),
              alignment: Alignment.center,
              child: Text(initial,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
            ),
          ),
        ),
        // Play overlay по центру
        Center(
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.5),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.play_arrow_rounded,
                size: 12, color: Colors.white),
          ),
        ),
        // Длительность в правом-верхнем углу
        Positioned(
          right: 0,
          top: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(duration,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 7,
                    fontWeight: FontWeight.w800)),
          ),
        ),
      ]),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  _ProgressRingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });
  final double progress;
  final Color trackColor;
  final Color progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - 4) / 2;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = trackColor;
    canvas.drawCircle(center, radius, track);
    if (progress > 0) {
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = progressColor;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress.clamp(0, 1),
        false,
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter old) =>
      old.progress != progress;
}

// --- 8. Folders & Threads ---

class MockFoldersThreads extends StatelessWidget {
  const MockFoldersThreads({super.key});
  @override
  Widget build(BuildContext context) {
    final t = _mockText(context);
    final scheme = Theme.of(context).colorScheme;
    final folders = [
      (t.folderAll, 24, false),
      (t.folderWork, 8, true),
      (t.folderFamily, 4, false),
      (t.folderStudy, 12, false),
    ];
    // В реальном `ConversationItem` тред-маркер встроен в строку чата
    // как маленький `<MessageSquare> N` бейдж — это и есть «треды».
    // Никаких отдельных блоков «Тред · …» под списком в реальном UI нет.
    final chats = [
      (t.chat1Name, t.chat1Last, 3, 0),
      (t.chat2Name, t.chat2Last, 0, 4),
      (t.chat3Name, t.chat3Last, 1, 0),
    ];
    return Row(children: [
      Container(
        width: 96,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: scheme.surface.withValues(alpha: 0.40),
          border: Border(right: BorderSide(color: scheme.onSurface.withValues(alpha: 0.08))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final f in folders)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 1),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: f.$3 ? featureAccentViolet.withValues(alpha: 0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: f.$3
                      ? Border.all(color: featureAccentViolet.withValues(alpha: 0.30))
                      : null,
                ),
                child: Row(children: [
                  Icon(f.$3 ? Icons.folder_open_rounded : Icons.folder_outlined,
                      size: 12,
                      color: f.$3 ? featureAccentViolet : scheme.onSurface.withValues(alpha: 0.6)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(f.$1,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: f.$3
                                ? featureAccentViolet
                                : scheme.onSurface.withValues(alpha: 0.7))),
                  ),
                  Text('${f.$2}',
                      style: TextStyle(
                          fontSize: 9,
                          color: scheme.onSurface.withValues(alpha: 0.55))),
                ]),
              ),
          ],
        ),
      ),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.folderWorkChats.toUpperCase(),
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface.withValues(alpha: 0.55),
                      letterSpacing: 0.6)),
              const SizedBox(height: 6),
              for (final c in chats)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(children: [
                    CircleAvatar(radius: 12, backgroundColor: featureAccentPrimary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(c.$1,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            Flexible(
                              child: Text(c.$2,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: scheme.onSurface.withValues(alpha: 0.55))),
                            ),
                            // Inline тред-бейдж — реальный `ConversationItem`.
                            if (c.$4 > 0) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: featureAccentViolet.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(Icons.chat_bubble_outline_rounded,
                                      size: 8, color: featureAccentViolet),
                                  const SizedBox(width: 2),
                                  Text('${c.$4}',
                                      style: TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.w800,
                                          color: featureAccentViolet)),
                                ]),
                              ),
                            ],
                          ]),
                        ],
                      ),
                    ),
                    if (c.$3 > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                            color: featureAccentPrimary,
                            borderRadius: BorderRadius.circular(999)),
                        child: Text('${c.$3}',
                            style: const TextStyle(
                                fontSize: 9,
                                color: Colors.white,
                                fontWeight: FontWeight.w700)),
                      ),
                  ]),
                ),
            ],
          ),
        ),
      ),
    ]);
  }
}

// --- 9. Live Location: ЗЕЛЁНЫЙ баннер (как реальный LiveLocationStopBanner) ---

class MockLiveLocation extends StatelessWidget {
  const MockLiveLocation({super.key});
  @override
  Widget build(BuildContext context) {
    final t = _mockText(context);
    return Stack(fit: StackFit.expand, children: [
      Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.4, -0.4),
            radius: 1.2,
            colors: [Color(0xFF6EC5E8), Color(0xFF1F4566)],
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Center(
              child: SizedBox(
                width: 80,
                height: 80,
                child: Stack(alignment: Alignment.center, children: [
                  _RepeatingPulse(
                    minScale: 1.0,
                    maxScale: 2.6,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        // Реальный баннер — зелёный (emerald).
                        color: featureAccentEmerald.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                  _RepeatingPulse(
                    minScale: 1.0,
                    maxScale: 2.6,
                    delay: const Duration(milliseconds: 1100),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: featureAccentEmerald.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                            color: featureAccentEmerald.withValues(alpha: 0.6),
                            blurRadius: 24,
                            spreadRadius: 4),
                      ],
                    ),
                    child: Icon(Icons.location_on_rounded,
                        color: featureAccentEmerald, size: 30),
                  ),
                ]),
              ),
            ),
            const Spacer(),
            // Реальный LiveLocationStopBanner: тёмно-зелёный, с MapPin и «Остановить».
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF052E1A).withValues(alpha: 0.92),
                border: Border.all(color: featureAccentEmerald.withValues(alpha: 0.40)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(children: [
                Icon(Icons.location_on_rounded,
                    size: 14, color: featureAccentEmerald.withValues(alpha: 0.85)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(t.liveLocationBanner,
                      style: const TextStyle(
                          color: Color(0xFFD1FAE5),
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.close_rounded, size: 12, color: Colors.white),
                    const SizedBox(width: 3),
                    Text(t.liveLocationStop,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  ]),
                ),
              ]),
            ),
          ],
        ),
      ),
    ]);
  }
}

// --- 10. Multi-device: новый — телефон + connector с ключами + ноут ---

class _QrCodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black;
    const cells = 21;
    final cell = size.width / cells;
    bool on(int r, int c) {
      // Угловые finder-метки (3 штуки).
      bool inFinder = false;
      for (final fr in [0, 14]) {
        for (final fc in [0, 14]) {
          if (fr == 14 && fc == 14) continue;
          if (r >= fr && r < fr + 7 && c >= fc && c < fc + 7) {
            final rr = r - fr;
            final cc = c - fc;
            final fOnEdge = rr == 0 || rr == 6 || cc == 0 || cc == 6;
            final fCore = rr >= 2 && rr <= 4 && cc >= 2 && cc <= 4;
            if (fOnEdge || fCore) return true;
            inFinder = true;
          }
        }
      }
      if (inFinder) return false;
      // Иначе детерминированный псевдо-узор.
      return ((r * 7 + c * 13) % 17) < 7;
    }

    for (var r = 0; r < cells; r++) {
      for (var c = 0; c < cells; c++) {
        if (on(r, c)) {
          canvas.drawRect(Rect.fromLTWH(c * cell, r * cell, cell, cell), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _QrScanLineSlim extends StatefulWidget {
  const _QrScanLineSlim({required this.height});
  final double height;

  @override
  State<_QrScanLineSlim> createState() => _QrScanLineSlimState();
}

class _QrScanLineSlimState extends State<_QrScanLineSlim>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return Positioned(
          top: 2 + (widget.height - 6) * _c.value,
          left: 2,
          right: 2,
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              color: featureAccentEmerald,
              boxShadow: [
                BoxShadow(
                    color: featureAccentEmerald.withValues(alpha: 0.7),
                    blurRadius: 6,
                    spreadRadius: 1),
              ],
            ),
          ),
        );
      },
    );
  }
}

class MockMultiDevice extends StatelessWidget {
  const MockMultiDevice({super.key});
  @override
  Widget build(BuildContext context) {
    final t = _mockText(context);
    return Stack(fit: StackFit.expand, children: [
      Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Phone
            _PhoneFrame(text: t),
            const SizedBox(width: 6),
            // Connector с бегущими ключами
            const Expanded(child: _PairingConnector()),
            const SizedBox(width: 6),
            // Laptop
            _LaptopFrame(text: t),
          ],
        ),
      ),
      // Backup pill снизу
      Positioned(
        left: 10,
        right: 10,
        bottom: 8,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: featureAccentEmerald.withValues(alpha: 0.10),
            border: Border.all(color: featureAccentEmerald.withValues(alpha: 0.30)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(children: [
            Icon(Icons.vpn_key_outlined, size: 14, color: featureAccentEmerald),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(t.multiDeviceBackup,
                      style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: featureAccentEmerald)),
                  Text(t.multiDeviceBackupSub,
                      style: TextStyle(
                          fontSize: 9.5,
                          color: featureAccentEmerald.withValues(alpha: 0.85))),
                ],
              ),
            ),
          ]),
        ),
      ),
    ]);
  }
}

class _PhoneFrame extends StatelessWidget {
  const _PhoneFrame({required this.text});
  final FeaturesMockText text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 86,
      height: 130,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 3),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(5),
      child: Column(children: [
        Container(
          width: 20,
          height: 3,
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(height: 4),
        Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.phone_iphone_rounded, color: featureAccentPrimary, size: 12),
          const SizedBox(width: 3),
          Flexible(
            child: Text(text.multiDevicePhone,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 6),
        Stack(children: [
          Container(
            width: 64,
            height: 64,
            color: Colors.white,
            padding: const EdgeInsets.all(2),
            child: CustomPaint(painter: _QrCodePainter()),
          ),
          const Positioned.fill(child: _QrScanLineSlim(height: 64)),
        ]),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: featureAccentEmerald.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(text.multiDevicePairing,
              style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  color: featureAccentEmerald)),
        ),
      ]),
    );
  }
}

class _LaptopFrame extends StatelessWidget {
  const _LaptopFrame({required this.text});
  final FeaturesMockText text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(clipBehavior: Clip.none, children: [
      Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 130,
          height: 80,
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border.all(color: scheme.onSurface, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.desktop_mac_outlined, size: 10),
                const SizedBox(width: 3),
                Flexible(
                  child: Text('LighChat · ${text.multiDeviceDesktop}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700)),
                ),
              ]),
              const SizedBox(height: 4),
              Expanded(
                child: Row(children: [
                  Expanded(
                      child: Container(
                          color: scheme.onSurface.withValues(alpha: 0.10))),
                  const SizedBox(width: 4),
                  Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                              height: 8,
                              color: scheme.onSurface.withValues(alpha: 0.10)),
                          const SizedBox(height: 3),
                          Container(
                              height: 8,
                              color: scheme.onSurface.withValues(alpha: 0.10)),
                          const SizedBox(height: 3),
                          Container(
                              height: 8,
                              color: featureAccentPrimary.withValues(alpha: 0.40)),
                        ],
                      )),
                ]),
              ),
            ],
          ),
        ),
        Container(
          width: 56,
          height: 4,
          decoration: BoxDecoration(
              color: scheme.onSurface,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(4))),
        ),
      ]),
      // Зелёный чек «подключено»
      Positioned(
        top: -6,
        right: -6,
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: featureAccentEmerald,
            boxShadow: [
              BoxShadow(
                  color: featureAccentEmerald.withValues(alpha: 0.5),
                  blurRadius: 6,
                  spreadRadius: 1),
            ],
          ),
          child: const Icon(Icons.check_rounded,
              size: 14, color: Colors.white),
        ),
      ),
    ]);
  }
}

class _PairingConnector extends StatelessWidget {
  const _PairingConnector();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: Stack(alignment: Alignment.center, children: [
        // Пунктирная линия
        Positioned(
          left: 0,
          right: 0,
          top: 11,
          child: CustomPaint(
            size: const Size.fromHeight(2),
            painter: _DashedLinePainter(),
          ),
        ),
        // Бегущие ключики
        Positioned.fill(
          child: _MarqueeStream(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                14,
                (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(Icons.vpn_key_rounded,
                      size: 11, color: featureAccentPrimary.withValues(alpha: 0.85)),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = featureAccentPrimary.withValues(alpha: 0.45)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    const dash = 4.0;
    const gap = 3.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dash, 0), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// --- 11. Stickers & Media ---

class MockStickersMedia extends StatelessWidget {
  const MockStickersMedia({super.key});
  @override
  Widget build(BuildContext context) {
    final t = _mockText(context);
    // Реальный sticker-picker — `grid-cols-3`. Опрос и фото-редактор —
    // отдельные UI; ниже мы выделяем их меченым блоком, чтобы было понятно.
    final faces = ['😀', '😎', '🤩', '😴', '😡', '🤔'];
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
            border: Border.all(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08)),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(children: [
            Icon(Icons.search_rounded,
                size: 12,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
            const SizedBox(width: 6),
            Text(t.stickerSearchHint,
                style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
            const Spacer(),
            Icon(Icons.emoji_emotions_outlined, size: 14, color: featureAccentAmber),
          ]),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: GridView.count(
            crossAxisCount: 3,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (var i = 0; i < faces.length; i++)
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: i.isEven
                          ? [featureAccentAmber, featureAccentCoral]
                          : [featureAccentViolet, featureAccentPrimary],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(faces[i], style: const TextStyle(fontSize: 24)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        // Подпись «Polls / Photo editor — separate dialogs» — отдельные
        // UI, а не часть emoji-popover.
        Row(children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.55),
                border: Border.all(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                Icon(Icons.bar_chart_rounded, size: 11, color: featureAccentAmber),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(t.pollLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 9, fontWeight: FontWeight.w800)),
                ),
              ]),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.55),
                border: Border.all(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                Icon(Icons.image_outlined, size: 11, color: featureAccentCoral),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(t.editorLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 9, fontWeight: FontWeight.w800)),
                ),
              ]),
            ),
          ),
        ]),
      ]),
    );
  }
}

// --- 12. Privacy ---

class MockPrivacy extends StatelessWidget {
  const MockPrivacy({super.key});
  @override
  Widget build(BuildContext context) {
    final t = _mockText(context);
    final scheme = Theme.of(context).colorScheme;

    Widget row(String label, String hint, bool on) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: scheme.surface.withValues(alpha: 0.6),
          border: Border.all(color: scheme.onSurface.withValues(alpha: 0.08)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                Text(hint,
                    style: TextStyle(
                        fontSize: 9, color: scheme.onSurface.withValues(alpha: 0.6))),
              ],
            ),
          ),
          Container(
            width: 30,
            height: 16,
            decoration: BoxDecoration(
              color: on ? featureAccentPrimary : scheme.onSurface.withValues(alpha: 0.30),
              borderRadius: BorderRadius.circular(999),
            ),
            alignment: on ? Alignment.centerRight : Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
          ),
        ]),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: featureAccentPrimary.withValues(alpha: 0.10),
            border: Border.all(color: featureAccentPrimary.withValues(alpha: 0.25)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(children: [
            Icon(Icons.shield_outlined, size: 14, color: featureAccentPrimary),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.privacyTitle,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  Text(t.privacySubtitle,
                      style: const TextStyle(fontSize: 9)),
                ],
              ),
            ),
          ]),
        ),
        const SizedBox(height: 6),
        row(t.privacyOnline, t.privacyOnlineHint, true),
        row(t.privacyLastSeen, t.privacyLastSeenHint, false),
        row(t.privacyReceipts, t.privacyReceiptsHint, true),
      ]),
    );
  }
}

// =====================================================================
//  Mapping
// =====================================================================

Widget buildFeatureMockFor(FeatureTopicId id) {
  switch (id) {
    case FeatureTopicId.encryption:
      return const MockEncryption();
    case FeatureTopicId.secretChats:
      return const MockSecretChats();
    case FeatureTopicId.disappearingMessages:
      return const MockDisappearing();
    case FeatureTopicId.scheduledMessages:
      return const MockScheduled();
    case FeatureTopicId.games:
      return const MockGames();
    case FeatureTopicId.meetings:
      return const MockMeetings();
    case FeatureTopicId.calls:
      return const MockCalls();
    case FeatureTopicId.foldersThreads:
      return const MockFoldersThreads();
    case FeatureTopicId.liveLocation:
      return const MockLiveLocation();
    case FeatureTopicId.multiDevice:
      return const MockMultiDevice();
    case FeatureTopicId.stickersMedia:
      return const MockStickersMedia();
    case FeatureTopicId.privacy:
      return const MockPrivacy();
  }
}

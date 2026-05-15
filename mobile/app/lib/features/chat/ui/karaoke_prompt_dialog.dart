import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// Премиальный диалог-подтверждение перед открытием karaoke-режима.
///
/// Заменяет системный `AlertDialog`: своя палитра (не наследует тон от
/// обоев чата), анимированная иконка микрофона с пульсирующими кольцами,
/// мини-эквалайзер под ней, gradient «Открыть» и outlined «Закрыть».
class KaraokePromptDialog extends StatelessWidget {
  const KaraokePromptDialog._();

  /// Возвращает `true` если пользователь нажал «Открыть», иначе `false`.
  static Future<bool> show(BuildContext context) async {
    final res = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Karaoke',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (ctx, anim, _) => const KaraokePromptDialog._(),
      transitionBuilder: (ctx, anim, sec, child) {
        final curved =
            CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
    return res == true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      type: MaterialType.transparency,
      child: Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1F1A2E),
                      Color(0xFF15131F),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                    width: 1,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 30,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _AnimatedMicHero(),
                    const SizedBox(height: 18),
                    Text(
                      l10n.voice_karaoke_prompt_title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.voice_karaoke_prompt_body,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.62),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: _OutlinedActionButton(
                            label: l10n.chat_list_action_close,
                            onTap: () => Navigator.of(context).pop(false),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _GradientActionButton(
                            label: l10n.voice_karaoke_prompt_open,
                            onTap: () => Navigator.of(context).pop(true),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }
}

/// Микрофон с пульсирующими кольцами + мини-эквалайзер по бокам.
class _AnimatedMicHero extends StatefulWidget {
  const _AnimatedMicHero();

  @override
  State<_AnimatedMicHero> createState() => _AnimatedMicHeroState();
}

class _AnimatedMicHeroState extends State<_AnimatedMicHero>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _eq;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _eq = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _eq.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Слева — эквалайзер.
          Positioned(
            left: 0,
            child: _EqualizerBars(controller: _eq, mirrored: true),
          ),
          // Справа — эквалайзер.
          Positioned(
            right: 0,
            child: _EqualizerBars(controller: _eq, mirrored: false),
          ),
          // По центру — пульсирующие кольца и микрофон.
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) {
              final t = _pulse.value;
              return SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _PulseRing(t: (t + 0.0) % 1.0),
                    _PulseRing(t: (t + 0.5) % 1.0),
                    Container(
                      width: 62,
                      height: 62,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFE9DBFF),
                            Color(0xFFB39DFF),
                            Color(0xFF7C5CFF),
                          ],
                          stops: [0.0, 0.55, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x55B39DFF),
                            blurRadius: 18,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.mic_rounded,
                        color: Color(0xFF1B0E3A),
                        size: 32,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PulseRing extends StatelessWidget {
  const _PulseRing({required this.t});
  final double t; // 0..1

  @override
  Widget build(BuildContext context) {
    final scale = 0.7 + 0.55 * t;
    final opacity = (1.0 - t).clamp(0.0, 1.0) * 0.55;
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFFB39DFF).withValues(alpha: opacity),
            width: 2,
          ),
        ),
      ),
    );
  }
}

class _EqualizerBars extends StatelessWidget {
  const _EqualizerBars({required this.controller, required this.mirrored});

  final AnimationController controller;
  final bool mirrored;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 56,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final t = controller.value;
          final bars = List<Widget>.generate(4, (i) {
            final phase = (i * 0.22) + (mirrored ? 0.5 : 0.0);
            final v = (math.sin((t + phase) * 2 * math.pi) + 1) / 2;
            final h = 8.0 + 36.0 * v;
            return Container(
              width: 4,
              height: h,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFE9DBFF), Color(0xFF7C5CFF)],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          });
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: mirrored ? bars.reversed.toList() : bars,
          );
        },
      ),
    );
  }
}

class _GradientActionButton extends StatelessWidget {
  const _GradientActionButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE9DBFF),
              Color(0xFFB39DFF),
              Color(0xFF7C5CFF),
            ],
            stops: [0.0, 0.55, 1.0],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x44B39DFF),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: const SizedBox(
            height: 46,
            child: Center(
              child: Text(
                'placeholder', // overridden via Padding below
                style: TextStyle(fontSize: 0),
              ),
            ),
          ),
        ),
      ).addLabel(label),
    );
  }
}

/// Хакерный helper для добавления текста поверх Ink (Ink требует Material
/// между ним и текстом, поэтому Stack — самый чистый путь).
extension _IconLabel on Widget {
  Widget addLabel(String label) {
    return Stack(
      alignment: Alignment.center,
      children: [
        this,
        IgnorePointer(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1B0E3A),
              letterSpacing: -0.1,
            ),
          ),
        ),
      ],
    );
  }
}

class _OutlinedActionButton extends StatelessWidget {
  const _OutlinedActionButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: Colors.white.withValues(alpha: 0.16),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 46,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.88),
                letterSpacing: -0.1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:go_router/go_router.dart';

import '../../../brand_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../data/first_login_animation_storage.dart';
import '../../features_tour/data/features_tour_storage.dart';
import 'welcome_painters.dart';

/// Master timeline ≈ 8s. Все фазы — нормализованные к [0..1] окна.
const Duration _kTotalDuration = Duration(milliseconds: 8700);
const Duration _kReducedMotionHold = Duration(milliseconds: 1000);

class WelcomeAnimationScreen extends StatefulWidget {
  const WelcomeAnimationScreen({super.key});

  @override
  State<WelcomeAnimationScreen> createState() => _WelcomeAnimationScreenState();
}

class _WelcomeAnimationScreenState extends State<WelcomeAnimationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _exited = false;
  bool _reducedMotion = false;
  final List<Offset> _trail = [];
  final Set<String> _hapticFired = <String>{};

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _kTotalDuration);
    _controller.addStatusListener(_onStatus);
    _controller.addListener(_onTick);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      FirstLoginAnimationStorage.markShownFor(uid);
    }
    if (kDebugMode) {
      debugPrint('[welcome-screen] mounted uid=$uid');
    }
  }

  void _onTick() {
    final t = _controller.value;
    if (t > 0.172 && _hapticFired.add('lighthouse')) {
      HapticFeedback.selectionClick();
    }
    if (t > 0.294 && _hapticFired.add('keeper')) {
      HapticFeedback.lightImpact();
    }
    if (t > 0.368 && _hapticFired.add('crab')) {
      HapticFeedback.selectionClick();
    }
    if (t > 0.515 && _hapticFired.add('throw')) {
      HapticFeedback.mediumImpact();
    }
    if (t > 0.653 && _hapticFired.add('bubble')) {
      HapticFeedback.lightImpact();
    }
    if (t > 0.822 && _hapticFired.add('logo')) {
      HapticFeedback.mediumImpact();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disable = MediaQuery.of(context).disableAnimations;
    if (disable && !_reducedMotion) {
      _reducedMotion = true;
      _scheduleReducedMotionExit();
    } else if (!disable && !_reducedMotion && !_controller.isAnimating &&
        _controller.value == 0) {
      _controller.forward();
    }
  }

  void _scheduleReducedMotionExit() {
    Future.delayed(_kReducedMotionHold, () {
      if (!mounted || _exited) return;
      _exitToChats();
    });
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _exitToChats();
    }
  }

  void _exitToChats() {
    if (_exited || !mounted) return;
    _exited = true;
    _controller.stop();
    // После welcome-анимации первого входа на устройстве показываем
    // тур по возможностям приложения (один раз на uid + устройство).
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      context.go('/chats');
      return;
    }
    FeaturesTourStorage.isShownFor(uid).then((shown) {
      if (!mounted) return;
      if (shown) {
        context.go('/chats');
      } else {
        // Помечаем сразу — чтобы возврат-навигация не привела к
        // повторному автозапуску тура.
        FeaturesTourStorage.markShownFor(uid);
        context.go('/features?source=welcome');
      }
    });
  }

  Future<void> _onSkip() async {
    _exitToChats();
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onStatus);
    _controller.removeListener(_onTick);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: kBrandNavyDark,
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (_reducedMotion)
              const _StaticFinalFrame()
            else
              _AnimatedStage(controller: _controller, trail: _trail),
            _SkipButton(onSkip: _onSkip),
          ],
        ),
      ),
    );
  }
}

class _SkipButton extends StatelessWidget {
  const _SkipButton({required this.onSkip});
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = l10n?.welcomeSkip ?? 'Пропустить';
    return SafeArea(
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Semantics(
            button: true,
            label: label,
            child: TextButton(
              onPressed: onSkip,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.white.withValues(alpha: 0.12),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              ),
              child: Text(label),
            ),
          ),
        ),
      ),
    );
  }
}

/// Static финальный кадр для reduced-motion.
class _StaticFinalFrame extends StatelessWidget {
  const _StaticFinalFrame();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (context, opacity, _) {
        return Opacity(
          opacity: opacity,
          child: LayoutBuilder(
            builder: (context, c) {
              final size = Size(c.maxWidth, c.maxHeight);
              final logoSide = size.width * 0.55;
              return Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(0.0, -0.4),
                        radius: 1.1,
                        colors: [kBrandNavy, Color(0xFF142849), kBrandNavyDark],
                        stops: [0.0, 0.55, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    left: (size.width - logoSide) / 2,
                    top: size.height * 0.32,
                    width: logoSide,
                    height: logoSide,
                    child: Image.asset('assets/lighchat_mark.png', fit: BoxFit.contain),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: size.height * 0.32 + logoSide + 12,
                    child: const _Wordmark(),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _AnimatedStage extends StatelessWidget {
  const _AnimatedStage({required this.controller, required this.trail});

  final AnimationController controller;
  final List<Offset> trail;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value;
        return LayoutBuilder(
          builder: (context, c) {
            final size = Size(c.maxWidth, c.maxHeight);
            final sceneFade = _interval(t, 0.754, 0.828).clamp(0.0, 1.0);
            final l10n = AppLocalizations.of(context);
            return Stack(
              fit: StackFit.expand,
              children: [
                Opacity(
                  opacity: 1 - sceneFade,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _BackgroundGradient(),
                      _StarsLayer(t: t),
                      _MoonLayer(t: t),
                      _SeaLayer(t: t),
                      _IslandLayer(t: t, size: size),
                      _LighthouseLayer(t: t, size: size),
                      _KeeperLayer(t: t, size: size),
                      _CrabLayer(t: t, size: size, trail: trail),
                      _PlaneLayer(t: t, size: size, trail: trail),
                      _BubbleLayer(t: t, size: size, locale: l10n),
                    ],
                  ),
                ),
                _FinalLogoLayer(t: t, size: size),
              ],
            );
          },
        );
      },
    );
  }
}

/// 0..1 normalized window over the master t.
double _interval(double t, double start, double end) {
  if (t <= start) return 0;
  if (t >= end) return 1;
  return (t - start) / (end - start);
}

double _ease(double t, double start, double end, Curve curve) {
  return curve.transform(_interval(t, start, end));
}

// =============================================================================
// Layers
// =============================================================================

class _BackgroundGradient extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.0, -0.4),
          radius: 1.1,
          colors: [kBrandNavy, Color(0xFF142849), kBrandNavyDark],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: SizedBox.expand(),
    );
  }
}

class _StarsLayer extends StatelessWidget {
  const _StarsLayer({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) {
    final fade = _ease(t, 0, 0.037, Curves.easeOut);
    return CustomPaint(
      painter: StarsPainter(t: t, seeds: kStarSeeds, fade: fade),
    );
  }
}

class _MoonLayer extends StatelessWidget {
  const _MoonLayer({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) {
    final p = _ease(t, 0.006, 0.061, Curves.easeOut) * 0.95;
    return CustomPaint(painter: MoonPainter(opacity: p));
  }
}

class _SeaLayer extends StatelessWidget {
  const _SeaLayer({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) {
    final p = _ease(t, 0.012, 0.080, Curves.easeOut);
    return CustomPaint(painter: SeaPainter(opacity: p, t: t));
  }
}

class _IslandLayer extends StatelessWidget {
  const _IslandLayer({required this.t, required this.size});
  final double t;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final p = _ease(t, 0.024, 0.098, Curves.easeOutCubic);
    return Opacity(
      opacity: p,
      child: Transform.translate(
        offset: Offset(0, (1 - p) * size.height * 0.10),
        child: const CustomPaint(painter: IslandPainter()),
      ),
    );
  }
}

class _LighthouseLayer extends StatelessWidget {
  const _LighthouseLayer({required this.t, required this.size});
  final double t;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final p = _ease(t, 0.080, 0.172, Curves.easeOutCubic);
    final beamI = _ease(t, 0.098, 0.184, Curves.easeOut);
    final beamAngle = -0.4 + (t - 0.080) * 1.8;

    final lhWidth = size.width * 0.36;
    final lhHeight = size.height * 0.55;
    final lhLeft = (size.width - lhWidth) / 2;
    final lhTop = size.height * 0.32 + (1 - p) * size.height * 0.12;
    // Лампа находится на ~0.30 высоты sprite
    final lampOrigin = Offset(
      lhLeft + lhWidth * 0.5,
      lhTop + lhHeight * 0.30,
    );

    return Stack(
      children: [
        // Beam under tower so it appears emanating
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: LighthouseBeamPainter(
                angle: beamAngle,
                intensity: beamI,
                origin: lampOrigin,
              ),
            ),
          ),
        ),
        Positioned(
          left: lhLeft,
          top: lhTop,
          width: lhWidth,
          height: lhHeight,
          child: Opacity(
            opacity: p,
            child: const CustomPaint(painter: LighthousePainter()),
          ),
        ),
      ],
    );
  }
}

class _KeeperLayer extends StatelessWidget {
  const _KeeperLayer({required this.t, required this.size});
  final double t;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final appear = _ease(t, 0.276, 0.405, Curves.easeOutBack);
    final visible = _ease(t, 0.276, 0.368, Curves.easeOut);
    final throwP = _ease(t, 0.423, 0.543, Curves.easeInOut);

    final kw = size.width * 0.16;
    final kh = size.height * 0.15;
    final left = size.width * 0.66;
    final top = size.height * 0.71;

    return Positioned(
      left: left,
      top: top,
      width: kw,
      height: kh,
      child: Opacity(
        opacity: visible,
        child: Transform.scale(
          scale: appear.clamp(0.0, 1.0),
          alignment: Alignment.bottomCenter,
          child: CustomPaint(painter: KeeperPainter(throwProgress: throwP)),
        ),
      ),
    );
  }
}

class _CrabLayer extends StatelessWidget {
  const _CrabLayer({required this.t, required this.size, required this.trail});
  final double t;
  final Size size;
  final List<Offset> trail;

  @override
  Widget build(BuildContext context) {
    final appear = _ease(t, 0.349, 0.478, Curves.easeOutBack);
    final visible = _ease(t, 0.349, 0.441, Curves.easeOut);
    if (visible <= 0.001) return const SizedBox.shrink();

    final cw = size.width * 0.20;
    final ch = size.height * 0.075;
    final bob = math.sin((t - 0.349) * math.pi * 8) * 2.0;
    final left = size.width * 0.20;
    final top = size.height * 0.84 + bob;

    // Eye tracking: глядит на самолётик в полёте
    Offset pupil = Offset.zero;
    if (trail.isNotEmpty) {
      final last = trail.last;
      final dx = (last.dx - (left + cw / 2)) / (size.width * 0.3);
      final dy = (last.dy - (top + ch / 2)) / (size.height * 0.2);
      pupil = Offset(dx.clamp(-1.0, 1.0), dy.clamp(-1.0, 1.0));
    }

    final wavePh = (t - 0.349) * math.pi * 6;
    final lWave = -15 + math.sin(wavePh) * 18;
    final rWave = 20 + math.sin(wavePh + math.pi) * 18;

    return Positioned(
      left: left,
      top: top,
      width: cw,
      height: ch,
      child: Opacity(
        opacity: visible,
        child: Transform.scale(
          scale: appear.clamp(0.0, 1.0),
          child: CustomPaint(
            painter: CrabPainter(
              clawWaveL: lWave,
              clawWaveR: rWave,
              pupilOffset: pupil,
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaneLayer extends StatelessWidget {
  const _PlaneLayer({
    required this.t,
    required this.size,
    required this.trail,
  });
  final double t;
  final Size size;
  final List<Offset> trail;

  // Bezier control points (доли экрана)
  static const _p0 = Offset(0.74, 0.74); // рука хранителя
  static const _p1 = Offset(0.20, 0.20);
  static const _p2 = Offset(0.70, 0.30);
  static const _p3 = Offset(0.50, 0.55);

  @override
  Widget build(BuildContext context) {
    final appear = _ease(t, 0.515, 0.543, Curves.easeOutBack);
    final flight = _ease(t, 0.515, 0.653, Curves.easeInOutCubic);
    final morphOut = _ease(t, 0.634, 0.671, Curves.easeInOut);
    final visibility = (appear * (1 - morphOut)).clamp(0.0, 1.0);

    if (visibility <= 0.001) {
      return const SizedBox.shrink();
    }

    final p0 = Offset(_p0.dx * size.width, _p0.dy * size.height);
    final p1 = Offset(_p1.dx * size.width, _p1.dy * size.height);
    final p2 = Offset(_p2.dx * size.width, _p2.dy * size.height);
    final p3 = Offset(_p3.dx * size.width, _p3.dy * size.height);

    final pos = cubicBezier(flight, p0, p1, p2, p3);
    final tan = cubicBezierTangent(flight, p0, p1, p2, p3);
    final wobble = math.sin(t * math.pi * 14) * 5 * flight * (1 - flight) * 4;
    final perp = Offset(-tan.dy, tan.dx);
    final perpLen = perp.distance;
    final wOff = perpLen == 0 ? Offset.zero : perp / perpLen * wobble;
    final finalPos = pos + wOff;
    final tilt = math.atan2(tan.dy, tan.dx);

    if (flight > 0 && flight < 1) {
      trail.add(finalPos);
      if (trail.length > 14) trail.removeAt(0);
    } else if (flight >= 1 && trail.isNotEmpty) {
      trail.clear();
    }

    final planeW = size.width * 0.13;
    final planeH = size.width * 0.10;

    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: PaperPlaneTrailPainter(
                points: List.of(trail),
                fade: 1 - morphOut,
              ),
            ),
          ),
        ),
        Positioned(
          left: finalPos.dx - planeW / 2,
          top: finalPos.dy - planeH / 2,
          width: planeW,
          height: planeH,
          child: Opacity(
            opacity: visibility,
            child: Transform.scale(
              scale: 0.7 + 0.3 * appear,
              child: Transform.rotate(
                angle: tilt,
                child: const CustomPaint(painter: PaperPlanePainter()),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BubbleLayer extends StatelessWidget {
  const _BubbleLayer({
    required this.t,
    required this.size,
    required this.locale,
  });
  final double t;
  final Size size;
  final AppLocalizations? locale;

  static const _target = Offset(0.50, 0.55);

  @override
  Widget build(BuildContext context) {
    final morphIn = _ease(t, 0.634, 0.699, Curves.elasticOut);
    if (morphIn <= 0.001) return const SizedBox.shrink();
    final typing = _ease(t, 0.653, 0.708, Curves.easeOut);

    final bubbleWidth = size.width * 0.72;
    final centerX = _target.dx * size.width;
    final centerY = _target.dy * size.height;

    return Positioned(
      left: centerX - bubbleWidth / 2,
      top: centerY - 32,
      width: bubbleWidth,
      child: Transform.scale(
        alignment: Alignment.centerLeft,
        scale: morphIn,
        child: _BubbleCard(visibleChars: typing, locale: locale),
      ),
    );
  }
}

class _BubbleCard extends StatelessWidget {
  const _BubbleCard({this.visibleChars = 1.0, this.locale});

  final double visibleChars;
  final AppLocalizations? locale;

  @override
  Widget build(BuildContext context) {
    final title = locale?.welcomeBubbleTitle ?? 'Добро пожаловать в LighChat';
    final subtitle = locale?.welcomeBubbleSubtitle ?? 'Маяк зажёгся';

    final visibleLen = (title.length * visibleChars).round();
    final shownTitle = title.substring(0, visibleLen.clamp(0, title.length));

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: kBrandCoral,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.30),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Аватар: настоящий PNG-логотип
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              clipBehavior: Clip.antiAlias,
              child: Image.asset('assets/lighchat_mark.png', fit: BoxFit.cover),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'LighChat',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    shownTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                  if (visibleChars > 0.95) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FinalLogoLayer extends StatelessWidget {
  const _FinalLogoLayer({required this.t, required this.size});
  final double t;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final logoP = _ease(t, 0.763, 0.828, Curves.easeOutBack);
    final wmP = _ease(t, 0.791, 0.828, Curves.easeOut);
    if (logoP <= 0.001) return const SizedBox.shrink();
    final logoSide = size.width * 0.55;
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            left: (size.width - logoSide) / 2,
            top: size.height * 0.32,
            width: logoSide,
            height: logoSide,
            child: Opacity(
              opacity: logoP.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: logoP.clamp(0.0, 1.0),
                child: Image.asset('assets/lighchat_mark.png', fit: BoxFit.contain),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: size.height * 0.32 + logoSide + 12,
            child: Opacity(
              opacity: wmP.clamp(0.0, 1.0),
              child: const _Wordmark(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text.rich(
        const TextSpan(
          children: [
            TextSpan(
              text: 'L',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: _DottedI(),
            ),
            TextSpan(
              text: 'gh',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
            TextSpan(
              text: 'Chat',
              style: TextStyle(
                color: kBrandCoral,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DottedI extends StatelessWidget {
  const _DottedI();

  @override
  Widget build(BuildContext context) {
    // dotless ı + coral-точка ровно над её stem. Stack без явной ширины
    // подгоняется под реальную ширину буквы, а Alignment.topCenter
    // центрирует точку относительно неё (а не относительно фиксированных
    // 12px, как было раньше — отсюда смещение влево).
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: const [
        Text(
          'ı',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: 3),
          child: SizedBox(
            width: 6,
            height: 6,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: kBrandCoral,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Debug-only helper: сбрасывает welcome-флаг и отправляет на /welcome.
Future<void> debugReplayWelcomeAnimation(BuildContext context) async {
  if (!kDebugMode) return;
  await FirstLoginAnimationStorage.clearForCurrentUser();
  if (!context.mounted) return;
  context.go('/welcome');
}

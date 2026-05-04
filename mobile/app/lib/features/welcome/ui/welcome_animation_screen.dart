import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:go_router/go_router.dart';

import '../../../brand_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../data/first_login_animation_storage.dart';
import 'welcome_painters.dart';

const Duration _kTotalDuration = Duration(milliseconds: 8000);
const Duration _kReducedMotionHold = Duration(milliseconds: 800);

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

  // Накопленные точки траектории для trail (обновляются в плановом порядке
  // через `addListener` — это валидный паттерн для CustomPainter).
  final List<Offset> _trail = [];

  // Haptic triggers (one-shot per playthrough)
  final Set<String> _hapticFired = <String>{};

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _kTotalDuration);
    _controller.addStatusListener(_onStatus);
    _controller.addListener(_onTick);

    // Помечаем флаг сразу — чтобы force-kill посреди анимации не
    // приводил к повторному показу.
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
    if (t > 0.18 && _hapticFired.add('lighthouse')) {
      HapticFeedback.selectionClick();
    }
    if (t > 0.42 && _hapticFired.add('keeper')) {
      HapticFeedback.lightImpact();
    }
    if (t > 0.66 && _hapticFired.add('throw')) {
      HapticFeedback.mediumImpact();
    }
    if (t > 0.81 && _hapticFired.add('bubble')) {
      HapticFeedback.lightImpact();
    }
    if (t > 0.94 && _hapticFired.add('logo')) {
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
    context.go('/chats');
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(label),
            ),
          ),
        ),
      ),
    );
  }
}

/// Статичный финальный кадр для reduced-motion.
class _StaticFinalFrame extends StatelessWidget {
  const _StaticFinalFrame();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      builder: (context, opacity, _) {
        return Opacity(
          opacity: opacity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const _BackgroundLayer(progress: 1, t: 0.5),
              LayoutBuilder(
                builder: (context, c) {
                  final size = Size(c.maxWidth, c.maxHeight);
                  return Stack(
                    children: [
                      Positioned(
                        left: size.width * 0.20,
                        top: size.height * 0.30,
                        width: size.width * 0.60,
                        height: size.height * 0.60,
                        child: const CustomPaint(
                          painter: LighthousePainter(),
                        ),
                      ),
                      Positioned(
                        left: size.width * 0.18,
                        top: size.height * 0.48,
                        width: size.width * 0.64,
                        child: const _BubbleCard(visibleChars: 1.0),
                      ),
                    ],
                  );
                },
              ),
            ],
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
            // Сцена выцветает только в финальной фазе (0.92..1.0), уступая
            // место финальному логотипу + wordmark.
            final sceneFade = _interval(t, 0.92, 1.0).clamp(0.0, 1.0);
            return Stack(
              fit: StackFit.expand,
              children: [
                Opacity(
                  opacity: 1 - sceneFade,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _BackgroundLayer(progress: _ease(t, 0.0, 0.06, Curves.easeOut), t: t),
                      _LighthouseLayer(t: t, size: size),
                      _KeeperLayer(t: t, size: size),
                      _PlaneLayer(t: t, size: size, trail: trail),
                      _BubbleLayer(t: t, size: size, locale: AppLocalizations.of(context)),
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

/// Финальная фаза: PNG-логотип в центре + wordmark "LighChat" под ним.
class _FinalLogoLayer extends StatelessWidget {
  const _FinalLogoLayer({required this.t, required this.size});

  final double t;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final logoP = _ease(t, 0.93, 1.00, Curves.easeOutBack);
    final wmP = _ease(t, 0.96, 1.00, Curves.easeOut);
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
                child: Image.asset(
                  'assets/lighchat_mark.png',
                  fit: BoxFit.contain,
                ),
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
            // Dotless `i` — точка над `i` сделана отдельным span coral-цвета
            // через WidgetSpan, чтобы попасть в брендовую палитру.
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
    // Используем dotless ı + сверху coral-точку. Размер согласован с 28sp text.
    return SizedBox(
      width: 12,
      height: 32,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned(
            left: 0,
            top: 0,
            child: Text(
              'ı',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
          ),
          Positioned(
            left: 3,
            top: 4,
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: kBrandCoral,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Возвращает прогресс t, нормализованный в окне [start..end] (0..1) или 0/1
/// за пределами. start/end — доли мастер-таймлайна.
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

class _BackgroundLayer extends StatelessWidget {
  const _BackgroundLayer({required this.progress, required this.t});

  final double progress;
  final double t;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: progress,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kBrandNavy, kBrandNavyDark],
          ),
        ),
        child: CustomPaint(painter: StarsPainter(t: t, seeds: kStarSeeds)),
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
    final p = _ease(t, 0.05, 0.18, Curves.easeOutCubic);
    final beamIntensity = _ease(t, 0.10, 0.30, Curves.easeOut);
    // Луч поворачивается медленно: ~1 оборот / 6с при общей продолжительности
    // 3.8с — фактически ~0.63 оборота. Стартовый угол слегка повёрнут влево.
    final beamAngle = -0.8 + (t * (math.pi * 2 / 6.0)) * (3.8);

    final tower = Positioned(
      left: size.width * 0.20,
      top: size.height * 0.30 + (1 - p) * size.height * 0.20,
      width: size.width * 0.60,
      height: size.height * 0.60,
      child: Opacity(
        opacity: p,
        child: const CustomPaint(painter: LighthousePainter()),
      ),
    );

    final beam = Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: LighthouseBeamPainter(
            angle: beamAngle,
            intensity: beamIntensity,
          ),
        ),
      ),
    );

    return Stack(children: [beam, tower]);
  }
}

class _KeeperLayer extends StatelessWidget {
  const _KeeperLayer({required this.t, required this.size});

  final double t;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final appear = _ease(t, 0.18, 0.30, Curves.easeInOut);
    final throwP = _ease(t, 0.30, 0.40, Curves.easeInOut);

    final keeperWidth = size.width * 0.10;
    final keeperHeight = size.height * 0.08;
    return Positioned(
      left: size.width * 0.42,
      top: size.height * 0.39,
      width: keeperWidth,
      height: keeperHeight,
      child: Opacity(
        opacity: appear,
        child: CustomPaint(
          painter: KeeperPainter(throwProgress: throwP),
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

  // Контрольные точки кубической Безье в долях экрана.
  static const _p0 = Offset(0.46, 0.43); // рука смотрителя
  static const _p1 = Offset(0.20, 0.20); // вверх и влево
  static const _p2 = Offset(0.70, 0.30); // дуга справа сверху
  static const _p3 = Offset(0.50, 0.55); // целевая точка bubble

  @override
  Widget build(BuildContext context) {
    // Самолётик появляется в (1300..1500), летит (1500..3000),
    // конвертируется в bubble (3000..3500).
    final appear = _ease(t, 0.342, 0.395, Curves.easeOutBack);
    final flight = _ease(t, 0.395, 0.789, Curves.easeInOutCubic);
    final morphOut = _ease(t, 0.789, 0.842, Curves.easeInOut);
    final visibility = (appear * (1 - morphOut)).clamp(0.0, 1.0);

    if (visibility <= 0.001) {
      return const SizedBox.shrink();
    }

    final p0 = Offset(_p0.dx * size.width, _p0.dy * size.height);
    final p1 = Offset(_p1.dx * size.width, _p1.dy * size.height);
    final p2 = Offset(_p2.dx * size.width, _p2.dy * size.height);
    final p3 = Offset(_p3.dx * size.width, _p3.dy * size.height);

    final pos = cubicBezier(flight, p0, p1, p2, p3);
    final tangent = cubicBezierTangent(flight, p0, p1, p2, p3);
    final wobble = math.sin(t * math.pi * 12) * 4 * flight * (1 - flight) * 4;
    final perpDx = -tangent.dy;
    final perpDy = tangent.dx;
    final perpLen = math.sqrt(perpDx * perpDx + perpDy * perpDy);
    final wDx = perpLen == 0 ? 0.0 : perpDx / perpLen * wobble;
    final wDy = perpLen == 0 ? 0.0 : perpDy / perpLen * wobble;
    final finalPos = Offset(pos.dx + wDx, pos.dy + wDy);

    final tilt = math.atan2(tangent.dy, tangent.dx);

    // Обновляем trail (последние 8 точек).
    if (flight > 0 && flight < 1) {
      trail.add(finalPos);
      if (trail.length > 8) trail.removeAt(0);
    } else if (flight >= 1 && trail.isNotEmpty) {
      trail.clear();
    }

    final planeSize = Size(size.width * 0.10, size.width * 0.08);
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: PaperPlaneTrailPainter(points: List.of(trail))),
          ),
        ),
        Positioned(
          left: finalPos.dx - planeSize.width / 2,
          top: finalPos.dy - planeSize.height / 2,
          width: planeSize.width,
          height: planeSize.height,
          child: Opacity(
            opacity: visibility,
            child: Transform.scale(
              scale: 0.4 + 0.6 * appear,
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
    final morphIn = _ease(t, 0.789, 0.921, Curves.elasticOut);
    if (morphIn <= 0.001) return const SizedBox.shrink();
    // Typing-эффект: символы "печатаются" 0.789..0.92.
    final typing = _ease(t, 0.815, 0.92, Curves.easeOut);

    final bubbleWidth = size.width * 0.64;
    final centerX = _target.dx * size.width;
    final centerY = _target.dy * size.height;

    return Positioned(
      left: centerX - bubbleWidth / 2,
      top: centerY - 30,
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

  /// 0..1, доля «напечатанного» текста.
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.white,
              backgroundImage: const AssetImage('assets/lighchat_mark.png'),
              onBackgroundImageError: (_, _) {},
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'LighChat',
                    style: const TextStyle(
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

/// Debug-only хелпер: сбрасывает welcome-флаг и переходит на /welcome.
/// Используется ListTile в Storage Settings.
Future<void> debugReplayWelcomeAnimation(BuildContext context) async {
  if (!kDebugMode) return;
  await FirstLoginAnimationStorage.clearForCurrentUser();
  if (!context.mounted) return;
  context.go('/welcome');
}

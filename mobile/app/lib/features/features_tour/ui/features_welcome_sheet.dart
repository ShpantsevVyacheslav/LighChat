import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/features_data.dart';
import 'feature_mocks.dart';

/// Модалка-приглашение в тур по возможностям LighChat. Показывается на
/// `/chats` после каждого успешного логина (см. `FeaturesWelcomePending`).
///
/// Дизайн повторяет welcome-overlay из веба:
///   – hero-коллаж (3 мокапа внахлест) с E2EE-бейджем сверху-слева;
///   – квадратная иконка `Icons.auto_awesome` в коралловом квадрате;
///   – заголовок и подзаголовок;
///   – 3 буллита с цветными иконками (E2EE / Secret / Games+Meetings);
///   – основная коралловая CTA-кнопка `Take a look` и текстовая `Later`.
Future<void> showFeaturesWelcomeSheet(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.78),
    barrierDismissible: false,
    builder: (_) => const _FeaturesWelcomeSheet(),
  );
}

class _FeaturesWelcomeSheet extends StatelessWidget {
  const _FeaturesWelcomeSheet();

  /// Палитра primary CTA — один в один с «Sign in» из `auth_screen.dart`
  /// (`_GradientPrimaryButton`): синий → синий → фиолетовый. Один и тот же
  /// визуальный аккорд для primary-действий по всему мобильному UI.
  static const List<Color> _ctaGradient = [
    Color(0xFF2E86FF),
    Color(0xFF5F90FF),
    Color(0xFF9A18FF),
  ];

  @override
  Widget build(BuildContext context) {
    final content = featuresContentFor(Localizations.localeOf(context));
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final cardBg = dark ? const Color(0xFF0F1118) : Colors.white;
    final fg = dark ? Colors.white : const Color(0xFF111827);
    final mutedFg = dark
        ? Colors.white.withValues(alpha: 0.65)
        : const Color(0xFF6B7280);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
                color: dark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Hero-коллаж сверху + E2EE-бейдж в углу.
              SizedBox(
                height: 220,
                child: Stack(children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: dark
                            ? [
                                const Color(0xFF1A1D2A),
                                const Color(0xFF0F1118),
                              ]
                            : [
                                const Color(0xFFEFF1F8),
                                const Color(0xFFF8F9FB),
                              ],
                      ),
                    ),
                  ),
                  const _HeroCollage(),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: featureAccentEmerald.withValues(alpha: 0.15),
                        border: Border.all(
                            color: featureAccentEmerald.withValues(alpha: 0.45)),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.shield_outlined,
                            size: 12, color: featureAccentEmerald),
                        const SizedBox(width: 4),
                        Text('E2EE',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: featureAccentEmerald)),
                      ]),
                    ),
                  ),
                ]),
              ),

              // Иконка-плашка
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0x332E86FF),
                        Color(0x339A18FF),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.auto_awesome,
                      size: 22, color: Color(0xFF5F90FF)),
                ),
              ),

              // Заголовок
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Text(content.welcomeTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w800, color: fg)),
              ),

              // Подзаголовок
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Text(content.welcomeSubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13, height: 1.4, color: mutedFg)),
              ),

              // Три буллита
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: Column(children: [
                  _Bullet(
                    icon: Icons.shield_outlined,
                    color: featureAccentEmerald,
                    text: content.welcomeBullets.isNotEmpty
                        ? content.welcomeBullets[0]
                        : '',
                  ),
                  const SizedBox(height: 8),
                  _Bullet(
                    icon: Icons.timer_outlined,
                    color: featureAccentViolet,
                    text: content.welcomeBullets.length > 1
                        ? content.welcomeBullets[1]
                        : '',
                  ),
                  const SizedBox(height: 8),
                  _Bullet(
                    icon: Icons.sports_esports_outlined,
                    color: featureAccentAmber,
                    text: content.welcomeBullets.length > 2
                        ? content.welcomeBullets[2]
                        : '',
                  ),
                ]),
              ),

              // Primary CTA — тот же градиент, что у «Sign in».
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: _ctaGradient,
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.push('/features?source=welcome');
                      },
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22)),
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        content.welcomePrimaryCta,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: mutedFg,
                    minimumSize: const Size.fromHeight(40),
                    textStyle: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  child: Text(content.welcomeSecondaryCta),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({
    required this.icon,
    required this.color,
    required this.text,
  });
  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.03),
        border: Border.all(
            color: dark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.05)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: scheme.brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.92)
                      : const Color(0xFF111827))),
        ),
      ]),
    );
  }
}

/// Hero-коллаж: три мокапа внахлест с лёгким поворотом, как на веб-варианте.
class _HeroCollage extends StatelessWidget {
  const _HeroCollage();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      return Stack(clipBehavior: Clip.none, children: [
        Positioned(
          left: w * 0.04,
          top: 18,
          width: w * 0.55,
          height: 130,
          child: Transform.rotate(
            angle: -0.05,
            child: const _CollageFrame(child: MockEncryption()),
          ),
        ),
        Positioned(
          right: w * 0.02,
          top: 8,
          width: w * 0.42,
          height: 105,
          child: Transform.rotate(
            angle: 0.04,
            child: const _CollageFrame(child: MockMeetings()),
          ),
        ),
        Positioned(
          left: w * 0.30,
          bottom: 6,
          width: w * 0.42,
          height: 110,
          child: Transform.rotate(
            angle: -0.02,
            child: const _CollageFrame(child: MockGames()),
          ),
        ),
      ]);
    });
  }
}

class _CollageFrame extends StatelessWidget {
  const _CollageFrame({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: (dark ? Colors.white : Colors.black)
                .withValues(alpha: dark ? 0.10 : 0.06)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.surface.withValues(alpha: dark ? 0.85 : 0.92),
            scheme.surface.withValues(alpha: dark ? 0.55 : 0.75),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.45 : 0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
            spreadRadius: -4,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

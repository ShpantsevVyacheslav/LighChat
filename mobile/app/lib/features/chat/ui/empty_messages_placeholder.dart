import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../brand_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../welcome/ui/welcome_painters.dart';

/// Карточка-пустышка для чата без сообщений, в стиле Telegram «No messages yet».
/// Внутри карточки — хранитель маяка, который машет рукой (idle-анимация
/// «синус по фазе бросания» из welcome-painters'а: ~1.4с период, без
/// зацикливания на 1.0 = full release).
class EmptyMessagesPlaceholder extends StatefulWidget {
  const EmptyMessagesPlaceholder({super.key});

  @override
  State<EmptyMessagesPlaceholder> createState() =>
      _EmptyMessagesPlaceholderState();
}

class _EmptyMessagesPlaceholderState extends State<EmptyMessagesPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = l10n?.chat_empty_title ?? 'Сообщений пока нет';
    final subtitle = l10n?.chat_empty_subtitle ?? 'Напишите первое сообщение';

    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final cardColor = (dark ? Colors.white : Colors.black)
        .withValues(alpha: dark ? 0.08 : 0.04);
    final textColor = scheme.onSurface;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: (dark ? Colors.white : Colors.black)
                    .withValues(alpha: dark ? 0.05 : 0.04),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 14),
                // Хранитель машет рукой (idle wave).
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final t = _controller.value;
                    // Махание: рука колеблется между ~0.3 (опущенная) и ~0.95
                    // (поднятая вверх) по синусу.
                    final wave = 0.3 + 0.65 * (0.5 + 0.5 * math.sin(t * 2 * math.pi));
                    return SizedBox(
                      width: 140,
                      height: 160,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Маленькая «земля» / тень
                          Positioned(
                            left: 12,
                            right: 12,
                            bottom: 8,
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(40),
                              ),
                            ),
                          ),
                          // Лёгкое мигание маячка-фона за спиной хранителя
                          Positioned.fill(
                            child: IgnorePointer(
                              child: Opacity(
                                opacity: 0.25 +
                                    0.15 * (0.5 + 0.5 * math.sin(t * 2 * math.pi)),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: RadialGradient(
                                      center: const Alignment(0.0, -0.2),
                                      radius: 0.7,
                                      colors: [
                                        kBrandOrange.withValues(alpha: 0.4),
                                        kBrandOrange.withValues(alpha: 0.0),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Сам хранитель
                          Positioned.fill(
                            child: CustomPaint(
                              painter: KeeperPainter(throwProgress: wave),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

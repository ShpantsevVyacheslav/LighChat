import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'chat_location_map_view.dart';

/// Карта на всю площадь footer'а, кнопки «Запросить» / «Поделиться»
/// — поверх карты внизу как pill-капсулы с blur background. Стиль
/// близкий к iMessage attach-карте: компактные, полупрозрачные,
/// floating.
class ChatLocationSharePanel extends StatelessWidget {
  const ChatLocationSharePanel({
    super.key,
    required this.lat,
    required this.lng,
    required this.onShare,
    this.onRequest,
    this.onPinMoved,
    this.onRecenterToCurrent,
    this.controller,
    this.shareLabel = 'Поделиться',
    this.requestLabel = 'Запросить',
  });

  final double lat;
  final double lng;
  final VoidCallback onShare;
  final VoidCallback? onRequest;

  /// Bug #6: пользователь перетащил аннотацию по карте → caller
  /// обновляет lat/lng (state в chat_screen).
  final ValueChanged<ChatLocationPinPosition>? onPinMoved;

  /// Тап «recenter to me» (compass-icon FAB) — caller (chat_screen)
  /// запрашивает current position у Geolocator, обновляет
  /// `_locationPanelLat/Lng` и шлёт setCenter native карте.
  final VoidCallback? onRecenterToCurrent;

  /// Bug #7: caller может прокинуть контроллер для программного
  /// сдвига карты (forward geocoding по composer text).
  final ChatLocationMapController? controller;
  final String shareLabel;
  final String requestLabel;

  @override
  Widget build(BuildContext context) {
    // Bug #3: SafeArea(top:false) обрезал карту снизу — на iPhone с
    // home-indicator оставалась чёрная полоса под картой. Карта теперь
    // на всю высоту footer'а; пилюли позиционируем с учётом
    // viewPadding.bottom вручную, чтобы они не залезали под индикатор.
    final mq = MediaQuery.of(context);
    return Stack(
      children: [
        // Карта на весь footer — без SafeArea, до самого низа.
        Positioned.fill(
          child: ChatLocationMapView(
            lat: lat,
            lng: lng,
            interactive: true,
            draggablePin: true,
            onPinMoved: onPinMoved,
            controller: controller,
          ),
        ),
        // Bug C: пилюли в ~1.5 раза меньше и обе прозрачные (glass-blur).
        // Не растягиваем на всю ширину — Wrap по контенту, центрируем
        // снизу.
        // Recenter-to-current-location FAB (compass icon) над
        // пилюлями справа. Стеклянный круглый button, glass-blur
        // как у outlined-pill.
        if (onRecenterToCurrent != null)
          Positioned(
            right: 14,
            bottom: mq.padding.bottom + 60,
            child: _GlassCircleButton(
              icon: Icons.my_location_rounded,
              onTap: onRecenterToCurrent!,
            ),
          ),
        // T4 v2: опустили пилюли обратно (с +28 на +12); IntrinsicHeight
        // + CrossAxisAlignment.stretch гарантируют одинаковую высоту
        // обеих пилюль, чтобы «Запросить» не была визуально ниже
        // «Поделиться» (раньше из-за разной длины текста padding
        // округлялся по-разному).
        Positioned(
          left: 14,
          right: 14,
          bottom: mq.padding.bottom + 12,
          child: IntrinsicHeight(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Pill(
                  label: requestLabel,
                  filled: false,
                  onTap: onRequest,
                ),
                const SizedBox(width: 8),
                _Pill(
                  label: shareLabel,
                  filled: true,
                  onTap: onShare,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final disabled = onTap == null;
    const appleBlue = Color(0xFF007AFF);

    // T4: ещё более прозрачные glass-translucent пилюли — alpha
    // понижена: outlined 0.18/0.42 вместо 0.28/0.62, filled blue
    // 0.42 вместо 0.55. Blur (BackdropFilter) compensates.
    final base = dark ? Colors.white : Colors.black;
    final outlinedFill = (dark ? Colors.black : Colors.white).withValues(
      alpha: dark ? 0.18 : 0.42,
    );
    final filledFill = filled
        ? appleBlue.withValues(alpha: disabled ? 0.22 : 0.42)
        : outlinedFill;
    final fg = filled
        ? Colors.white.withValues(alpha: disabled ? 0.55 : 0.96)
        : base.withValues(alpha: disabled ? 0.35 : 0.92);
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Material(
          color: filledFill,
          shape: StadiumBorder(
            side: BorderSide(
              color: base.withValues(alpha: dark ? 0.18 : 0.10),
              width: 0.5,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            customBorder: const StadiumBorder(),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 7,
              ),
              // T4 v2: Center внутри stretched-Row — текст по центру
              // pill'а независимо от того, что соседняя пилюля растянула
              // высоту через IntrinsicHeight.
              child: Center(
                widthFactor: 1,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: fg,
                    letterSpacing: -0.1,
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

/// Стеклянный круглый glass-blur button. Используется для recenter-FAB
/// в share-panel.
class _GlassCircleButton extends StatelessWidget {
  const _GlassCircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final base = dark ? Colors.white : Colors.black;
    final bg = (dark ? Colors.black : Colors.white).withValues(
      alpha: dark ? 0.28 : 0.55,
    );
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Material(
          color: bg,
          shape: CircleBorder(
            side: BorderSide(
              color: base.withValues(alpha: dark ? 0.18 : 0.10),
              width: 0.5,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                icon,
                size: 20,
                color: base.withValues(alpha: dark ? 0.92 : 0.85),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

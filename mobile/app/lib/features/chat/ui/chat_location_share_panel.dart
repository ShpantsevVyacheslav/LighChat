import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'chat_location_map_view.dart';

/// Inline-панель снизу, заменяющая клавиатуру (iMessage Location-share
/// paritет). Полноэкранная карта; кнопки «Поделиться» / «Запросить»
/// рендерятся overlay поверх карты в нижней части, в Apple-стилизации
/// (translucent rounded pills с backdrop blur, vertical stack как
/// iMessage's «Send My Location» / «Request» menu).
class ChatLocationSharePanel extends StatelessWidget {
  const ChatLocationSharePanel({
    super.key,
    required this.lat,
    required this.lng,
    required this.onShare,
    this.onRequest,
    this.shareLabel = 'Поделиться',
    this.requestLabel = 'Запросить',
  });

  final double lat;
  final double lng;
  final VoidCallback onShare;
  final VoidCallback? onRequest;
  final String shareLabel;
  final String requestLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final bg = dark ? const Color(0xFF0E1015) : Colors.white;

    return ColoredBox(
      color: bg,
      child: SafeArea(
        top: false,
        child: Stack(
          children: [
            // Карта на весь footer.
            Positioned.fill(
              child: ChatLocationMapView(
                lat: lat,
                lng: lng,
                interactive: true,
              ),
            ),
            // Apple-style overlay c двумя actions внизу карты.
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: _ActionsCard(
                shareLabel: shareLabel,
                requestLabel: requestLabel,
                onShare: onShare,
                onRequest: onRequest,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Apple action-card стиль: rounded rectangle с blur background +
/// hairline divider между actions. Иконка слева, лейбл слева от центра.
class _ActionsCard extends StatelessWidget {
  const _ActionsCard({
    required this.shareLabel,
    required this.requestLabel,
    required this.onShare,
    required this.onRequest,
  });

  final String shareLabel;
  final String requestLabel;
  final VoidCallback onShare;
  final VoidCallback? onRequest;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    // Apple semitransparent: ~85% white в light, ~28% white в dark поверх blur.
    final cardColor = dark
        ? const Color(0xFFFFFFFF).withValues(alpha: 0.18)
        : const Color(0xFFFFFFFF).withValues(alpha: 0.88);
    final divider = (dark ? Colors.white : Colors.black).withValues(
      alpha: dark ? 0.16 : 0.10,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _CardAction(
                label: shareLabel,
                icon: CupertinoIcons.location_solid,
                onTap: onShare,
                accent: true,
              ),
              Container(height: 0.5, color: divider),
              _CardAction(
                label: requestLabel,
                icon: CupertinoIcons.location,
                onTap: onRequest,
                accent: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardAction extends StatelessWidget {
  const _CardAction({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.accent,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final disabled = onTap == null;
    // Apple iOS system blue (≈ `systemBlue`).
    const appleBlue = Color(0xFF007AFF);
    final tint = accent
        ? appleBlue
        : (dark ? Colors.white : Colors.black);
    final tintEffective = disabled ? tint.withValues(alpha: 0.36) : tint;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 19, color: tintEffective),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: tintEffective,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

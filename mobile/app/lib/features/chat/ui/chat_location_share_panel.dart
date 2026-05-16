import 'package:flutter/material.dart';

import 'chat_location_map_view.dart';

/// Inline-панель снизу, заменяющая клавиатуру. Карта на бóльшую часть
/// footer'а, ПОД картой — две горизонтальные pill-кнопки «Запросить»
/// (outlined) и «Поделиться» (filled blue), как в iMessage Maps-attach.
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
        child: Column(
          children: [
            // Карта — растягиваем на всё доступное пространство выше
            // ряда кнопок.
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: ChatLocationMapView(
                    lat: lat,
                    lng: lng,
                    interactive: true,
                  ),
                ),
              ),
            ),
            // Ряд кнопок ПОД картой. Request — outlined, Share — filled
            // blue. Без иконок, лейблы по центру.
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: _Pill(
                      label: requestLabel,
                      filled: false,
                      onTap: onRequest,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Pill(
                      label: shareLabel,
                      filled: true,
                      onTap: onShare,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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

    final Color bg;
    final Color fg;
    if (filled) {
      bg = disabled ? appleBlue.withValues(alpha: 0.35) : appleBlue;
      fg = Colors.white;
    } else {
      bg = (dark ? Colors.white : Colors.black)
          .withValues(alpha: dark ? 0.12 : 0.06);
      final base = dark ? Colors.white : Colors.black;
      fg = base.withValues(alpha: disabled ? 0.35 : 0.92);
    }
    return Material(
      color: bg,
      shape: const StadiumBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: fg,
                letterSpacing: -0.1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'chat_location_map_view.dart';

/// Inline-панель снизу, заменяющая клавиатуру (Phase 12.1, iMessage
/// "Send My Location" / "Request Location" UX). Полноэкранная карта
/// + bottom-bar с двумя action-кнопками:
///  - **«Поделиться»** → дёргает [onShare] (chat_screen показывает
///    CupertinoActionSheet длительности).
///  - **«Запросить»** → [onRequest] (отдельный flow в Phase 12.3, пока
///    может быть null = кнопка disabled).
///
/// Высота — footer-height (как у sticker panel), карту скейлим под
/// доступное пространство. Геолокация уже захвачена parent'ом — этой
/// панели только показать карту.
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

    return Container(
      color: bg,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Карта — занимает всё свободное пространство выше action-bar'а.
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: ChatLocationMapView(
                    lat: lat,
                    lng: lng,
                    interactive: true,
                  ),
                ),
              ),
            ),
            // Action-bar — две большие кнопки, как Apple Messages.
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: _PanelButton(
                      label: shareLabel,
                      icon: CupertinoIcons.location_solid,
                      filled: true,
                      onTap: onShare,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PanelButton(
                      label: requestLabel,
                      icon: CupertinoIcons.location,
                      filled: false,
                      onTap: onRequest,
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

class _PanelButton extends StatelessWidget {
  const _PanelButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final disabled = onTap == null;
    final accent = const Color(0xFF2A79FF);
    final outline = (dark ? Colors.white : Colors.black).withValues(
      alpha: dark ? 0.16 : 0.12,
    );

    return Material(
      color: filled
          ? (disabled ? accent.withValues(alpha: 0.32) : accent)
          : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: filled
            ? BorderSide.none
            : BorderSide(color: outline, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: filled
                    ? Colors.white
                    : (dark ? Colors.white : Colors.black)
                        .withValues(alpha: disabled ? 0.32 : 0.78),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: filled
                      ? Colors.white
                      : (dark ? Colors.white : Colors.black)
                          .withValues(alpha: disabled ? 0.32 : 0.92),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

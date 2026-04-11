import 'package:flutter/material.dart';
import 'package:lighchat_models/lighchat_models.dart';

/// First pinned message preview + unpin (web `PinnedMessageBar` lite).
class ChatPinnedStrip extends StatelessWidget {
  const ChatPinnedStrip({
    super.key,
    required this.pin,
    required this.totalPins,
    required this.onUnpin,
  });

  final PinnedMessage pin;
  final int totalPins;
  final VoidCallback onUnpin;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.push_pin_rounded, size: 18, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      totalPins > 1 ? 'Закреплено: $totalPins' : 'Закреплено',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: scheme.primary),
                    ),
                    Text(
                      pin.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: scheme.onSurface),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Открепить',
                onPressed: onUnpin,
                icon: Icon(Icons.close_rounded, color: scheme.onSurface.withValues(alpha: 0.65)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

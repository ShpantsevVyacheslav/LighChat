import 'package:flutter/material.dart';

/// Мини-иконки статуса доставки (web `MessageStatus`): рядом со временем.
class MessageBubbleDeliveryIcons extends StatelessWidget {
  const MessageBubbleDeliveryIcons({
    super.key,
    required this.deliveryStatus,
    required this.readAt,
    required this.iconColor,
    this.size = 12,
  });

  final String? deliveryStatus;
  final DateTime? readAt;
  final Color iconColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ds = deliveryStatus ?? 'sent';
    if (ds == 'sending') {
      return Icon(Icons.schedule_rounded, size: size, color: iconColor);
    }
    if (ds == 'failed') {
      return Icon(
        Icons.error_outline_rounded,
        size: size,
        color: Theme.of(context).colorScheme.error,
      );
    }
    if (readAt != null) {
      return SizedBox(
        width: size * 1.75,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              top: 0,
              child: Icon(Icons.done_rounded, size: size, color: iconColor),
            ),
            Positioned(
              left: size * 0.28,
              top: 0,
              child: Icon(Icons.done_rounded, size: size, color: iconColor),
            ),
          ],
        ),
      );
    }
    return Icon(Icons.done_rounded, size: size, color: iconColor);
  }
}

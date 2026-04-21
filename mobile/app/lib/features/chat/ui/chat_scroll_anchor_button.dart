import 'package:flutter/material.dart';

class ChatScrollAnchorButton extends StatelessWidget {
  const ChatScrollAnchorButton({
    super.key,
    required this.isVisible,
    required this.unreadCount,
    required this.onTap,
    this.reactionEmoji,
    this.onReactionTap,
  });

  final bool isVisible;
  final int unreadCount;
  final VoidCallback onTap;
  final String? reactionEmoji;
  final VoidCallback? onReactionTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final emojiToken = reactionEmoji?.trim();
    final isReactionMode = emojiToken != null && emojiToken.isNotEmpty;
    final showBadge = !isReactionMode && unreadCount > 0;
    final badgeText = unreadCount > 99 ? '99+' : '$unreadCount';
    return IgnorePointer(
      ignoring: !isVisible,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        offset: isVisible ? Offset.zero : const Offset(0, 0.24),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          opacity: isVisible ? 1 : 0,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: isReactionMode ? (onReactionTap ?? onTap) : onTap,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dark
                        ? Colors.white.withValues(alpha: 0.14)
                        : Colors.white.withValues(alpha: 0.25),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: dark ? 0.2 : 0.3),
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: dark ? 0.33 : 0.18,
                        ),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: isReactionMode
                        ? Text(
                            emojiToken,
                            style: const TextStyle(fontSize: 24, height: 1),
                          )
                        : Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 28,
                            color: Colors.white.withValues(alpha: 0.95),
                          ),
                  ),
                ),
              ),
              if (showBadge)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF4D67),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.85),
                        width: 1.4,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      badgeText,
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

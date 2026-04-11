import 'package:flutter/material.dart';

import 'chat_avatar.dart';

class ChatBottomNav extends StatelessWidget {
  const ChatBottomNav({
    super.key,
    required this.onProfileTap,
    this.avatarUrl,
    this.userTitle,
  });

  final VoidCallback onProfileTap;
  final String? avatarUrl;
  final String? userTitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: Colors.white.withValues(alpha: dark ? 0.08 : 0.22),
            border: Border.all(
              color: Colors.white.withValues(alpha: dark ? 0.12 : 0.35),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _NavCircle(icon: Icons.chat_bubble_rounded, active: true),
              const _NavCircle(icon: Icons.group_rounded),
              const _NavCircle(icon: Icons.videocam_rounded),
              const _NavCircle(icon: Icons.call_rounded),
              _ProfileAvatarButton(
                onTap: onProfileTap,
                avatarUrl: avatarUrl,
                title: userTitle ?? 'U',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatarButton extends StatelessWidget {
  const _ProfileAvatarButton({
    required this.onTap,
    required this.avatarUrl,
    required this.title,
  });

  final VoidCallback onTap;
  final String? avatarUrl;
  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 54,
          height: 54,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: scheme.primary.withValues(alpha: 0.45)),
          ),
          child: ChatAvatar(title: title, radius: 23, avatarUrl: avatarUrl),
        ),
      ),
    );
  }
}

class _NavCircle extends StatelessWidget {
  const _NavCircle({required this.icon, this.active = false});

  final IconData icon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = active
        ? scheme.primary
        : scheme.onSurface.withValues(alpha: 0.72);
    final bg = active
        ? scheme.primary.withValues(alpha: 0.22)
        : Colors.white.withValues(alpha: 0.0);

    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
      alignment: Alignment.center,
      child: Icon(icon, color: color, size: 26),
    );
  }
}

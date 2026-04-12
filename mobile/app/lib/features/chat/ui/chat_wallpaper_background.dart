import 'package:flutter/material.dart';

import '../../auth/ui/auth_glass.dart';
import 'chat_cached_network_image.dart';

/// Фон чата по `users/*/chatSettings.chatWallpaper` — тот же слой, что в [ChatScreen].
class ChatWallpaperBackground extends StatelessWidget {
  const ChatWallpaperBackground({
    super.key,
    required this.wallpaper,
    required this.child,
  });

  /// Значение `chatWallpaper` (URL, пресет градиента CSS-строкой или пусто).
  final String? wallpaper;
  final Widget child;

  static final Map<String, Gradient> _gradients = <String, Gradient>{
    'linear-gradient(135deg, #667eea 0%, #764ba2 100%)': const LinearGradient(
      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
    ),
    'linear-gradient(135deg, #f093fb 0%, #f5576c 100%)': const LinearGradient(
      colors: [Color(0xFFF093FB), Color(0xFFF5576C)],
    ),
    'linear-gradient(135deg, #4facfe 0%, #00f2fe 100%)': const LinearGradient(
      colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
    ),
    'linear-gradient(135deg, #43e97b 0%, #38f9d7 100%)': const LinearGradient(
      colors: [Color(0xFF43E97B), Color(0xFF38F9D7)],
    ),
    'linear-gradient(135deg, #fa709a 0%, #fee140 100%)': const LinearGradient(
      colors: [Color(0xFFFA709A), Color(0xFFFEE140)],
    ),
    'linear-gradient(135deg, #a18cd1 0%, #fbc2eb 100%)': const LinearGradient(
      colors: [Color(0xFFA18CD1), Color(0xFFFBC2EB)],
    ),
    'linear-gradient(135deg, #0c0c0c 0%, #1a1a2e 100%)': const LinearGradient(
      colors: [Color(0xFF0C0C0C), Color(0xFF1A1A2E)],
    ),
    'linear-gradient(135deg, #d4fc79 0%, #96e6a1 100%)': const LinearGradient(
      colors: [Color(0xFFD4FC79), Color(0xFF96E6A1)],
    ),
  };

  @override
  Widget build(BuildContext context) {
    final raw = wallpaper?.trim();
    if (raw == null || raw.isEmpty) {
      return AuthBackground(child: child);
    }

    final gradient = _gradients[raw];
    return Stack(
      fit: StackFit.expand,
      children: [
        if (raw.startsWith('http'))
          Positioned.fill(
            child: ChatCachedNetworkImage(
              url: raw,
              fit: BoxFit.cover,
              showProgressIndicator: false,
              errorOverride: const SizedBox.shrink(),
            ),
          )
        else if (gradient != null)
          DecoratedBox(decoration: BoxDecoration(gradient: gradient))
        else
          AuthBackground(child: const SizedBox.expand()),
        if (raw.startsWith('http'))
          Container(color: Colors.black.withValues(alpha: 0.35)),
        child,
      ],
    );
  }
}

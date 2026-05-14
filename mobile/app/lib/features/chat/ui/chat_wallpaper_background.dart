import 'package:flutter/material.dart';

import '../data/builtin_wallpapers.dart';
import 'chat_cached_network_image.dart';
import 'chat_wallpaper_scope.dart';

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
    'linear-gradient(135deg, #C6E8EB 0%, #E9D0DE 100%)': const LinearGradient(
      colors: [Color(0xFFC6E8EB), Color(0xFFE9D0DE)],
    ),
    'linear-gradient(135deg, #D9F904 0%, #6CEB00 100%)': const LinearGradient(
      colors: [Color(0xFFD9F904), Color(0xFF6CEB00)],
    ),
    'linear-gradient(135deg, #151619 0%, #23242A 100%)': const LinearGradient(
      colors: [Color(0xFF151619), Color(0xFF23242A)],
    ),
  };

  @override
  Widget build(BuildContext context) {
    final raw = wallpaper?.trim();
    if (raw == null || raw.isEmpty) {
      return ChatWallpaperScope(wallpaper: null, child: _DefaultChatBackdrop(child: child));
    }

    final builtin = resolveBuiltinWallpaper(raw);
    final gradient = _gradients[raw];
    final isNetwork = raw.startsWith('http');
    final isImage = builtin != null || isNetwork;

    return ChatWallpaperScope(
      wallpaper: raw,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (builtin != null)
            Positioned.fill(
              child: Image.asset(
                builtin.assetFor(Theme.of(context).brightness),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const _DefaultChatBackdrop(child: SizedBox.expand()),
              ),
            )
          else if (isNetwork)
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
            const _DefaultChatBackdrop(child: SizedBox.expand()),
          if (isImage)
            Container(color: Colors.black.withValues(alpha: 0.35)),
          child,
        ],
      ),
    );
  }
}

class _DefaultChatBackdrop extends StatelessWidget {
  const _DefaultChatBackdrop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(decoration: BoxDecoration(color: Color(0xFF04070C))),
        Positioned(
          left: -120,
          top: -140,
          child: IgnorePointer(
            child: Container(
              width: 390,
              height: 390,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF1F60F8).withValues(alpha: 0.28),
                    const Color(0xFF1F60F8).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: -110,
          bottom: -120,
          child: IgnorePointer(
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF661CFF).withValues(alpha: 0.24),
                    const Color(0xFF661CFF).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.20),
                  Colors.black.withValues(alpha: 0.45),
                ],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

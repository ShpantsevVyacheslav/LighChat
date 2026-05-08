import 'package:flutter/material.dart';

import 'chat_cached_network_image.dart';

class ChatAvatar extends StatelessWidget {
  const ChatAvatar({
    super.key,
    required this.title,
    required this.radius,
    required this.avatarUrl,
  });

  final String title;
  final double radius;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl;
    final canRenderNetwork = url != null && url.isNotEmpty && !_looksLikeSvg(url);

    if (!canRenderNetwork) {
      return ChatAvatarLetter(title: title, radius: radius);
    }

    return ClipOval(
      child: SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: ChatCachedNetworkImage(
          url: url,
          fit: BoxFit.cover,
          compact: true,
          errorOverride: ChatAvatarLetter(title: title, radius: radius),
        ),
      ),
    );
  }

  bool _looksLikeSvg(String url) {
    final u = url.toLowerCase();
    if (u.contains('/svg')) return true;
    if (u.endsWith('.svg')) return true;
    if (u.contains('format=svg')) return true;
    return false;
  }
}

/// Единый плейсхолдер «первая буква имени» для всех экранов: чат-лист,
/// шапка чата, профили, список и детальная звонков. Тёмная диагональ
/// синий → пурпур + белая буква (светлая тема — мягкий голубой фон).
class ChatAvatarLetter extends StatelessWidget {
  const ChatAvatarLetter({
    super.key,
    required this.title,
    required this.radius,
  });

  final String title;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final initial = title.trim().isEmpty
        ? '?'
        : title.trim().characters.first.toUpperCase();
    final dark = Theme.of(context).colorScheme.brightness == Brightness.dark;
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [Color(0xFF18357C), Color(0xFF29133F)]
              : const [Color(0xFFE5ECFF), Color(0xFFDCE5FF)],
        ),
        border: Border.all(
          color: dark
              ? Colors.white.withValues(alpha: 0.18)
              : Colors.black.withValues(alpha: 0.10),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: radius * 0.8,
          fontWeight: FontWeight.w900,
          color: dark ? Colors.white : const Color(0xFF23315F),
        ),
      ),
    );
  }
}

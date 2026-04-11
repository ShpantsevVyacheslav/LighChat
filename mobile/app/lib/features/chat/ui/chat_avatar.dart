import 'package:flutter/material.dart';

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

    return CircleAvatar(
      radius: radius,
      backgroundImage: canRenderNetwork ? NetworkImage(url) : null,
      child: !canRenderNetwork ? Text(title.characters.first) : null,
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


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
      return CircleAvatar(
        radius: radius,
        child: Text(title.isEmpty ? '?' : title.characters.first.toString()),
      );
    }

    return ClipOval(
      child: SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: ChatCachedNetworkImage(
          url: url,
          fit: BoxFit.cover,
          compact: true,
          errorOverride: CircleAvatar(
            radius: radius,
            child: Text(title.isEmpty ? '?' : title.characters.first.toString()),
          ),
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


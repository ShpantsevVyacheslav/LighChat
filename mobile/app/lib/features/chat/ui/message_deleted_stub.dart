import 'package:flutter/material.dart';

import 'chat_wallpaper_contrast.dart';
import 'chat_wallpaper_scope.dart';
import 'chat_wallpaper_tone.dart';

class MessageDeletedStub extends StatelessWidget {
  const MessageDeletedStub({super.key, required this.alignRight});

  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    final wallpaper = ChatWallpaperScope.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Align(
        alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: chatWallpaperSafePillDecoration(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.delete_outline_rounded,
                size: 16,
                color: chatWallpaperAdaptiveSecondaryTextColor(
                  context: context,
                  wallpaper: wallpaper,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Сообщение удалено',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: chatWallpaperAdaptivePrimaryTextColor(
                    context: context,
                    wallpaper: wallpaper,
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


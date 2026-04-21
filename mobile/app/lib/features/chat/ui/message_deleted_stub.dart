import 'package:flutter/material.dart';

import 'chat_wallpaper_contrast.dart';

class MessageDeletedStub extends StatelessWidget {
  const MessageDeletedStub({super.key, required this.alignRight});

  final bool alignRight;

  @override
  Widget build(BuildContext context) {
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
                color: chatWallpaperSafeSecondaryIconColor(context),
              ),
              const SizedBox(width: 6),
              Text(
                'Сообщение удалено',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: chatWallpaperSafePrimaryTextColor(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


import 'dart:ui';

import 'package:flutter/material.dart';

/// Выбор источника после пункта «Фото и видео»: галерея / камера / видео.
Future<String?> showPhotoVideoSourceSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (ctx) {
      final fg = Colors.white.withValues(alpha: 0.92);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.32),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: Icon(Icons.photo_library_outlined, color: fg),
                      title: Text(
                        'Галерея',
                        style: TextStyle(
                          color: fg,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: () => Navigator.pop(ctx, 'gallery'),
                    ),
                    ListTile(
                      leading: Icon(Icons.photo_camera_outlined, color: fg),
                      title: Text(
                        'Сделать фото',
                        style: TextStyle(
                          color: fg,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: () => Navigator.pop(ctx, 'camera_photo'),
                    ),
                    ListTile(
                      leading: Icon(Icons.videocam_outlined, color: fg),
                      title: Text(
                        'Записать видео',
                        style: TextStyle(
                          color: fg,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: () => Navigator.pop(ctx, 'camera_video'),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'chat_cached_network_image.dart';

/// Полноэкранный просмотр аватара: исходное фото без круглого кропа (паритет веба: `avatar` vs `avatarThumb`).
class UserAvatarFullscreenViewer extends StatelessWidget {
  const UserAvatarFullscreenViewer({
    super.key,
    this.imageUrl,
    this.imageBytes,
  });

  final String? imageUrl;
  final Uint8List? imageBytes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: Center(
                  child: imageBytes != null
                      ? Image.memory(
                          imageBytes!,
                          fit: BoxFit.contain,
                        )
                      : (imageUrl != null && imageUrl!.trim().isNotEmpty)
                      ? ChatCachedNetworkImage(
                          url: imageUrl!.trim(),
                          fit: BoxFit.contain,
                          showProgressIndicator: true,
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
            Positioned(
              top: 4,
              left: 4,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

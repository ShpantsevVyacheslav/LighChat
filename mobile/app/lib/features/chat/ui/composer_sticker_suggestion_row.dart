import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lighchat_models/lighchat_models.dart';

import '../data/user_sticker_item_attachment.dart';
import '../data/user_sticker_packs_repository.dart';

/// Узкая горизонтальная строка быстрого доступа к стикерам над композером.
///
/// Изолированный виджет, вызывается как необязательный «слот» из `ChatComposer`
/// (см. `stickerSuggestionBuilder`). Отображает последние N стикеров из первого
/// личного пака пользователя, а если личных паков нет — из первого публичного
/// пака. Если стикеров в итоге нет — строка не рисуется (`SizedBox.shrink`).
///
/// При тапе по стикеру вызывается [onPickAttachment] с тем же `ChatAttachment`,
/// что и в полной панели стикеров (см. `composer_sticker_gif_sheet.dart`), —
/// поэтому дальнейший pipeline отправки не меняется.
class ComposerStickerSuggestionRow extends StatelessWidget {
  const ComposerStickerSuggestionRow({
    super.key,
    required this.userId,
    required this.repo,
    required this.onPickAttachment,
    this.maxCount = 8,
  });

  final String userId;
  final UserStickerPacksRepository repo;
  final void Function(ChatAttachment attachment) onPickAttachment;
  final int maxCount;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserStickerPackRow>>(
      stream: repo.watchMyPacks(userId),
      builder: (context, packsSnap) {
        final myPacks = packsSnap.data ?? const <UserStickerPackRow>[];
        if (myPacks.isNotEmpty) {
          return StreamBuilder<List<StickerItemRow>>(
            stream: repo.watchMyPackItems(userId, myPacks.first.id),
            builder: (c, s) =>
                _buildForItems(s.data ?? const <StickerItemRow>[]),
          );
        }
        return StreamBuilder<List<PublicStickerPackRow>>(
          stream: repo.watchPublicPacks(),
          builder: (context, pubSnap) {
            final publics = pubSnap.data ?? const <PublicStickerPackRow>[];
            if (publics.isEmpty) return const SizedBox.shrink();
            return StreamBuilder<List<StickerItemRow>>(
              stream: repo.watchPublicPackItems(publics.first.id),
              builder: (c, s) =>
                  _buildForItems(s.data ?? const <StickerItemRow>[]),
            );
          },
        );
      },
    );
  }

  Widget _buildForItems(List<StickerItemRow> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    final take = items.take(maxCount).toList(growable: false);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        height: 64,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 2),
          itemCount: take.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final it = take[i];
            return _StickerCell(
              item: it,
              onTap: () => onPickAttachment(userStickerItemToAttachment(it)),
            );
          },
        ),
      ),
    );
  }
}

class _StickerCell extends StatelessWidget {
  const _StickerCell({required this.item, required this.onTap});

  final StickerItemRow item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isVideo = item.contentType.startsWith('video/');
    final isAnim = isVideo || item.contentType == 'image/gif';
    final tile = Material(
      color: Colors.white.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 56,
          height: 56,
          child: isVideo
              ? const Center(
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white70,
                    size: 24,
                  ),
                )
              : CachedNetworkImage(
                  imageUrl: item.downloadUrl,
                  fit: BoxFit.contain,
                  placeholder: (_, _) => const SizedBox.shrink(),
                  errorWidget: (_, _, _) => const SizedBox.shrink(),
                ),
        ),
      ),
    );
    if (!isAnim) return tile;
    return Stack(
      alignment: Alignment.topRight,
      children: [
        tile,
        Padding(
          padding: const EdgeInsets.all(4),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(6),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            child: const Text(
              'GIF',
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

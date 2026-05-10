import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lighchat_models/lighchat_models.dart';

import '../../settings/data/energy_saving_preference.dart';
import '../data/recent_stickers_store.dart';
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
class ComposerStickerSuggestionRow extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final energy = ref.watch(energySavingProvider);
    final allowGifAutoplay = energy.effectiveAutoplayGif;
    final allowAnimatedStickers = energy.effectiveAnimatedStickers;
    final allowAnimatedEmoji = energy.effectiveAnimatedEmoji;
    return FutureBuilder<List<ChatAttachment>>(
      future: RecentStickersStore.instance.getRecents(),
      builder: (context, recentSnap) {
        final recents = recentSnap.data ?? const <ChatAttachment>[];
        if (recents.isNotEmpty) {
          return _buildForRecents(
            recents,
            allowGifAutoplay: allowGifAutoplay,
            allowAnimatedStickers: allowAnimatedStickers,
            allowAnimatedEmoji: allowAnimatedEmoji,
          );
        }
        return StreamBuilder<List<UserStickerPackRow>>(
          stream: repo.watchMyPacks(userId),
          builder: (context, packsSnap) {
            final myPacks = packsSnap.data ?? const <UserStickerPackRow>[];
            if (myPacks.isNotEmpty) {
              return StreamBuilder<List<StickerItemRow>>(
                stream: repo.watchMyPackItems(userId, myPacks.first.id),
                builder: (c, s) => _buildForItems(
                  s.data ?? const <StickerItemRow>[],
                  allowGifAutoplay: allowGifAutoplay,
                  allowAnimatedStickers: allowAnimatedStickers,
                ),
              );
            }
            return StreamBuilder<List<PublicStickerPackRow>>(
              stream: repo.watchPublicPacks(),
              builder: (context, pubSnap) {
                final publics =
                    pubSnap.data ?? const <PublicStickerPackRow>[];
                if (publics.isEmpty) return const SizedBox.shrink();
                return StreamBuilder<List<StickerItemRow>>(
                  stream: repo.watchPublicPackItems(publics.first.id),
                  builder: (c, s) => _buildForItems(
                    s.data ?? const <StickerItemRow>[],
                    allowGifAutoplay: allowGifAutoplay,
                    allowAnimatedStickers: allowAnimatedStickers,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildForRecents(
    List<ChatAttachment> items, {
    required bool allowGifAutoplay,
    required bool allowAnimatedStickers,
    required bool allowAnimatedEmoji,
  }) {
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
            final att = take[i];
            final isGif = att.name.toLowerCase().startsWith('gif_') ||
                (att.type ?? '').toLowerCase() == 'image/gif';
            final tile = Material(
              color: Colors.white.withValues(alpha: 0.06),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => onPickAttachment(att),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: TickerMode(
                    enabled: _tickerEnabledForRecent(
                      att,
                      allowGifAutoplay: allowGifAutoplay,
                      allowAnimatedStickers: allowAnimatedStickers,
                      allowAnimatedEmoji: allowAnimatedEmoji,
                    ),
                    child: CachedNetworkImage(
                      imageUrl: att.url,
                      fit: BoxFit.contain,
                      placeholder: (_, _) => const SizedBox.shrink(),
                      errorWidget: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            );
            if (!isGif) return tile;
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
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
          },
        ),
      ),
    );
  }

  Widget _buildForItems(
    List<StickerItemRow> items, {
    required bool allowGifAutoplay,
    required bool allowAnimatedStickers,
  }) {
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
              allowAnimation: _tickerEnabledForStickerItem(
                it,
                allowGifAutoplay: allowGifAutoplay,
                allowAnimatedStickers: allowAnimatedStickers,
              ),
              onTap: () => onPickAttachment(userStickerItemToAttachment(it)),
            );
          },
        ),
      ),
    );
  }

  bool _tickerEnabledForRecent(
    ChatAttachment attachment, {
    required bool allowGifAutoplay,
    required bool allowAnimatedStickers,
    required bool allowAnimatedEmoji,
  }) {
    final name = attachment.name.toLowerCase();
    if (name.startsWith('sticker_emoji_giphy_')) return allowAnimatedEmoji;
    if (name.startsWith('sticker_')) return allowAnimatedStickers;
    final type = (attachment.type ?? '').toLowerCase();
    if (name.startsWith('gif_') || type == 'image/gif') {
      return allowGifAutoplay;
    }
    return true;
  }

  bool _tickerEnabledForStickerItem(
    StickerItemRow item, {
    required bool allowGifAutoplay,
    required bool allowAnimatedStickers,
  }) {
    final t = item.contentType.toLowerCase();
    if (t == 'image/gif') return allowGifAutoplay;
    return allowAnimatedStickers;
  }
}

class _StickerCell extends StatelessWidget {
  const _StickerCell({
    required this.item,
    required this.onTap,
    required this.allowAnimation,
  });

  final StickerItemRow item;
  final VoidCallback onTap;
  final bool allowAnimation;

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
    final wrappedTile = isVideo
        ? tile
        : TickerMode(enabled: allowAnimation, child: tile);
    if (!isAnim) return tile;
    return Stack(
      alignment: Alignment.topRight,
      children: [
        wrappedTile,
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

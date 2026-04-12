import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lighchat_models/lighchat_models.dart';

import '../data/chat_media_layout_tokens.dart';
import '../data/google_maps_urls.dart';
import '../data/live_location_utils.dart';
import 'chat_cached_network_image.dart';
import 'location_live_countdown.dart';
import 'chat_glass_panel.dart';
import 'message_bubble_delivery_icons.dart';
import 'shared_location_map_screen.dart';

/// OSM и ряд CDN отклоняют запросы с дефолтным Dart User-Agent.
const _kLocationPreviewHttpHeaders = <String, String>{
  'User-Agent': 'LighChatMobile/1.0 (location preview; contact: app)',
};

/// Превью геолокации в чате (паритет `MessageLocationCard.tsx`): без рамки, тап — полный экран.
class MessageLocationCard extends StatelessWidget {
  const MessageLocationCard({
    super.key,
    required this.share,
    required this.senderId,
    required this.isMine,
    required this.createdAt,
    required this.showTimestamps,
    this.deliveryStatus,
    this.readAt,
  });

  final ChatLocationShare share;
  final String senderId;
  final bool isMine;
  final DateTime createdAt;
  final bool showTimestamps;
  final String? deliveryStatus;
  final DateTime? readAt;

  String _timeHm(DateTime dt) {
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  void _openMap(BuildContext context) {
    final external = share.mapsUrl.trim().isNotEmpty
        ? share.mapsUrl
        : buildGoogleMapsPlaceUrl(share.lat, share.lng);
    final liveExp = share.liveSession?.expiresAt;
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => SharedLocationMapScreen(
          lat: share.lat,
          lng: share.lng,
          externalMapsUrl: external,
          liveExpiresAtIso: (liveExp != null && liveExp.isNotEmpty) ? liveExp : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userRef = FirebaseFirestore.instance.collection('users').doc(senderId);

    return StreamBuilder<DocumentSnapshot<Map<String, Object?>>>(
      stream: userRef.snapshots(),
      builder: (context, snap) {
        UserLiveLocationShare? senderLive;
        var profileResolved = false;
        if (snap.hasError) {
          profileResolved = false;
        } else if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          profileResolved = false;
        } else if (snap.hasData) {
          profileResolved = true;
          final data = snap.data?.data();
          final raw = data?['liveLocationShare'];
          senderLive = UserLiveLocationShare.fromJson(raw);
        }

        final stillStreaming = share.liveSession != null &&
            isChatLiveLocationMessageStillStreaming(
              share,
              createdAt,
              senderLive,
              profileResolved,
            );

        if (share.liveSession != null && !stillStreaming) {
          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: ChatMediaLayoutTokens.locationPreviewMaxWidth),
            child: ChatGlassPanel(
              child: Text(
                isMine
                    ? 'Трансляция геолокации завершена. Собеседник больше не видит ваше актуальное местоположение.'
                    : 'Трансляция геолокации у этого контакта завершена. Актуальная позиция недоступна.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.94),
                ),
              ),
            ),
          );
        }

        final liveExp = share.liveSession?.expiresAt;
        final staticUrl = share.staticMapUrl;

        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: ChatMediaLayoutTokens.locationPreviewMaxWidth),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _openMap(context),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    if (staticUrl != null && staticUrl.isNotEmpty)
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: ChatCachedNetworkImage(
                          url: staticUrl,
                          httpHeaders: _kLocationPreviewHttpHeaders,
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                          errorOverride: _FallbackLocationTile(
                            share: share,
                            isMine: isMine,
                          ),
                        ),
                      )
                    else
                      _FallbackLocationTile(share: share, isMine: isMine),
                    if (liveExp != null && liveExp.isNotEmpty)
                      Positioned(
                        left: 8,
                        bottom: 8,
                        child: LocationLiveCountdown(expiresAtIso: liveExp),
                      ),
                    if (showTimestamps)
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.black.withValues(alpha: 0.45),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _timeHm(createdAt.toLocal()),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                                if (isMine) ...[
                                  const SizedBox(width: 3),
                                  MessageBubbleDeliveryIcons(
                                    deliveryStatus: deliveryStatus,
                                    readAt: readAt,
                                    iconColor: Colors.white.withValues(alpha: 0.75),
                                    size: 11,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FallbackLocationTile extends StatelessWidget {
  const _FallbackLocationTile({
    required this.share,
    required this.isMine,
  });

  final ChatLocationShare share;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = isMine ? scheme.onPrimary : scheme.primary;
    return SizedBox(
      height: 108,
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Row(
          children: [
            Icon(Icons.location_on_rounded, color: accent, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Местоположение',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isMine ? scheme.onPrimary : scheme.onSurface,
                    ),
                  ),
                  if (share.accuracyM != null)
                    Text(
                      '±${share.accuracyM!.round()} м',
                      style: TextStyle(
                        fontSize: 11,
                        color: (isMine ? scheme.onPrimary : scheme.onSurface)
                            .withValues(alpha: 0.65),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

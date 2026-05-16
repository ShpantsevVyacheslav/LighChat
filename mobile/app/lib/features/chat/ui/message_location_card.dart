import 'dart:ui' show ImageFilter;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lighchat_models/lighchat_models.dart';

import '../../../l10n/app_localizations.dart';
import '../data/chat_media_layout_tokens.dart';
import '../data/location_scroll_diagnostics.dart';
import '../data/google_maps_urls.dart';
import '../data/live_location_utils.dart';
import 'chat_cached_network_image.dart';
import 'location_live_countdown.dart';
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
    this.flat = false,
  });

  final ChatLocationShare share;
  final String senderId;
  final bool isMine;
  final DateTime createdAt;
  final bool showTimestamps;
  final String? deliveryStatus;
  final DateTime? readAt;

  /// Bug E: когда `true`, не оборачиваем содержимое в свой ClipRRect
  /// и не накладываем maxWidth — карта примыкает к краям родителя.
  /// Используется в combined location+caption bubble, где внешний
  /// контейнер уже клипает по своему радиусу.
  final bool flat;

  /// Scroll-jitter fix (Phase 13+): раньше `userRef.snapshots()`
  /// вызывался прямо в `build` — каждый scroll-tick ListView
  /// перестраивает item, MessageLocationCard.build вызывается заново,
  /// new Stream object каждый раз → StreamBuilder сбрасывал
  /// connectionState на waiting, отрисовывал loading-placeholder и
  /// триггерил relayout соседних bubble'ов — это и было видимое
  /// «дёргание» (повтор паттерна 5998afe1). Теперь Stream-объекты
  /// хранятся в process-wide LRU-кэше по uid, и `identical()` —
  /// true между rebuild'ами → StreamBuilder сохраняет
  /// connectionState=active.
  static final Map<String, Stream<DocumentSnapshot<Map<String, Object?>>>>
      _userStreamCache = <String,
          Stream<DocumentSnapshot<Map<String, Object?>>>>{};

  Stream<DocumentSnapshot<Map<String, Object?>>> _userStream() {
    final cached = _userStreamCache[senderId];
    if (cached != null) return cached;
    final stream = FirebaseFirestore.instance
        .collection('users')
        .doc(senderId)
        .snapshots()
        .asBroadcastStream();
    _userStreamCache[senderId] = stream;
    LocationScrollDiag.cardSubscribe();
    return stream;
  }

  String _timeHm(DateTime dt) {
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Widget _endedBubble(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Bug G: убрали ChatGlassPanel (BackdropFilter) — в серии end-bubble
    // он дёргал scroll. Заменили на простой DecoratedBox с тёмной
    // полупрозрачной заливкой — визуально похоже, но рендерится
    // дёшево (нет per-frame blur'ов на всё, что под ним).
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: ChatMediaLayoutTokens.locationPreviewMaxWidth,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.36),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            isMine
                ? l10n.location_card_broadcast_ended_mine
                : l10n.location_card_broadcast_ended_other,
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.94),
            ),
          ),
        ),
      ),
    );
  }

  void _openMap(BuildContext context) {
    final external = share.mapsUrl.trim().isNotEmpty
        ? share.mapsUrl
        : buildGoogleMapsPlaceUrl(share.lat, share.lng);
    final liveExp = share.liveSession?.expiresAt;
    final hasLive = liveExp != null && liveExp.isNotEmpty;
    // Bug 13: если share — live (есть expiresAt), пробрасываем uid
    // отправителя — full-screen карта подпишется на trackPoints и
    // нарисует MKPolyline трека (на iOS).
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => SharedLocationMapScreen(
          lat: share.lat,
          lng: share.lng,
          externalMapsUrl: external,
          liveExpiresAtIso: hasLive ? liveExp : null,
          senderUidForTracking: hasLive ? senderId : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    LocationScrollDiag.tickCardBuild();
    // Bug #18: scroll-jitter в серии «end of share» сообщений. Каждый
    // такой bubble раньше открывал персональный
    // StreamBuilder<users/{senderId}> → много активных подписок на
    // Firestore при скролле → дёргается layout. Для УЖЕ истёкших
    // live-сессий статус собеседника не нужен — сразу рендерим
    // «ended» pill без StreamBuilder. Паттерн повторяет fix
    // 5998afe1 (stable Future identity) — здесь стабилизируем тем,
    // что подписки нет вовсе.
    final liveSession = share.liveSession;
    if (liveSession != null) {
      final expIso = liveSession.expiresAt;
      if (expIso != null && expIso.isNotEmpty) {
        final exp = DateTime.tryParse(expIso);
        if (exp != null && !exp.isAfter(DateTime.now())) {
          return _endedBubble(context);
        }
      }
    }

    return StreamBuilder<DocumentSnapshot<Map<String, Object?>>>(
      stream: _userStream(),
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
          return _endedBubble(context);
        }

        final liveExp = share.liveSession?.expiresAt;
        final staticUrl = share.staticMapUrl;

        // Bug #11: aspect ratio 7:5 (+27% высоты от 16:9).
        const aspect = 7 / 5;
        // Scroll-perf fix (Phase 13+ v2): убрали interactive MKMapView
        // из inline-bubble. PlatformView в ListView создавался и
        // уничтожался на каждом recycle item'а (видно в логах:
        // `CAMetalLayer ignoring invalid setDrawableSize 0×0` +
        // `Resetting GeoCSS zone allocator`) — каждый scroll-tick
        // запускал full MKMapView lifecycle, что и было главным
        // источником дёргания при серии location-сообщений.
        // Решение: inline = статичная OSM-плитка (cheap, кэшируется
        // CDN'ом), interactive MKMapView остаётся только в fullscreen
        // (тап на expand-кнопку или на саму карту → _openMap).
        // Bug #12 trade-off: пользователь жертвует pan/zoom в bubble
        // в обмен на плавный скролл; fullscreen открывается одним
        // тапом.
        final stackBody = Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openMap(context),
            child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    if (staticUrl != null && staticUrl.isNotEmpty)
                      AspectRatio(
                        aspectRatio: aspect,
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
                    // expand-иконка в углу — намёк что тап откроет
                    // интерактивную fullscreen-карту.
                    Positioned(
                      right: 8,
                      top: 8,
                      child: _MapExpandButton(
                        onTap: () => _openMap(context),
                      ),
                    ),
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
        );
        if (flat) {
          // Bug E: внешний bubble уже клипает по своему радиусу +
          // конструирует maxWidth; не оборачиваем ничем.
          return stackBody;
        }
        return ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: ChatMediaLayoutTokens.locationPreviewMaxWidth,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: stackBody,
          ),
        );
      },
    );
  }
}

/// Bug #12: стеклянный кружок «expand» в углу карты. Открывает
/// fullscreen, потому что таппать саму карту нельзя (она интерактивна
/// и съедает gestures).
class _MapExpandButton extends StatelessWidget {
  const _MapExpandButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Material(
          color: Colors.black.withValues(alpha: 0.38),
          shape: const CircleBorder(
            side: BorderSide(color: Colors.white24, width: 0.5),
          ),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: const Padding(
              padding: EdgeInsets.all(7),
              child: Icon(
                Icons.open_in_full_rounded,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
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
    final l10n = AppLocalizations.of(context)!;
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
                    l10n.location_card_title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isMine ? scheme.onPrimary : scheme.onSurface,
                    ),
                  ),
                  if (share.accuracyM != null)
                    Text(
                      l10n.location_card_accuracy(share.accuracyM!.round()),
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

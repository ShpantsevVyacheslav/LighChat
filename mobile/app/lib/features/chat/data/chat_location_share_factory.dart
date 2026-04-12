import 'package:geolocator/geolocator.dart';
import 'package:lighchat_models/lighchat_models.dart';

import 'google_maps_urls.dart';
import 'live_location_duration_options.dart';

/// Сборка `ChatLocationShare` + флаги для `users.liveLocationShare` (паритет веб).
ChatLocationShare buildChatLocationShareFromPosition(
  Position pos, {
  required String durationId,
}) {
  final lat = pos.latitude;
  final lng = pos.longitude;
  final mapsUrl = buildGoogleMapsPlaceUrl(lat, lng);
  final staticMapUrl = buildChatLocationStaticPreviewUrl(lat, lng);
  final capturedAt = DateTime.now().toUtc().toIso8601String();
  final live = liveLocationDurationActivatesUserShare(durationId);
  final expiresAt = liveLocationExpiresAtForDurationId(durationId);
  return ChatLocationShare(
    lat: lat,
    lng: lng,
    mapsUrl: mapsUrl,
    capturedAt: capturedAt,
    accuracyM: pos.accuracy,
    staticMapUrl: staticMapUrl,
    liveSession:
        live ? ChatLocationLiveSession(expiresAt: expiresAt) : null,
  );
}

bool shouldActivateUserLiveShare(String durationId) =>
    liveLocationDurationActivatesUserShare(durationId);

String? userLiveExpiresAtForSend(String durationId) =>
    liveLocationDurationActivatesUserShare(durationId)
        ? liveLocationExpiresAtForDurationId(durationId)
        : null;

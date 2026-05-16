import 'dart:async';
import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lighchat_firebase/lighchat_firebase.dart' show ChatRepository;
import 'package:lighchat_models/lighchat_models.dart';

import 'live_location_utils.dart';

/// Bug 13 (Phase 13): сервис, который пишет trackPoints в Firestore
/// пока юзер делится live-location'ом.
///
/// Алгоритм:
///   1. Подписывается на `users/{currentUid}.liveLocationShare`.
///   2. Когда share становится visible (active && !expired) — стартует
///      `Geolocator.getPositionStream(distanceFilter=15м)`.
///   3. На каждый fix зовёт `repo.writeLiveLocationTrackPoint`.
///   4. Когда share исчезает / expires — отписывается от geolocator.
///
/// **Foreground only (MVP)**: запись активна, пока app живёт. Если
/// iOS suspendит процесс — поток геолокации прервётся; восстановится
/// при возврате в foreground (snapshot listener поднимет stream
/// снова). Background-режим (`NSLocationAlwaysAndWhenInUseUsage` +
/// background_modes) — отдельный этап.
///
/// Использование: один экземпляр на app. Вызвать `attach(repo)` после
/// инициализации Firebase / Riverpod. Сам по себе ничего не пишет —
/// только реагирует на Firestore changes.
class LiveLocationTracker {
  LiveLocationTracker._();

  static final LiveLocationTracker instance = LiveLocationTracker._();

  ChatRepository? _repo;
  StreamSubscription<DocumentSnapshot<Map<String, Object?>>>? _shareSub;
  StreamSubscription<Position>? _posSub;
  String? _activeUid;

  /// Идемпотентный entry-point. Вызывать после Firebase ready;
  /// повторный вызов с тем же repo — no-op.
  void attach(ChatRepository repo) {
    if (identical(_repo, repo) && _shareSub != null) return;
    _repo = repo;
    _shareSub?.cancel();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _activeUid = uid;
    _shareSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen(_onUserSnapshot, onError: (Object e, StackTrace st) {
      debugPrint('[live-tracker] user snapshot error: $e');
    });
  }

  /// Не используется напрямую, но даёт возможность остановить трекер
  /// для logout-flow / тестов.
  Future<void> dispose() async {
    await _shareSub?.cancel();
    _shareSub = null;
    await _stopPositionStream();
    _activeUid = null;
    _repo = null;
  }

  void _onUserSnapshot(DocumentSnapshot<Map<String, Object?>> doc) {
    final raw = doc.data()?['liveLocationShare'];
    final live = UserLiveLocationShare.fromJson(raw);
    if (live == null || !isLiveShareVisible(live)) {
      _stopPositionStream();
      return;
    }
    // Уже стримим — ничего не делаем.
    if (_posSub != null) return;
    _startPositionStream();
  }

  void _startPositionStream() {
    final repo = _repo;
    final uid = _activeUid;
    if (repo == null || uid == null) return;
    debugPrint('[live-tracker] starting Geolocator.getPositionStream');
    // Bug 13: чистим хвост от прошлого live-share — это безопасно,
    // т.к. сам snapshot listener выставил _posSub=null только если
    // прошлый share уже скрыт. Best-effort, fire-and-forget.
    unawaited(repo.clearLiveLocationTrackPoints(uid: uid).catchError(
      (Object e) {
        debugPrint('[live-tracker] cleanup pre-start failed: $e');
      },
    ));
    // Background-tracking escalation. На iOS — попробуем подняться
    // до .authorizedAlways (Info.plist
    // `NSLocationAlwaysAndWhenInUseUsageDescription` + UIBackgroundModes
    // location). Если юзер откажет — продолжаем foreground-only:
    // когда app свернётся, stream приостановится, при возврате
    // в foreground snapshot listener запустит его снова.
    unawaited(_maybeEscalateToAlwaysPermission());
    final settings = _platformLocationSettings();
    _posSub = Geolocator.getPositionStream(locationSettings: settings).listen(
      (pos) {
        debugPrint(
          '[live-tracker] fix lat=${pos.latitude} lng=${pos.longitude} '
          'acc=${pos.accuracy}',
        );
        unawaited(repo.writeLiveLocationTrackPoint(
          uid: uid,
          lat: pos.latitude,
          lng: pos.longitude,
          accuracyM: pos.accuracy,
        ));
      },
      onError: (Object e, StackTrace st) {
        debugPrint('[live-tracker] position stream error: $e');
      },
      cancelOnError: false,
    );
  }

  Future<void> _stopPositionStream() async {
    if (_posSub != null) {
      debugPrint('[live-tracker] stopping Geolocator stream');
      await _posSub!.cancel();
      _posSub = null;
    }
  }

  /// Platform-specific `LocationSettings`: на iOS включаем
  /// `allowBackgroundLocationUpdates` + `showBackgroundLocationIndicator`
  /// чтобы CoreLocation продолжал стримить fix'ы когда app в фоне;
  /// на Android — foreground service notification (без него Android
  /// 8+ убивает background stream через ~минуту).
  LocationSettings _platformLocationSettings() {
    if (Platform.isIOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 15,
        // Активирует CoreLocation `allowsBackgroundLocationUpdates`.
        // Требует UIBackgroundModes=location в Info.plist (есть).
        allowBackgroundLocationUpdates: true,
        // Синий статус-бар индикатор: «приложение продолжает следить
        // за вашей геопозицией». Apple-mandated UX.
        showBackgroundLocationIndicator: true,
        // Без этого CoreLocation останавливает stream после ~1 мин в
        // background для экономии батареи.
        pauseLocationUpdatesAutomatically: false,
        activityType: ActivityType.other,
      );
    }
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 15,
        // Foreground service нужен Android 8+ чтобы не убивать stream.
        // Notification минимальная — UI достаточно: пользователь видит
        // что app пишет геолокацию.
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Идёт трансляция геолокации',
          notificationText:
              'Приложение делится вашим местоположением. Откройте чат, '
              'чтобы остановить.',
          enableWakeLock: true,
        ),
      );
    }
    // Web / desktop — generic.
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 15,
    );
  }

  /// Bug 13: на iOS пробуем поднять permission до `.authorizedAlways`.
  /// На устройстве с `.authorizedWhenInUse` Geolocator всё равно
  /// будет стримить, но iOS поставит stream на паузу через ~10 минут
  /// после suspension. Запрос always — best-effort: если юзер уже
  /// отказал, повторного диалога Apple не покажет.
  Future<void> _maybeEscalateToAlwaysPermission() async {
    if (!Platform.isIOS) return;
    try {
      final current = await Geolocator.checkPermission();
      if (current == LocationPermission.whileInUse) {
        await Geolocator.requestPermission();
      }
    } catch (e) {
      debugPrint('[live-tracker] permission escalation failed: $e');
    }
  }
}

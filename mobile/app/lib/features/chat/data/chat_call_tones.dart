import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:just_audio/just_audio.dart';

import 'ringtone_presets.dart';

/// Плеер звонковых тонов для 1:1 звонков:
/// - входящий звонок: пресет из [callRingtoneId] (asset) или `audio/ringtone.mp3` (Storage fallback)
/// - исходящий дозвон: `audio/ringback.mp3`
///
/// Поведение повторяет web-оверлей: пока статус `calling`, играет один
/// из loop-тонов в зависимости от роли участника, в остальных статусах
/// оба тона останавливаются.
class ChatCallToneController {
  ChatCallToneController({this.callRingtoneId});

  /// Id пресета мелодии звонка (см. ringtone_presets.dart). `null` —
  /// используется legacy-звук из Firebase Storage.
  final String? callRingtoneId;

  final AudioPlayer _ringtonePlayer = AudioPlayer();
  final AudioPlayer _ringbackPlayer = AudioPlayer();

  bool _disposed = false;
  bool _ringtoneReady = false;
  bool _ringbackReady = false;
  Future<void>? _prepareFuture;

  Future<void> prepare() {
    final f = _prepareFuture;
    if (f != null) return f;
    final next = _prepareImpl();
    _prepareFuture = next;
    return next;
  }

  Future<void> _prepareImpl() async {
    if (_disposed) return;
    await _ringtonePlayer.setLoopMode(LoopMode.one);
    await _ringbackPlayer.setLoopMode(LoopMode.one);

    final resolvedId = callRingtoneId ?? await _resolveCallRingtoneIdFromUser();
    final preset = ringtonePresetById(resolvedId);
    if (preset != null) {
      _ringtoneReady = await _loadFromAsset(
        player: _ringtonePlayer,
        assetPath: preset.assetPath,
      );
    } else {
      _ringtoneReady = await _loadFromStorage(
        player: _ringtonePlayer,
        path: 'audio/ringtone.mp3',
      );
    }
    _ringbackReady = await _loadFromStorage(
      player: _ringbackPlayer,
      path: 'audio/ringback.mp3',
    );
  }

  Future<String?> _resolveCallRingtoneIdFromUser() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return null;
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final data = snap.data();
      if (data == null) return null;
      final notif = data['notificationSettings'];
      if (notif is! Map) return null;
      final raw = notif['callRingtoneId'];
      if (raw is String && raw.isNotEmpty) return raw;
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> _loadFromAsset({
    required AudioPlayer player,
    required String assetPath,
  }) async {
    try {
      await player.setAsset(assetPath);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _loadFromStorage({
    required AudioPlayer player,
    required String path,
  }) async {
    try {
      final url = await FirebaseStorage.instance.ref(path).getDownloadURL();
      await player.setAudioSource(AudioSource.uri(Uri.parse(url)));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> sync({
    required bool playIncomingRingtone,
    required bool playOutgoingRingback,
  }) async {
    if (_disposed) return;
    await prepare();
    if (_disposed) return;

    if (playIncomingRingtone && _ringtoneReady) {
      await _pauseAndRewind(_ringbackPlayer);
      if (!_ringtonePlayer.playing) {
        await _ringtonePlayer.play();
      }
      return;
    }

    if (playOutgoingRingback && _ringbackReady) {
      await _pauseAndRewind(_ringtonePlayer);
      if (!_ringbackPlayer.playing) {
        await _ringbackPlayer.play();
      }
      return;
    }

    await stop();
  }

  Future<void> stop() async {
    if (_disposed) return;
    await _pauseAndRewind(_ringtonePlayer);
    await _pauseAndRewind(_ringbackPlayer);
  }

  Future<void> _pauseAndRewind(AudioPlayer player) async {
    try {
      await player.pause();
    } catch (_) {}
    try {
      await player.seek(Duration.zero);
    } catch (_) {}
  }

  Future<void> dispose() async {
    if (_disposed) return;
    await stop();
    _disposed = true;
    await _ringtonePlayer.dispose();
    await _ringbackPlayer.dispose();
  }
}

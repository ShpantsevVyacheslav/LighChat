import 'dart:async';

import 'package:just_audio/just_audio.dart';

import '../../chat/data/ringtone_presets.dart';

/// Лёгкий синглтон-плеер короткого «пинга» при поднятии руки другим
/// участником видеоконференции.
class MeetingHandRaisePlayer {
  MeetingHandRaisePlayer._();

  static final MeetingHandRaisePlayer instance = MeetingHandRaisePlayer._();

  final AudioPlayer _player = AudioPlayer();
  bool _loaded = false;
  bool _disposed = false;

  Future<void> play() async {
    if (_disposed) return;
    try {
      if (!_loaded) {
        await _player.setAsset(kHandRaiseAssetPath);
        _loaded = true;
      }
      await _player.seek(Duration.zero);
      await _player.play();
    } catch (_) {
      // Не критично.
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    try {
      await _player.dispose();
    } catch (_) {}
  }
}

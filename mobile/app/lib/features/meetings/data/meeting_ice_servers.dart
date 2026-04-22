import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Источник ICE-конфига для мобильных peer-connections.
///
/// По умолчанию запрашиваем у web-деплоя `/api/webrtc/ice` (Next.js API route),
/// который знает Metered TURN-credentials. Позволяем переопределить базовый URL
/// через `--dart-define=LIGHCHAT_API_ORIGIN=https://staging.lighchat.app`,
/// если приложение общается со staging-бекендом.
///
/// В случае неудачи откатываемся к публичным Google STUN-серверам — соединение
/// всё ещё возможно для клиентов без симметричного NAT.
class MeetingIceServers {
  MeetingIceServers({http.Client? httpClient}) : _client = httpClient ?? http.Client();

  final http.Client _client;

  static const _apiOrigin = String.fromEnvironment(
    'LIGHCHAT_API_ORIGIN',
    defaultValue: 'https://lighchat.app',
  );

  static const _fallback = <Map<String, dynamic>>[
    <String, dynamic>{'urls': 'stun:stun1.l.google.com:19302'},
    <String, dynamic>{'urls': 'stun:stun2.l.google.com:19302'},
  ];

  static const _timeout = Duration(seconds: 5);

  /// Возвращает `{ 'iceServers': [...], 'sdpSemantics': 'unified-plan' }` —
  /// готовый конфиг для `createPeerConnection`.
  Future<Map<String, dynamic>> fetchConfig() async {
    final servers = await _fetchServers();
    return <String, dynamic>{
      'iceServers': servers,
      'sdpSemantics': 'unified-plan',
      // Trickle ICE включён по умолчанию; дубль для ясности, фактически это дефолт.
      'iceCandidatePoolSize': 0,
    };
  }

  Future<List<Map<String, dynamic>>> _fetchServers() async {
    final uri = Uri.parse('$_apiOrigin/api/webrtc/ice');
    try {
      final resp = await _client.get(uri).timeout(_timeout);
      if (resp.statusCode != 200) return _fallback;
      final decoded = jsonDecode(resp.body);
      if (decoded is! Map) return _fallback;
      final raw = decoded['iceServers'];
      if (raw is! List) return _fallback;
      final servers = <Map<String, dynamic>>[];
      for (final entry in raw) {
        if (entry is Map) {
          servers.add(
            entry.map((k, v) => MapEntry(k.toString(), v)),
          );
        }
      }
      if (servers.isEmpty) return _fallback;
      return servers;
    } catch (_) {
      return _fallback;
    }
  }

  void dispose() {
    _client.close();
  }
}

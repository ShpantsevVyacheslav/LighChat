import 'package:flutter_webrtc/flutter_webrtc.dart';

class _PrevPackets {
  int? packets;
}

/// Сэмплер «активности речи» по статистике WebRTC (паритет идеи web
/// `getStats`, без изменения mesh-сигналинга).
///
/// Для каждого удалённого участника [remoteId] — прирост `inbound-rtp`
/// **audio** `packetsReceived` на соответствующем PC.
///
/// Для локального пользователя — прирост `outbound-rtp` **audio**
/// `packetsSent` из **первого** ответа `getStats` (тот же снимок, что и
/// inbound для первого peer).
class MeetingActiveSpeakerSampler {
  final Map<String, _PrevPackets> _inboundByPeer = {};
  final _PrevPackets _localOutbound = _PrevPackets();

  void removePeer(String remoteId) {
    _inboundByPeer.remove(remoteId);
  }

  void clear() {
    _inboundByPeer.clear();
    _localOutbound.packets = null;
  }

  /// Сбросить базу для исходящего аудио (вызывать при вкл/выкл микрофона).
  void resetLocalOutbound() {
    _localOutbound.packets = null;
  }

  static int _sumInboundAudioPackets(Iterable<dynamic> reports) {
    var n = 0;
    for (final r in reports) {
      if (r.type != 'inbound-rtp') continue;
      final v = r.values;
      final kind = v['kind'] ?? v['mediaType'];
      if (kind != 'audio') continue;
      final pr = v['packetsReceived'];
      if (pr is num) n += pr.toInt();
    }
    return n;
  }

  static int _sumOutboundAudioPackets(Iterable<dynamic> reports) {
    var n = 0;
    for (final r in reports) {
      if (r.type != 'outbound-rtp') continue;
      final v = r.values;
      final kind = v['kind'] ?? v['mediaType'];
      if (kind != 'audio') continue;
      final ps = v['packetsSent'];
      if (ps is num) n += ps.toInt();
    }
    return n;
  }

  double _consumeOutboundDelta(Iterable<dynamic> reports) {
    final total = _sumOutboundAudioPackets(reports);
    final base = _localOutbound.packets ?? total;
    final delta = (total - base).clamp(0, 800).toDouble();
    _localOutbound.packets = total;
    return delta;
  }

  Future<Map<String, double>> sample({
    required Map<String, RTCPeerConnection> peersByRemoteId,
    required String selfUid,
    required bool localMicMuted,
  }) async {
    final out = <String, double>{};
    if (peersByRemoteId.isEmpty) {
      return out;
    }

    var isFirstPeer = true;
    for (final e in peersByRemoteId.entries) {
      final reports = await e.value.getStats();
      final totalIn = _sumInboundAudioPackets(reports);
      final prev = _inboundByPeer.putIfAbsent(e.key, _PrevPackets.new);
      final baseIn = prev.packets ?? totalIn;
      final deltaIn = (totalIn - baseIn).clamp(0, 800).toDouble();
      prev.packets = totalIn;
      out[e.key] = deltaIn;

      if (isFirstPeer) {
        isFirstPeer = false;
        out[selfUid] =
            localMicMuted ? 0.0 : _consumeOutboundDelta(reports);
      }
    }

    return out;
  }
}

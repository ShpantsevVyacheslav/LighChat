import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';

/// Классификация качества WebRTC-соединения.
/// Совпадает с web (`src/lib/webrtc/peer-stats.ts`).
enum PeerConnectionQuality { unknown, good, poor, bad }

class PeerStatsSample {
  const PeerStatsSample({
    required this.quality,
    required this.packetLossRatio,
    required this.roundTripTimeMs,
    required this.jitterMs,
  });

  final PeerConnectionQuality quality;
  final double packetLossRatio;
  final double? roundTripTimeMs;
  final double? jitterMs;
}

class PeerStatsThresholds {
  const PeerStatsThresholds({
    this.poorPacketLossRatio = 0.03,
    this.badPacketLossRatio = 0.10,
    this.poorRttMs = 300,
    this.badRttMs = 700,
  });

  final double poorPacketLossRatio;
  final double badPacketLossRatio;
  final double poorRttMs;
  final double badRttMs;
}

/// Подписка на периодическую выборку `getStats` одного RTCPeerConnection.
/// Колбэк вызывается только при СМЕНЕ качества — не спамит.
/// Возвращает функцию отписки; обязательно вызывать при уничтожении peer.
Function watchPeerStats(
  RTCPeerConnection pc,
  void Function(PeerStatsSample) onSample, {
  Duration interval = const Duration(seconds: 5),
  PeerStatsThresholds thresholds = const PeerStatsThresholds(),
}) {
  var disposed = false;
  var prevReceived = 0;
  var prevLost = 0;
  var lastQuality = PeerConnectionQuality.unknown;

  Future<void> tick() async {
    if (disposed) return;
    try {
      final reports = await pc.getStats();
      var packetsReceived = 0;
      var packetsLost = 0;
      var jitterSum = 0.0;
      var jitterSamples = 0;
      double? rttMs;

      for (final r in reports) {
        final values = r.values;
        if (r.type == 'inbound-rtp') {
          final kind = values['kind'] ?? values['mediaType'];
          if (kind == 'video' || kind == 'audio') {
            final pr = values['packetsReceived'];
            final pl = values['packetsLost'];
            final jit = values['jitter'];
            if (pr is num) packetsReceived += pr.toInt();
            if (pl is num) packetsLost += pl.toInt();
            if (jit is num) {
              jitterSum += jit.toDouble();
              jitterSamples++;
            }
          }
        } else if (r.type == 'candidate-pair') {
          final state = values['state'];
          final nominated = values['nominated'] == true;
          final rtt = values['currentRoundTripTime'];
          if ((state == 'succeeded' || nominated) && rtt is num) {
            rttMs = rtt.toDouble() * 1000;
          }
        }
      }

      final deltaRecv = (packetsReceived - prevReceived).clamp(0, 1 << 31).toInt();
      final deltaLost = (packetsLost - prevLost).clamp(0, 1 << 31).toInt();
      prevReceived = packetsReceived;
      prevLost = packetsLost;
      final total = deltaRecv + deltaLost;
      final ratio = total > 0 ? deltaLost / total : 0.0;
      final quality = _classify(ratio, rttMs, thresholds);
      final jitterMs = jitterSamples > 0 ? (jitterSum / jitterSamples) * 1000 : null;

      if (quality != lastQuality) {
        lastQuality = quality;
        onSample(PeerStatsSample(
          quality: quality,
          packetLossRatio: ratio,
          roundTripTimeMs: rttMs,
          jitterMs: jitterMs,
        ));
      }
    } catch (_) {
      // getStats может упасть при закрытом pc — это нормальная гонка.
    }
  }

  final timer = Timer.periodic(interval, (_) => tick());
  // Первая выборка чуть раньше — быстрее покажем «плохо».
  final initialTimer = Timer(const Duration(milliseconds: 1500), tick);

  return () {
    disposed = true;
    timer.cancel();
    initialTimer.cancel();
  };
}

PeerConnectionQuality _classify(
  double ratio,
  double? rttMs,
  PeerStatsThresholds t,
) {
  if (ratio >= t.badPacketLossRatio || (rttMs != null && rttMs >= t.badRttMs)) {
    return PeerConnectionQuality.bad;
  }
  if (ratio >= t.poorPacketLossRatio || (rttMs != null && rttMs >= t.poorRttMs)) {
    return PeerConnectionQuality.poor;
  }
  return PeerConnectionQuality.good;
}

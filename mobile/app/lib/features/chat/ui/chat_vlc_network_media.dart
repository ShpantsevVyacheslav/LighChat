import 'dart:async';

import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

import 'vlc_ios_simulator_stub.dart'
    if (dart.library.io) 'vlc_ios_simulator_io.dart' as vlc_sim;

/// AVPlayer / just_audio на iOS не декодируют WebM (VP8/VP9 + Opus). VLC — обходной путь.
/// На iOS Simulator VLC часто падает с `channel-error` — не используем.
bool chatMediaNeedsVlcOnIos(String url, {String? mimeType}) {
  if (kIsWeb) return false;
  if (defaultTargetPlatform != TargetPlatform.iOS) return false;
  if (vlc_sim.vlcIosSimulatorHost()) return false;
  final path = url.split('?').first.toLowerCase();
  if (path.endsWith('.webm')) return true;
  final t = (mimeType ?? '').toLowerCase();
  return t.contains('webm');
}

/// Полноэкранное видео по сети (WebM на iOS и при необходимости другие форматы).
class ChatVlcFullscreenViewer extends StatefulWidget {
  const ChatVlcFullscreenViewer({super.key, required this.url});

  final String url;

  @override
  State<ChatVlcFullscreenViewer> createState() => _ChatVlcFullscreenViewerState();
}

class _ChatVlcFullscreenViewerState extends State<ChatVlcFullscreenViewer> {
  late final VlcPlayerController _vlc;

  @override
  void initState() {
    super.initState();
    _vlc = VlcPlayerController.network(
      widget.url,
      hwAcc: HwAcc.auto,
      autoPlay: true,
      autoInitialize: true,
    );
    _vlc.addListener(_onVlc);
  }

  void _onVlc() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _vlc.removeListener(_onVlc);
    unawaited(_vlc.dispose());
    super.dispose();
  }

  Future<void> _togglePlay() async {
    final v = _vlc.value;
    if (!v.isInitialized || v.hasError) return;
    if (v.isPlaying) {
      await _vlc.pause();
    } else {
      await _vlc.play();
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final v = _vlc.value;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Видео'),
      ),
      body: Center(
        child: v.hasError
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.videocam_off_rounded,
                      color: Colors.white.withValues(alpha: 0.85),
                      size: 44,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Не удалось воспроизвести видео.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              )
            : !v.isInitialized
            ? const CircularProgressIndicator()
            : AspectRatio(
                aspectRatio: v.aspectRatio > 0 ? v.aspectRatio : 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    VlcPlayer(
                      controller: _vlc,
                      aspectRatio: v.aspectRatio > 0 ? v.aspectRatio : 16 / 9,
                      placeholder: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _togglePlay,
                        child: AnimatedOpacity(
                          opacity: v.isPlaying ? 0.0 : 1.0,
                          duration: const Duration(milliseconds: 180),
                          child: Center(
                            child: Icon(
                              Icons.play_circle_fill_rounded,
                              size: 72,
                              color: Colors.white.withValues(alpha: 0.92),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

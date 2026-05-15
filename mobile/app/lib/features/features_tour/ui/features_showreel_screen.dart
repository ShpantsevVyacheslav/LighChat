import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';

import '../data/features_showreel_scenes.dart';
import 'feature_mocks.dart';

/// Fullscreen-плеер showreel-тура с TTS-озвучкой.
///
///  – авто-переключение сцен по `ShowreelScene.durationMs`;
///  – озвучка через `flutter_tts` (на iOS использует AVSpeechSynthesizer
///    с premium-голосом, если он установлен в Settings → Accessibility →
///    Spoken Content; на Android — системный TextToSpeech);
///  – контролы: Play/Pause, Prev/Next, Mute, Close + прогресс-бар по
///    сценам;
///  – Ken-Burns зум на каждой сцене для динамики.
class FeaturesShowreelScreen extends StatefulWidget {
  const FeaturesShowreelScreen({super.key});

  @override
  State<FeaturesShowreelScreen> createState() => _FeaturesShowreelScreenState();
}

class _FeaturesShowreelScreenState extends State<FeaturesShowreelScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _tick = Duration(milliseconds: 100);

  final FlutterTts _tts = FlutterTts();
  late final AnimationController _kenBurns;

  int _sceneIdx = 0;
  int _elapsedInSceneMs = 0;
  bool _paused = false;
  bool _muted = false;
  Timer? _ticker;
  bool _ttsInitDone = false;

  @override
  void initState() {
    super.initState();
    _kenBurns = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: kShowreelScenes[0].durationMs),
    )..forward();
    _initTts();
    _startTicker();
    // Озвучку запускаем после первого build'а — нужен `context.locale`.
    WidgetsBinding.instance.addPostFrameCallback((_) => _speakCurrent());
  }

  Future<void> _initTts() async {
    try {
      await _tts.setSpeechRate(0.50); // нативный синтез — комфортная скорость
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      _ttsInitDone = true;
    } catch (_) {
      _ttsInitDone = false;
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(_tick, (_) {
      if (!mounted || _paused) return;
      setState(() => _elapsedInSceneMs += _tick.inMilliseconds);
      final cur = kShowreelScenes[_sceneIdx];
      if (_elapsedInSceneMs >= cur.durationMs) {
        _advance();
      }
    });
  }

  void _advance() {
    if (_sceneIdx >= kShowreelScenes.length - 1) {
      _onClose();
      return;
    }
    setState(() {
      _sceneIdx += 1;
      _elapsedInSceneMs = 0;
    });
    _resetKenBurns();
    _speakCurrent();
  }

  void _resetKenBurns() {
    final cur = kShowreelScenes[_sceneIdx];
    _kenBurns
      ..stop()
      ..duration = Duration(milliseconds: cur.durationMs)
      ..value = 0
      ..forward();
  }

  Future<void> _speakCurrent() async {
    if (!_ttsInitDone || _muted) return;
    final locale = Localizations.localeOf(context);
    final scene = kShowreelScenes[_sceneIdx];
    try {
      await _tts.stop();
      await _tts.setLanguage(scene.ttsLang(locale));
      await _tts.speak(scene.voiceover(locale));
    } catch (_) {
      /* ignore */
    }
  }

  void _togglePause() {
    setState(() => _paused = !_paused);
    if (_paused) {
      _kenBurns.stop();
      _tts.pause();
    } else {
      _kenBurns.forward();
      _speakCurrent();
    }
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    if (_muted) {
      _tts.stop();
    } else {
      _speakCurrent();
    }
  }

  void _next() {
    if (_sceneIdx >= kShowreelScenes.length - 1) return;
    setState(() {
      _sceneIdx += 1;
      _elapsedInSceneMs = 0;
      _paused = false;
    });
    _resetKenBurns();
    _speakCurrent();
  }

  void _prev() {
    if (_sceneIdx == 0) return;
    setState(() {
      _sceneIdx -= 1;
      _elapsedInSceneMs = 0;
      _paused = false;
    });
    _resetKenBurns();
    _speakCurrent();
  }

  void _jumpTo(int idx) {
    if (idx < 0 || idx >= kShowreelScenes.length) return;
    setState(() {
      _sceneIdx = idx;
      _elapsedInSceneMs = 0;
      _paused = false;
    });
    _resetKenBurns();
    _speakCurrent();
  }

  void _onClose() {
    _ticker?.cancel();
    _tts.stop();
    if (mounted) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/features');
      }
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _kenBurns.dispose();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final scene = kShowreelScenes[_sceneIdx];
    final sceneProgress = (_elapsedInSceneMs / scene.durationMs).clamp(0.0, 1.0);
    final totalMs = showreelTotalMs();
    final elapsedSoFar = _elapsedSoFar();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(children: [
          // Сцена с Ken-Burns
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 140),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: AnimatedBuilder(
                    animation: _kenBurns,
                    builder: (context, child) => Transform.scale(
                      scale: 1.0 + 0.06 * _kenBurns.value,
                      child: child,
                    ),
                    child: FeatureMockFrame(
                      key: ValueKey(scene.id),
                      child: scene.builder(context),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Заголовок + субтитр
          Positioned(
            left: 20,
            right: 20,
            bottom: 96,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_sceneIdx + 1} / ${kShowreelScenes.length}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  scene.title(locale),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  scene.voiceover(locale),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ),
              ],
            ),
          ),
          // Close (X)
          Positioned(
            right: 12,
            top: 12,
            child: _circleBtn(
              icon: Icons.close_rounded,
              onTap: _onClose,
            ),
          ),
          // Контролы внизу
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(children: [
                // Прогресс-полоски по сценам
                Row(
                  children: List.generate(kShowreelScenes.length, (i) {
                    final isPast = i < _sceneIdx;
                    final isCurrent = i == _sceneIdx;
                    final w = isPast ? 1.0 : (isCurrent ? sceneProgress : 0.0);
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => _jumpTo(i),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: w,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                // Кнопки управления
                Row(children: [
                  _circleBtn(icon: Icons.chevron_left_rounded, onTap: _prev),
                  const SizedBox(width: 4),
                  _circleBtn(
                    icon: _paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    onTap: _togglePause,
                    big: true,
                  ),
                  const SizedBox(width: 4),
                  _circleBtn(icon: Icons.chevron_right_rounded, onTap: _next),
                  const Spacer(),
                  Text(
                    '${_formatTime(elapsedSoFar)} / ${_formatTime(totalMs)}',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _circleBtn(
                    icon: _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                    onTap: _toggleMute,
                  ),
                ]),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  int _elapsedSoFar() {
    int total = 0;
    for (int i = 0; i < _sceneIdx; i++) {
      total += kShowreelScenes[i].durationMs;
    }
    return total + _elapsedInSceneMs;
  }

  String _formatTime(int ms) {
    final s = ms ~/ 1000;
    final m = s ~/ 60;
    final r = s % 60;
    return '$m:${r.toString().padLeft(2, '0')}';
  }

  Widget _circleBtn({
    required IconData icon,
    required VoidCallback onTap,
    bool big = false,
  }) {
    final size = big ? 44.0 : 36.0;
    return Material(
      color: big ? Colors.white : Colors.white.withValues(alpha: 0.12),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: big ? 22 : 20, color: big ? Colors.black : Colors.white),
        ),
      ),
    );
  }
}
